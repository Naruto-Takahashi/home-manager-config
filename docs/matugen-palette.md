# Matugen パレット — 色の名前と用途

壁紙から matugen で抽出・生成される動的パレットの一覧。
`matugen-apply` (WSL: `~/.local/bin/matugen-apply`) が壁紙変更のたびに
`~/.cache/matugen/colors.lua` へ書き出し、各アプリがそこから読む。

## 色の定義

| 名前 | 由来 | 説明 |
| :--- | :--- | :--- |
| `accent` | Material **primary** | メインハイライト。最も目立つ色 |
| `secondary` | Material **secondary** | 2番めの色。accent より落ち着いた同系統 |
| `tertiary` | Material **tertiary** | 3番めの色。旧名 `accent_sub` |
| `complement` | accent の**色相 180° 回転** (計算生成) | 補色。どんな壁紙でも accent から最も遠い色相になる。旧名 `visual` |
| `triad` | accent の**色相 120° 回転** (計算生成) | トライアド。accent / complement と色相環上で均等に散らばる |
| `text` | Material on_surface | 本文の文字色 (落ち着いた白) |
| `muted` | Material on_surface_variant | 控えめな文字色 (薄いグレー系) |
| `surface` | Material surface_container_high | 暗色セグメントの地 (黒ブロック) |
| `on_accent` | Material surface | accent 等の明色地に載せる暗い文字色 |
| `accent_pale` | accent を**白へ 40% ブレンド** (計算生成) | 装飾ブロック用のパステル色 |

- 色相回転 (`complement` / `triad`) は HLS の H だけ回して計算する
  (彩度は accent の 0.75 倍に抑える)。明度は accent と同じなのでパレットに馴染む。
  `accent_pale` は RGB を白へ 40% 線形ブレンドする。
  実装は `modules/theming/matugen/lib/derive-colors.py` に集約されており、
  NixOS (wppicker.sh) と WSL (matugen-apply.sh) の両方がこれを呼ぶ。
- 各設定にはファイルが無い環境用のフォールバック値がハードコードされている
  (`nvim/lua/matugen.lua`, `modules/apps/wezterm/wezterm.lua` の colors テーブルなど)。
  壁紙を変えたら `modules/theming/matugen/bake-fallbacks.sh` でこれらを
  今の壁紙色に一括更新できる (詳細は後述の「フォールバックの一括更新」)。

## 用途の割り当て

| 場所 | accent | secondary | tertiary | complement | triad |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Starship** | ディレクトリ地 / git 文字 | 左端ブロック (OSロゴ/PS) | — | — | — |
| **WezTerm タブ** | アクティブタブ | — | カーソル色 | — | — |
| **lualine** | Normal モード | 左端ブロック (Normal時) | Insert モード | Visual モード | — |
| **yazi ステータスバー** | Normal モード | 左端ブロック (Normal時) | — | Select モード | — |
| **yazi ファイル色** | — | フォルダ名/アイコン | ドキュメント・テキスト系 | スクリプト・メディア系 | Web・データ系 |
| **nvim タブライン** | アクティブタブ | — | — | — | — |
| **nvim ダッシュボード** | メニューアイコン | ロゴ / 起動メッセージ | キー割当 (f, r...) | — | — |
| **Neo-tree** | — | フォルダ名/アイコン | — | — | — |
| **komorebi 枠** | single / floating | — | monocle (ALT+F) | — | — |
| **lazygit** | アクティブ枠 | — | 検索枠 / オプション文字 | チェリーピック文字 | — |
| **YASB** | フォーカス島 / アクティブWS | — | cava 波形 / 空WSドット | — | — |

補足:
- Insert/Visual などモード変化時、lualine / yazi の左端ブロックは
  「モード色を白へ 40% 寄せたパステル版」になる (Normal の secondary と同じ関係)。
- 赤系 (Replace モード、yazi のコンパイル言語/アーカイブ、lazygit の未ステージ、Quit) は
  matugen の `error` 色 (colors.lua にも出力) を使用。
- komorebi の unfocused 枠は matugen の outline トーン、yazi のフルボーダーは
  muted と surface の中間色 (実行時合成)、nvim のメニュー文字は text。

