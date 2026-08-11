/*
    =============================================================================
    komorebi & YASB 用 AutoHotkey スクリプト (GlazeWM のキーバインド再現)
    =============================================================================
    キーバインドを変更したら docs/komorebi.md も直すこと
    (このファイルから自動生成されるドキュメントではないため乖離に注意)。
*/

#NoEnv
#SingleInstance Force
SendMode Input
SetWorkingDir %A_ScriptDir%

; --- モニタ構成変化 (WM_DISPLAYCHANGE) で komorebi/YASB を自動復旧 ---
; ケーブル抜き差しでワークスペース表示が崩れる問題対策
Gui, +LastFound
OnMessage(0x007E, "HandleDisplayChange")

HandleDisplayChange(wParam, lParam) {
    ; イベントは連発するためデバウンスして1回だけ実行
    SetTimer, ReapplyDisplayConfig, -5000
}

; --- フォーカス移動 ---
!h::Run, komorebic focus left, , Hide
!l::Run, komorebic focus right, , Hide
!k::Run, komorebic focus up, , Hide
!j::Run, komorebic focus down, , Hide

; --- ウィンドウ移動 (スワップ) ---
!+h::Run, komorebic move left, , Hide
!+l::Run, komorebic move right, , Hide
!+k::Run, komorebic move up, , Hide
!+j::Run, komorebic move down, , Hide

; --- リサイズ (GlazeWM の alt+u/p/o/i を再現) ---
; komorebi 0.1.41 でピクセル指定が廃止され increase/decrease に変更。
; resize-edge は対象辺が画面端だと無効なため、位置に依らず効く resize-axis を使う
!u::Run, komorebic resize-axis horizontal decrease, , Hide
!p::Run, komorebic resize-axis horizontal increase, , Hide
!o::Run, komorebic resize-axis vertical increase, , Hide
!i::Run, komorebic resize-axis vertical decrease, , Hide

; --- ウィンドウ操作 ---
!f::Run, komorebic toggle-monocle, , Hide
!m::Run, komorebic minimize, , Hide
!t::Run, komorebic toggle-tiling, , Hide
; BSP は新規ウィンドウをフォーカス中ウィンドウの長辺で分割するため上下配置に
; なることがある。レイアウトを巡回して左右型 (VerticalStack/Columns) へ即切替
!+t::Run, komorebic cycle-layout next, , Hide
; 素のAlt+Bは他ホスト(NixOS/macOS)に合わせて未使用に統一したため，
; ここではAlt+Shift+Bに退避している (機能自体は維持)
!+b::Run, komorebic flip-layout horizontal-and-vertical, , Hide
!r::Run, komorebic retile, , Hide
; モニタ再接続で表示が崩れたとき等に手動で復旧 (自動復旧と同じ処理)
!+d::Gosub, ReapplyDisplayConfig

!+q::Run, komorebic close, , Hide
!+w::Run, komorebic close, , Hide

; --- 追跡から外れたウィンドウの手動復旧 ---
; komorebi は WinEvent 通知の取りこぼしで稀にウィンドウの追跡を失うことがある。
; その場でフォーカス中のウィンドウを再登録できるようにする (R = Recover)。
!+r::Run, komorebic manage, , Hide

; --- ワークスペース (巡回) ---
!a::Run, komorebic cycle-workspace previous, , Hide
!s::Run, komorebic cycle-workspace next, , Hide

; --- ワークスペース (直接ジャンプ) ---
; モニタ0 (ワークスペース 1-5)
!1::Run, komorebic focus-monitor-workspace 0 0, , Hide
!2::Run, komorebic focus-monitor-workspace 0 1, , Hide
!3::Run, komorebic focus-monitor-workspace 0 2, , Hide
!4::Run, komorebic focus-monitor-workspace 0 3, , Hide
!5::Run, komorebic focus-monitor-workspace 0 4, , Hide
; モニタ1 (ワークスペース 6-9)
!6::Run, komorebic focus-monitor-workspace 1 0, , Hide
!7::Run, komorebic focus-monitor-workspace 1 1, , Hide
!8::Run, komorebic focus-monitor-workspace 1 2, , Hide
!9::Run, komorebic focus-monitor-workspace 1 3, , Hide

