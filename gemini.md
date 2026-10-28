# AntiScreenSaver

本專案提供防止 Windows 系統進入螢幕保護程式或休眠狀態的解決方案：
1. **PowerShell 腳本版 (`AntiScreenSaver.ps1`)**：適用於允許執行 PowerShell 腳本的環境，具備互動式選單並定期模擬滑鼠微動。
2. **免安裝純網頁版 (`KeepAwake.html`)**：專為企業資安嚴格環境設計，當公司防火牆或防毒軟體 (EDR) 封鎖 `.ps1` 檔案或阻擋腳本時，以 W3C Screen Wake Lock API 提供零阻礙替代方案。