## 反映の仕組み

同じパレットを WSL・Mac・NixOS の3つのホストで別の経路で反映している。

### WSL (Windows / komorebi + YASB)

中核は `modules/theming/matugen/wsl/matugen-apply.sh`
(home-manager が `~/.local/bin/matugen-apply` として mkOutOfStoreSymlink 配置。
リポジトリを編集すればそのまま反映され、switch は不要)。

```
壁紙変更 (YASB wallpapers ウィジェットの run_after)
  → matugen-apply <image>
     1. matugen image <壁紙> -c ~/.config/matugen-wsl/config.toml
        → テンプレート palette.css から ~/.cache/matugen/yasb-palette.css を生成
          (matugen が作るのはこの CSS 1枚だけ)
        あわせて Windows のロック画面壁紙も同じ画像に設定する
        (UWP UserProfile.LockScreen API を PowerShell -EncodedCommand で呼ぶ)
     2. matugen-apply が palette.css から CSS 変数を抽出し、一時 colors.lua
        (7キー: accent/tertiary/secondary/text/muted/surface/on_accent + error)
        を組み立てて NixOS と共通の modules/theming/matugen/lib/ に渡す:
        - derive-colors.py  : complement/triad/accent_pale を追記 (11キーに)
        - render-template.sh: starship.toml / lazygit-theme.yml /
                              yazi theme.toml / cz.toml / eza/theme.yml を
                              共通テンプレートから生成 (cz.tomlのtype選択肢は
                              modules/apps/git-hooks/cz.toml と手動で同じ
                              内容を保つ運用。単一ソース化は複雑さに見合わず
                              revert済み)
     3. 残りは WSL/YASB 固有のまま展開する:
        - YASB styles.css   : MATUGEN マーカー間を差し替えて /mnt/c へ配置
        - komorebi.json     : 枠色 (single/floating/monocle) を sed → 同期 reload
        - colors.lua        : nvim / yazi / wezterm 共通の Lua パレット (完成形をコピー)。
                              selection_bg (surface色、fzf/nvim/atuinの選択行背景
                              に共通で使う) もここに含まれる
        - starship (Windows): 生成済み ~/.cache/matugen/starship.toml から
                              os_logo を除去した PowerShell 用変種を /mnt/c へ配置
        - fzf               : 設定ファイルを丸ごと生成 (ATUIN_SELECTION_BGの
                              exportも同じfzf-colors.shに含める)
        - cava              : config.yaml 内の色を sed (inode 保持で watch_config を維持)。
                              この書き換えは YASB の全体リロードを誘発するため必ず最後。
                              komorebi のリロードと重なると YASB→komorebi の pipe
                              再購読が失敗しワークスペース表示が消えるため
```

- 各アプリの反映タイミング: YASB はファイル監視 (watch_config/watch_stylesheet) で即時、
  WezTerm は自動リロードで即時、nvim / yazi / starship / lazygit / fzf は次回起動時。
- `sync-win` は設定コピー後に必ず `matugen-apply --reapply` を呼ぶ。
  raw コピーはフォールバック色に戻ってしまうため、**手動で /mnt/c へコピーした場合も
  必ず reapply を実行する**こと。
- `--reapply` は `~/.cache/matugen/last-wallpaper` に記録された前回の壁紙から
  フル再生成する (テンプレート更新も反映される)。

### NixOS (Hyprland)

matugen の**テンプレート機能と post_hook**で完結するもの
(`modules/wm/hyprland/config/matugen/config.toml`) と、色相回転が必要で
matugen 単体では作れないものを分けている。後者は WSL/NixOS 共通モジュール
`modules/theming/matugen/`（後述）に実装が集約されている。

