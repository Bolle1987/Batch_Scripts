# =============================================================================
# VS Code mit API-Keys starten
#
# ZWECK
#   Startet VS Code und stellt ihm die API-Keys für Claude (Anthropic) und
#   Codex (OpenAI) als Umgebungsvariablen bereit, ohne sie im Klartext auf der
#   Platte oder dauerhaft in den Systemvariablen zu hinterlegen.
#
# ABLAUF
#   1. Key-Dateien werden geladen; fehlt eine, wird der Key einmalig abgefragt
#      (verdeckte Eingabe) und verschlüsselt gespeichert.
#   2. Die Keys landen als prozesslokale Umgebungsvariablen in dieser
#      PowerShell-Sitzung (ANTHROPIC_API_KEY, OPENAI_API_KEY).
#   3. VS Code wird gestartet (Workspace $projectPath) und erbt diese Umgebung.
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
#   - VS Code erhält beim Start eine eigene Kopie der Umgebung und behält die
#     Keys für seine gesamte Laufzeit. Das ist der Zweck des Skripts, lässt
#     sich aber nicht begrenzen: Jeder Prozess mit den Rechten des angemeldeten
#     Benutzers kann diese Umgebung auslesen.
#   - In der Konsole wird nur ein Präfix des Keys angezeigt (erste 10 Zeichen).
#   - Angelegt werden ausserdem zwei Logdateien mit der Startausgabe von VS Code
#     unter %TEMP% (vscode_start_out.log, vscode_start_err.log). Sie enthalten
#     keine Keys und werden bei jedem Start überschrieben.
#
# VORAUSSETZUNG
#   VS Code ist installiert und der Befehl "code" ist über PATH erreichbar.
# 
# 20260901 https://github.com/Bolle1987/Scripts
# =============================================================================

$projectPath = "$env:USERPROFILE\GitHub"

$UseClaudeKey = $true
$claudeFile = "$HOME\.claude\anthropic-key.dpapi"

$UseCodexKey = $true
$codexFile = "$HOME\.codex\openai-key.dpapi"

# Sekunden, die das Fenster nach dem Start offen bleibt, um den Key-Status
# prüfen zu können. 0 = sofort schliessen. Ein Tastendruck schliesst vorzeitig.
$CLOSEDELAY = 1

$claudePtr = [IntPtr]::Zero
$codexPtr = [IntPtr]::Zero

Write-Host ""

function Get-OrCreate-DpapiSecret {
    param (
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Prompt,

        [Parameter(Mandatory)]
        [string]$Name
    )

    Write-Host ""
    Write-Host "[$Name]"
    Write-Host "  Key-Datei: $Path"

    $dir = Split-Path $Path -Parent

    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Force $dir | Out-Null
    }

    if (-not (Test-Path $Path)) {
        Write-Host "  Status:    nicht gefunden - wird neu angelegt"
        Write-Host ""

        $secure = Read-Host $Prompt -AsSecureString

        # Leere Eingabe nicht speichern, sonst gilt der Key künftig als
        # vorhanden und landet ungültig in der Umgebungsvariable
        if ($secure.Length -eq 0) {
            Write-Host "  Status:    keine Eingabe - Key wird nicht angelegt"
            return $null
        }

        $secure |
            ConvertFrom-SecureString |
            Set-Content $Path

        Write-Host "  Status:    verschlüsselt gespeichert"
    }
    else {
        Write-Host "  Status:    gefunden"
    }

    return Get-Content $Path | ConvertTo-SecureString
}

