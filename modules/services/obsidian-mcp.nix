# =========================================================================
# Obsidian MCP 連携サービス設定モジュール
# =========================================================================
{ config, pkgs, lib, ... }:

let
  # --- Obsidian Vault の場所 (WSL から見た Windows 側パス) ---
  vaultPath = "/mnt/c/Users/tnaru/Obsidian/Vault";

  # --- 共通ルールプロンプトの定義 ---
  rulePrompt = ''
    あなたは私のAIアシスタントです．
    ObsidianのVaultを「外部脳」として扱い，セッションを跨いで知識を引き継いでください．
    MCP経由（obsidianツール）でObsidianを読み書きできます．

    ---

    【行動ルール】
    1. 読み取り（セッション開始時に必ず実行）：
       - 行動ルール（04_Library/Knowledge/mistakes.md）と，05_Profile/ 配下のユーザープロファイルを最初に必ず読み込んでください．
       - 私の質問に関連するキーワードでVaultを検索し，ヒットしたノートを読んでその内容を踏まえて回答してください．

    2. 書き込み（その場でVaultに書き込みます．「後で書く」は行いません）：
       - バグ解決，設定ハマり対策，新しい発見などは「04_Library/Knowledge/」に書き込む．
       - 判断・設計の方針決定は「04_Library/Decisions/」に書き込む．
       - プロジェクトの状態変更は「03_Projects/」に書き込む．
       - ユーザーの好みの発見は「05_Profile/」に書き込む．

    3. 書き込みフォーマット：
       ノートには必ず以下のYAMLフロントマターを付与してください：
       ---
       date: YYYY-MM-DD
       tags: [relevant, tags]
       project: project-name
       related: [[Other Note]]
       ---
       タイトル
       本文．関連ノートには [[wiki link]] でリンクする．

    4. mistakes.md への追記ルール：
       ユーザーから明示的な訂正を受け，かつ「繰り返し起こり得るパターン」を満たす場合，即座に 04_Library/Knowledge/mistakes.md に追記してください．

    5. 報告：
       Obsidianを読み書きしたら，必ずユーザーに伝えてください．

    ---
    それでは，指示通り初期ファイルを読み込んでから回答を開始してください．
  '';

  # --- agy-brain (Antigravity用連携スクリプト) ---
  agy-brain = pkgs.writeShellApplication {
    name = "agy-brain";
    runtimeInputs = [ pkgs.gum pkgs.ripgrep pkgs.jq pkgs.coreutils pkgs.findutils ];
    excludeShellChecks = [ "SC2012" ];
    text = ''
      VAULT_PATH="${vaultPath}"
      RULE_PROMPT="${rulePrompt}"

      echo "=== Obsidian 外部脳連携 Antigravity CLI ==="
      
      BRAIN_DIR="$HOME/.gemini/antigravity-cli/brain"
      PREV_LATEST=""
      if [ -d "$BRAIN_DIR" ]; then
        PREV_LATEST=$(ls -td "$BRAIN_DIR"/*/ 2>/dev/null | head -n 1)
      fi

      antigravity-cli --prompt-interactive "$RULE_PROMPT"

      echo "対話セッションが終了しました．会話履歴をObsidianに保存します．"
      sleep 2
      
      if [ -d "$BRAIN_DIR" ]; then
        NEW_LATEST=$(ls -td "$BRAIN_DIR"/*/ 2>/dev/null | head -n 1)
        if [ -n "$NEW_LATEST" ] && [ "$NEW_LATEST" != "$PREV_LATEST" ]; then
          DATE_STR=$(date "+%Y-%m-%d_%H-%M-%S")
          LOG_DIR="$VAULT_PATH/02_Journal/Antigravity"
          mkdir -p "$LOG_DIR"
          LOG_FILE="$LOG_DIR/$DATE_STR.md"

          TRANSCRIPT_PATH="$NEW_LATEST/transcript.jsonl"
          if [ -f "$TRANSCRIPT_PATH" ]; then
            SESSION_ID=$(basename "$NEW_LATEST")
            {
              echo "---"
              echo "date: $(date "+%Y-%m-%d")"
              echo "tags: [ai-log, antigravity]"
              echo "session_id: $SESSION_ID"
              echo "---"
              echo "# Antigravity CLI 会話ログ"
              echo ""
              jq -r 'select(.type=="USER_INPUT" or .type=="PLANNER_RESPONSE") | 
                     if .type=="USER_INPUT" then
                       "\n---\n\n## 👤 ユーザー\n" + (.content // "")
                     else
                       "\n## 🤖 アシスタント\n" + 
                       (if .thinking then "\n<details>\n<summary>思考プロセス</summary>\n\n" + .thinking + "\n</details>\n" else "" end) +
                       (.content // "")
                     end' "$TRANSCRIPT_PATH"
            } > "$LOG_FILE"
            echo "-> 会話ログを保存しました: $LOG_FILE"
          fi
        fi
      fi
    '';
  };

  # --- gemini-brain (Gemini-CLI用連携スクリプト) ---
  gemini-brain = pkgs.writeShellApplication {
    name = "gemini-brain";
    runtimeInputs = [ pkgs.ripgrep pkgs.jq pkgs.coreutils pkgs.findutils ];
    excludeShellChecks = [ "SC2012" ];
    text = ''
      VAULT_PATH="${vaultPath}"
      RULE_PROMPT="${rulePrompt}"

      echo "=== Obsidian 外部脳連携 Gemini CLI ==="
      
      PROJECT_NAME=$(basename "$(pwd)")
      HISTORY_DIR="$HOME/.gemini/tmp/$PROJECT_NAME/chats"
      PREV_LATEST=""
      if [ -d "$HISTORY_DIR" ]; then
        PREV_LATEST=$(ls -t "$HISTORY_DIR"/session-*.jsonl 2>/dev/null | head -n 1)
      fi

      gemini --prompt-interactive "$RULE_PROMPT"

      echo "対話セッションが終了しました．会話履歴をObsidianに保存します．"
      sleep 2
      
      if [ -d "$HISTORY_DIR" ]; then
        NEW_LATEST=$(ls -t "$HISTORY_DIR"/session-*.jsonl 2>/dev/null | head -n 1)
        if [ -n "$NEW_LATEST" ] && [ "$NEW_LATEST" != "$PREV_LATEST" ]; then
          DATE_STR=$(date "+%Y-%m-%d_%H-%M-%S")
          LOG_DIR="$VAULT_PATH/02_Journal/Gemini"
          mkdir -p "$LOG_DIR"
          LOG_FILE="$LOG_DIR/$DATE_STR.md"

          {
            echo "---"
            echo "date: $(date "+%Y-%m-%d")"
            echo "tags: [ai-log, gemini]"
            echo "project: $PROJECT_NAME"
            echo "---"
            echo "# Gemini CLI 会話ログ"
            echo ""
            jq -r 'select(.type=="user" or .type=="gemini") | 
                   if .type=="user" then
                     "\n---\n\n## 👤 ユーザー\n" + (.content[0].text // "")
                   else
                     "\n## 🤖 アシスタント\n" + 
                     (if (.thoughts | length > 0) then "\n<details>\n<summary>思考プロセス (" + .thoughts[0].subject + ")</summary>\n\n" + ([.thoughts[].description] | join("\n\n")) + "\n</details>\n" else "" end) +
                     (if (.content != "") then "\n" + .content else (if (.toolCalls | length > 0) then "\n> [!INFO] ツール実行: " + ([.toolCalls[].displayName] | join(", ")) else "" end) end)
                   end' "$NEW_LATEST"
          } > "$LOG_FILE"
          echo "-> 会話ログを保存しました: $LOG_FILE"
        fi
      fi
    '';
  };

  # --- Claude Code 用ルール (CLAUDE.md) ---
  # agy-brain/gemini-brain の rulePrompt と同内容だが，Claude Codeには
  # ラッパースクリプトによるプロンプト強制注入の仕組みが無いため，
  # 標準の~/.claude/CLAUDE.md (グローバル、全プロジェクトで自動読込) に
  # 置くことで同じ「セッション開始時に必ず読む/その場で書く」を実現する。
  # ツール名はClaude Code側のMCPツール実名 (mcp__obsidian__*) に合わせている。
  claudeObsidianRules = ''
    # Obsidian Vault 連携 (外部脳)

    ObsidianのVaultを「外部脳」として扱い，セッションを跨いで知識を引き継ぐ。MCP経由 (`mcp__obsidian__*` ツール群) でVaultを読み書きできる。

    ## 行動ルール

    1. **読み取り (セッション開始時、最初のツール呼び出しとして必ず実行)**
       - `mcp__obsidian__read_note` で `04_Library/Knowledge/mistakes.md` と `05_Profile/` 配下のユーザープロファイルを読む
       - ユーザーの質問に関連するキーワードで `mcp__obsidian__search_notes` を実行し，ヒットしたノートを読んでから回答する

    2. **書き込み (気づいた・決まったその場で書く。「後で書く」はしない)**
       - バグ解決・設定のハマり対策・新しい発見 → `04_Library/Knowledge/`
       - 判断・設計の方針決定 → `04_Library/Decisions/`
       - プロジェクトの状態変更 → `03_Projects/`
       - ユーザーの好みの発見 → `05_Profile/`
       - `mcp__obsidian__write_note` (新規) または `mcp__obsidian__patch_note` (既存ノートへの追記) を使う

    3. **書き込みフォーマット**
       ノートには必ず以下のYAMLフロントマターを付与する:
       ```
       ---
       date: YYYY-MM-DD
       tags: [relevant, tags]
       project: project-name
       related: [[Other Note]]
       ---
       タイトル

       本文。関連ノートには [[wiki link]] でリンクする。
       ```

    4. **mistakes.md への追記ルール**
       ユーザーから明示的な訂正を受け，かつ「繰り返し起こり得るパターン」を満たす場合，即座に `mcp__obsidian__patch_note` で `04_Library/Knowledge/mistakes.md` に追記する

    5. **報告**
       Obsidianを読み書きしたら，何を読んだ/書いたか(パス)を必ずユーザーに伝える

    6. **フォールバック**
       `mcp__obsidian__*` ツールが見当たらない場合 (MCPサーバー未接続)，その旨をユーザーに伝えて通常の対応を続ける。無言でスキップしない
  '';
in
{
  # --- 連携パッケージの追加 ---
  home.packages = [
    agy-brain
    gemini-brain
  ];

  # --- mcp_config.json の生成 ---
  # ~/.gemini/config/mcp_config.json の宣言的生成を行います．
  home.file."${config.home.homeDirectory}/.gemini/config/mcp_config.json".text = builtins.toJSON {
    mcpServers = {
      obsidian = {
        command = "npx";
        # @bitbonsai/mcpvault はVaultパスを環境変数(OBSIDIAN_VAULT)ではなく
        # 位置引数で受け取る仕様 (省略時はカレントディレクトリをVault扱いする)。
        # 以前は誤って環境変数経由 + ~/ghq/.../obsidian-vault (git バックアップ用
        # クローン、実際のノートは入っていない) を指していた。Obsidianアプリ・
        # agy-brain/gemini-brain が実際に読み書きするVaultに合わせる
        args = [ "-y" "@bitbonsai/mcpvault" vaultPath ];
      };
    };
  };

  # Claude Codeはグローバル ~/.claude/CLAUDE.md を全プロジェクトで自動的に
  # 読み込むため，宣言的に配置するだけで自律的な読み書きが有効になる
  home.file."${config.home.homeDirectory}/.claude/CLAUDE.md".text = claudeObsidianRules;

  # --- Obsidian Vault作成アクティベーションフック ---
  # ObsidianのVaultディレクトリを初期作成するフックです．
  home.activation = {
    createObsidianVault = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "${vaultPath}"
    '';
  };
}
