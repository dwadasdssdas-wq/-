@echo off
echo Quick test build with .NET 6.0...

(
echo ^<Project Sdk="Microsoft.NET.Sdk"^>
echo   ^<PropertyGroup^>
echo     ^<OutputType^>WinExe^</OutputType^>
echo     ^<TargetFramework^>net6.0-windows^</TargetFramework^>
echo     ^<UseWindowsForms^>true^</UseWindowsForms^>
echo     ^<PublishSingleFile^>true^</PublishSingleFile^>
echo     ^<RuntimeIdentifier^>win-x64^</RuntimeIdentifier^>
echo   ^</PropertyGroup^>
echo ^</Project^>
) > test.csproj

dotnet publish test.csproj -c Release -o test-dist

if exist "test-dist\test.exe" (
    ren "test-dist\test.exe" "WindowsService.exe"
    echo ✅ Test build successful!
    move "test-dist\WindowsService.exe" "dist\"
    rmdir /s /q "test-dist"
) else (
    echo ❌ Test build failed
)

del test.csproj
pause