```
壁紙変更 (rofi の壁紙ピッカー wppicker.sh)
  → matugen image <壁紙>
     - [config.wallpaper] で awww により壁紙も matugen が設定
     - [templates.*] で各アプリの設定を直接生成 + post_hook で即時リロード:
       waybar (SIGUSR2) / kitty (SIGUSR1) / hyprland (hyprctl reload) /
       cava (SIGUSR1) / gtk3・gtk4 / rofi / spicetify / vesktop /
       colors.lua (nvim・yazi の Material role 部分, 7キー) / fzf
  → wppicker.sh が modules/theming/matugen/lib/ の共通スクリプトを呼ぶ:
     1. derive-colors.py が colors.lua に complement/triad/accent_pale を追記
        (11キーの完成形になる)
     2. render-template.sh が @@プレースホルダ@@ テンプレートをレンダリング:
        yazi theme.toml / lazygit-theme.yml / starship.toml (palettes.matugen
        ブロックのみ、他は静的)
     3. colors.lua をそのまま ~/.config/wezterm/matugen-colors.lua へコピー
        (wezterm は colors.lua と同一内容の11キーをそのまま使う)
```

### Mac (AeroSpace)

WSL版の簡略版。YASB/komorebi/ロック画面などWindows固有部分を持たず、
壁紙決定〜配色反映を1本の `matugen-apply` (mac) にまとめている。実体は
`modules/theming/matugen/mac/`。

```
壁紙変更 (ctrl-cmd-w のポップアップピッカー、または手動でSystem Settings)
  → matugen-apply [壁紙パス | 省略時はSystem Events経由で現在の壁紙を自動検出]
     1. matugen image <壁紙> -c ~/.config/matugen-mac/config.toml
        → テンプレート palette.css (WSL版と同じCSS変数構成) から
          ~/.cache/matugen/mac-palette.css を生成 (matugenが作るのはこの1枚だけ)
     2. WSL版と同じ抽出→派生色計算→レンダリングをそのまま行う:
        - CSS変数からMaterial roleを抽出し一時colors.luaを組み立てる
        - derive-colors.py (共通lib) でcomplement/triad/accent_pale/selection_bgを追記
        - render-template.sh (共通lib) でstarship/lazygit/cz.toml/yazi theme.toml/
          eza/theme.yml/atuin-theme.toml/btop.themeをレンダリング
        - tealdeer-config.py / fzf-colors.sh もWSL版と同じ
     3. colors.lua を ~/.config/wezterm/matugen-colors.lua と
        ~/.cache/matugen/colors.lua へコピー
     4. aerospace-launch-borders (modules/apps/aerospace/launch-borders.sh) を呼び、
        AeroSpace(JankyBorders)の枠色(accent/muted)を反映する
```

- 壁紙変更の入口は2つ:
  - `ctrl-cmd-w` → `wallpaper-pick-popup.sh` がローカルHTTPサーバ
    (`wallpaper-pick-gui.py`) を起動し、Vivaldiのapp-modeウィンドウで
    `~/Pictures/Wallpapers` のサムネイルグリッドをポップアップ表示する。
    クリックすると壁紙変更(`osascript`でSystem Eventsに設定)→`matugen-apply`が
    即座に走り、完了後サーバは自動終了する。
  - `wallpaper-pick` (fzfのターミナル版。WSL `wallpaper-pick.sh` と同系統) も
    引き続き使える。プレビューは `chafa --format symbols` (WezTerm imgcatは
    fzfの再描画でエスケープシーケンスが崩れるため不採用)。見た目は
    `modules/shell/zsh/functions.zsh` と同じ `FZF_DEFAULT_OPTS` を読む。
- `home-manager switch` (`darwin-rebuild switch`) のたびに、`home.activation`
  フックがその時点の壁紙で自動的に一度 `matugen-apply` を実行する
  (初回・Automation許可待ちなどで失敗してもビルド自体は止めない)。
- AeroSpaceの枠色 (`launch-borders.sh`) は **`borders` を都度 `pkill` して
  再起動しない**。`borders` は起動中に同じコマンドを再実行するとIPC経由で
  設定を生きたまま更新する仕様のため、`pkill`すると次のインスタンスが
  上がるまでの一瞬、枠ハイライトが消える。`pgrep -x borders` で起動有無を
  判定し、起動中ならそのまま同じコマンドを再実行するだけにしている。
