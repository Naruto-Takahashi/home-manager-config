# =========================================================================
# LazyGit 宣言的設定モジュール
# =========================================================================
{ config, pkgs, ... }:

{
  # --- LazyGitの設定 ---
  # LazyGitの有効化，およびカスタムコマンド・外観テーマを設定します．
  programs.lazygit = {
    enable = true;
    
    settings = {
      # lazygit内蔵の差分パネルはデフォルトでは自前のシンタックスハイライトを
      # 使っており、~/.gitconfigのcore.pager=deltaとは無関係。ここでもdeltaを
      # 使うよう明示する (git diff/showと同じ見た目に揃える)。
      git = {
        pagers = [
          {
            colorArg = "always";
            pager = "delta --dark --paging=never";
          }
        ];
      };

      # Gemini APIを使用したコミットメッセージ自動生成コマンドの登録
      customCommands = [
        {
          key = "<c-g>";
          description = "Generate commit message via Gemini and Edit";
          context = "global";
          command = "${config.home.homeDirectory}/.local/bin/lazygit-gemini-commit";
          output = "terminal";
        }
        {
          # commitizen (cz) で type/scope/subject を対話選択してコミット
          # (docs/gitmoji.md, .cz.toml 参照)。stageされた変更がある前提。
          # 既定のcommitChanges(通常コミット)を使わなくなったため、
          # 一等地の c キーをcustomCommandsで上書きする
          # (lazygitはcustomCommandsを既定キーバインドより優先する)。
          # 素のコミットメッセージ入力に戻したい場合は C (commitChangesWithEditor)
          # または w (commitChangesWithoutHook, フック無視) を使う。
          key = "c";
          description = "Commit interactively via commitizen (cz)";
          context = "files";
          command = "cz commit";
          output = "terminal";
        }
      ];

      # 外観テーマ設定（kanagawa-dragon配色）
      gui = {
        theme = {
          # フォールバック値 (matugen適用時は ~/.cache/matugen/lazygit-theme.yml が
          # LG_CONFIG_FILE経由で色だけ上書きする。role対応は
          # modules/theming/matugen/templates/lazygit-theme.yml と揃えること)
          activeBorderColor = [ "#a2c9fd" "bold" ]; # accent
          inactiveBorderColor = [ "#c3c6cf" ]; # muted
          searchingActiveBorderColor = [ "#d7bde4" ]; # tertiary
          optionsTextColor = [ "#d7bde4" ]; # tertiary
          selectedLineBgColor = [ "#272a2f" ]; # surface
          cherryPickedCommitBgColor = [ "#272a2f" ]; # surface
          cherryPickedCommitFgColor = [ "#f2d4ad" ]; # complement
          unstagedChangesColor = [ "#ffb4ab" ]; # error
          defaultFgColor = [ "#e1e2e8" ]; # text
        };
      };
    };
  };
}
