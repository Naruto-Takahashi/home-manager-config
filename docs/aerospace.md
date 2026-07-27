# 🗔 AeroSpace ウィンドウマネージャ キーバインド・設定詳細

**macOS専用**です．[modules/apps/aerospace/default.nix](../modules/apps/aerospace/default.nix) で宣言的に管理されているタイル型ウィンドウマネージャ **AeroSpace** の操作・配色連携・自動化まわりを解説します．NixOSの[Hyprland](hyprland.md)，Windows/WSLの[komorebi](komorebi.md)に相当する役割です．

物理キーは全て `Alt` 長押しですが，Kanataがそれを `Ctrl+Cmd` (`ctrl-cmd-*`) に変換してAeroSpaceへ送っています（macOS標準のCmd単体ショートカットと衝突しないようにするため）．変換の仕組みは [kanata.md](kanata.md) の「対象OS・実装方式の違い」を参照してください．

---

## ⌨️ キーバインド (Main Mode)

すべて `Alt + <キー>` （実際に送信されるのは `Ctrl+Cmd + <キー>`）です．

### フォーカス・ウィンドウ移動

| キー | 動作 |
| :---: | :--- |
| `H` / `J` / `K` / `L` | フォーカスを 左/下/上/右 へ移動 |
| `Shift + H/J/K/L` | フォーカスウィンドウを 左/下/上/右 へ移動 |
| `Ctrl + H/J/K/L` | 隣のウィンドウとコンテナを結合 (`join-with`) |

### サイズ調整

| キー | 動作 |
| :---: | :--- |
| `U` / `P` | 幅を -50 / +50 |
| `O` / `I` | 高さを +50 / -50 |
| `R` | リサイズモードへ移行 (`H/J/K/L`でリサイズ，`Esc`/`Enter`で戻る) |

### レイアウト

| キー | 動作 |
| :---: | :--- |
| `V` | 分割方向をタイル横⇄縦に切り替え |
| `Shift + Space` | フローティング⇄タイリングを切り替え |
| `F` | フルスクリーン切り替え |
| `M` | ウィンドウを最小化 (macOSネイティブ) |
| `Shift + W` | ウィンドウを閉じる |
| `Shift + R` | 設定ファイルの再読み込み (`reload-config`) |

### ワークスペース

| キー | 動作 |
| :---: | :--- |
| `S` / `A` | 次 / 前のワークスペースへ |
| `D` (実送信は `ctrl-cmd-t`) | 直近のワークスペースと切り替え |
| `1`〜`9` | 該当ワークスペースへ直接ジャンプ |
| `Shift + 1`〜`9` | フォーカスウィンドウを該当ワークスペースへ移動しつつ追従 |

### アプリのクイック起動

| キー | 起動するもの |
| :---: | :--- |
| `Enter` | WezTerm (新規ウィンドウ) |
| `Y` | WezTerm内でYazi |
| `N` | WezTerm内でNeovim |
| `B` | Vivaldi |
| `W` | 壁紙ピッカー ([matugen-palette.md](matugen-palette.md#壁紙ファイルの配置場所) 参照) |

---

## 🎨 配色連携 (Matugen) と枠線 (JankyBorders)

アクティブウィンドウの枠線ハイライトは Homebrew の `borders` (JankyBorders) が担当します．色は壁紙から抽出した [Matugen](matugen-palette.md) のパレット (`~/.cache/matugen/colors.lua` の `accent`/`muted`) に自動追従します．

- 起動スクリプトは [`launch-borders.sh`](../modules/apps/aerospace/launch-borders.sh)．**`borders` は起動中に同じコマンドを再実行するとIPC経由で設定を生きたまま更新する仕様**なので，`pkill`して再起動する必要はありません（`pkill`すると次のインスタンスが上がるまでの一瞬，枠ハイライトが消えるため意図的に避けています）．
- matugenキャッシュが無い場合は，WSL/NixOS側と同じ青ベースのフォールバック配色を使います．
- ギャップ (`[gaps]`) は `inner.horizontal/vertical = 10`，`outer.left/bottom/right = 8`，`outer.top = 4`．WSL側komorebiの値 (`default_container_padding=6` / `default_workspace_padding=1`) と揃える案も試しましたが，見た目の好みでMac独自の値に戻しています．

## 🖼️ 壁紙ピッカー

`Alt + W` (`ctrl-cmd-w`) で [`wallpaper-pick-popup.sh`](../modules/theming/matugen/mac/wallpaper-pick-popup.sh) が起動し，Vivaldiのapp-modeウィンドウでサムネイルグリッドのポップアップが開きます．クリックすると即座に壁紙変更とMatugen配色反映（このAeroSpaceの枠線色を含む）が走ります．詳細は [matugen-palette.md](matugen-palette.md) を参照してください．

このポップアップウィンドウはタイル化させず，`on-window-detected` コールバックでフローティング表示に固定しています（ウィンドウタイトル `"wallpaper picker"` で判定，他のVivaldiウィンドウには影響しません）．

```toml
on-window-detected = [
  { if = 'test %{window-title} ~= "wallpaper picker"', run = 'layout floating' }
]
```

## 🔁 ログイン時の自動リカバリ (LaunchAgent)

AeroSpace自身の `start-at-login = true` はmacOSのログインアイテムとして働きますが，**ログインセッションが完全に立ち上がる前に起動してしまうことがあります**．その場合，カスタム設定 (キーバインド・gaps・`on-window-detected`等) を読み込めずAeroSpaceの初期値 (ギャップ0・独自バインド無し) のまま起動してしまい，`after-startup-command` (borders起動) も取りこぼされます．

`after-startup-command` はAeroSpace自身の起動時に一度しか実行されず，`reload-config` では再実行されない仕様のため，取りこぼした場合は手動で気づいて直すしかありませんでした．これを防ぐため，ログイン20秒後に `aerospace reload-config` と `aerospace-launch-borders` の両方を確実に実行するLaunchAgent (`launchd.agents.aerospace-reload-config`) を登録しています．

`darwin-rebuild switch` の直後にすぐ変更を見たい場合（次回ログインを待たない場合）は，手動で以下を実行してください．

```bash
aerospace reload-config
```

## ⚠️ 設定変更時の注意

`aerospace.toml` は `xdg.configFile` でNix管理のファイルとして生成されるため，`darwin-rebuild switch` を実行しないと反映されません．また，ファイルを書き換えただけではAeroSpace自身が読みに行かない（`after-startup-command` は起動時にしか走らない）ため，`darwin-rebuild switch` の後は上記の `aerospace reload-config` を実行するか，次回ログインまで待つ必要があります．
