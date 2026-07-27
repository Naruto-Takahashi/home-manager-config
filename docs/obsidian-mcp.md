# Obsidian MCP 連携 (外部脳)

**WSL2専用**です．[modules/services/obsidian-mcp.nix](../modules/services/obsidian-mcp.nix) で管理されている，ObsidianのVaultをAIエージェントの「外部脳」として使う仕組みです．セッションを跨いで知識・作業ログを引き継ぐことを目的としています．

## 仕組み

- **Vault**: Windows側の `C:\Users\<user>\Obsidian\Vault` (WSLからは `/mnt/c/Users/tnaru/Obsidian/Vault`)。初回はhome-managerのactivationフックが自動でディレクトリを作成します。
- **MCP接続**: `~/.gemini/config/mcp_config.json` を宣言的に生成し，`@bitbonsai/mcpvault` (npx経由) をMCPサーバーとして登録します。`OBSIDIAN_VAULT` 環境変数でVaultの場所を渡します。
- **ルールプロンプト**: セッション開始時に「行動ルール (`04_Library/Knowledge/mistakes.md`) とユーザープロファイル (`05_Profile/`) を必ず読む」「バグ解決・設計判断・プロジェクト状態変更・ユーザーの好みの発見はその場でVaultへ書き込む (`04_Library/Knowledge/`・`04_Library/Decisions/`・`03_Projects/`・`05_Profile/`)」といった行動ルールをAIに強制するプロンプトが，下記2つのラッパースクリプトに埋め込まれています。

## 提供コマンド

| コマンド | 対象CLI | 動作 |
| :--- | :--- | :--- |
| `agy-brain` | Antigravity CLI | ルールプロンプト付きで対話セッションを起動し，終了後に会話ログ (`transcript.jsonl`) をパースして `02_Journal/Antigravity/` にMarkdownで保存 |
| `gemini-brain` | Gemini CLI | 同上。Gemini CLIのセッション履歴 (`~/.gemini/tmp/<project>/chats/session-*.jsonl`) から `02_Journal/Gemini/` に保存 |

どちらも `jq` でJSONL形式の会話ログをパースし，ユーザー発言・アシスタント応答 (thinking/toolCallsを含む) をYAMLフロントマター付きのMarkdownノートに変換します。保存後は必ずファイルパスをターミナルに表示します。

## 他OSでの扱い

NixOS・Ubuntu・macOSではこのモジュールをimportしていません。Vaultのパスハードコード (`/mnt/c/Users/tnaru/...`) がWindowsパス前提であることもあり，他OS向けには未移植です。
