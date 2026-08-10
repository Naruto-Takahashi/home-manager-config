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
          # 02_Journal/Antigravity のようなツール別フォルダは作らず、
          # 日付ベースの02_Journal/YYYY/MM/に統一する (2026-07-27，
          # 02_Journal/README.mdが定義する唯一の運用ルールに合わせるため)。
          # ツールの区別はfrontmatterのtagsで行う。
          DATE_STR=$(date "+%Y-%m-%d_%H-%M-%S")
          LOG_DIR="$VAULT_PATH/02_Journal/$(date "+%Y")/$(date "+%m")"
          mkdir -p "$LOG_DIR"
          LOG_FILE="$LOG_DIR/$DATE_STR.md"

          TRANSCRIPT_PATH="$NEW_LATEST/transcript.jsonl"
          if [ -f "$TRANSCRIPT_PATH" ]; then
            SESSION_ID=$(basename "$NEW_LATEST")
            # 生ログ(アシスタントの応答・思考プロセス全文)は保存しない
            # (Vaultの肥大化・陳腐化の主因だったため2026-07-27に方針変更)。
            # ユーザー発言だけを抜き出した軽量な箇条書き要約に留める。
            # 重要な知見・決定はセッション中にルールプロンプトが
            # Knowledge/Decisions/Projectsへ直接書き込ませている
            {
              echo "---"
              echo "date: $(date "+%Y-%m-%d")"
              echo "tags: [ai-log, antigravity, summary]"
              echo "session_id: $SESSION_ID"
              echo "---"
              echo "# Antigravity CLI セッション要約 (ユーザー発言のみ)"
              echo ""
              jq -r 'select(.type=="USER_INPUT") | "- " + ((.content // "") | gsub("\n"; " "))' "$TRANSCRIPT_PATH"
            } > "$LOG_FILE"
            echo "-> セッション要約を保存しました: $LOG_FILE"
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
          # 02_Journal/Gemini のようなツール別フォルダは作らず、
          # 日付ベースの02_Journal/YYYY/MM/に統一する (2026-07-27，
          # 02_Journal/README.mdが定義する唯一の運用ルールに合わせるため)。
          # ツールの区別はfrontmatterのtagsで行う。
          DATE_STR=$(date "+%Y-%m-%d_%H-%M-%S")
          LOG_DIR="$VAULT_PATH/02_Journal/$(date "+%Y")/$(date "+%m")"
          mkdir -p "$LOG_DIR"
          LOG_FILE="$LOG_DIR/$DATE_STR.md"

          # 生ログ(アシスタントの応答・思考プロセス全文)は保存しない
          # (Vaultの肥大化・陳腐化の主因だったため2026-07-27に方針変更)。
          # ユーザー発言だけを抜き出した軽量な箇条書き要約に留める。
          # 重要な知見・決定はセッション中にルールプロンプトが
          # Knowledge/Decisions/Projectsへ直接書き込ませている
          {
            echo "---"
            echo "date: $(date "+%Y-%m-%d")"
            echo "tags: [ai-log, gemini, summary]"
            echo "project: $PROJECT_NAME"
            echo "---"
            echo "# Gemini CLI セッション要約 (ユーザー発言のみ)"
            echo ""
            jq -r 'select(.type=="user") | "- " + ((.content[0].text // "") | gsub("\n"; " "))' "$NEW_LATEST"
          } > "$LOG_FILE"
          echo "-> セッション要約を保存しました: $LOG_FILE"
        fi
      fi
    '';
  };

  # --- vaultPath自体のgit自動commit&push ---
  # Vault (/mnt/c/Users/tnaru/Obsidian/Vault) は元からgit管理下
  # (obsidian-vault リポジトリのworking copy) だが、コミット・pushは
  # 手動運用だったため自動化する。AIエージェント(Claude/Gemini/Antigravity)
  # がその場で書き込んだ内容も取りこぼさないよう、変更があれば無条件でcommitする。
  obsidian-vault-sync = pkgs.writeShellApplication {
    name = "obsidian-vault-sync";
    runtimeInputs = [ pkgs.git ];
    text = ''
      cd "${vaultPath}"

      # gitリポジトリでなければ何もしない (初回セットアップがまだの環境等)
      if [ ! -d .git ]; then
        echo "obsidian-vault-sync: ${vaultPath} はgitリポジトリではないためスキップ"
        exit 0
      fi

      git add -A

      if git diff --cached --quiet; then
        exit 0
      fi

      git commit -q -m "auto: vault sync $(date '+%Y-%m-%d %H:%M:%S')"
      # ネットワーク不通等でpushが失敗してもタイマー自体は落とさない
      # (次回実行時に前回分もまとめてpushされる)
      git push -q || echo "obsidian-vault-sync: pushに失敗 (次回リトライされます)" >&2
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
  # 読み込むため，宣言的に配置するだけで自律的な読み書きが有効になる。
  # CLAUDE.md自体の生成は modules/apps/claude-code が一元管理しているため，
  # ここでは追加ルールとして注入するのみ
  programs.claudeCode.extraInstructions = [ claudeObsidianRules ];

  # --- Obsidian Vault作成アクティベーションフック ---
  # ObsidianのVaultディレクトリを初期作成するフックです．
  home.activation = {
    createObsidianVault = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "${vaultPath}"
    '';
  };

  # --- Vault自動sync用 systemd --user タイマー ---
  # 30分おきにVaultの変更をcommit&pushする。WSL2はsystemd=trueが前提
  # (/etc/wsl.conf)。ログオン中しか動かないため、ログオフ中の変更は
  # 次回ログオン後の最初の実行でまとめて拾われる。
  systemd.user.services.obsidian-vault-sync = {
    Unit.Description = "Obsidian Vault の変更をgit commit & pushする";
    Service = {
      Type = "oneshot";
      ExecStart = "${obsidian-vault-sync}/bin/obsidian-vault-sync";
    };
  };
  systemd.user.timers.obsidian-vault-sync = {
    Unit.Description = "obsidian-vault-sync を30分おきに実行";
    Timer = {
      OnStartupSec = "5m"; # ログオン直後の混雑を避けて少し待ってから初回実行
      OnUnitActiveSec = "30m";
      Persistent = true; # 前回実行を過ぎていたら起動直後に追いつき実行する
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
