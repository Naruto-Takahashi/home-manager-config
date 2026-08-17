# =========================================================================
# AutoHotkey (Windows用IME制御・SandS・キーリマップ) 宣言的設定モジュール
# =========================================================================
# kanata (modules/input/kanata) と役割は同じ「キーボードリマップ」だが，
# kanataがクロスプラットフォームなのに対しこちらはWindows専用のため
# 分離している。komorebi固有のホットキー (modules/wm/komorebi/komorebi.ahk)
# は，このmain.ahkから#Includeされる (起動するAHKプロセスを1つに集約するため)。
{ config, dotfilesPath, ... }:

{
  # sync-win が ~/.config/ahk 配下をまるごと Windows の
  # Tools/Customization へコピーする (modules/shell/zsh/functions.zsh 参照)。
  xdg.configFile."ahk/main.ahk" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/modules/input/ahk/main.ahk";
    force = true;
  };
  xdg.configFile."ahk/lib/ime_functions.ahk" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/modules/input/ahk/lib/ime_functions.ahk";
    force = true;
  };
}