; --- ワークスペース (ウィンドウを移動してフォーカス追従) ---
; move-to-monitor-workspace はフォーカス追従するため focus の追撃は不要
; モニタ0 (ワークスペース 1-5)
!+vk31::Run, komorebic move-to-monitor-workspace 0 0, , Hide
!+vk32::Run, komorebic move-to-monitor-workspace 0 1, , Hide
!+vk33::Run, komorebic move-to-monitor-workspace 0 2, , Hide
!+vk34::Run, komorebic move-to-monitor-workspace 0 3, , Hide
!+vk35::Run, komorebic move-to-monitor-workspace 0 4, , Hide
; モニタ1 (ワークスペース 6-9)
!+vk36::Run, komorebic move-to-monitor-workspace 1 0, , Hide
!+vk37::Run, komorebic move-to-monitor-workspace 1 1, , Hide
!+vk38::Run, komorebic move-to-monitor-workspace 1 2, , Hide
!+vk39::Run, komorebic move-to-monitor-workspace 1 3, , Hide

; --- ワークスペースごとモニタへ移動 ---
!+a::Run, komorebic move-workspace-to-monitor 0, , Hide
!+f::Run, komorebic move-workspace-to-monitor 1, , Hide

; --- アプリ起動 --- (起動系キーは他ホストと同じ「アプリ名の頭文字」に統一)
; ALT+Y: WezTerm で yazi
!y::LaunchWeztermOnCursorMonitor(" -- wsl.exe --cd ~ -e zsh -ic yazi")
; ALT+N: WezTerm で nvim
!n::LaunchWeztermOnCursorMonitor(" -- wsl.exe --cd ~ -e zsh -ic nvim")
; ALT+W: 壁紙ピッカー (Vivaldiのapp-modeポップアップ、色候補もその場で試せる)
!w::Run, wsl.exe -e /home/nalt/.local/bin/wallpaper-pick-popup, , Hide
; ALT+V: Vivaldi (Chromium系は --window-position=X,Y でカーソルのあるモニタに開く)
!v::
    CoordMode, Mouse, Screen
    MouseGetPos, CursorX, CursorY
    fullCmd := "C:\Users\tnaru\AppData\Local\Vivaldi\Application\vivaldi.exe --new-window --window-position=" . CursorX . "," . CursorY
    Run, %fullCmd%
Return

; --- Alt+Enter で WezTerm (Excel では無効) ---
#IfWinNotActive ahk_exe EXCEL.EXE
!Enter::LaunchWeztermOnCursorMonitor("")
#IfWinNotActive

; カーソル座標を `wezterm-gui start --position screen:X,Y` へ直接渡して
; 起動する。komorebiは新規ウィンドウが生成された瞬間の物理位置でタイル先
; モニタを決めるため (focus-monitor-at-cursorで事前にkomorebi側のフォーカス
; モニタを切り替えても、生成後にset_positionで動かしても、wezterm.lua の
; gui-startupイベントでspawn_window生成と同時にpositionを渡しても、
; いずれも実機で効果が無いことを確認済み)。--position はwezterm-gui start
; 自体のCLI引数として使えるため、これを直接使う
; komorebic query の出力を一時ファイル経由で受け取る。
; WScript.Shell.Exec は (AHKのRun ", , Hide" と違って) コンソールウィンドウを
; 完全に隠せず一瞬表示することがあり、それをkomorebiが新規ウィンドウとして
; 検知してフォーカス/ワークスペースを奪ってしまう副作用があったため、
; 確実に隠せるAHKネイティブのRunWaitに戻した
KomorebicQuery(queryName) {
    outFile := A_Temp . "\komorebi-query-" . queryName . ".txt"
    FileDelete, %outFile%
    RunWait, %ComSpec% /c komorebic query %queryName% > "%outFile%" 2>nul, , Hide
    FileRead, result, %outFile%
    return Trim(result, " `t`r`n")
}

