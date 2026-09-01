#Requires -Version 5.1

<#
DISCLAIMER:
This script is provided without any warranty.
Use at your own risk.
BIOS updates can render devices unusable.
Before running this script:
- Verify the device manufacturer
- Ensure a stable power supply
- Create a full backup


.SYNOPSIS
    Updates the BIOS on Dell computers to the latest available version.

.DESCRIPTION
    Downloads and parses the Dell catalog XML to determine the latest BIOS
    update for the current system. If a newer version is available, it
    downloads and installs the update.

    Supports logging, hash verification, and unattended execution.
    Automatically requests administrative privileges if required.

    Safe to run repeatedly: the working directory is always cleaned up
    before and after each run, preventing stale files from accumulating.

.PARAMETER LogPath
    Path to the log file.
    Defaults to $env:TEMP\Update-Dell-BIOS.log

.PARAMETER Silent
    Suppresses all console output and skips the final pause.
    Intended for unattended deployments (e.g. SCCM / Intune).

.PARAMETER NoPause
    Skips the "Press any key" prompt at the end while still showing console output.

.PARAMETER DownloadOnly
    Downloads the BIOS update but does not install it.

.EXAMPLE
    PS C:\> .\Update-Dell-BIOS.ps1
    Interactive mode. Checks for and installs a BIOS update if available.

.EXAMPLE
    PS C:\> .\Update-Dell-BIOS.ps1 -Silent
    Unattended mode for deployment tools.

.EXAMPLE
    PS C:\> .\Update-Dell-BIOS.ps1 -DownloadOnly
    Downloads the BIOS file without installing it.

.NOTES
    Author  : Bolle1987 (optimized version)
    Original: https://github.com/boustba/Update-DellBIOS.ps1
    Requires: Dell system, internet access (administrator rights are requested automatically)
#>

[CmdletBinding()]
param (
    [string]$LogPath = (Join-Path $env:TEMP 'Update-Dell-BIOS.log'),
    [switch]$Silent,
    [switch]$NoPause,
    [switch]$DownloadOnly
)

#region Self Elevation
# If not running as admin, relaunch this script elevated and pass all parameters through.
$currentIdentity  = [Security.Principal.WindowsIdentity]::GetCurrent()
$currentPrincipal = [Security.Principal.WindowsPrincipal]$currentIdentity
$isAdmin          = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host 'Requesting administrator privileges...' -ForegroundColor Yellow

    # Determine script path. When invoked via iex (Invoke-Expression) there is
    # no file on disk, so $MyInvocation.MyCommand.Path is empty. In that case
    # we save the running script to a temp file and elevate that instead.
    $scriptPath = $MyInvocation.MyCommand.Path
    if ([string]::IsNullOrWhiteSpace($scriptPath)) {
        $scriptPath = Join-Path $env:TEMP 'Update-Dell-BIOS.ps1'
        # $MyInvocation.MyCommand.ScriptBlock contains the full script text when run via iex
        Set-Content -Path $scriptPath -Value $MyInvocation.MyCommand.ScriptBlock.ToString() -Encoding UTF8 -Force
        Write-Host "Running via iex: saved script to $scriptPath" -ForegroundColor DarkGray
    }

    $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$scriptPath`"")
    if ($LogPath)      { $argList += "-LogPath `"$LogPath`"" }
    if ($Silent)       { $argList += '-Silent' }
    if ($NoPause)      { $argList += '-NoPause' }
    if ($DownloadOnly) { $argList += '-DownloadOnly' }

    try {
        # Close this window immediately once the elevated process launches
        Start-Process -FilePath 'powershell.exe' -ArgumentList $argList -Verb RunAs
        exit 0
    }
    catch {
        # UAC was denied or another error occurred
        Write-Host ''
        Write-Host 'ERROR: Admin privileges are required but were not granted.' -ForegroundColor Red
        Write-Host 'The script cannot continue without administrator rights.' -ForegroundColor Red
        Write-Host ''
        Pause
        exit 1
    }
}
#endregion

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#region Configuration
$DellCatalogUrl    = 'https://downloads.dell.com/catalog/'
$DellDownloadsBase = 'https://downloads.dell.com/'
$CatalogCabName    = 'CatalogIndexPC.cab'
$WorkDir           = Join-Path $env:TEMP 'DellBIOSUpdate'
#endregion

#region Functions

