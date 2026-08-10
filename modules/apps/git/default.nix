# =========================================================================
# git 宣言的設定モジュール (~/.gitconfig)
# =========================================================================
# 以前は ~/.gitconfig を手動管理していたが(git-hooksモジュールのgitmoji
# include等を初回のみ手動追記する運用)、他の設定と同じく一元管理したいので
# programs.git に移行する。ホスト固有の値 (WSLのcredential.helperなど)は
# 各hosts/*/default.nix側で programs.git.extraConfig に追記する
{ config, pkgs, ... }:

{
  home.packages = [
    pkgs.delta # git diff のシンタックスハイライト付きページャ (下記 core.pager が参照)
  ];

  programs.git = {
    enable = true;

    # 個人リポジトリ配下のみgitmojiフックを適用する (modules/apps/git-hooks が
    # ~/.config/git/gitmoji.conf を生成する。他人のOSSや会社リポジトリに
    # 無断でgitmojiが混ざるのを防ぐため、includeIfで範囲を限定している)
    includes = [
      {
        condition = "gitdir:~/ghq/github.com/Naruto-Takahashi/**";
        path = "~/.config/git/gitmoji.conf";
      }
    ];

    settings = {
      user = {
        name = "Naruto-Takahashi";
        email = "t.naruto7610@gmail.com";
      };
      core.pager = "delta";
      interactive.diffFilter = "delta --color-only";
      # 配色は modules/apps/bat で登録している "Kanagawa Dragon" テーマ (bat/delta共通)
      delta = {
        navigate = true;
        light = false;
        syntax-theme = "Kanagawa Dragon";
      };
      merge.conflictstyle = "diff3";
      diff.colorMoved = "default";
      ghq.root = "${config.home.homeDirectory}/ghq";
      pull.rebase = true;
      url."git@github.com:".insteadOf = "https://github.com/";
    };
  };
}
