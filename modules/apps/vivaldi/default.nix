# =========================================================================
# Vivaldi 宣言的設定モジュール
# =========================================================================
{ config, dotfilesPath, ... }:

{
  # --- VivaldiカスタムCSS設定 ---
  # Vivaldi設定のCSS UI Mods DirectoryがこのWSLパス (~/.config/vivaldi、
  # mkOutOfStoreSymlink) を \\wsl.localhost\... 経由で直接参照しているため、
  # 同期処理 (sync-win) は不要でファイル保存が即座に反映される。
  # air-zenify.css (ELGUAPOLIFE/Zen-Theme-CSS-for-Vivaldi-Browser由来、
  # Vivaldi 7.9+ ネイティブUI自動非表示前提) がタブバー/パネルの自動非表示・
  # 透過を担い、custom.css は信号ボタンの色・タブ高さなど個別カスタムのみ持つ。
  xdg.configFile."vivaldi/custom.css" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/modules/apps/vivaldi/css/custom.css";
    force = true;
  };
  xdg.configFile."vivaldi/air-zenify.css" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/modules/apps/vivaldi/css/air-zenify.css";
    force = true;
  };
}
