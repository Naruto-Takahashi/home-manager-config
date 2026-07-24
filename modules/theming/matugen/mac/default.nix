# =========================================================================
# matugen Mac連携モジュール
# =========================================================================
# WSL側 (modules/theming/matugen/wsl/, modules/wm/yasb/default.nix の配線)
# のMac版。壁紙から抽出したパレットを ~/.local/bin/matugen-apply 経由で
# WezTerm/nvim/yazi/starship/lazygit/btop/eza/atuin/fzf/AeroSpace枠線へ反映する。
{ config, lib, pkgs, dotfilesPath, ... }:

{
  # chafa: wezterm imgcatが使えない場合の壁紙プレビューのフォールバック用
  home.packages = [ pkgs.matugen pkgs.chafa ];

  xdg.configFile."matugen-mac" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/modules/theming/matugen/mac";
    force = true;
  };
  home.file.".local/bin/matugen-apply" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/modules/theming/matugen/mac/matugen-apply.sh";
  };
  home.file.".local/bin/wallpaper-pick" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/modules/theming/matugen/mac/wallpaper-pick.sh";
  };
  home.file.".local/bin/wallpaper-pick-popup" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/modules/theming/matugen/mac/wallpaper-pick-popup.sh";
  };

  # home-manager switch のたびに、その時点の壁紙で一度パレットを反映しておく。
  # 初回(壁紙未取得・Automation許可待ち等)で失敗してもビルド自体は止めない。
  home.activation.matugenMacApply = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD $HOME/.local/bin/matugen-apply >/dev/null 2>&1 || true
  '';
}
