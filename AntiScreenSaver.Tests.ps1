# 載入腳本並設定測試狀態，避免主迴圈直接啟動
BeforeAll {
    $global:IsTesting = $true
    $scriptPath = Join-Path $PSScriptRoot "AntiScreenSaver.ps1"
    . $scriptPath
}

AfterAll {
    $global:IsTesting = $false
}

Describe "AntiScreenSaver 單元測試" {
    
    Context "選單邏輯 (Show-Menu)" {
        It "應正確回傳使用者的輸入 '1'" {
            Mock Read-Host { return "1" }
            $result = Show-Menu
            $result | Should -Be "1"
        }
        
        It "應正確回傳使用者的輸入 '2'" {
            Mock Read-Host { return "2" }
            $result = Show-Menu
            $result | Should -Be "2"
        }
    }

    Context "滑鼠微動 (Move-MouseToPreventSleep)" {
        It "執行期間不應拋出任何例外" {
            { Move-MouseToPreventSleep } | Should -Not -Throw
        }
    }

    Context "防休眠迴圈 (Start-AntiIdleLoop)" {
        It "當偵測到按下 Q 鍵時，應跳出迴圈不致無窮卡死" {
            Mock Test-StopKeyPressed { return $true }
            Mock Move-MouseToPreventSleep {}
            Mock Start-Sleep {}

            { Start-AntiIdleLoop -IntervalSeconds 1 } | Should -Not -Throw
        }
    }
}
