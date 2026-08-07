# =========================================================================
# Home Manager WSL環境用設定ファイル (~/.config/home-manager/home-wsl.nix)
# =========================================================================
{ config, pkgs, nixgl, ... }:

{
  # -----------------------------------------------------------------------
  # 各種機能・アプリケーションモジュールの読み込み
  # -----------------------------------------------------------------------
  imports = [
    ../../profiles/base.nix
    ../../modules/input/ahk
    ../../modules/wm/komorebi
    ../../modules/wm/yasb
    ../../modules/services/obsidian-mcp.nix
    ../../modules/apps/vivaldi
    ../../modules/desktop/packages.nix
  ];

  # -----------------------------------------------------------------------
  # ユーザーメタデータ & 基本システム設定
  # -----------------------------------------------------------------------
  home.username      = "nalt";
  home.homeDirectory = "/home/nalt";
  home.stateVersion  = "25.11";

  # Home Manager 自体の管理を有効化
  programs.home-manager.enable = true;

  # 非自由ライセンス（Vivaldi等プロプライエタリなソフトウェア）のインストールを許可
  nixpkgs.config.allowUnfree = true;

  # WSLではWindows側のGit for Windows (wincred) の資格情報ストアを使う
  # (modules/apps/git の共通設定に対するホスト固有の追加)
  programs.git.settings.credential.helper =
    "/mnt/c/Program Files/Git/mingw64/libexec/git-core/git-credential-wincred.exe";

  # -----------------------------------------------------------------------
  # インストールするパッケージの定義
  # -----------------------------------------------------------------------
  home.packages = with pkgs; [
    gemini-cli-bin
    codex
    fastfetch
    cowsay
    fortune
    lolcat
    nodejs_22
    wsl-open # Windowsの規定のアプリでファイルを開くためのコマンド
    gh
    sshfs   # SSH経由でリモートホストのファイルシステムをマウントするためのツール
    cava
    matugen # 壁紙から配色を抽出しYASB等へ流し込むツール
  ];
}
