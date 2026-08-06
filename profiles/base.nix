# =========================================================================
# 全ホスト共通プロファイル (シェル環境 + コア CLI アプリ)
# =========================================================================
# wsl / mac / nixos の全ホストが import する共通セット。
# ホスト固有のモジュール (WM や OS 依存アプリ) は各 hosts/*/ 側で追加する。
{ config, pkgs, lib, ... }:

{
  # -----------------------------------------------------------------------
  # 各モジュールで利用するグローバル引数
  # -----------------------------------------------------------------------
  # mkOutOfStoreSymlink で参照するこのリポジトリのチェックアウト位置。
  # リポジトリをこのパス以外に clone すると、symlink 配置される設定
  # (starship / yasb / komorebi / vivaldi / matugen-common など) が
  # すべて壊れるので注意。
  _module.args = {
    dotfilesPath = "${config.home.homeDirectory}/ghq/github.com/Naruto-Takahashi/nix-config";
  };

  imports = [
    ../modules/shell/zsh
    ../modules/shell/starship
    ../modules/shell/direnv
    ../modules/shell/fastfetch
    ../modules/shell/atuin
    ../modules/apps/wezterm
    ../modules/apps/neovim
    ../modules/apps/yazi
    ../modules/apps/eza
    ../modules/apps/bat
    ../modules/apps/git
    ../modules/apps/lazygit
    ../modules/apps/git-hooks
    ../modules/apps/btop
    ../modules/theming/matugen
  ];

  # -----------------------------------------------------------------------
  # 全ホスト共通の小物 CLI ツール
  # -----------------------------------------------------------------------
  # tldr クライアント (コマンドの使用例を素早く確認する)
  # 配色は kanagawa-dragon 準拠のフォールバック。matugen 環境 (WSL) では
  # matugen-apply が ~/.cache/matugen/tealdeer/config.toml を生成し、
  # zsh が TEALDEER_CONFIG_DIR でそちらを優先する。
  programs.tealdeer = {
    enable = true;
    settings = {
      updates.auto_update = true; # キャッシュが古いとき自動で `tldr --update` 相当を実行
      style = {
        description.foreground.rgb = { r = 225; g = 226; b = 232; };      # text #e1e2e8
        command_name = {
          foreground.rgb = { r = 162; g = 201; b = 253; };                # accent #a2c9fd
          bold = true;
        };
        example_text.foreground.rgb = { r = 195; g = 198; b = 207; };     # muted #c3c6cf
        example_code.foreground.rgb = { r = 215; g = 189; b = 228; };     # tertiary #d7bde4
        example_variable = {
          foreground.rgb = { r = 187; g = 199; b = 219; };                # secondary #bbc7db
          italic = true;
        };
      };
    };
  };

  # comma (`, <cmd>`) が使う nix-index DB。command-not-found 時の
  # 「どのパッケージにあるか」提案も有効になる。DB は `nix-index` で生成/更新
  programs.nix-index = {
    enable = true;
    enableZshIntegration = true;
  };

  home.packages = [
    pkgs.smassh # MonkeyType 風の TUI タイピング練習
    pkgs.fd # find の現代版 (fzf バックエンドにも)
    # ghq-fzf (Ctrl+G, modules/shell/zsh/functions.zsh) と telescope-ghq.nvim
    # (modules/apps/neovim) が両方とも依存する。以前はdesktop系ホストのみ
    # modules/desktop/packages.nix経由で入っていたが、CLI専用ホスト
    # (nalt-distrobox) で欠けていたため全ホスト共通のここに移した
    pkgs.ghq
    pkgs.delta # git diff のシンタックスハイライト付きページャ (~/.gitconfig が参照)
    pkgs.comma # `, <cmd>` で未インストールのコマンドをその場で一時実行
    pkgs.just # コマンドランナー (justfile に定型タスクをまとめる)
    # `cz commit` (対話コミット) は modules/apps/git-hooks で `cz` ラッパーとして提供
  ];
}
