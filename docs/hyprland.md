# Hyprland キーバインド・操作詳細 (Hyprland Workflows)

このドキュメントは、NixOS環境で使用する **Hyprland** Waylandコンポジタのキーバインドとワークフローに関する詳細設定を解説します。

Kanataキーリマップ（Alt長押しでSuperキーへ変換）と連携し、物理 `Alt` キーを起点として快適なハッカー向けウィンドウマネージャー操作を実現しています。実体は [`modules/wm/hyprland/config/hypr/configs/keybinds.conf`](../modules/wm/hyprland/config/hypr/configs/keybinds.conf)（`$mainMod` = `SUPER`）です。

**注意**: Kanataが送信する信号自体 (`Super+X`) は [kanata.md](kanata.md) と共通ですが、Hyprland側でそのSuperキーに何を割り当てるかは各バインド定義に依存し、経緯上ずれているキーがあります (コメントに `moved from ...` とある箇所)。ここでは実際の`keybinds.conf`の内容を正としています。

---

## 1. アプリケーションの起動と管理 (App Launchers)

起動系キーは3ホスト共通で「アプリ名の頭文字」に統一しています (`N`=Neovim, `Y`=Yazi, `V`=Vivaldi)．[kanata.md](kanata.md)参照．

| 操作内容 | ショートカットキー | 内部で送信されるキー |
| :--- | :--- | :--- |
| **アプリランチャー (Rofi) 起動** | `Alt` + `Space` または `Alt` + `D` | `SUPER` + `D` |
| **ターミナル (WezTerm) 起動** | `Alt` + `Enter` | `SUPER` + `Return` |
| **ターミナル (WezTerm，フロート800x550) 起動** | `Alt` + `Shift` + `Enter` (※物理キー) | `SUPER` + `SHIFT` + `Return` |
| **ファイルマネージャー (Yazi，WezTerm内) 起動** | `Alt` + `Y` | `SUPER` + `Y` |
| **Neovim (WezTerm内) 起動** | `Alt` + `N` | `SUPER` + `N` |
| **デフォルトブラウザ (Vivaldi) 起動** | `Alt` + `V` | `SUPER` + `V` |
| **ウィンドウ一覧切り替え (Rofi Window Switcher)** | `Alt` + `Tab` | `SUPER` + `Tab` |

---

## 2. ウィンドウ操作 (Window Management)

| 操作内容 | ショートカットキー | 内部で送信されるキー |
| :--- | :--- | :--- |
| **フォーカス移動** (左 / 下 / 上 / 右) | `Alt` + `H` / `J` / `K` / `L` | `SUPER` + `H/J/K/L` |
| **ウィンドウ位置入れ替え** | `Alt` + `Shift` + `H` / `J` / `K` / `L` | `SUPER` + `SHIFT` + `H/J/K/L` |
| **ウィンドウのリサイズ** (幅小 / 高大 / 高小 / 幅大) | `Alt` + `U` / `I` / `O` / `P` | `SUPER` + `U/I/O/P` |
| **フローティング (浮動表示) 切り替え** | `Alt` + `D` (物理キー) または `Alt` + `Shift` + `Space` | `SUPER` + `T` / `SHIFT+Space` |
| **フルスクリーン表示切り替え** | `Alt` + `F` | `SUPER` + `F` |
| **ウィンドウ分割方向の切り替え** | `Alt` + `Shift` + `T` | `SUPER` + `SHIFT` + `T` |
| **アクティブウィンドウを閉じる** | `Alt` + `Q` | `SUPER` + `SHIFT` + `W` |
| **ウィンドウの最小化 (トグル)** | `Alt` + `M` | `SUPER` + `M` |
| **最小化ウィンドウの表示切り替え (Scratchpad)** | `Alt` + `Shift` + `M` | `SUPER` + `SHIFT` + `M` |

---

## 3. ワークスペースの移動 (Workspace Navigation)

| 操作内容 | ショートカットキー | 内部で送信されるキー |
| :--- | :--- | :--- |
| **ワークスペースの直接ジャンプ** | `Alt` + `1` 〜 `9` | `SUPER` + `1` 〜 `9` |
| **ウィンドウを別ワークスペースへ移動** | `Alt` + `Shift` + `1` 〜 `9` | `SUPER` + `SHIFT` + `1` 〜 `9` |
| **次のワークスペースへ移動** | `Alt` + `S` | `SUPER` + `S` |
| **前のワークスペースへ移動** | `Alt` + `A` | `SUPER` + `A` |
| **直前まで表示していたワークスペースに戻る** | `Alt` + <code>`</code> (半角/全角キー付近) | `SUPER` + <code>`</code> |
| **マウスホイールでワークスペース切り替え** | `Super` + スクロール (※物理キー操作) | — |

---

## 4. 便利機能とシステムコントロール (Utilities)

* **壁紙チェンジャーの起動**:
  - `Alt` + `W` (`SUPER` + `W`)
  - 起動すると画面中央に壁紙候補の一覧（画像プレビュー付き）がRofiで表示されます。選択すると自動的に壁紙が切り替わり、さらに **`matugen` がその壁紙に合わせた配色をシステム（WaybarやSwayNCなど）全体に動的に適用**します。
* **画面キャプチャ (スクリーンショット)**:
  - `Alt` + `Shift` + `S` (`SUPER` + `SHIFT` + `S`)
* **画面の色抽出 (カラーピッカー)**:
  - `Alt` + `C` (`SUPER` + `C`) で `hyprpicker` を起動。
* **Waybarの再起動**:
  - `Alt` + `R` (`SUPER` + `R`)
* **Waybarスタイルメニュー**:
  - `Super` + `Ctrl` + `B` (※物理キー操作)
* **Waybarレイアウトメニュー**:
  - `Super` + `Alt` + `B` (※物理キー操作)
* **Waybarの表示 / 非表示切り替え**:
  - `Super` + `Ctrl` + `H` (※物理キー操作。以前は `Super` + `H`)
* **画面ロック**:
  - `Super` + `Alt` + `L` (※物理キー操作。以前は `Super` + `L`)
* **ログアウト / 電源メニュー起動**:
  - `Ctrl` + `Alt` + `Delete` (Hyprlandセッションの終了)

---

## 現在使われていないキー

`Alt` + `B` (`SUPER` + `B`) はKanata側の`hyp-b`エイリアスとしては存在しますが，Hyprland側の対応するバインドが無く，押しても何も起こりません．NixOS/macOS/WSLの3ホストで共通して未使用に統一しています (経緯は[kanata.md](kanata.md)参照)．WSL側で同等機能 (レイアウト反転) が必要な場合は`Alt`+`Shift`+`B`を使ってください．

なお `Alt` + `D` (物理キー，`SUPER` + `T`) は上表の「フローティング切替」で実際に機能しますが，同じ操作は`Alt`+`Shift`+`Space`でも行えるため，こちらを主に使う必要はありません．

---

## 関連ファイル

| ファイル | 役割 |
| :--- | :--- |
| `modules/wm/hyprland/config/hypr/configs/keybinds.conf` | キーバインド本体 (このドキュメントの一次情報源) |
| `modules/wm/hyprland/config/hypr/hyprland.conf` | `$terminal`/`$menu`等の変数定義 |
| `modules/wm/hyprland/config/hypr/scripts/wppicker.sh` | 壁紙ピッカー・Matugen配色反映スクリプト |
| `modules/wm/hyprland/config/waybar/` | Waybar (ステータスバー) 設定 |
