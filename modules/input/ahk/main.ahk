/*
    =============================================================================
    メイン AutoHotkey スクリプト (Main AutoHotkey Script)
    説明: キーのリマッピング，Vimライクなカーソル移動，およびIME制御の統合。
          起動するAHKプロセスをこの1つに集約するため，komorebi/YASB用の
          キーバインドスクリプト(komorebi.ahk、modules/wm/komorebi/管理)も
          ここから読み込む。
    =============================================================================
*/

; =============================================================================
; グローバル設定 (Global Settings)
; =============================================================================
#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%

; 外部ライブラリの読み込み (IME制御関数群)
#Include %A_ScriptDir%\lib\ime_functions.ahk

; kanata (modules/input/kanata/wsl.nix) がSandS/CapsLock/Alt-IME切り替えを
; 肩代わりする移行を進めている (AHKの `Key & Key` コンボ実装がキー状態を
; 稀に取りこぼし「押されっぱなし」になる不具合の対策)。kanataが起動中は
; 下記の該当セクションを自動的に無効化し、二重処理による衝突を防ぐ。
; ロールバックしたい場合はkanataを終了するだけでよい (AHK再起動不要、
; ホットキー押下のたびにこの条件が再評価されるため即座に有効化される)
KanataActive() {
    Process, Exist, kanata-windows.exe
    return (ErrorLevel != 0)
}

; komorebi/YASB操作用キーバインド。役割としては別モジュール
; (modules/wm/komorebi/komorebi.ahk) が持つため配置場所を分けているが、
; 起動するAHKプロセスは1つに集約するためここから#Includeする
; (相対パスでは届かない配置のため絶対パス)。
#Include C:\Users\tnaru\.config\komorebi\komorebi.ahk

; =============================================================================
; キー・リマッピング設定 (Key Remappings)
; =============================================================================

; kanata稼働中は下記ブロック (CapsLock/LCtrl/Space/Alt-IME) を無効化する。
; #IfWinActiveとの入れ子ができないため、途中のwezterm限定ブロックも
; 同じ #If の複合条件式に統一している
#If !KanataActive()

; --- CapsLock単押しでEscape（かつIME OFF），長押しでCtrl化 ---
; ※レジストリや他ソフト等で CapsLock が F13 にマップされていることを前提とします．
*F13::
    Send, {LCtrl down}
    KeyWait, F13
    Send, {LCtrl up}
    if (A_PriorKey == "F13") {
        SendInput, {Esc}
        Sleep 10
        IME_SET(0) ; 英語入力（IME OFF）へ強制切り替え
    }
Return

; --- 物理左Controlキー単押しでEscape（かつIME OFF）にする設定 ---
~LCtrl Up::
    if (A_PriorKey == "LControl") {
        SendInput, {Esc}
        Sleep 10
        IME_SET(0) ; 英語入力（IME OFF）へ強制切り替え
    }
Return

; =============================================================================
; スペースキー拡張設定 (SandS & Vim Mode)
; =============================================================================
; kanata (modules/input/kanata/config.kbd の nav レイヤー) に完全移植済みの
; ため削除。AHKの "Key & Key" カスタムコンビネーションは #If ガードが
; false でも物理キー自体を常にフックしてしまう (コンボ検知のため) 仕様が
; あり、Space Up::Send, {Space} がkanataのspc-nav (tap-hold-press) と
; 同時に発火してSpaceキーが常に二重入力される不具合の原因になっていた
; (実機でAHK単体停止により再現・解消を確認済み)。

#If !KanataActive() && WinActive("ahk_exe wezterm-gui.exe")
; WezTermアクティブ時はCtrl+Space/Ctrl+;を透過してLeaderキーとして機能させつつ，IMEをOFFにする
~^Space::
    Sleep 10
    IME_SET(0) ; 英語入力（IME OFF）へ強制切り替え
Return
~^`;::
    Sleep 10
    IME_SET(0) ; 英語入力（IME OFF）へ強制切り替え
Return

#If !KanataActive()
^Space::    Send, ^{Space}    ; Ctrl + Space のパススルー（衝突回避）
!Space::    Send, !{Space}    ; Alt + Space のパススルー（衝突回避）

; =============================================================================
; IME制御 & Vim連携 (IME & Vim Integration)
; =============================================================================

; --- Mac風のAltキー単押しによるIME切り替え ---
; 左Alt単押し：英語入力（IME OFF）
~LAlt Up::
    if (A_PriorHotkey == "~LAlt")
        IME_SET(0)
    Return
~LAlt::SendInput, {vkE8} ; キーの衝突防止ダミー出力を送信

; 右Alt単押し：日本語入力（IME ON）
~RAlt Up::
    if (A_PriorHotkey == "~RAlt")
        IME_SET(1)
    Return
~RAlt::SendInput, {vkE8} ; キーの衝突防止ダミー出力を送信

#If
; --- Escapeキー押下時に強制的にIMEをOFFにする設定 ---
$Esc::
    SendInput, {LCtrl up}{RCtrl up}{Esc}
    Sleep 10 ; Escapeキーの入力を確実に処理させるための微小ディレイ
    IME_SET(0)
Return

; --- Ctrl + [ 押下時にEscapeかつIMEをOFFにする設定 (Vim/Neovim互換) ---
^[::
    SendInput, {LCtrl up}{RCtrl up}{Esc}
    Sleep 10
    IME_SET(0)
Return

; =============================================================================
; アプリケーション個別ショートカット (Application Shortcuts)
; =============================================================================
; Alt+Enter (WezTerm起動、Excel除外・カーソルのあるモニタに開く) は
; komorebi.ahk 側で定義済み (LaunchWeztermOnCursorMonitor)。

; =============================================================================
; エクスプローラー統合 (Everything検索連携)
; =============================================================================

#IfWinActive ahk_class CabinetWClass
; エクスプローラー上で Ctrl + F を押した際，開いているフォルダパスを対象に Everything で検索する
^f::
    path := GetExplorerPath()
    if (path) {
        ; TODO: Everything 1.5a のパスが異なる場合は適宜書き換える
        everythingPath := "C:\Program Files\Everything 1.5a\Everything.exe"
        
        if FileExist(everythingPath) {
            Run, "%everythingPath%" -path "%path%"
        } else {
            MsgBox, 16, エラー, Everything 1.5a が以下のパスに見つかりませんでした．:`n%everythingPath%`n`nインストールパスをご確認ください．
        }
    } else {
        Send, ^f
    }
Return
#IfWinActive

; アクティブなエクスプローラーから現在のカレントディレクトリパスを取得する関数
GetExplorerPath() {
    WinGetClass, winClass, A
    if (winClass ~= "Progman|WorkerW")
        return A_Desktop
    else {
        for window in ComObjCreate("Shell.Application").Windows
        {
            if (window.hwnd == WinExist("A"))
                return window.Document.Folder.Self.Path
        }
    }
}