function Write-Log {
    param (
        [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error')]
        [string]$Level = 'Info'
    )
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $entry = "[$timestamp] [$Level] $Message"
    Add-Content -Path $LogPath -Value $entry -ErrorAction SilentlyContinue

    if (-not $Silent) {
        switch ($Level) {
            'Error'   { Write-Host $entry -ForegroundColor Red }
            'Warning' { Write-Host $entry -ForegroundColor Yellow }
            default   { Write-Host $entry -ForegroundColor Cyan }
        }
    }
}

function Wait-IfInteractive {
    # Pauses by default so the user can read the output.
    # Skipped with -Silent or -NoPause (for SCCM/Intune/automation).
    if (-not $Silent -and -not $NoPause) {
        Write-Host ''
        Pause
    }
}

function Get-SystemId {
    [CmdletBinding()]
    param ([CimInstance]$SystemInfo)

    # Prefer SystemSKUNumber (reliable on modern Dell systems)
    $sku = $SystemInfo.SystemSKUNumber
    if (-not [string]::IsNullOrWhiteSpace($sku)) {
        Write-Log "System ID from SKU: $sku"
        return $sku
    }

    # Fallback: parse OEMStringArray
    $oemArray = $SystemInfo.OEMStringArray
    if ($null -eq $oemArray -or $oemArray.Count -lt 2) {
        throw 'Cannot determine System ID: OEMStringArray is missing or too short.'
    }

    foreach ($entry in $oemArray) {
        if ($entry -match '\[(.+?)\]') {
            $id = $Matches[1]
            Write-Log "System ID from OEMStringArray: $id"
            return $id
        }
    }

    throw 'Cannot determine System ID: no bracketed value found in OEMStringArray.'
}

function Get-ModelNumber {
    [CmdletBinding()]
    param ([string]$FullModelString)

    if ($FullModelString -match '[A-Z]?[0-9]{4}[a-zA-Z]?') {
        return $Matches[0]
    }

    Write-Log "Could not extract model number from '$FullModelString', using full string." -Level Warning
    return $FullModelString
}

function Invoke-FileDownload {
    param (
        [string]$Uri,
        [string]$Destination
    )
    Write-Log "Downloading: $Uri"

    # Use TLS 1.2+ for HTTPS
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13

    try {
        $ProgressPreference = 'SilentlyContinue'  # Speeds up Invoke-WebRequest significantly
        Invoke-WebRequest -Uri $Uri -OutFile $Destination -UseBasicParsing -ErrorAction Stop
        Write-Log "Downloaded to: $Destination"
    }
    catch {
        throw "Download failed for '$Uri': $_"
    }
}

function Expand-CabFile {
    param (
        [string]$CabPath,
        [string]$FileName,
        [string]$DestinationDir
    )

    if (-not (Test-Path $DestinationDir)) {
        New-Item -ItemType Directory -Path $DestinationDir -Force | Out-Null
    }

    $targetPath = Join-Path $DestinationDir $FileName
    Write-Log "Expanding '$FileName' from '$CabPath'"

    # Pass the full output FILE path (proven working approach)
    $expandResult = & expand.exe $CabPath -F:$FileName $targetPath 2>&1
    Write-Log "expand.exe output: $expandResult"

    if (-not (Test-Path $targetPath)) {
        throw "Extraction failed: '$targetPath' not found. expand.exe said: $expandResult"
    }

    Write-Log "Extracted: $targetPath"
    return $targetPath
}

function Convert-BiosVersionToObject {
    param ([string]$VersionString)

    $cleaned = $VersionString.Trim()

    # Handle Dell "A##" format, e.g. "A12" becomes "1.2"
    if ($cleaned -match '^A(\d+)$') {
        $digits = $Matches[1]
        if ($digits.Length -ge 2) {
            $cleaned = $digits.Insert($digits.Length - 1, '.')
        }
    }

    try {
        return [version]$cleaned
    }
    catch {
        throw "Cannot parse BIOS version '$VersionString' (cleaned: '$cleaned') as a version object."
    }
}

function Remove-WorkDir {
    if (Test-Path $WorkDir) {
        Remove-Item -Path $WorkDir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Log 'Cleaned up temporary files.'
    }
}

#endregion

#region Main

try {
    Write-Log '=== Dell BIOS Update Script started ==='

    # Always start with a clean working directory (removes leftovers from previous runs)
    if (Test-Path $WorkDir) {
        Remove-Item -Path $WorkDir -Recurse -Force
        Write-Log 'Removed leftover working directory from previous run.'
    }
    New-Item -ItemType Directory -Path $WorkDir -Force | Out-Null

    # Gather system info
    $cimBios   = Get-CimInstance -ClassName CIM_BIOSElement
    $cimSystem = Get-CimInstance -ClassName CIM_ComputerSystem

    $model       = $cimSystem.Model
    $biosVersion = $cimBios.SMBIOSBIOSVersion
    $systemId    = Get-SystemId -SystemInfo $cimSystem

    Write-Log "Model: $model | BIOS: $biosVersion | SystemID: $systemId"

    # Download and parse main catalog
    $cabPath = Join-Path $WorkDir $CatalogCabName
    Invoke-FileDownload -Uri "$DellCatalogUrl$CatalogCabName" -Destination $cabPath

    $xmlName = $CatalogCabName.Replace('.cab', '.xml')
    $xmlPath = Expand-CabFile -CabPath $cabPath -FileName $xmlName -DestinationDir $WorkDir

    [xml]$catalog = Get-Content -Path $xmlPath -ErrorAction Stop
    $modelManifest = $catalog.ManifestIndex.GroupManifest |
        Where-Object { $_.SupportedSystems.Brand.Model.systemID -eq $systemId }

    if ($null -eq $modelManifest) {
        Write-Log "System ID '$systemId' not found in Dell catalog. This model may not be supported." -Level Error
        Wait-IfInteractive
        exit 1
    }

    $modelCabRelPath = $modelManifest.ManifestInformation.path
    Write-Log "Model catalog path: $modelCabRelPath"

    # Download and parse model specific catalog
    $modelCabName = Split-Path $modelCabRelPath -Leaf
    $modelCabPath = Join-Path $WorkDir $modelCabName
    Invoke-FileDownload -Uri "$DellDownloadsBase$modelCabRelPath" -Destination $modelCabPath

    $modelXmlName = $modelCabName.Replace('.cab', '.xml')
    $modelXmlPath = Expand-CabFile -CabPath $modelCabPath -FileName $modelXmlName -DestinationDir $WorkDir

    [xml]$modelXml = Get-Content -Path $modelXmlPath -ErrorAction Stop
    $components    = $modelXml.Manifest.SoftwareComponent
    $modelNumber   = Get-ModelNumber -FullModelString $model

    Write-Log "Searching BIOS packages for model number: $modelNumber"

    # Find BIOS packages: primary match on SupportedDevices, fallback on SupportedSystems
    $biosPackages = $components | Where-Object {
        $_.ComponentType.value -eq 'BIOS' -and
        $($_.SupportedDevices.Device.Display.'#cdata-section') -match [regex]::Escape($modelNumber)
    }

    if ($null -eq $biosPackages) {
        $biosPackages = $components | Where-Object {
            $_.ComponentType.value -eq 'BIOS' -and
            $($_.SupportedSystems.Brand.Model.Display.'#cdata-section') -match [regex]::Escape($modelNumber)
        }
    }

    if ($null -eq $biosPackages) {
        Write-Log "No BIOS packages found for model '$modelNumber'." -Level Error
        Wait-IfInteractive
        exit 1
    }

    # Select the newest BIOS package by version (not by array position)
    $latestBios = $biosPackages | Sort-Object {
        Convert-BiosVersionToObject -VersionString $_.dellVersion
    } | Select-Object -Last 1

    $installedVersion = Convert-BiosVersionToObject -VersionString $biosVersion
    $availableVersion = Convert-BiosVersionToObject -VersionString $latestBios.dellVersion

    Write-Log "Installed: $installedVersion | Available: $availableVersion"

    # Compare versions
    if ($installedVersion -ge $availableVersion) {
        Write-Log 'BIOS is already up to date. Nothing to do.' -Level Info
        Remove-WorkDir
        Wait-IfInteractive
        exit 0
    }

    Write-Log "Update available: $installedVersion -> $availableVersion"

    # Download BIOS update
    $biosFileUrl  = "$DellDownloadsBase$($latestBios.path)"
    $biosFileName = Split-Path $latestBios.path -Leaf
    $biosFilePath = Join-Path $WorkDir $biosFileName

    Invoke-FileDownload -Uri $biosFileUrl -Destination $biosFilePath

    # Verify hash if available in the catalog
	$expectedHash = if ($latestBios.PSObject.Properties['hashMD5']) {
		$latestBios.hashMD5
		} elseif ($latestBios.PSObject.Properties['hashValue'] -and $latestBios.hashingAlgorithm -eq 'MD5') {
			$latestBios.hashValue
		} else {
			$null
		}
		if (-not [string]::IsNullOrWhiteSpace($expectedHash)) {
			$actualHash = (Get-FileHash -Path $biosFilePath -Algorithm MD5).Hash
			if ($actualHash -ne $expectedHash) {
				throw "Hash mismatch! Expected: $expectedHash, Got: $actualHash. The download may be corrupted."
				}
			Write-Log "Hash verified (MD5: $actualHash)"
			}
    else {
        Write-Log 'No hash available in catalog, skipping verification.' -Level Warning
    }

    if ($DownloadOnly) {
        $finalPath = Join-Path $env:TEMP $biosFileName
        Copy-Item -Path $biosFilePath -Destination $finalPath -Force
        Write-Log "Download only mode. BIOS file saved to: $finalPath"
        Remove-WorkDir
        Wait-IfInteractive
        exit 0
    }

    # Install BIOS update
    Write-Log "Installing BIOS update: $biosFileName"
    $installArgs = '/s /r'  # /s = Silent, /r = Reboot when required
    $process = Start-Process -FilePath $biosFilePath -ArgumentList $installArgs -Verb RunAs -PassThru -Wait
    Write-Log "Installer exited with code: $($process.ExitCode)"

    if ($process.ExitCode -notin @(0, 2)) {
        # 0 = Success, 2 = Reboot required (expected for BIOS)
        Write-Log "Installer returned unexpected exit code: $($process.ExitCode)" -Level Warning
    }

    Remove-WorkDir
    Write-Log '=== Dell BIOS Update Script completed ==='
    Wait-IfInteractive
}
catch {
    Write-Log "FATAL: $($_.Exception.Message)" -Level Error
    Write-Log "Stack: $($_.ScriptStackTrace)" -Level Error
    Remove-WorkDir
    Wait-IfInteractive
    exit 1
}

#endregion
