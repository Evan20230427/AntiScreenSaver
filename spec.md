# AntiScreenSaver 規格文件 (spec.md)

## 1. 架構與選型
本專案提供多軌架構，徹底解決一般環境與企業 GPO 嚴格受限環境下的休眠問題：

1. **強化版免安裝網頁喚醒版 (`KeepAwake.html`)**
   - **平臺**: 現代瀏覽器 (Microsoft Edge, Google Chrome, Firefox 等)
   - **多重防護機制**:
     - **主鎖定**: W3C Screen Wake Lock API（前景顯示器鎖定）
     - **背景不凍結 (Audible Audio)**: Web Audio API 微弱次音頻產生器（20Hz / 振幅 0.0005），模擬持續音訊播放，防止背景分頁被瀏覽器休眠，並向作業系統宣告媒體運作。
     - **畫中畫（Picture-in-Picture, PiP）機制**: 利用 `<canvas>` 動態串流彈出 PiP 小視窗，強制分頁維持實質前景活躍狀態，徹底消除 WakeLock 在背景被瀏覽器自動釋放的問題。
     - **離線音訊循環備援**: 內建有效之無聲循環音軌 Data URI。

2. **原生 C# 免安裝雙保險版 (`AntiScreenSaver.cs` / `AntiScreenSaver.exe`)**
   - **作業系統**: Windows 10 / 11
   - **編譯器**: Windows 內建 .NET Framework 編譯器 (`csc.exe`)，無須安裝額外 SDK
   - **Win32 API 調用**:
     - `mouse_event`: 每 60 秒微幅移動滑鼠游標 (±1 px)，重置 Windows `GetLastInputInfo` 輸入閒置計時器，完全破解企業 AD GPO 螢幕保護程式鎖定。
     - `SetThreadExecutionState`: 宣告 `ES_CONTINUOUS | ES_DISPLAY_REQUIRED | ES_SYSTEM_REQUIRED`，保證系統與顯示器雙重清醒。
   - **優勢**: 單一可執行檔，完全免除 PowerShell 執行權限（ExecutionPolicy）與 EDR 針對 `.ps1` 腳本的攔截。

3. **PowerShell 腳本版 (`AntiScreenSaver.ps1`)**
   - **語言**: PowerShell 7+ (`pwsh`)
   - **適用場景**: 開發者本機終端機日常使用。

---

## 2. 系統脈絡圖 (System Context)
```mermaid
graph TD
    User([使用者 / 主人]) -->|開啟或執行| Choice{選擇防休眠方案}
    Choice -->|方案 A: 現代瀏覽器| Web["KeepAwake.html (WakeLock + WebAudio + PiP)"]
    Choice -->|方案 B: 原生免安裝 .exe| Native["AntiScreenSaver.exe (C# / Win32 API)"]
    Choice -->|方案 C: 命令列 PowerShell| PS["AntiScreenSaver.ps1"]
    
    Web -->|Web Audio + WakeLock 宣告| OS[Windows 作業系統]
    Native -->|mouse_event 重置輸入計時器| OS
    PS -->|Win32 Cursor 微動| OS
    
    OS -->|阻斷螢幕保護程式 & 待命鎖定| AntiLock[保持電腦清醒]
```

---

## 3. 模組關係圖
```mermaid
classDiagram
    class WebWakeLockModule {
        +acquireWakeLock()
        +releaseWakeLock()
        +handleVisibilityChange()
    }
    class WebAudioKeeper {
        +startSubAudibleTone()
        +stopSubAudibleTone()
    }
    class PictureInPictureModule {
        +togglePiP()
        +renderCanvasHeartbeat()
    }
    class NativeJigglerApp {
        +Main()
        +SetThreadExecutionState()
        +mouse_event()
        +JiggleLoop()
    }

    WebWakeLockModule ..> WebAudioKeeper : 協同保障背景清醒
    WebWakeLockModule ..> PictureInPictureModule : 視窗前景錨定
```

---

## 4. 關鍵流程圖 (Key Workflow)

### 4.1 網頁版 KeepAwake.html 強化流程圖
```mermaid
graph TD
    A[開啟 KeepAwake.html] --> B[頁面初始化]
    B --> C[要求 Screen Wake Lock]
    B --> D[啟動 Web Audio 微弱無聲波維持背景活躍]
    C -->|成功取得鎖定| E[UI 顯示：防休眠運作中]
    D --> E
    E --> F{使用者切換分頁至背景？}
    F -->|是: 進入背景| G[Web Audio 阻止分頁凍結並維持系統喚醒]
    F -->|可選: 啟用畫中畫 PiP| H[以浮動小視窗保持前景活躍狀態]
    F -->|否: 留在前景| E
    E --> I{點擊暫停按鈕}
    I -->|是| J[釋放 WakeLock & 停止 Web Audio]
```

### 4.2 C# 原生免安裝執行檔流程圖
```mermaid
graph TD
    Start([啟動 AntiScreenSaver.exe]) --> SetState["宣告 SetThreadExecutionState (Display + System)"]
    SetState --> Loop["進入背景防護迴圈 (每 60 秒)"]
    Loop --> Move["mouse_event (+1 px 微動並復原)"]
    Move --> Reset["Windows GetLastInputInfo 計時器重置為 0"]
    Reset --> Wait["Thread.Sleep(60000)"]
    Wait --> Loop
```

---

## 5. 狀態轉換圖 (State Diagram)
```mermaid
stateDiagram-v2
    [*] --> Active : 啟動防休眠
    Active --> BackgroundActive : 視窗切換至背景 (WebAudio 接手維持喚醒)
    BackgroundActive --> Active : 視窗回到前景 (WakeLock 重新鎖定)
    Active --> PiPActive : 啟動畫中畫 (始終前景)
    PiPActive --> Active : 關閉畫中畫
    Active --> Paused : 點擊暫停
    Paused --> Active : 點擊恢復
    Active --> [*] : 關閉程式
```

---

## 6. 虛擬碼 (Pseudocode)

### Web Audio 微弱無聲波維持背景活躍
```javascript
function startSubAudibleTone() {
    const audioCtx = new (window.AudioContext || window.webkitAudioContext)();
    const osc = audioCtx.createOscillator();
    const gain = audioCtx.createGain();
    
    // 設定為 20Hz (人耳聽覺極限邊緣) 且音量微小 (0.0001)，達到實質無聲
    osc.frequency.value = 20;
    gain.gain.value = 0.0001;
    
    osc.connect(gain);
    gain.connect(audioCtx.destination);
    osc.start();
    return { audioCtx, osc };
}
```

### C# 原生 Win32 滑鼠微動與電源喚醒
```csharp
[DllImport("user32.dll")]
static extern void mouse_event(uint dwFlags, uint dx, uint dy, uint dwData, UIntPtr dwExtraInfo);

[DllImport("kernel32.dll")]
static extern uint SetThreadExecutionState(uint esFlags);

const uint ES_CONTINUOUS = 0x80000000;
const uint ES_SYSTEM_REQUIRED = 0x00000001;
const uint ES_DISPLAY_REQUIRED = 0x00000002;

SetThreadExecutionState(ES_CONTINUOUS | ES_SYSTEM_REQUIRED | ES_DISPLAY_REQUIRED);
while (keepRunning) {
    mouse_event(0x0001, 1, 0, 0, UIntPtr.Zero);  // +1 px
    mouse_event(0x0001, 0xFFFFFFFF, 0, 0, UIntPtr.Zero); // -1 px
    Thread.Sleep(60000);
}
```
