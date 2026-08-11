# Start critical background tools at logon as fast as possible

# 1. AutoHotkey (main.ahkがエントリポイント。komorebi.ahkはそこから#Includeされる)
Start-Process "C:\Users\tnaru\Tools\Customization\main.ahk"

# 1.1 kanata (SandS/CapsLock/Alt-IME切り替え。AHKの `Key & Key` コンボ実装が
# キー状態を稀に取りこぼす不具合の対策として移行中。main.ahk側は
# KanataActive()でkanata起動を検知すると該当ホットキーを自動的に無効化する
# ため、二重定義のまま共存できる。ロールバックしたい場合はこのプロセスを
# 終了するだけでよい (AHK再起動不要)
$kanataExe = "C:\Users\tnaru\.config\kanata-wsl\kanata-windows.exe"
$kanataConfig = "C:\Users\tnaru\.config\kanata-wsl\config.kbd"
if ((Test-Path $kanataExe) -and (Test-Path $kanataConfig)) {
    Start-Process $kanataExe -ArgumentList "-c", "`"$kanataConfig`""
}

# 2. Komorebi
$env:PATH += ";C:\Program Files\masir\bin"
Start-Process "C:\Program Files\komorebi\bin\komorebic.exe" -ArgumentList "start --masir" -WindowStyle Hidden

# 2.1 セカンドモニタのワークスペース名 (6-9) を付与
# komorebi.json (monitors[1].workspaces[].name) は現行バージョン (0.1.41) では
# なぜか2台目以降のモニタに反映されないため、起動後にCLIで直接設定する。
# 自宅のMi Monitor/外出先のZS-156どちらでも同じ番号体系になるよう、
# モニタの個体ではなく「2台目として認識されたモニタ」に対して適用する。
$komorebic = "C:\Program Files\komorebi\bin\komorebic.exe"
for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Seconds 1
    $state = & $komorebic state 2>$null | ConvertFrom-Json -ErrorAction SilentlyContinue
    if ($state -and $state.monitors.elements.Count -gt 1) { break }
}
if ($state -and $state.monitors.elements.Count -gt 1) {
    & $komorebic ensure-workspaces 1 4 | Out-Null
    & $komorebic workspace-name 1 0 6 | Out-Null
    & $komorebic workspace-name 1 1 7 | Out-Null
    & $komorebic workspace-name 1 2 8 | Out-Null
    & $komorebic workspace-name 1 3 9 | Out-Null
}

# 3. YASB
Start-Process "C:\Program Files\YASB\yasb.exe"

# 4. PowerToys
Start-Process -FilePath "C:\Users\tnaru\AppData\Local\PowerToys\PowerToys.exe"

# 5. Command Palette (ストアアプリ起動の確実化)
Start-Sleep -Seconds 10
$cmdPalLnk = "C:\Users\tnaru\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Microsoft.CmdPal.UI.lnk"
if (Test-Path $cmdPalLnk) {
    Start-Process $cmdPalLnk
} else {
    Start-Process "shell:AppsFolder\Microsoft.CommandPalette_8wekyb3d8bbwe!App"
}
