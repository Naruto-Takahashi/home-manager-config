# komorebi ウィンドウマネージャ キーバインド一覧

Windows環境のタイル型ウィンドウマネージャ **komorebi** の操作チートシートです．
キーバインドは AutoHotkey (`modules/wm/komorebi/komorebi.ahk`) で定義され，`sync-win` で Windows 側 (`C:\Users\tnaru\.config\komorebi\`) に同期されます．
起動するAHKプロセスは `modules/input/ahk/main.ahk` (IME制御等，[kanata.md](kanata.md) 参照) 1つに集約されており，`komorebi.ahk` はそこから絶対パスで `#Include` されます．
**AHK スクリプトの変更はタスクトレイの AutoHotkey アイコン → Reload This Script で再読み込みが必要です (main.ahkとkomorebi.ahkどちらを直しても，リロードするのはmain.ahk側のプロセスです)．**

配色 (枠線色など) は Matugen 連携で壁紙から自動生成されます ([matugen-palette.md](matugen-palette.md) 参照)．

---

## キーバインド

### 1. フォーカス・ウィンドウ移動 (Vim 風)

| キーバインド | 動作 | 覚え方 |
| :--- | :--- | :--- |
| **`Alt + H / J / K / L`** | 左 / 下 / 上 / 右 のウィンドウへフォーカス移動 | Vim のカーソル移動 |
| **`Alt + Shift + H / J / K / L`** | ウィンドウを 左 / 下 / 上 / 右 へ移動 (スワップ) | Vim + Shift |

### 2. リサイズ

| キーバインド | 動作 | 覚え方 |
| :--- | :--- | :--- |
| **`Alt + U`** | 横幅を縮小 | GlazeWM 時代のキー配置を踏襲 |
| **`Alt + P`** | 横幅を拡大 | 〃 |
| **`Alt + O`** | 縦幅を拡大 | 〃 |
| **`Alt + I`** | 縦幅を縮小 | 〃 |

### 3. ウィンドウ・レイアウト操作

| キーバインド | 動作 | 覚え方 |
| :--- | :--- | :--- |
| **`Alt + F`** | モノクル (単一ウィンドウ最大化) 切り替え | **F**ullscreen |
| **`Alt + M`** | 最小化 | **M**inimize |
| **`Alt + T`** | タイリング ON/OFF | **T**iling |
| **`Alt + Shift + T`** | レイアウトを巡回 (BSP → Columns → …) | **T**iling の仲間 |
| **`Alt + B`** | レイアウトの縦横反転 (flip) | (歴史的経緯・意味なし) |
| **`Alt + R`** | 再タイル (整列し直し) | **R**etile |
| **`Alt + Shift + Q`** / **`Alt + Shift + W`** | ウィンドウを閉じる | **Q**uit |

> [!TIP]
> BSP レイアウトは「フォーカス中ウィンドウの長い辺」を分割するため，2枚目が上下配置になることがあります．
> その場で直すなら **`Alt + B`** (反転)，レイアウトごと左右型 (VerticalStack / Columns) に変えるなら **`Alt + Shift + T`** を使います．

### 4. トラブル復旧

| キーバインド | 動作 | 覚え方 |
| :--- | :--- | :--- |
| **`Alt + Shift + R`** | フォーカス中のウィンドウを再登録 (`komorebic manage`)．追跡から外れたウィンドウの復旧に | **R**ecover |
| **`Alt + Shift + D`** | ディスプレイ構成の再適用 + YASB 再構築．モニタ抜き差しで表示が崩れたときに (ケーブル抜き差し時は自動実行) | **D**isplay |

### 5. ワークスペース

| キーバインド | 動作 | 覚え方 |
| :--- | :--- | :--- |
| **`Alt + A`** / **`Alt + S`** | 前 / 次のワークスペースへ巡回 | 隣接キーで左右 |
| **`Alt + 1〜5`** | モニタ0 のワークスペース 1〜5 へジャンプ | 番号 |
| **`Alt + 6〜9`** | モニタ1 のワークスペース 6〜9 へジャンプ | 番号 |
| **`Alt + Shift + 1〜9`** | ウィンドウを指定ワークスペースへ移動 (フォーカス追従) | 番号 + Shift |
| **`Alt + Shift + A`** | 表示中ワークスペースをモニタ0 へ移動 | (位置的な割り当て) |
| **`Alt + Shift + F`** | 表示中ワークスペースをモニタ1 へ移動 | 〃 |

### 6. アプリ起動

| キーバインド | 動作 | 覚え方 |
| :--- | :--- | :--- |
| **`Alt + Enter`** | WezTerm を起動 (Excel アクティブ時は無効) | ターミナル定番 |
| **`Alt + Y`** | WezTerm 上で yazi を起動 | **Y**azi |
| **`Alt + V`** | Vivaldi を起動 | **V**ivaldi |

---

## 関連ファイル

| ファイル | 役割 |
| :--- | :--- |
| `modules/wm/komorebi/komorebi.ahk` | キーバインド定義 (AutoHotkey v1) |
| `modules/wm/komorebi/komorebi.json` | komorebi 本体設定 (ワークスペース・枠線・ignore ルール) |
| `modules/wm/komorebi/applications.json` | アプリ別の追跡ルール (Office のスプラッシュ無視など) |
| `modules/wm/komorebi/startup.ps1` | Windows ログオン時の起動スクリプト |