- macOSの `sed` (BSD sed) は `\s` などGNU拡張の正規表現クラスを解釈できず、
  `render-template.sh` の色抽出が黙って失敗する(プレースホルダが残ったまま
  になる)不具合があったため、共通ライブラリ側を `[[:space:]]` (POSIX標準)に
  書き換えて解消した。WSL/NixOS側もこの変更の影響を受けるが、GNU
  sedでも`[[:space:]]`は等価に動くため挙動は変わらない。

### 共通モジュール `modules/theming/matugen/`

派生色計算 (`lib/derive-colors.py`) とテンプレート後処理
(`lib/render-template.sh`、汎用の `@@KEY@@` 置換エンジン) を1箇所にまとめた
WM非依存のモジュール。`profiles/base.nix` から全ホスト共通で import され、
`~/.config/matugen-common/{lib,templates}` に mkOutOfStoreSymlink 配置される
(python3 の依存もこのモジュール自身が `home.packages` で宣言する)。

- 対象は「`@@プレースホルダ@@` + 色相回転/白ブレンドの派生色」が両方必要な
  生成物: yazi theme.toml、lazygit-theme.yml、starship.toml の
  `palettes.matugen` ブロック、wezterm の配色パレット (colors.lua をそのまま
  流用)。fzf は Material role の参照だけで完結するため matugen 本体の
  テンプレート機能のまま (対象外)。
- 以前あった `accent_pale` 定義差 (WSL: 白40%ブレンド / NixOS: Material
  `primary_container`) と wezterm パレットのキー数差 (WSL 11キー / NixOS
  7キー) は、この共通化で解消済み。両OSとも `accent_pale` は白ブレンド式、
  wezterm は colors.lua と同一の11キーになった。
- **NixOS (`wppicker.sh`) と WSL/Mac (`matugen-apply.sh`) がこの共通
  モジュールを呼ぶ。** WSL/Mac はパレット抽出元 (`yasb-palette.css`/`mac-palette.css` の CSS変数)
  が colors.lua と形式が違うため、抽出後に一時 colors.lua を組み立てて
  `derive-colors.py` に渡す一手間がある (NixOS は matugen が直接 colors.lua
  を生成するため不要)。lazygit/yazi の生成は両OSとも `render-template.sh`
  経由で完全に同じ。starship も共通テンプレート
  `modules/theming/matugen/templates/starship.toml` を両OSが
  `render-template.sh` でレンダリングする方式に統一済み (次項)。
- 新しいアプリを同様の「色相回転＋テンプレート」で追従させたいときは、
  `modules/theming/matugen/templates/`（または既存アプリのテンプレート）
  にプレースホルダ版を用意し、`wppicker.sh` と `matugen-apply.sh` の両方
  から `render-template.sh` を1行呼べばよい。

### starship.toml の2ファイル構成 (フォールバック + テンプレート)

starship には役割の異なる2ファイルがある:

- `modules/shell/starship/starship.toml` — 全ホスト共通の**静的フォールバック**。
  最後に `bake-fallbacks.sh` を実行した時点の壁紙色が入っており、matugen 未実行
  環境でも壊れず動く (`~/.cache/matugen/starship.toml` が無ければ zsh がこれを
  直接使う。`modules/shell/zsh/functions.zsh` 参照)。
- `modules/theming/matugen/templates/starship.toml` — 両OS共通の**生成テンプレート**。
  `palettes.matugen` ブロックだけが `@@プレースホルダ@@` で、壁紙変更のたびに
  `render-template.sh` が `~/.cache/matugen/starship.toml` を生成する
  (NixOS は `wppicker.sh`、WSL は `matugen-apply.sh` から呼ぶ)。

`@@プレースホルダ@@` 化するとフォールバックとして壊れるため、この2ファイルは
統合できない。プロンプト構成 (`format` やセグメント定義) を変えるときは
**両方を同じ内容に保つ**こと (差分は `palettes.matugen` ブロックのみ)。

### フォールバックの一括更新 (`bake-fallbacks.sh`)

