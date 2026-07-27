# Kanata キーボードリマッパー設定・キーマップ詳細

このドキュメントでは、[modules/input/kanata/config.kbd](../modules/input/kanata/config.kbd) に定義されている Kanata デーモンの独自キーレイヤー設定および IME 統合動作について詳細に解説します。

## 対象OS・実装方式の違い (重要)

**このドキュメントの内容は NixOS・macOS にのみ適用されます。Windows/WSL2環境ではKanataは一切使われません**（WSL上のプロセスはWindows側のキーボード入力を物理的に捕まえられないため）。同等の機能はWindows専用の [AutoHotkeyスクリプト](../modules/input/ahk/main.ahk) が別実装で提供しています（設定は共通ではなく、`main.ahk` 側で個別にメンテナンスされています）。

Kanataを使う2ホストの間でも、レイヤー定義 (`config.kbd`) は共通の1ファイルですが、`wmmodifier-` プレースホルダの実際の変換先がホストごとに異なります（ホスト側の `.nix` ファイルで文字列置換）:

| ホスト | `wmmodifier-` の変換先 | 連携するWM | 備考 |
| :--- | :--- | :--- | :--- |
| **NixOS** | `M-` (Super単体) | Hyprland ([hyprland.md](hyprland.md)) | `modules/input/kanata/kanata-config.nix` |
| **macOS** | `C-M-` (Ctrl+Cmd) | AeroSpace ([aerospace.nix](../modules/apps/aerospace/default.nix)) | macOS標準の`Cmd`単体ショートカットと衝突しないよう二重修飾にしている |

