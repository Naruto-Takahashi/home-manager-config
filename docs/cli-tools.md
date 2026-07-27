# CLI ユーティリティ 使い方チートシート

`profiles/base.nix` で全ホスト共通に導入している小物 CLI/TUI ツールの基本操作集です。
atuin / btop / tealdeer の配色は Matugen 連携 (壁紙由来 + kanagawa-dragon フォールバック) です ([matugen-palette.md](matugen-palette.md) 参照)。

---

## starship — プロンプトの Git ステータス記号

プロンプトの `git_branch` セグメントの右側 (`git_status`) に、作業ツリーの状態が記号で並びます。複数の状態が同時に立つ場合は隙間なく連結して表示されます (例: `- » ! + ?`)。

| 記号 | 意味 |
| :---: | :--- |
| `=` | **conflicted** — マージコンフリクト中のファイルがある |
| `⇡` | **ahead** — ローカルがリモートより進んでいる (push 前のコミットあり) |
| `⇣` | **behind** — リモートの方が進んでいる (pull が必要) |
| `⇕` | **diverged** — ローカルとリモートが分岐している |
| `?` | **untracked** — Git管理外の新規ファイルがある |
| `$` | **stashed** — `git stash` した変更がある |
| `!` | **modified** — 変更したが未ステージのファイルがある |
| `+` | **staged** — `git add` 済みの変更がある |
| `»` | **renamed** — ファイル名が変更された |
| `-` | **deleted** — 削除されたファイルがある |

- `deleted` だけ既定の `✘` (U+2718 HEAVY BALLOT X) から `-` (ハイフン) に変更している。`✘`/軽量版の `✗` (U+2717) も試したが、フォントによって隣の記号 (特に `renamed` の `»` 等) と重なって崩れて見えることがあったため、幅計算がブレないASCII文字に変更した (`modules/shell/starship/starship.toml` と `modules/theming/matugen/templates/starship.toml` の `[git_status]` セクション参照。2ファイルは内容を揃える規約、[matugen-palette.md](matugen-palette.md) 参照)
- 他の記号は starship の既定のまま (フォントの表示崩れが確認されていないため)

---

## atuin — シェル履歴の記録・検索

atuin はシェル履歴の記録・暗号化同期の**バックエンド**として使い、`Ctrl+R` の検索 UI は実物の `fzf` に置き換えています (`atuin-fzf`, `modules/shell/zsh/functions.zsh`)。**↑キーは従来の zsh 履歴のまま**です。

| 操作 | 動作 |
| :--- | :--- |
| **`Ctrl+R`** | `atuin history list --cmd-only` を fzf にパイプして検索 (fuzzy 検索) |
| **`Enter` (fzf内)** | 選択したコマンドをプロンプトに挿入 (実行はもう一度 Enter) |
| **`Esc`** | 閉じる |

- 実行ディレクトリ・終了コード・所要時間も記録されます
- `atuin stats` でよく使うコマンドの統計が見られます
- 配色・枠線・ハイライトは `FZF_DEFAULT_OPTS` (matugen 追従、`modules/theming/matugen/templates/fzf-colors.sh`) に従う。Ctrl+G の ghq ジャンプと同じ見た目
- 過去は atuin 自身の TUI を fzf 風に見せるためソースパッチ (`fzf-style.patch`) を当てていたが、atuin の内部レンダリング実装のリファクタで頻繁にパッチが壊れ運用コストが高すぎたため撤廃した。検索 UI 自体を素の fzf に任せることで、見た目のカスタマイズにソースパッチが不要になった

---

## tealdeer (tldr) — コマンドの使用例を引く

| コマンド | 動作 |
| :--- | :--- |
| **`tldr <コマンド>`** | よく使う実用例を数行で表示 (例: `tldr tar`) |
| **`tldrj <コマンド>`** | 日本語訳ページで表示 (コミュニティ翻訳。無いページは英語のまま) |
| **`tldr --list`** | ページがあるコマンドの一覧 |

- キャッシュは自動更新 (`auto_update`) なので手動の `tldr --update` は不要
- 細かいオプションの正確な仕様は従来どおり `man <コマンド>` で

---

## fd — find の現代版

| コマンド | 動作 |
| :--- | :--- |
| **`fd <パターン>`** | カレント以下を再帰検索 (`.gitignore` を自動で尊重) |
| **`fd -e md`** | 拡張子で絞る (.md ファイルだけ) |
| **`fd -H <パターン>`** | 隠しファイルも含める |
| **`fd <パターン> /path`** | 検索場所を指定 |
| **`fd -x <cmd> {}`** | ヒットした各ファイルにコマンド実行 (例: `fd -e log -x rm {}`) |

