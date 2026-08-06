# =========================================================================
# Home Manager 用設定ファイル: rootless podman (distrobox) コンテナ内のCLI環境
# =========================================================================
# sudoが無いホスト上で、distroboxで作ったUbuntuコンテナに通常の(/nixを
# 持つ)Nixをインストールして動かす。distroboxはホストの$HOMEをそのまま
# 共有するため、profiles/base.nixのCLIツール一式がホスト側からも
# 透過的に使えるようになる。GUI/systemdユーザーサービス/カーネル入力
# リマップ(kanata)等コンテナに乗らないものはimportしない。
{ config, pkgs, ... }:

{
  imports = [
    ../../profiles/base.nix
  ];

  home.username      = "pt_takahashi";
  home.homeDirectory = "/home/pt_takahashi";
  home.stateVersion  = "25.11";

  programs.home-manager.enable = true;

  nixpkgs.config.allowUnfree = true;
}
