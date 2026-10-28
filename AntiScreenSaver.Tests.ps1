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

    Context "強化版網頁喚醒器 (KeepAwake.html) 完整性測試" {
        It "應存在 KeepAwake.html 檔案且包含三大防護技術特徵" {
            $htmlPath = Join-Path $PSScriptRoot "KeepAwake.html"
            (Test-Path $htmlPath) | Should -Be $true

            $content = Get-Content $htmlPath -Raw -Encoding UTF8
            $content | Should -Match "navigator\.wakeLock\.request"
            $content | Should -Match "AudioContext"
            $content | Should -Match "requestPictureInPicture"
            $content | Should -Match "createBuffer"
        }
    }

    Context "原生 C# 執行檔 (AntiScreenSaver.exe) 驗證" {
        It "原始碼 AntiScreenSaver.cs 應定義 Win32 API" {
            $csPath = Join-Path $PSScriptRoot "AntiScreenSaver.cs"
            (Test-Path $csPath) | Should -Be $true

            $csContent = Get-Content $csPath -Raw -Encoding UTF8
            $csContent | Should -Match "SetThreadExecutionState"
            $csContent | Should -Match "mouse_event"
        }

        It "AntiScreenSaver.exe 應存在且具備有效可執行檔特徵" {
            $exePath = Join-Path $PSScriptRoot "AntiScreenSaver.exe"
            (Test-Path $exePath) | Should -Be $true

            $bytes = [System.IO.File]::ReadAllBytes($exePath)
            # PE 執行檔開頭兩個字節必須為 'MZ' (0x4D, 0x5A)
            $bytes[0] | Should -Be 0x4D
            $bytes[1] | Should -Be 0x5A
        }
    }
}
