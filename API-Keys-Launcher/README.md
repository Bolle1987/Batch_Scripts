# API-Key Start Scripts

Starts Visual Studio Code or Obsidian with Anthropic and OpenAI API keys provided as process-local environment variables.

The API keys are stored locally using Windows Data Protection API (DPAPI) instead of being saved as plaintext or as permanent Windows environment variables.

## Files

* `start_vscode_with_api.cmd`
  Entry point for starting the PowerShell script.

* `load_vscode_with_api.ps1`
  Loads or creates the encrypted API key files, sets the environment variables and starts VS Code.

* `start_obsidian_with_api.cmd`
  Entry point for starting Obsidian with API keys for Claudian.

* `load_obsidian_with_api.ps1`
  Loads or creates the same encrypted API key files, sets the environment variables and starts Obsidian.

## How it works

On first use, the script prompts for the configured API keys and stores them encrypted using Windows DPAPI:

```text
%USERPROFILE%\.claude\anthropic-key.dpapi
%USERPROFILE%\.codex\openai-key.dpapi
```

The encrypted files can only be decrypted by the same Windows user account on the same computer.

When VS Code or Obsidian is started, the keys are temporarily provided through these process-local environment variables:

```text
ANTHROPIC_API_KEY
OPENAI_API_KEY
```

The selected application inherits these variables when it starts. Obsidian passes them on to CLIs started by Claudian.

After the application has been launched, the variables and plaintext key values are removed from the PowerShell process.

## Requirements

* Windows
* PowerShell
* Visual Studio Code
* `code` command available through `PATH`
* Obsidian for `start_obsidian_with_api.cmd`

## Configuration

The default workspace is:

```powershell
$projectPath = "$env:USERPROFILE\GitHub"
```

Change this value in `load_vscode_with_api.ps1` if your projects are stored elsewhere.

Obsidian is expected at:

```text
%LOCALAPPDATA%\Programs\Obsidian\Obsidian.exe
```

Individual API keys can be enabled or disabled using:

```powershell
$UseClaudeKey = $true
$UseCodexKey = $true
```

## Usage

Run:

```text
start_vscode_with_api.cmd
```

Or, for Obsidian and Claudian:

```text
start_obsidian_with_api.cmd
```

Close Obsidian completely before using the Obsidian launcher. A running Obsidian process cannot inherit new environment variables, so the launcher stops with a message instead.

On the first start, you will be prompted for the enabled API keys. Subsequent starts use the encrypted copies stored in your user profile.

To replace a stored key, delete the corresponding `.dpapi` file. The script will prompt for a new key the next time it is started.

## Security considerations

The API keys are not stored as plaintext files and are not added permanently to the Windows user or system environment.

However, VS Code or Obsidian receives its own copy of the environment when it starts and retains the API keys for its entire lifetime.

**Any process running with sufficient access under the same Windows user account may potentially read environment variables belonging to the started application or its child processes.**

DPAPI protects the keys at rest. It does not protect them while they are actively being used by VS Code, Obsidian or their child processes.

The script also creates the following temporary log files containing the redirected VS Code startup output:

```text
%TEMP%\vscode_start_out.log
%TEMP%\vscode_start_err.log
%TEMP%\obsidian_start_out.log
%TEMP%\obsidian_start_err.log
```

The script itself does not write API keys to these files.

## Disclaimer

The scripts are provided **as-is, without warranty of any kind**.

Use them **at your own risk**. Review and understand the scripts before running them, especially on production systems.

The author assumes **no liability for data loss, system failures, downtime, exposure of credentials, or any other damage** resulting from the use of these scripts.

Always ensure that important data and system configurations are properly backed up before use.
