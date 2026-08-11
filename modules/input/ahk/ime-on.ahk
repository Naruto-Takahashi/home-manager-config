; =============================================================================
; kanata の Alt(右)単押しタップから `cmd` アクションで呼ばれる一発実行スクリプト。
; IMEをON(日本語)にして即座に終了する。main.ahkのAlt単押し実装(~RAlt Up::)と
; 同じ IME_SET() を使う (modules/input/kanata/wsl-config.nix 参照)。
; =============================================================================
#NoEnv
#Include %A_ScriptDir%\lib\ime_functions.ahk
IME_SET(1)
ExitApp
