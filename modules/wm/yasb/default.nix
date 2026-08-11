# =========================================================================
# YASB (Yet Another Status Bar) 宣言的設定モジュール
# =========================================================================
{ config, dotfilesPath, ... }:

{
  # --- YASB設定ディレクトリ ---
  # 設定ファイル一式を配置するディレクトリへのシンボリックリンク．
  xdg.configFile."yasb" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/modules/wm/yasb";
    force = true;
  };

  # --- 配色連携 (WSL 側 matugen パイプライン) ---
  # 実体は modules/theming/matugen/wsl/。YASB の wallpapers ウィジェットが
  # 壁紙変更時に matugen-apply を叩くため、この WSL ホスト専用モジュールから配置する．
  xdg.configFile."matugen-wsl" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/modules/theming/matugen/wsl";
    force = true;
  };
  home.file.".local/bin/matugen-apply" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/modules/theming/matugen/wsl/matugen-apply.sh";
    force = true;
  };
  home.file.".local/bin/wallpaper-pick" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/modules/theming/matugen/wsl/wallpaper-pick.sh";
    force = true;
  };
  home.file.".local/bin/wallpaper-pick-popup" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/modules/theming/matugen/wsl/wallpaper-pick-popup.sh";
    force = true;
  };
}
