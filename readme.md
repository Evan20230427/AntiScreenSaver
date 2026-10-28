# AntiScreenSaver

這是一個專門用來防止 Windows 系統進入螢幕保護程式、鎖定或休眠狀態的專業工具集。特別針對嚴格的企業端點防護（EDR）、Active Directory 群組原則（GPO）與資安防火牆環境設計，提供三大靈活方案。

---

## 方案介紹

### 方案一：強化版免安裝純網頁喚醒 (`KeepAwake.html`)【零腳本、免安裝最佳首選】
- **特色**：專為完全禁止執行外部程式或腳本的高資安限制環境設計。純 HTML5/JavaScript，零安裝、零二進位代碼，100% 不會被防毒軟體或 EDR 攔截。
- **三重防休眠核心機制**：
  1. **Screen Wake Lock API**：前景時主動向作業系統請求螢幕與電源鎖定。
  2. **Web Audio API 微弱次音頻 (20Hz)**：解決瀏覽器背景分頁自動休眠的限制！以人耳幾不可聞的微弱低頻維持瀏覽器「Audible 媒體播放」狀態，強制保持系統電源活躍。
  3. **畫中畫（Picture-in-Picture, PiP）模式**：可一鍵將動態清醒畫面彈出為獨立懸浮小視窗，永久保持在系統前景，徹底杜絕分頁在背景時被瀏覽器釋放 WakeLock 的問題。
- **執行方式**：
  - 直接以任何現代瀏覽器（Microsoft Edge、Google Chrome）開啟 `KeepAwake.html`。
  - 亦可點擊「啟用懸浮畫中畫（PiP）」，將迷你清醒視窗置於桌面角落。

---

### 方案二：C# 原生免安裝雙保險執行檔 (`AntiScreenSaver.exe`)【100% 擊破企業 GPO 鎖定】
- **特色**：針對公司網域強制啟用「滑鼠閒置逾時鎖定（GPO GetLastInputInfo）」的情境。
- **運作原理**：
  - 每 60 秒自動模擬 1 像素的極微幅滑鼠位移（`mouse_event`），重置 Windows 實體輸入閒置計時器。
  - 同步宣告 Win32 `SetThreadExecutionState(ES_CONTINUOUS | ES_DISPLAY_REQUIRED | ES_SYSTEM_REQUIRED)`。
  - 由 Windows 內建的 `csc.exe` 就地編譯，無需安裝任何第三方軟體或 Python/Node。
- **執行方式**：
  - 直接執行 `AntiScreenSaver.exe`。
  - 或在終端機中執行：
    ```powershell
    # 本地一鍵編譯指令 (使用 Windows 內建編譯器)
    C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe /target:winexe /out:AntiScreenSaver.exe AntiScreenSaver.cs
    ```

---

### 方案三：PowerShell 終端腳本 (`AntiScreenSaver.ps1`)
- **特色**：提供互動式終端機選單，定期模擬滑鼠微動以防休眠。
- **環境需求**：Windows、PowerShell 7+ (`pwsh`)。
- **執行方式**：
  ```powershell
  .\AntiScreenSaver.ps1
  ```