try {
    if (-not (Test-Path $projectPath)) {
        throw "Projektordner nicht gefunden: $projectPath"
    }

    # Claude / Anthropic
    if ($UseClaudeKey) {
        $claudeSecure = Get-OrCreate-DpapiSecret `
            -Path $claudeFile `
            -Prompt "Anthropic API Key" `
            -Name "Claude / Anthropic"

        if ($null -eq $claudeSecure) {
            Write-Host "  Key:       uebersprungen (kein gueltiger Key)"
        }
        else {
            $claudePtr =
                [Runtime.InteropServices.Marshal]::SecureStringToBSTR($claudeSecure)

            $env:ANTHROPIC_API_KEY =
                [Runtime.InteropServices.Marshal]::PtrToStringBSTR($claudePtr)

            Write-Host "  Key:       $($env:ANTHROPIC_API_KEY.Substring(0, 10))..."
        }
    }

    # Codex / OpenAI
    if ($UseCodexKey) {
        $codexSecure = Get-OrCreate-DpapiSecret `
            -Path $codexFile `
            -Prompt "Codex / OpenAI API Key" `
            -Name "Codex / OpenAI"

        if ($null -eq $codexSecure) {
            Write-Host "  Key:       uebersprungen (kein gueltiger Key)"
        }
        else {
            $codexPtr =
                [Runtime.InteropServices.Marshal]::SecureStringToBSTR($codexSecure)

            $env:OPENAI_API_KEY =
                [Runtime.InteropServices.Marshal]::PtrToStringBSTR($codexPtr)

            Write-Host "  Key:       $($env:OPENAI_API_KEY.Substring(0, 10))..."
        }
    }

    # VS-Code-Installation über den vorhandenen code-Befehl ermitteln
    $codeCmd = (Get-Command code -ErrorAction Stop).Source
    $codeBin = Split-Path $codeCmd -Parent
    $codeRoot = Split-Path $codeBin -Parent
    $codeExe = Join-Path $codeRoot "Code.exe"

    if (-not (Test-Path $codeExe)) {
        throw "VS Code wurde nicht gefunden: $codeExe"
    }

    # cli.js suchen. Das entspricht dem Aufruf aus code.cmd, ohne cmd.exe
    # dazwischen. Direkter Code.exe-Aufruf ist keine Alternative: dann landen
    # die VS-Code-Logs (Storage, Deprecations, Jump List) in der Konsole.
    $cliJs = Get-ChildItem `
        -Path $codeRoot `
        -Filter "cli.js" `
        -File `
        -Recurse `
        -ErrorAction SilentlyContinue |
        Where-Object {
            $_.FullName -like "*\resources\app\out\cli.js"
        } |
        Select-Object -First 1 -ExpandProperty FullName

    if (-not $cliJs) {
        throw "VS Code CLI (resources\app\out\cli.js) wurde nicht gefunden."
    }

    # Entspricht den Variablen aus der originalen code.cmd
    $env:VSCODE_DEV = ""
    $env:ELECTRON_RUN_AS_NODE = "1"

    # Ausgabe in Dateien umleiten, damit VS Code nicht das stdout-Handle der
    # Konsole erbt. Ohne Umleitung hält Code.exe dieses Handle dauerhaft offen
    # (nachgewiesen mit handle64: \Device\ConDrv\CurrentOut), wodurch conhost.exe
    # und damit das Fenster bis zum Beenden von VS Code stehen bleiben.
    $outLog = Join-Path $env:TEMP "vscode_start_out.log"
    $errLog = Join-Path $env:TEMP "vscode_start_err.log"

    Start-Process `
        -FilePath $codeExe `
        -ArgumentList @(
            "`"$cliJs`"",
            "`"$projectPath`""
        ) `
        -RedirectStandardOutput $outLog `
        -RedirectStandardError $errLog

}
catch {
    Write-Host ""
    Write-Host "Fehler: $($_.Exception.Message)"
    Write-Host ""
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
    Remove-Item Env:ELECTRON_RUN_AS_NODE -ErrorAction SilentlyContinue
    Remove-Item Env:VSCODE_DEV -ErrorAction SilentlyContinue
}

# Wartezeit bewusst nach dem finally-Block: Keys und Umgebungsvariablen sind
# zu diesem Zeitpunkt bereits gelöscht
if ($CLOSEDELAY -gt 0) {
    Write-Host ""

    # Eingabepuffer leeren: enthält beim Start bereits Ereignisse (Doppelklick,
    # Fokuswechsel), die den Countdown sonst sofort abbrechen würden
    $Host.UI.RawUI.FlushInputBuffer()

    $keyPressed = $false

    for ($remaining = $CLOSEDELAY; $remaining -gt 0 -and -not $keyPressed; $remaining--) {
        # Nachgestellte Leerzeichen überschreiben Reste laengerer Zahlen
        Write-Host "`rSchliesst in $remaining s - Taste zum sofortigen Schliessen  " -NoNewline

        # In Teilschritten warten, damit ein Tastendruck sofort greift
        for ($tick = 0; $tick -lt 10; $tick++) {
            if ($Host.UI.RawUI.KeyAvailable) {
                # Taste auslesen, damit sie nicht im Puffer verbleibt
                $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
                $keyPressed = $true
                break
            }

            Start-Sleep -Milliseconds 100
        }
    }

    Write-Host ""
}

Stop-Process -Id $PID -Force