---

## delta — git diff の美しい表示

インストールするだけで `git diff` / `git log -p` の差分がシンタックスハイライト付きになります (`programs.git.settings.core.pager`、`modules/apps/git` で管理)。lazygit内蔵の差分パネルも別途 `git.pagers` (`modules/apps/lazygit`) で delta を使うよう明示している。

| 操作 | 動作 |
| :--- | :--- |
| **`n` / `N`** | (ページャ内) 次 / 前のファイルへジャンプ (`navigate` 有効) |
| **`git diff --no-pager`** | 素の diff が欲しいとき |

- シンタックス配色 (`delta.syntax-theme`) は `modules/apps/bat` が登録している `Kanagawa Dragon` テーマ。既定の `Monokai Extended` は他ツールと配色が馴染まないため、kanagawa.nvim本家のtmTheme (無印wave配色) を `lua/kanagawa/themes.lua` の dragon 色定義に合わせて手動で色置換したものを使っている (upstreamにdragon版tmThemeは存在しないため自前で用意、`modules/apps/bat/kanagawa-dragon.tmTheme`)
- bat自体もこの `Kanagawa Dragon` テーマが既定 (`bat <file>` の表示にも反映される)

---

## eza — ls の置き換え

`ls`/`ll`/`la`/`l`/`tree` エイリアスと `cd` 後の自動一覧表示 (`chpwd`) は全て eza を使う。ファイル種別ごとの色分けは yazi の `theme-template.toml` と同じ拡張子→役割 (tertiary/complement/triad/error/secondary) の対応で揃えており、アイコンの色もファイル名の文字色と一致させている (`modules/apps/eza/theme.yml`、matugen環境では `~/.cache/matugen/eza/theme.yml` を `EZA_CONFIG_DIR` 経由で優先)。

- 拡張子/ファイル名それぞれに `filename.foreground` と `icon.style.foreground` の両方を同じ色で指定する必要がある (eza はアイコン色をファイル名の色から自動導出しないため)
- 旧来の固定 `LS_COLORS` は eza のテーマ (特に `di`=ディレクトリ色) を上書きしてしまうため撤去済み

---

## btop — システムモニタ

`btop` で起動。CPU / メモリ / ネットワーク / プロセスを一望できます。

| 操作 | 動作 |
| :--- | :--- |
| **`j` / `k`** | プロセス選択の上下移動 (vim_keys 有効) |
| **`f`** | プロセス名でフィルタ |
| **`t`** | ツリー表示切替 |
| **`+` / `-`** | 選択プロセスの詳細を開閉 |
| **`k`(詳細内) / `T`** | プロセスを kill / terminate |
| **`m` / `1`〜`4`** | 表示ボックスのプリセット切替 / 個別トグル |
| **`Esc`** | メニュー (オプション・テーマ等) |
| **`q`** | 終了 |

- テーマは `matugen` 固定 (壁紙変更で自動追従)。アプリ内でテーマを変えても次の home-manager 適用では戻らないが、`btop.conf` は書き換え可能なので他のアプリ内設定は自由に保存できる

---

## smassh — タイピング練習

`smassh` で起動する MonkeyType 風タイピング練習 TUI。

| 操作 | 動作 |
| :--- | :--- |
| **`Ctrl+L`** | 言語パレット (↑/↓で合わせた瞬間に即適用・**Enter 不要**、`Esc` で閉じる) |
| **`Ctrl+T`** | テーマパレット (同上) |
| **`Ctrl+S`** | 設定画面 |
| **`Tab`** | テスト再スタート |
| **`Ctrl+C`** | 終了 |

- 言語パックは `smassh add <名前>` で MonkeyType のパック名を指定して追加 (ユーザーデータ扱いで Nix 管理外)

---

## 関連ファイル

| ファイル | 役割 |
| :--- | :--- |
| `profiles/base.nix` | 各ツールの導入宣言・atuin 設定・テーマのシード処理 |
| `modules/theming/matugen/templates/{atuin-theme.toml,btop.theme}` | Matugen テンプレート (@@KEY@@ 置換) |
| `modules/theming/matugen/fallbacks/` | kanagawa-dragon フォールバックテーマ |
| `modules/theming/matugen/lib/tealdeer-config.py` | tealdeer 用配色生成 (hex→rgb 変換) |
| `modules/shell/zsh/default.nix` | `tldrj` エイリアス定義 |