LaunchWeztermOnCursorMonitor(extraArgs) {
    ; ALT+1等でワークスペースを切り替えた直後 (特に空ワークスペースへの
    ; 切り替え時) は mouse_follows_focus によるカーソル移動が非同期で、
    ; 直後にこの関数が呼ばれるとカーソルがまだ古いモニタに残っていることが
    ; ある (レースコンディション)。その状態で --position にカーソル座標を
    ; 渡すと意図しないモニタ/ワークスペースに開かれてしまうため、
    ; spawn前に「現在フォーカス中のモニタ/ワークスペース」を明示的に
    ; 問い合わせておき、起動後に強制的にそこへ移動させることで確実にする
    focusedMonitor := KomorebicQuery("focused-monitor-index")
    focusedWorkspace := KomorebicQuery("focused-workspace-index")

    CoordMode, Mouse, Screen
    MouseGetPos, CursorX, CursorY
    ; Run,コマンドはカンマを自身の引数区切りとして解釈するため、
    ; screen:X,Y のカンマをそのまま埋め込むと途中で切れてしまう。
    ; 変数に組み立ててから渡すことでカンマをコマンド文字列の一部として扱う
    fullCmd := "wezterm-gui start --always-new-process --position screen:" . CursorX . "," . CursorY . extraArgs

    ; spawn直後、komorebiのタイル配置処理(SetWindowPos等)にフォーカスを
    ; 奪われてしまい前面のウィンドウのまま変わらないことがある。
    ; spawn前後のwezterm-gui.exeウィンドウID一覧を比較して新規ウィンドウを
    ; 特定し、明示的にアクティブ化することで確実にフォーカスさせる
    WinGet, beforeList, List, ahk_exe wezterm-gui.exe
    Run, %fullCmd%

    Loop, 40 {
        Sleep, 50
        WinGet, afterList, List, ahk_exe wezterm-gui.exe
        newHwnd := 0
        Loop, %afterList% {
            id := afterList%A_Index%
            isNew := true
            Loop, %beforeList% {
                if (id = beforeList%A_Index%) {
                    isNew := false
                    Break
                }
            }
            if (isNew) {
                newHwnd := id
                Break
            }
        }
        if (newHwnd) {
            WinActivate, ahk_id %newHwnd%
            WinWaitActive, ahk_id %newHwnd%, , 1
            ; komorebiがカーソル位置で決めた配置先が、実際に切り替え先
            ; だったワークスペースと異なる場合に備えて強制的に揃える。
            ; komorebi側が新規ウィンドウを完全に管理下に置くまで間があるため
            ; (500ms未満だと move-to-monitor-workspace が反映されないことを
            ; 実機で確認済み)、ある程度待ってから実行する
            if (focusedMonitor != "" && focusedWorkspace != "") {
                Sleep, 500
                Run, komorebic move-to-monitor-workspace %focusedMonitor% %focusedWorkspace%, , Hide
            }
            Break
        }
    }
}

; --- モニタ抜き差し時の自動復旧処理本体 ---
ReapplyDisplayConfig:
    ; reload-configuration では再検出モニタにワークスペース定義が再適用
    ; されないため、replace-configuration で明示的に再適用する
    Run, komorebic replace-configuration "C:\Users\tnaru\.config\komorebi\komorebi.json", , Hide
    ; 再適用完了を待つ (早すぎると YASB が古い状態を読んで再構築する)
    Sleep, 4000
    ; YASB のウィジェットも watch_config 経由で再構築 (バー再起動なし)
    Run, %ComSpec% /c copy /y "C:\Users\tnaru\.config\yasb\config.yaml" "%A_Temp%\yasb-reapply.yaml" & copy /y "%A_Temp%\yasb-reapply.yaml" "C:\Users\tnaru\.config\yasb\config.yaml", , Hide
    Sleep, 2000
    ; komorebi イベントを発火させて YASB のラベルを最新状態に更新する
    ; (ALT+6 で治るのと同じ原理。focus-monitor 0 は実害のない no-op)
    Run, komorebic focus-monitor 0, , Hide
Return

