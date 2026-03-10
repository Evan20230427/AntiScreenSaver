# 載入腳本並設定測試狀態，避免主迴圈直接啟動
$global:IsTesting = $true
$scriptPath = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "AntiScreenSaver.ps1"
. $scriptPath

Describe "AntiScreenSaver 單元測試" {
    
    Context "選單顯示 (Show-Menu)" {
        It "應該回傳使用者的輸入 '1'" {
            Mock Read-Host { return "1" }
            $result = Show-Menu
            $result | Should -Be "1"
        }
        
        It "應該回傳使用者的輸入 '2'" {
            Mock Read-Host { return "2" }
            $result = Show-Menu
            $result | Should -Be "2"
        }
    }

    Context "滑鼠移動 (Move-MouseToPreventSleep)" {
        It "執行時不應發生錯誤" {
            # 因為實際改變滑鼠可能影響開發者，這裡主要測試不拋出例外
            { Move-MouseToPreventSleep } | Should -Not -Throw
        }
    }

    Context "防休眠迴圈 (Start-AntiIdleLoop)" {
        It "當偵測到按下 Q 鍵時，應該跳出迴圈不無限卡死" {
            # 模擬偵測到 Q 鍵被按下
            Mock Test-StopKeyPressed { return $true }
            Mock Move-MouseToPreventSleep {}
            Mock Start-Sleep {}

            # 如果沒有跳出迴圈，測試將會卡住
            { Start-AntiIdleLoop -IntervalSeconds 1 } | Should -Not -Throw
        }
    }
}

$global:IsTesting = $false
