# =========================================================================
# Home Manager 用設定ファイル: rootless podman (distrobox) コンテナ内のCLI環境
# =========================================================================
# sudoが無いホスト上で、distroboxで作ったUbuntuコンテナに通常の(/nixを
# 持つ)Nixをインストールして動かす。GUI/systemdユーザーサービス/カーネル
# 入力リマップ(kanata)等コンテナに乗らないものはimportしない。
#
# home.homeDirectoryは`distrobox create --home <path>`で指定した独立
# ディレクトリになる想定 (ホストの$HOMEとは共有しない)。共有すると、
# host-nativeで直接読まれるファイル(.zshrc等)とhome-manager管理下の
# ファイルが同じパスで衝突し、switchのたびに壊れるため。パスをリポジトリ
# 側にハードコードせず、コンテナ起動時の$HOME環境変数から動的に読む。
{ config, pkgs, ... }:

{
  imports = [
    ../../profiles/base.nix
  ];

  home.username      = "pt_takahashi";
  home.homeDirectory = builtins.getEnv "HOME";
  home.stateVersion  = "25.11";

  programs.home-manager.enable = true;

  nixpkgs.config.allowUnfree = true;
}
