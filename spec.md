# AntiScreenSaver 規格文件

## 1. 架構與選型
本專案提供雙軌架構，滿足一般個人環境與企業受限環境：

1. **PowerShell 腳本版 (`AntiScreenSaver.ps1`)**
   - **作業系統**: Windows
   - **語言**: PowerShell 7+ (`pwsh`)
   - **依賴**: 內建 .NET API `System.Windows.Forms.Cursor`
   - **適用場景**: 允許執行本機 PowerShell 腳本的環境。

2. **免安裝網頁喚醒版 (`KeepAwake.html`)**
   - **平臺**: 現代瀏覽器 (Microsoft Edge, Google Chrome 等)
   - **技術**: HTML5, CSS3, JavaScript (W3C Screen Wake Lock API)
   - **備援機制**: 內嵌 HTML5 Video 靜音微循環
   - **適用場景**: 企業資安環境有端點防護 (EDR)、防毒軟體封鎖 `.ps1`、阻擋可疑捷徑或限制 ExecutionPolicy 時的零阻礙替代方案。

## 2. 系統脈絡圖 (System Context)
```mermaid
graph TD
    User([使用者 / 主人]) -->|執行或開啟| App{選擇模式}
    App -->|模式 A: 終端機| PS[AntiScreenSaver.ps1]
    App -->|模式 B: 瀏覽器| Web[KeepAwake.html]
    PS -->|Win32 Cursor API 微動| OS[Windows 作業系統]
    Web -->|Screen Wake Lock API 鎖定| OS
    OS -->|阻止狀態觸發| ScreenSaver[螢幕保護 / 睡眠鎖定]
```

## 3. 關鍵流程 (Key Workflow)

### 3.1 網頁版 KeepAwake.html 流程圖
```mermaid
graph TD
    A[使用者於瀏覽器開啟 KeepAwake.html] --> B[頁面初始化]
    B --> C[請求 navigator.wakeLock.request]
    C -->|成功取得鎖定| D[更新狀態：防休眠運行中 & 啟動計時器]
    C -->|不支援或被拒| E[啟動備援靜音影片循環播放]
    E --> D
    D --> F{使用者操作或狀態變更}
    F -->|點擊暫停按鈕| G[釋放 WakeLock 並停止計時]
    G --> H[更新狀態為已暫停]
    H -->|點擊恢復按鈕| C
    F -->|分頁重新回到前景| C
    F -->|關閉分頁| I[自動釋放並結束]
```

### 3.2 網頁版狀態圖 (State Diagram)
```mermaid
stateDiagram-v2
    [*] --> ActiveState : 開啟網頁自動鎖定
    ActiveState --> PausedState : 點擊暫停防休眠
    PausedState --> ActiveState : 點擊恢復防休眠
    ActiveState --> ActiveState : 分頁切回前景自動重取鎖定
    ActiveState --> [*] : 關閉瀏覽器分頁
```

### 3.3 PowerShell 版關鍵流程
```mermaid
graph TD
    A[啟動腳本] --> B[顯示主選單]
    B --> C{選擇操作}
    C -->|輸入 1| D[啟動防止休眠迴圈]
    D --> E[等待指定間隔時間 120s]
    E --> F{偵測是否按下 Q 鍵}
    F -->|否| G[微微移動滑鼠]
    G --> E
    F -->|是| B
    C -->|輸入 2| H[結束程式]
```

## 4. 虛擬碼 (Pseudocode)

### KeepAwake.html
```javascript
// 核心喚醒鎖定邏輯
async function acquireWakeLock() {
    if ('wakeLock' in navigator) {
        wakeLock = await navigator.wakeLock.request('screen');
        wakeLock.addEventListener('release', onReleased);
        updateUI(true);
    } else {
        // Fallback: 靜音循環播放微型影音
        fallbackVideo.play();
        updateUI(true);
    }
}

async function releaseWakeLock() {
    if (wakeLock) await wakeLock.release();
    fallbackVideo.pause();
    updateUI(false);
}
```
