; kanataのalt-layer中、Tabキー(hyp-tab)が押されるたびにこのスクリプトが
; cmdアクションで都度起動される。kanataはWindows標準のAlt+Tabウィンドウ
; 切り替え (Altを押しっぱなしでTabを連打して選択、Alt解放で確定) に必要な
; 「実際にOSレベルでAltキーが押されている状態」を再現できない
; (kanataの仮想キー出力がGetAsyncKeyStateで一切検出されないことを実機で
; 確認済み) ため、AHK自身がkeybd_event相当のSend {LAlt down}でAltを
; 物理的に保持する。
;
; kanataは物理Altキー自体を消費してしまい離した瞬間も検知できないため、
; 「最後にこのスクリプトが呼ばれてから一定時間操作がなければAltを離す」
; というdebounce方式で疑似的な押しっぱなし挙動を実現する。
; #SingleInstance Force により、Tab連打のたびに新しいインスタンスが
; 古いインスタンス(の保留中タイマー含め)を即座に置き換える。古い
; インスタンスは何もせず終了する(Alt解放処理は実行されない)ため、
; Alt down状態は連打が続く限り維持され、連打が止まった時の最後の
; インスタンスのタイマーだけが実際にAltを解放する。
#NoEnv
#SingleInstance Force
SendMode Input

if !GetKeyState("LAlt", "P")
    Send {Blind}{LAlt down}
Send {Blind}{Tab}

SetTimer, ReleaseAlt, -600
Return

ReleaseAlt:
    Send {Blind}{LAlt up}
    ExitApp
Return
