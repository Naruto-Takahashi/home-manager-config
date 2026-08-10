# グローバル指示

このファイルは `modules/apps/claude-code` が生成する `~/.claude/CLAUDE.md` の
ベース部分。機能別の追加ルール (obsidian連携など) は各モジュールが
`programs.claudeCode.extraInstructions` 経由でこの下に追記する。

## 常時ルール

1. **常に日本語でやり取りする**

2. **dotfiles/設定変更は `~/ghq/github.com/Naruto-Takahashi/nix-config` で一元管理する**
   `~/.zshrc` 等を直接編集せず、`profiles/base.nix` (全ホスト共通) または
   `modules/` 配下の該当モジュールに変更を加える。ホスト固有の設定は `hosts/` 側。

3. **nix-configでの変更は `git add` してからビルドする**
   ローカルflakeはgit管理下 (stage済み) のファイルしか評価しないため、
   新規ファイルや変更を `git add` する前に `nix flake check` / `home-manager switch`
   すると古い内容のまま反映されない。

4. **commitメッセージは gitmoji + `type(scope): 説明` 形式**
   例: `✨ feat(nix): ...` / `🐛 fix(hosts): ...`。個人リポジトリでは
   `modules/apps/git-hooks` のフックが自動付与するため、手動でも同形式に揃える。
