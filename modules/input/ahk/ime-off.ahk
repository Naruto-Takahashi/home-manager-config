; =============================================================================
; kanata の Alt(左)単押しタップから `cmd` アクションで呼ばれる一発実行スクリプト。
; IMEをOFF(英数)にして即座に終了する。main.ahkのAlt単押し実装(~LAlt Up::)と
; 同じ IME_SET() を使う (modules/input/kanata/wsl-config.nix 参照)。
; =============================================================================
#NoEnv
#Include %A_ScriptDir%\lib\ime_functions.ahk
IME_SET(0)
ExitApp
