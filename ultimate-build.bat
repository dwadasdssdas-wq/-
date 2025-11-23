@echo off
echo ULTIMATE BUILD SOLUTION

echo Method 1: Direct compilation
dotnet new winforms -n TempApp --force
cd TempApp
copy ..\Program.cs .
dotnet publish -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -o ..\dist
cd ..
if exist "dist\TempApp.exe" (
    ren "dist\TempApp.exe" "WindowsService.exe"
    echo ✅ Method 1 Success
    goto success
)

echo Method 2: Manual compilation
set csc="C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if exist %csc% (
    %csc% /target:winexe /out:dist\WindowsService.exe /reference:System.dll /reference:System.Windows.Forms.dll /reference:System.Drawing.dll /reference:System.Net.WebSockets.dll Program.cs
    if exist "dist\WindowsService.exe" (
        echo ✅ Method 2 Success
        goto success
    )
)

echo ❌ ALL METHODS FAILED
echo Install Visual Studio Build Tools or .NET SDK
pause
exit

:success
echo.
echo 🎉 WINDOWSSERVICE.EXE CREATED!
echo Location: dist\WindowsService.exe
echo Size: 
dir "dist\WindowsService.exe"
pause