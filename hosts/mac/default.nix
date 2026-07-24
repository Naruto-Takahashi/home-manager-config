# =========================================================================
# Home Manager Mac環境用設定ファイル (~/.config/home-manager/hosts/mac/default.nix)
# =========================================================================
{ config, pkgs, ... }:

{
  # -----------------------------------------------------------------------
  # 各種機能・アプリケーションモジュールの読み込み
  # -----------------------------------------------------------------------
  imports = [
    ../../profiles/base.nix
    ../../modules/apps/aerospace
    ../../modules/theming/matugen/mac
  ];

  # -----------------------------------------------------------------------
  # ユーザーメタデータ & 基本システム設定
  # -----------------------------------------------------------------------
  home.username      = "nalt";
  home.homeDirectory = "/Users/nalt";
  home.stateVersion  = "25.11";

  # Home Manager 自体の管理を有効化
  programs.home-manager.enable = true;

  # 非自由ライセンスのインストールを許可
  nixpkgs.config.allowUnfree = true;

  # -----------------------------------------------------------------------
  # インストールするパッケージの定義
  # -----------------------------------------------------------------------
  home.packages = with pkgs; [
    fastfetch
    cowsay
    fortune
    lolcat
    nodejs_22
    gh
    ghq
    antigravity-cli
    claude-code
    hackgen-nf-font
    kanata
  ];

  # フォントの設定を有効化
  fonts.fontconfig.enable = true;


  # Mac向け Kanata 設定ファイルの動的生成（Linux/他環境との互換性を維持する置換）
  # 英数/かな切り替え・WM操作ともKanata側（config.kbd）で完結させるため，
  # Karabiner-Elements本体（karabiner.json）は導入しない．
  xdg.configFile."kanata/config.kbd".text =
    let
      original = builtins.readFile ../../modules/input/kanata/config.kbd;
      # 1. macOSでは Ctrl 長押し時に ctrl-layer を有効化する
      replaced1 = builtins.replaceStrings [ "cap-ctrl-action" ] [ "(layer-toggle ctrl-layer)" ] original;
      # 2. ウィンドウマネージャーのモディファイアは Ctrl + Cmd (C-M-) にする (wmmodifier- -> C-M-)
      replaced2 = builtins.replaceStrings [ "wmmodifier-" ] [ "C-M-" ] replaced1;
      # 3. macOSでは Alt + Space (alt-layer + spc) を A-spc (Alt + Space) に直接マッピングする
      replaced3 = builtins.replaceStrings [ "@hyp-d " ] [ "A-spc " ] replaced2;
      # 4. macOSでは Alt + Tab (alt-layer + tab) を A-tab (Alt + Tab) に直接マッピングする (AltTabアプリとの連携用)
      replaced4 = builtins.replaceStrings [ "@hyp-tab" ] [ "A-tab" ] replaced3;
    in
      replaced4;
}
