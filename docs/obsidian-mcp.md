# Obsidian MCP 連携 (外部脳)

**WSL2専用**です．[modules/services/obsidian-mcp.nix](../modules/services/obsidian-mcp.nix) で管理されている，ObsidianのVaultをAIエージェントの「外部脳」として使う仕組みです．セッションを跨いで知識・作業ログを引き継ぐことを目的としています．

---

## 仕組み

- **Vault**: Windows側の `C:\Users\<user>\Obsidian\Vault` (WSLからは `/mnt/c/Users/tnaru/Obsidian/Vault`)。初回はhome-managerのactivationフックが自動でディレクトリを作成します。
- **MCP接続**: `~/.gemini/config/mcp_config.json` を宣言的に生成し，`@bitbonsai/mcpvault` (npx経由) をMCPサーバーとして登録します。`@bitbonsai/mcpvault` はVaultの場所を**環境変数ではなく位置引数**で受け取る仕様 (省略時はカレントディレクトリをVault扱いしてしまう) のため，`args` にVaultパスを直接渡しています。
- **ルールプロンプト**: セッション開始時に「行動ルール (`04_Library/Knowledge/mistakes.md`) とユーザープロファイル (`05_Profile/`) を必ず読む」「バグ解決・設計判断・プロジェクト状態変更・ユーザーの好みの発見はその場でVaultへ書き込む (`04_Library/Knowledge/`・`04_Library/Decisions/`・`03_Projects/`・`05_Profile/`)」といった行動ルールをAIに強制するプロンプトが，下記2つのラッパースクリプトに埋め込まれています。

---

## 提供コマンド

| コマンド | 対象CLI | 動作 |
| :--- | :--- | :--- |
| `agy-brain` | Antigravity CLI | ルールプロンプト付きで対話セッションを起動し，終了後に会話ログ (`transcript.jsonl`) をパースして `02_Journal/Antigravity/` にMarkdownで保存 |
| `gemini-brain` | Gemini CLI | 同上。Gemini CLIのセッション履歴 (`~/.gemini/tmp/<project>/chats/session-*.jsonl`) から `02_Journal/Gemini/` に保存 |

どちらも `jq` でJSONL形式の会話ログをパースし，ユーザー発言・アシスタント応答 (thinking/toolCallsを含む) をYAMLフロントマター付きのMarkdownノートに変換します。保存後は必ずファイルパスをターミナルに表示します。

---

## Claude Code での利用

Claude Codeは標準でMCPサーバーに対応しているため，`agy-brain`/`gemini-brain`のような専用ラッパースクリプトは不要で，Claude Code自身の設定にMCPサーバーを1回登録するだけでよい:

```
claude mcp add -s user obsidian -- npx -y @bitbonsai/mcpvault "/mnt/c/Users/tnaru/Obsidian/Vault"
```

- `@bitbonsai/mcpvault` はVaultパスを環境変数ではなく**位置引数**で受け取る (省略時はカレントディレクトリをVault扱いしてしまう罠がある。`-e OBSIDIAN_VAULT=...` は効かないので注意)
- `-s user` でユーザースコープ (全プロジェクト共通) に登録される。この設定は `~/.claude.json` に保存され，home-manager管理外 (Claude Code自身の状態ファイルであり，宣言的に上書きすると他の状態を壊すリスクがあるため意図的に対象外にしている)
- 新しい環境では上記コマンドを一度実行するだけでよい (`claude mcp list` で `obsidian: ... ✔ Connected` と出れば成功)
- 登録直後の**今のセッションには反映されない** (MCPサーバーはセッション開始時にしかロードされない)。Claude Codeを再起動した新しいセッションで `mcp__obsidian__list_directory` 等を呼び，Vault側の実際のフォルダ (`01_Meta`/`02_Journal`/... ) が見えることを確認すること。nix-configリポジトリのファイル (`docs`/`modules`/...) が見えたらVaultパスが渡っていない
- ルールプロンプト (セッション開始時に読むべきファイル・書き込み先など) はagy-brain/gemini-brainのように自動注入されないため，必要ならCLAUDE.mdやセッション冒頭で明示的に伝える運用になる
- 会話ログの自動Vault保存 (`02_Journal/`) もagy-brain/gemini-brain相当の仕組みは無い (Claude Codeは会話履歴の保存場所・形式が異なるため未実装)

---

## 他OSでの扱い

NixOS・macOSではこのモジュールをimportしていません。Vaultのパスハードコード (`/mnt/c/Users/tnaru/...`) がWindowsパス前提であることもあり，他OS向けには未移植です。

---

## 関連ファイル

| ファイル | 役割 |
| :--- | :--- |
| `modules/services/obsidian-mcp.nix` | MCP設定生成・`agy-brain`/`gemini-brain`ラッパー・Vault作成フックの実装 |
