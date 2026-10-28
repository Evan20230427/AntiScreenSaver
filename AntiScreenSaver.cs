using System;
using System.Runtime.InteropServices;
using System.Threading;

namespace AntiScreenSaver
{
    /// <summary>
    /// Win32 底層 API 封裝類別
    /// </summary>
    internal static class NativeMethods
    {
        // 執行緒電源狀態常數
        public const uint ES_SYSTEM_REQUIRED = 0x00000001;
        public const uint ES_DISPLAY_REQUIRED = 0x00000002;
        public const uint ES_CONTINUOUS = 0x80000000;

        // 滑鼠事件常數 (相對位移)
        public const uint MOUSEEVENTF_MOVE = 0x0001;

        /// <summary>
        /// 設定當前執行緒之系統執行狀態以阻止睡眠或螢幕關閉
        /// </summary>
        [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        public static extern uint SetThreadExecutionState(uint esFlags);

        /// <summary>
        /// 綜合滑鼠事件模擬 (重置 Windows GetLastInputInfo 閒置計時器)
        /// </summary>
        [DllImport("user32.dll")]
        public static extern void mouse_event(uint dwFlags, uint dx, uint dy, uint dwData, UIntPtr dwExtraInfo);
    }

    /// <summary>
    /// 單一職責原則 (SRP): 負責執行滑鼠微動與電源狀態重置之核心服務
    /// </summary>
    public class IdleResetService
    {
        /// <summary>
        /// 宣告系統維持顯示與運作狀態
        /// </summary>
        public static void MaintainExecutionState()
        {
            NativeMethods.SetThreadExecutionState(
                NativeMethods.ES_CONTINUOUS | 
                NativeMethods.ES_DISPLAY_REQUIRED | 
                NativeMethods.ES_SYSTEM_REQUIRED
            );
        }

        /// <summary>
        /// 執行 1 像素無感滑鼠微動以重置 GPO 閒置計時器
        /// </summary>
        public static void JiggleMouse()
        {
            // 向右移動 1 像素，隨即向左移回 1 像素，使用者完全無感但 Windows 輸入計時器立即歸零
            NativeMethods.mouse_event(NativeMethods.MOUSEEVENTF_MOVE, 1, 0, 0, UIntPtr.Zero);
            NativeMethods.mouse_event(NativeMethods.MOUSEEVENTF_MOVE, unchecked((uint)-1), 0, 0, UIntPtr.Zero);
        }
    }

    /// <summary>
    /// 程式主要進入點
    /// </summary>
    internal class Program
    {
        private static volatile bool _isRunning = true;

        private static void Main(string[] args)
        {
            Console.OutputEncoding = System.Text.Encoding.UTF8;
            Console.Title = "AntiScreenSaver - 主人的專屬防休眠喚醒器 (C# 原生版)";

            Console.CancelKeyPress += (sender, e) =>
            {
                e.Cancel = true;
                _isRunning = false;
            };

            Console.ForegroundColor = ConsoleColor.Cyan;
            Console.WriteLine("======================================================");
            Console.WriteLine("      AntiScreenSaver - 專屬防休眠守護器 (原生 C# 版)");
            Console.WriteLine("======================================================");
            Console.ResetColor();
            Console.WriteLine("運作機制：");
            Console.WriteLine("  1. 宣告 Win32 SetThreadExecutionState (系統/顯示器清醒)");
            Console.WriteLine("  2. 每 60 秒模擬 1 像素微動，重置 Windows 閒置逾時計時器");
            Console.WriteLine("  3. 100% 繞過企業網域 GPO 螢幕保護與鎖定政策\n");
            Console.ForegroundColor = ConsoleColor.Yellow;
            Console.WriteLine("隨時按下 [Q] 鍵或 [Ctrl+C] 即可安全退出程式。\n");
            Console.ResetColor();

            // 啟用電源喚醒鎖定
            IdleResetService.MaintainExecutionState();

            DateTime startTime = DateTime.Now;
            int pulseCount = 0;

            // 啟動鍵盤監聽執行緒
            Thread inputThread = new Thread(() =>
            {
                while (_isRunning)
                {
                    if (Console.KeyAvailable)
                    {
                        var key = Console.ReadKey(true);
                        if (key.Key == ConsoleKey.Q)
                        {
                            _isRunning = false;
                            break;
                        }
                    }
                    Thread.Sleep(200);
                }
            })
            {
                IsBackground = true
            };
            inputThread.Start();

            // 主防護迴圈 (每 60 秒微動一次，每秒更新計時器)
            int secondCounter = 0;
            while (_isRunning)
            {
                TimeSpan elapsed = DateTime.Now - startTime;
                string timeStr = string.Format("{0:D2}:{1:D2}:{2:D2}", (int)elapsed.TotalHours, elapsed.Minutes, elapsed.Seconds);

                Console.Write("\r[☕ 運行中] 已維持清醒: {0} | 閒置重置次數: {1} 次  ", timeStr, pulseCount);

                Thread.Sleep(1000);
                secondCounter++;

                if (secondCounter >= 60)
                {
                    secondCounter = 0;
                    IdleResetService.JiggleMouse();
                    IdleResetService.MaintainExecutionState();
                    pulseCount++;
                }
            }

            // 釋放鎖定
            NativeMethods.SetThreadExecutionState(NativeMethods.ES_CONTINUOUS);
            Console.WriteLine("\n\n已安全解除防休眠狀態，程式結束。祝主人工作愉快！");
        }
    }
}