各アプリのフォールバック値 (matugenキャッシュが無い環境で使われる、リポジトリに
commit された配色) は、壁紙を変えるたびに手動で1ファイルずつ書き換えていると
漏れが出やすい。`modules/theming/matugen/bake-fallbacks.sh` は
`~/.cache/matugen/colors.lua` (+ WSLでは `yasb-palette.css`) を読み、
既知の全フォールバック箇所へ一括反映する。

```
# 1. 普段通り壁紙を変更する (matugen-apply が実行され、キャッシュが更新される)
# 2. リポジトリルートで実行:
./modules/theming/matugen/bake-fallbacks.sh
# 3. git diff で見た目を確認して commit
```

対象ファイル (2026-07時点):

- `modules/apps/neovim/nvim/lua/matugen.lua` / `modules/apps/wezterm/wezterm.lua` /
  `modules/apps/yazi/init.lua` — 12キー共通パレット
- `modules/shell/starship/starship.toml` (`palettes.matugen` ブロック)
- `modules/theming/matugen/fallbacks/{atuin-theme.toml,btop.theme}`
- `modules/apps/eza/theme.yml` / `modules/apps/lazygit/default.nix` /
  `modules/apps/git-hooks/cz.toml`
- `modules/wm/komorebi/komorebi.json` (枠色) / `modules/wm/yasb/{styles.css,config.yaml}`
  (YASBパネル全体 + cavaグラデーション)
- `modules/shell/zsh/functions.zsh` (`FZF_DEFAULT_OPTS`) /
  `profiles/base.nix` (tealdeerのRGB値)
- `modules/theming/matugen/wsl/matugen-apply.sh` (色相回転計算が失敗した
  ときのセーフティネット値)

新しいアプリのフォールバックを追加したときは、対応する `bake_*` 関数も
このスクリプトに追加すること (role→変数名の対応は `matugen-apply.sh` の
各セクションと揃える)。なお `modules/apps/yazi/theme-template.toml` は
フォールバックではなく**レンダリング元テンプレート**そのものなので対象外
(生の色コードが混入していないかだけ `bake_yazi_template` が検査する)。

Hyprland側 (`modules/wm/hyprland/`) のwaybar/hyprlockフォールバックと、
Mac側 (`modules/apps/aerospace/launch-borders.sh` のAeroSpace枠色フォールバック)
は、このスクリプトの対象に**まだ入っていない** (WSLとは別ホスト・別壁紙のため、
そのホスト上で実行して確認する必要がある)。

### 3経路の違いまとめ

| | WSL | Mac | NixOS |
| :--- | :--- | :--- | :--- |
| matugen の役割 | palette.css を1枚生成するだけ | mac-palette.css を1枚生成するだけ | 全テンプレート生成 + post_hook |
| パレット抽出 | palette.css の CSS変数から | mac-palette.css の CSS変数から (WSLと同じ変数名) | matugen が colors.lua を直接生成 |
| 色相回転・プレースホルダ後処理 (yazi/lazygit) | `modules/theming/matugen/lib/` (共通) | `modules/theming/matugen/lib/` (共通) | `modules/theming/matugen/lib/` (共通) |
| starship 生成方式 | render-template.sh (共通テンプレート) | render-template.sh (共通テンプレート) | render-template.sh (共通テンプレート) |
| 壁紙変更の入口 | YASBウィジェット / ALT+W (fzf) | `ctrl-cmd-w` (Vivaldiポップアップ) / `wallpaper-pick` (fzf) | rofi (`wppicker.sh`) |
| WM枠色の反映方式 | komorebi.json を sed → 同期 reload | `borders` へ同じコマンドを再実行 (IPCで生きたまま更新) | hyprland の post_hook |
| 反映先が Windows | あり (/mnt/c へ配置 + sed) | なし | なし |

新しいアプリを追従させたいときは、Material role の参照だけで足りるなら
WSL/Mac は matugen-apply.sh に palette.css からの抽出を足し、NixOS は
`config.toml` にネイティブ `[templates.x]` を足すだけでよい。色相回転が
必要なら、いずれのOSも `modules/theming/matugen/` にテンプレートを足し、
それぞれのスクリプトから `render-template.sh` を呼べばよい。
