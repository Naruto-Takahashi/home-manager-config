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

## atuin — シェル履歴の検索・記録

`Ctrl+R` が atuin の全文検索 UI に置き換わっています。**↑キーは従来の zsh 履歴のまま**です。

| 操作 | 動作 |
| :--- | :--- |
| **`Ctrl+R`** | 履歴検索 UI を開く (fuzzy 検索。打つだけで絞り込み) |
| **`↑` / `↓`** | 候補の移動 (最上段で `↑` を押しても終了しない) |
| **`Enter`** | 選択したコマンドを即実行 |
| **`Tab`** | 実行せずプロンプトに挿入 (編集してから実行したいとき) |
| **`Ctrl+R` (UI 内)** | フィルタ切替 (global → host → session → directory) |
| **`Esc`** | 閉じる |

- 実行ディレクトリ・終了コード・所要時間も記録されます
- `atuin stats` でよく使うコマンドの統計が見られます
- フィルタの「directory」は「今のディレクトリで実行したものだけ」— 特定プロジェクトの履歴を掘るのに便利
- `\` 継続の複数行コマンドは改行・インデントごと記録され、`Tab`/`Enter` での呼び出し時に縦に並んだ元の形で復元される。リスト内では1行に畳んで表示 (改行は見た目だけ空白に変換し `^J` 表記が出ないようにしている)。プレビュー欄は表示崩れがあったため無効化済み
- レイアウトは検索バー上・結果下 (`invert = true`)、fzf 風の枠線付き (`style = "full"`)。検索欄と結果の間は fzf と同じ「一致件数/全件数 ────」の区切りが表示される (件数は検索一致ハイライトと同じ AlertWarn 色。全件数は DB 全体の件数を流用しており、fzf の「絞り込み前プール」とは厳密には意味が異なる)。キーヘルプは非表示
- フィルタモード名 (`GLOBAL`/`HOST`/`SESSION`/`DIRECTORY`/`WORKSPACE`) は外枠自体のタイトルとして埋め込まれる (`╭─ GLOBAL ─╮`)。枠線は fzf 実機と同じ枠線色 (#5f5f87) で統一されている (matugen には追従しない固定色)
- 左端のインジケータは fzf 風の塗りブロック (`▌`)。選択行は accent 太字、それ以外の行は選択行の背景と同じグレー
- 配色は fzf (ghq 検索等) と同じ文法: 選択行の背景色は環境変数 `ATUIN_SELECTION_BG` (matugen の surface 色、starship の `git_branch` 背景と同じ値) を実行時に読む。ビルド不要で壁紙テーマに追従する (未設定/不正なら固定色にフォールバック)。検索一致文字 = fzf の hl と同色 (matugen tertiary)
- 実行時間列 (例: `20ms`) は成功=緑・失敗=赤 (zsh syntax-highlighting と同じ固定色)。経過時間列は非表示 (実行時刻は `Ctrl+O` のインスペクタで確認)
- 注: 見た目の大部分は `modules/shell/atuin/fzf-style.patch` によるソースパッチで実現している (atuin はソースから再ビルドされる)。数字ショートカット (Alt+1..9) は komorebi のワークスペース移動と衝突するため番号表示ごと無効化

## tealdeer (tldr) — コマンドの使用例を引く

| コマンド | 動作 |
| :--- | :--- |
| **`tldr <コマンド>`** | よく使う実用例を数行で表示 (例: `tldr tar`) |
| **`tldrj <コマンド>`** | 日本語訳ページで表示 (コミュニティ翻訳。無いページは英語のまま) |
| **`tldr --list`** | ページがあるコマンドの一覧 |

- キャッシュは自動更新 (`auto_update`) なので手動の `tldr --update` は不要
- 細かいオプションの正確な仕様は従来どおり `man <コマンド>` で

## fd — find の現代版

| コマンド | 動作 |
| :--- | :--- |
| **`fd <パターン>`** | カレント以下を再帰検索 (`.gitignore` を自動で尊重) |
| **`fd -e md`** | 拡張子で絞る (.md ファイルだけ) |
| **`fd -H <パターン>`** | 隠しファイルも含める |
| **`fd <パターン> /path`** | 検索場所を指定 |
| **`fd -x <cmd> {}`** | ヒットした各ファイルにコマンド実行 (例: `fd -e log -x rm {}`) |

## delta — git diff の美しい表示

インストールするだけで `git diff` / `git log -p` の差分がシンタックスハイライト付きになります (`programs.git.settings.core.pager`、`modules/apps/git` で管理)。lazygit内蔵の差分パネルも別途 `git.pagers` (`modules/apps/lazygit`) で delta を使うよう明示している。

| 操作 | 動作 |
| :--- | :--- |
| **`n` / `N`** | (ページャ内) 次 / 前のファイルへジャンプ (`navigate` 有効) |
| **`git diff --no-pager`** | 素の diff が欲しいとき |

- シンタックス配色 (`delta.syntax-theme`) は `modules/apps/bat` が登録している `Kanagawa Dragon` テーマ。既定の `Monokai Extended` は他ツールと配色が馴染まないため、kanagawa.nvim本家のtmTheme (無印wave配色) を `lua/kanagawa/themes.lua` の dragon 色定義に合わせて手動で色置換したものを使っている (upstreamにdragon版tmThemeは存在しないため自前で用意、`modules/apps/bat/kanagawa-dragon.tmTheme`)
- bat自体もこの `Kanagawa Dragon` テーマが既定 (`bat <file>` の表示にも反映される)

## eza — ls の置き換え

`ls`/`ll`/`la`/`l`/`tree` エイリアスと `cd` 後の自動一覧表示 (`chpwd`) は全て eza を使う。ファイル種別ごとの色分けは yazi の `theme-template.toml` と同じ拡張子→役割 (tertiary/complement/triad/error/secondary) の対応で揃えており、アイコンの色もファイル名の文字色と一致させている (`modules/apps/eza/theme.yml`、matugen環境では `~/.cache/matugen/eza/theme.yml` を `EZA_CONFIG_DIR` 経由で優先)。

- 拡張子/ファイル名それぞれに `filename.foreground` と `icon.style.foreground` の両方を同じ色で指定する必要がある (eza はアイコン色をファイル名の色から自動導出しないため)
- 旧来の固定 `LS_COLORS` は eza のテーマ (特に `di`=ディレクトリ色) を上書きしてしまうため撤去済み

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
