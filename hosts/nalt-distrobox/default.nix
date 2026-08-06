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
#
# builtins.getEnvは`--impure`無しの評価では常に""を返す (再現性のための
# Nixの仕様)。CIの`nix build`/`nix flake check`は--impureを付けずに評価
# するため、""のままだと`home.homeDirectory`が絶対パスでないというエラーで
# 評価自体が落ちる。実際に使う時 (`--impure`付き) は環境変数を優先しつつ、
# 未設定/pure評価時はCIが通る程度のダミー絶対パスにフォールバックする。
{ config, pkgs, ... }:

let
  envHome = builtins.getEnv "HOME";
in
{
  imports = [
    ../../profiles/base.nix
  ];

  home.username      = "pt_takahashi";
  home.homeDirectory =
    if envHome != "" then envHome else "/home/pt_takahashi/distrobox-homes/nixcli-dev";
  home.stateVersion  = "25.11";

  programs.home-manager.enable = true;

  nixpkgs.config.allowUnfree = true;
}
