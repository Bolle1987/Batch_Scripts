# =============================================================================
# Obsidian mit API-Keys starten
#
# ZWECK
#   Startet Obsidian und stellt Claudian die API-Keys für Claude (Anthropic)
#   und Codex (OpenAI) als Umgebungsvariablen bereit, ohne sie im Klartext auf
#   der Platte oder dauerhaft in den Systemvariablen zu hinterlegen.
#
# ABLAUF
#   1. Key-Dateien werden geladen; fehlt eine, wird der Key einmalig abgefragt
#      (verdeckte Eingabe) und verschlüsselt gespeichert.
#   2. Die Keys landen als prozesslokale Umgebungsvariablen in dieser
#      PowerShell-Sitzung (ANTHROPIC_API_KEY, OPENAI_API_KEY).
#   3. Obsidian wird gestartet und erbt diese Umgebung für Claudian.
#   4. Direkt danach werden Keys und Umgebungsvariablen aus diesem Prozess
#      entfernt und die Sitzung beendet.
#
# DATENSCHUTZ / SICHERHEIT
#   - Speicherort der Keys:
#       %USERPROFILE%\.claude\anthropic-key.dpapi
#       %USERPROFILE%\.codex\openai-key.dpapi
#   - Verschlüsselung per Windows DPAPI: entschlüsselbar ausschliesslich vom
#     selben Windows-Benutzerkonto auf demselben Rechner. Kopieren der Dateien
#     auf einen anderen Rechner oder zu einem anderen Benutzer nützt nichts.
#   - Die Keys werden von diesem Skript nirgendwohin übertragen und nie im
#     Klartext auf die Platte geschrieben.
#   - Die Umgebungsvariablen sind prozesslokal (Scope Process), nicht Benutzer-
#     oder Systemvariablen. Sie tauchen also nicht in den Windows-Einstellungen
#     auf und überdauern die Sitzung nicht.
#   - Obsidian erhält beim Start eine eigene Kopie der Umgebung und behält die
#     Keys für seine gesamte Laufzeit. Jeder Prozess mit den Rechten des
#     angemeldeten Benutzers kann diese Umgebung währenddessen auslesen.
#   - In der Konsole wird nur ein Präfix des Keys angezeigt (erste 10 Zeichen).
#   - Angelegt werden ausserdem zwei Logdateien mit der Startausgabe von
#     Obsidian unter %TEMP% (obsidian_start_out.log, obsidian_start_err.log).
#     Sie enthalten keine Keys und werden bei jedem Start überschrieben.
#
# VORAUSSETZUNG
#   Obsidian ist unter %LOCALAPPDATA%\Programs\Obsidian installiert.
#   Alternativ bitte Pfadvariable unten anpassen: $obsidianExe
# 
# 20260912 https://github.com/Bolle1987/Scripts
# =============================================================================

$UseClaudeKey = $true
$claudeFile = "$HOME\.claude\anthropic-key.dpapi"

$UseCodexKey = $true
$codexFile = "$HOME\.codex\openai-key.dpapi"

# Sekunden, die das Fenster nach dem Start offen bleibt, um den Key-Status
# prüfen zu können. 0 = sofort schliessen. Ein Tastendruck schliesst vorzeitig.
$CLOSEDELAY = 1

$obsidianExe = "$env:LOCALAPPDATA\Programs\Obsidian\Obsidian.exe"

$claudePtr = [IntPtr]::Zero
$codexPtr = [IntPtr]::Zero

function Get-OrCreate-DpapiSecret {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Prompt,

        [Parameter(Mandatory)]
        [string]$Name
    )

    $directory = Split-Path -Path $Path -Parent
    if (-not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }

    if (-not (Test-Path -LiteralPath $Path)) {
        Write-Host "[$Name] Key-Datei fehlt und wird einmalig angelegt."
        $secure = Read-Host -Prompt $Prompt -AsSecureString
        if ($secure.Length -eq 0) {
            Write-Host "[$Name] uebersprungen (kein gueltiger Key)."
            return $null
        }
        $secure | ConvertFrom-SecureString | Set-Content -LiteralPath $Path
    }

    Get-Content -LiteralPath $Path | ConvertTo-SecureString
}

function Write-KeyStatus {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$Value
    )

    $prefixLength = [Math]::Min(10, $Value.Length)
    Write-Host "${Name}: $($Value.Substring(0, $prefixLength))..."
}

try {
    if (Get-Process -Name Obsidian -ErrorAction SilentlyContinue) {
        throw "Obsidian laeuft bereits. Bitte vollstaendig beenden und diesen Starter erneut ausfuehren."
    }
    if (-not (Test-Path -LiteralPath $obsidianExe)) {
        throw "Obsidian wurde nicht gefunden: $obsidianExe"
    }

    if ($UseClaudeKey) {
        $claudeSecure = Get-OrCreate-DpapiSecret -Path $claudeFile -Prompt "Anthropic API Key" -Name "Claude / Anthropic"
        if ($null -ne $claudeSecure) {
            $claudePtr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($claudeSecure)
            $env:ANTHROPIC_API_KEY = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($claudePtr)
            Write-KeyStatus -Name "Claude / Anthropic" -Value $env:ANTHROPIC_API_KEY
        }
    }

    if ($UseCodexKey) {
        $codexSecure = Get-OrCreate-DpapiSecret -Path $codexFile -Prompt "OpenAI API Key" -Name "Codex / OpenAI"
        if ($null -ne $codexSecure) {
            $codexPtr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($codexSecure)
            $env:OPENAI_API_KEY = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($codexPtr)
            Write-KeyStatus -Name "Codex / OpenAI" -Value $env:OPENAI_API_KEY
        }
    }

    $outLog = Join-Path $env:TEMP "obsidian_start_out.log"
    $errLog = Join-Path $env:TEMP "obsidian_start_err.log"
    Start-Process `
        -FilePath $obsidianExe `
        -RedirectStandardOutput $outLog `
        -RedirectStandardError $errLog
    Write-Host "Obsidian wurde mit prozesslokalen API-Keys gestartet."
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}
finally {
    if ($claudePtr -ne [IntPtr]::Zero) {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($claudePtr)
    }
    if ($codexPtr -ne [IntPtr]::Zero) {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($codexPtr)
    }
    Remove-Item Env:ANTHROPIC_API_KEY -ErrorAction SilentlyContinue
    Remove-Item Env:OPENAI_API_KEY -ErrorAction SilentlyContinue
}

if ($CLOSEDELAY -gt 0) {
    $Host.UI.RawUI.FlushInputBuffer()
    $keyPressed = $false

    for ($remaining = $CLOSEDELAY; $remaining -gt 0 -and -not $keyPressed; $remaining--) {
        Write-Host "`rSchliesst in $remaining s - Taste zum sofortigen Schliessen  " -NoNewline
        for ($tick = 0; $tick -lt 10; $tick++) {
            if ($Host.UI.RawUI.KeyAvailable) {
                $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
                $keyPressed = $true
                break
            }
            Start-Sleep -Milliseconds 100
        }
    }
    Write-Host ""
}
