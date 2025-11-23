@echo off
echo Simple compilation without publish...

dotnet build -c Release

if exist "bin\Release\net8.0-windows\win-x64\RemoteClient.exe" (
    copy "bin\Release\net8.0-windows\win-x64\RemoteClient.exe" "WindowsService.exe"
    echo ✅ Simple build successful: WindowsService.exe
) else (
    echo Trying alternative...
    dotnet build -c Release -r win-x64
    if exist "bin\Release\net8.0-windows\win-x64\RemoteClient.exe" (
        copy "bin\Release\net8.0-windows\win-x64\RemoteClient.exe" "WindowsService.exe"
        echo ✅ Alternative build successful: WindowsService.exe
    ) else (
        echo ❌ All builds failed
    )
)

pause