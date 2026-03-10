<#
.SYNOPSIS
    防止螢幕保護程式啟動。
.DESCRIPTION
    AntiScreenSaver，提供簡單選單以定期移動滑鼠防止休眠。符合 S.O.L.I.D. 原則將功能模組化。
#>

function Show-Menu {
    <#
    .SYNOPSIS
        顯示主選單並回傳選擇
    #>
    Write-Host "================"
    Write-Host " AntiScreenSaver"
    Write-Host "================"
    Write-Host "1. 啟動防休眠"
    Write-Host "2. 結束程式"
    Write-Host "================"
    
    $choice = Read-Host "請輸入選項 (1 或 2)"
    return $choice
}

function Move-MouseToPreventSleep {
    <#
    .SYNOPSIS
        微微移動滑鼠再移回原位
    #>
    Add-Type -AssemblyName System.Windows.Forms
    $pos = [System.Windows.Forms.Cursor]::Position
    for ($i = 0; $i -lt 2; $i++) {
        [System.Windows.Forms.Cursor]::Position = [System.Drawing.Point]::new($pos.X + 1, $pos.Y + 1)
        Start-Sleep -Milliseconds 50
        [System.Windows.Forms.Cursor]::Position = $pos
        Start-Sleep -Milliseconds 50
    }
}

function Test-StopKeyPressed {
    <#
    .SYNOPSIS
        偵測是否有按下停止鍵 (Q鍵)
    #>
    if ([Console]::KeyAvailable) {
        $key = [Console]::ReadKey($true)
        if ($key.Key -eq [ConsoleKey]::Q) {
            return $true
        }
    }
    return $false
}

function Start-AntiIdleLoop {
    <#
    .SYNOPSIS
        啟動防休眠迴圈
    #>
    param (
        [int]$IntervalSeconds = 120
    )
    Write-Host "已啟動防休眠功能，每 $IntervalSeconds 秒會微動滑鼠。按下 'Q' 鍵停止..."
    while ($true) {
        if (Test-StopKeyPressed) {
            Write-Host "`n已停止防休眠功能。"
            break
        }
        Move-MouseToPreventSleep
        Start-Sleep -Seconds $IntervalSeconds
    }
}

function Invoke-MainApp {
    <#
    .SYNOPSIS
        主程式邏輯
    #>
    while ($true) {
        $choice = Show-Menu
        if ($choice -eq "1") {
            # 預設每 2 分鐘 (120 秒) 移動兩次
            Start-AntiIdleLoop -IntervalSeconds 120
        }
        elseif ($choice -eq "2") {
            Write-Host "程式已結束。主人再見！"
            break
        }
        else {
            Write-Host "輸入錯誤，請重新輸入。"
            Start-Sleep -Seconds 1
        }
    }
}

# 為了方便單元測試，若全域變數 IsTesting 為 True，則不自動執行主程式
if (-not $global:IsTesting) {
    Try {
        Invoke-MainApp
    }
    Catch {
        Write-Error "執行期間發生錯誤：$_"
    }
}
