@echo off & color 2 & cls & title Bolle's Disable USB Power Saving Management (%0)
echo ===================================
echo.
echo  Bolle's DisableUSBPowerSaving.cmd
echo.
echo ===================================
echo.

goto checkPrivileges
:gotPrivileges

echo PowerShell script to disable Windows power management on all currently connected usb ports
echo In simpler terms, it prevents Windows from turning off connected usb devices to save power.
echo Equivalent to right-clicking on a usb port device in Device Manager ^> Properties ^> "Power Management" Tab ^> Unchecking "Allow the computer to turn off this device to save power."
echo.
pause
echo.

set psscript="%temp%\Disable_USB_Power_Saving_Management.ps1"
echo ^# PowerShell script to disable Windows power management on all currently connected usb ports>%psscript%
echo ^# In simpler terms, it prevents Windows from turning off connected usb devices to save power.>>%psscript%
echo ^# Equivalent to right-clicking on a usb port device in Device Manager > Properties > "Power Management" Tab > Unchecking "Allow the computer to turn off this device to save power.">>%psscript%
echo. >>%psscript%
echo ^# Dynamic power devices>>%psscript%
echo $powerMgmt = Get-CimInstance -ClassName MSPower_DeviceEnable -Namespace root/WMI>>%psscript%
echo. >>%psscript%
echo ^# All USB devices>>%psscript%
echo $UsbDevices = Get-CimInstance -ClassName Win32_PnPEntity -Filter 'PNPClass = "USB"'>>%psscript%
echo. >>%psscript%
echo $UsbDevices ^| ForEach-Object {>>%psscript%
echo     ^# Get the power management instance for this device, if there is one>>%psscript%
echo     $powerMgmt ^| Where-Object InstanceName -Like "*$($_.PNPDeviceID)*">>%psscript%
echo } ^| Set-CimInstance -Property @{Enable = $false}>>%psscript%
echo. >>%psscript%
echo Remove-Item -Force -Path %psscript%>>%psscript%

powershell.exe -ExecutionPolicy unrestricted -File %psscript%

echo Done!
echo.
pause
exit

:checkPrivileges 
NET FILE 1>NUL 2>NUL
if '%errorlevel%' == '0' ( goto gotPrivileges 
) else ( powershell "Start-Process -filepath '%0' -verb runas" >nul 2>&1)
exit /b