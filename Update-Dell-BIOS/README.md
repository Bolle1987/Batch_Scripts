# Update-Dell-BIOS.ps1

A PowerShell script that downloads and parses XML files from downloads.dell.com to update the BIOS to the latest available version.

> [!IMPORTANT]
> **WARNING:**  
> This script performs a BIOS update.  
> BIOS updates can render a device unusable.  
> Use at your own risk.
>
> Ensure before use:
> - You are running this on a Dell system
> - The device is connected to reliable power
> - Important data is backed up

> [!NOTE]
> **PowerShell command:**
>
> ```powershell
> iex (irm https://boll.digital/dell)
> ```
>
> **PowerShell command with direct GitHub URL:**
>
> ```powershell
> iex (irm https://raw.githubusercontent.com/Bolle1987/Scripts/main/Update-Dell-BIOS/Update-Dell-BIOS.ps1)
> ```