macOSはさらに以下の3点が個別の置換で上書きされています（`hosts/mac/default.nix`）:
- `cap-ctrl-action` → `(layer-toggle ctrl-layer)` (CapsLock長押し時のレイヤー)
- `Alt+Space` (`hyp-d`) → `A-spc` に直接マッピング (wmmodifier経由ではなくmacOS標準のSpotlight的挙動に寄せるため)
- `Alt+Tab` (`hyp-tab`) → `A-tab` に直接マッピング ([Alt-Tab](https://alt-tab-macos.netlify.app/)アプリとの連携用)

下記の「2. 窓操作の最適化」セクションの表は `Super + ...` の**NixOS向けの表記**です。macOSでは同じキー入力が `Ctrl+Cmd + ...` に変換されます。IME切り替え（3節）とSandSナビゲーション（1節）、CapsLock改修（4節）は2ホスト共通です。

---

## 特徴的な独自仕様 (Core Concepts)

Kanata をバックグラウンドサービスとして稼働させることで、**OS依存・WM依存のない、あらゆる環境で完全に統一されたキー体験** を実現します。
特に、**「キーボードのホームポジション（手を置く基本位置）から一切手を動かさない」** ことを極限まで追求したキーマッピング設計になっています。

---

## 1. ホームポジション専用：SandS & Vimナビゲーション (Nav-Layer)

スペースキー長押しによって、キーボードが瞬時に「超高速カーソル操作・テキスト編集レイヤー」へと変貌します（SandS: Space and Shift）。

* **スペース単押し**: 通常通り `スペース` を入力します。
* **スペース長押し (Hold) + 他のキー**: ナビゲーションレイヤーへ移行します。

### スペース長押し中のキーマッピング一覧

| キー | 割り当てられた操作 | 説明 |
| :---: | :---: | :--- |
| **`H`** | **`Left` (←)** | 左に1文字移動 (Vimスタイル) |
| **`J`** | **`Down` (↓)** | 下に1行移動 (Vimスタイル) |
| **`K`** | **`Up` (↑)** | 上に1行移動 (Vimスタイル) |
| **`L`** | **`Right` (→)** | 右に1文字移動 (Vimスタイル) |
| **`A`** | **`Home`** | 行頭（一番左）にジャンプ |
| **`E`** | **`End`** | 行末（一番右）にジャンプ |
| **`U`** | **`Ctrl + Z`** | 直前の操作を取り消す (**Undo / 元に戻す**) |
| **`B`** | **`Backspace`** | 1文字左側を削除する (**バックスペース**) |
| **`X`** | **`Delete`** | 1文字右側（カーソル上）を削除する (**デリート**) |

---

## 2. 窓操作の最適化：Alt長押し連携 (Alt-Layer)

左右の `Alt` キーを長押ししながらアルファベットを押すことで、ウィンドウ操作機能を `Alt` キー単体の修飾で発動させることができます（裏側で自動的に `Super`／macOSでは`Ctrl+Cmd`と組み合わせた信号に変換しています。変換ルールは前述の「対象OS・実装方式の違い」参照）。

* **Alt単押し**: IMEのオン/オフ切り替え（以下参照）。
* **Alt長押し (Hold) + 他のキー**: Altレイヤー（ウィンドウ操作層）へ移行します。

### Alt長押し中のキーマッピング一覧

このレイヤーが送信する**信号自体**は3ホスト共通ですが、その信号にWM側が何を割り当てるかはホストごと・時期によって独立して変わりうるため、**発動するアクションの正はホストごとのドキュメントを見てください**：NixOSは[hyprland.md](hyprland.md)、macOSは[aerospace.md](aerospace.md)、WSLは[komorebi.md](komorebi.md) (WSLはKanataではなくAutoHotkeyの独自実装なので、下表の信号とは無関係にキーが割り当てられています)。

起動系のキー (`N`=Neovim、`Y`=Yazi、`V`=Vivaldi) は3ホストで意味が揃うように統一済みです。`D`と`B`は逆に「無理に意味を揃えない」方針にしており、`B`はどのホストでも未使用，`D`はホストごとに個別の(既存の別キーと重複する)動作のままにしています。

| キー | 実際に送信される信号 |
| :---: | :--- |
| **`SPACE`** | `Super + D` |
| **`T`** | `Super + Shift + Space` |
| **`D`** | `Super + T` |
| **`Return`** | `Super + Enter` |
| **`TAB`** | `Super + Tab` |
| **`Q`** | `Super + Shift + W` |
| **`F`** | `Super + F` |
| **`V`** | `Super + V` |
| **`M`** | `Super + M` |
| **`H / J / K / L`** | `Super + HJKL` |
| **`U / I / O / P`** | `Super + UIOP` |
| **`S / A`** | `Super + S / A` |
| **`[1~9]`** | `Super + [1~9]` |

---

## 3. Mac風・快適日本語入力 (IME Integration)

左右の `Alt` キー単押し（タップ）に、Macと同じ極めて快適な日本語入力切り替え（無変換 / 変換）をバインドしています。

* **左Alt単押し (Tap)**: IMEを **オフ（英語入力）** に変更します。
* **右Alt単押し (Tap)**: IMEを **オン（日本語入力）** に変更します。
* **長押し時 (Hold)**: 上記の `Alt-Layer` ウィンドウ操作ショートカット用の修飾キーとして機能します。

これにより、現在の入力状態を気にすることなく、「日本語を書きたいときは右Altを叩いてから打つ」「英語を書きたいときは左Altを叩いてから打つ」という無意識かつストレスフリーなタイピングが可能です。

---

## 4. CapsLockの徹底改修 (Caps-to-Control)

普段ほとんど使用しないにもかかわらず、Aの横という特等席に配置されている `CapsLock` キーを、最も頻繁に使うキーへと変更します。

* **CapsLock単押し (Tap)**: **`Escape` (エスケープ)** として機能します。
* **CapsLock長押し (Hold)**: **`Left Control`** として機能します。

これによって、Vim などのノーマルモード移行（Escキー）がホームポジションから離れることなく行えるようになり、さらに `Ctrl + C` などのショートカットの入力負荷が劇的に低減します。

---

## 5. Windows専用の補完: AutoHotkey (modules/input/ahk)

kanataはクロスプラットフォームだが，Windowsの一部機能(IMEのオン/オフをWin32 API経由で確実に制御する処理，SandS，WezTermとの連携)はkanataだけでは実現できないため，`modules/input/ahk/main.ahk` をAutoHotkeyの実行ファイルとして併用している。役割としてはkanataと同じ「キーボードリマップ」層に属するため`modules/input/`配下に置いているが，実装はWindows専用。

* エントリポイントは `main.ahk` の1つのみ。komorebi固有のホットキー定義 (`modules/wm/komorebi/komorebi.ahk`、[komorebi.md](komorebi.md) 参照) はここから絶対パスで `#Include` される
* IME制御関数 (`ImmGetDefaultIMEWnd` 等のWin32 API呼び出し) は `modules/input/ahk/lib/ime_functions.ahk` に切り出している
* `sync-win` が `~/.config/ahk` 配下をまるごと Windows の `Tools\Customization\` へコピーする

---

## 関連ファイル

| ファイル | 役割 |
| :--- | :--- |
| `modules/input/kanata/config.kbd` | レイヤー定義本体 (3ホスト共通) |
| `modules/input/kanata/kanata-config.nix` | NixOS向け`wmmodifier-`置換ロジック |
| `hosts/mac/default.nix` | macOS向け`wmmodifier-`/その他置換ロジック |
| `modules/input/ahk/main.ahk` | WSL/Windows向けの別実装 |
