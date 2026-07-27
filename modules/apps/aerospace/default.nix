# =========================================================================
# AeroSpace タイリングウィンドウマネージャ宣言的設定モジュール
# =========================================================================
# キーバインドを変更したら docs/aerospace.md も直すこと
# (このファイルから自動生成されるドキュメントではないため乖離に注意)。
{ config, pkgs, dotfilesPath, ... }:

{
  # borders起動スクリプト。matugenパレット(~/.cache/matugen/colors.lua)の
  # accent/mutedがあればそれを使い、無ければ青ベースのフォールバックを使う。
  home.file.".local/bin/aerospace-launch-borders" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/modules/apps/aerospace/launch-borders.sh";
  };

  # AeroSpace自身の`start-at-login`はmacOSのログインアイテムとして働くため、
  # ログインセッションが完全に立ち上がる前に起動してしまうことがある。
  # その場合カスタム設定(キーバインド・gaps等)を読み込めずデフォルト値
  # (ギャップ0・独自バインド無し)のまま起動してしまい、加えて
  # after-startup-command (borders起動) も取りこぼされる。
  # after-startup-commandはAeroSpace自身の起動時に一度しか実行されず
  # reload-configでは再実行されないため、borders起動はここで明示的に
  # 行う必要がある。ログイン後に少し待ってから両方を確実に行う。
  launchd.agents.aerospace-reload-config = {
    enable = true;
    config = {
      ProgramArguments = [
        "/bin/sh"
        "-c"
        "sleep 20 && /opt/homebrew/bin/aerospace reload-config && $HOME/.local/bin/aerospace-launch-borders"
      ];
      RunAtLoad = true;
      StandardOutPath = "/tmp/aerospace-reload-config.out.log";
      StandardErrorPath = "/tmp/aerospace-reload-config.err.log";
    };
  };

  # --- AeroSpace設定 ---
  # aerospace.toml設定ファイルの宣言的な自動生成を行います．
  xdg.configFile."aerospace/aerospace.toml".text = ''
    # AeroSpace Configuration

    # ログイン時に起動します．
    start-at-login = true

    # デフォルトのレイアウトをアコーディオンではなく「タイル型 (tiles)」にします．
    default-root-container-layout = 'tiles'
    default-root-container-orientation = 'auto'

    # マウスカーソルが乗ったウィンドウに自動でフォーカスを移します（focus follows mouse）．
    focus-follows-mouse.enabled = true

    # キーボード操作等でフォーカスが変わった際は，逆にマウスカーソルの方をフォーカスウィンドウの中央へ追従させます．
    on-focus-changed = ['move-mouse window-lazy-center']

    # AeroSpace起動完了時にJankyBorders（アクティブウィンドウ枠線表示ツール）をバックグラウンド実行します．
    # 色はmatugenパレット(~/.cache/matugen/colors.lua)のaccent/mutedに追従します
    # (未生成時はWSL/NixOS側と同じ青ベースのフォールバック値を使います)．
    # 参考: modules/theming/matugen/mac/matugen-apply.sh, modules/apps/aerospace/launch-borders.sh
    after-startup-command = [
      'exec-and-forget /Users/nalt/.local/bin/aerospace-launch-borders'
    ]

    # 壁紙ピッカー(wallpaper-pick-popup.sh)のVivaldiアプリモードウィンドウは
    # ポップアップとして使いたいのでタイル化させずフローティング表示にします．
    # タイトルで判定するため他のVivaldiウィンドウには影響しません．
    on-window-detected = [
      { if = 'test %{window-title} ~= "wallpaper picker"', run = 'layout floating' }
    ]

    # ギャップ設定（Gaps）
    [gaps]
    inner.horizontal = 10
    inner.vertical = 10
    outer.left = 8
    outer.bottom = 8
    outer.top = 4
    outer.right = 8

    # キーバインド設定（Main Mode）
    # macOS標準および一般コピペ（Cmd）と衝突させないため，すべての操作プレフィックスに Ctrl+Cmd (ctrl-cmd) を使用します．
    [mode.main.binding]
    # ウィンドウ間のフォーカス移動（Alt + HJKL）
    ctrl-cmd-h = 'focus left'
    ctrl-cmd-j = 'focus down'
    ctrl-cmd-k = 'focus up'
    ctrl-cmd-l = 'focus right'

    # ウィンドウの移動（Alt + Shift + HJKL）
    ctrl-cmd-shift-h = 'move left'
    ctrl-cmd-shift-j = 'move down'
    ctrl-cmd-shift-k = 'move up'
    ctrl-cmd-shift-l = 'move right'

    # ウィンドウサイズの簡易調整（Alt + UIPO）
    ctrl-cmd-u = 'resize width -50'
    ctrl-cmd-p = 'resize width +50'
    ctrl-cmd-o = 'resize height +50'
    ctrl-cmd-i = 'resize height -50'

    # リサイズモードへの移行（Alt + R）
    ctrl-cmd-r = 'mode resize'

    # ウィンドウ分割方向の切り替え（Alt + V）
    ctrl-cmd-v = 'layout tiles horizontal vertical'

    # フローティング/タイリングの切り替え（Alt + Shift + Space）
    ctrl-cmd-shift-space = 'layout floating tiling'

    # フルスクリーン表示の切り替え（Alt + F）
    ctrl-cmd-f = 'fullscreen'

    # ウィンドウの最小化（Alt + M）
    ctrl-cmd-m = 'macos-native-minimize'

    # ウィンドウを閉じる（Alt + Q が Ctrl+Cmd+Shift+W を送信します）．
    ctrl-cmd-shift-w = 'close'

    # 設定ファイルの再読み込みを行います．
    ctrl-cmd-shift-r = 'reload-config'

    # ワークスペース間のフォーカス移動（Alt + S / Alt + A が ctrl-cmd-s / ctrl-cmd-a を送信します）．
    ctrl-cmd-s = 'workspace next'
    ctrl-cmd-a = 'workspace prev'
    
    # 直近のワークスペースと切り替え（Alt + D が ctrl-cmd-t を送信します）．
    ctrl-cmd-t = 'workspace-back-and-forth'

    # 特定ワークスペースへのダイレクトジャンプ（Alt + 1-9）
    ctrl-cmd-1 = 'workspace 1'
    ctrl-cmd-2 = 'workspace 2'
    ctrl-cmd-3 = 'workspace 3'
    ctrl-cmd-4 = 'workspace 4'
    ctrl-cmd-5 = 'workspace 5'
    ctrl-cmd-6 = 'workspace 6'
    ctrl-cmd-7 = 'workspace 7'
    ctrl-cmd-8 = 'workspace 8'
    ctrl-cmd-9 = 'workspace 9'

    # フォーカスウィンドウを別ワークスペースへ移動し，フォーカスも追従させます（Alt + Shift + 1-9）．
    ctrl-cmd-shift-1 = ['move-node-to-workspace 1', 'workspace 1']
    ctrl-cmd-shift-2 = ['move-node-to-workspace 2', 'workspace 2']
    ctrl-cmd-shift-3 = ['move-node-to-workspace 3', 'workspace 3']
    ctrl-cmd-shift-4 = ['move-node-to-workspace 4', 'workspace 4']
    ctrl-cmd-shift-5 = ['move-node-to-workspace 5', 'workspace 5']
    ctrl-cmd-shift-6 = ['move-node-to-workspace 6', 'workspace 6']
    ctrl-cmd-shift-7 = ['move-node-to-workspace 7', 'workspace 7']
    ctrl-cmd-shift-8 = ['move-node-to-workspace 8', 'workspace 8']
    ctrl-cmd-shift-9 = ['move-node-to-workspace 9', 'workspace 9']

    # アプリケーションのクイック起動を行います．
    ctrl-cmd-enter = 'exec-and-forget open -n -a WezTerm'
    ctrl-cmd-y = 'exec-and-forget /etc/profiles/per-user/nalt/bin/wezterm start /etc/profiles/per-user/nalt/bin/yazi'
    ctrl-cmd-n = 'exec-and-forget /etc/profiles/per-user/nalt/bin/wezterm start /etc/profiles/per-user/nalt/bin/nvim'
    ctrl-cmd-b = 'exec-and-forget open -n -a Vivaldi'
    ctrl-cmd-w = 'exec-and-forget /Users/nalt/.local/bin/wallpaper-pick-popup'

    # ウィンドウの結合（Alt + Ctrl + HJKL）
    ctrl-cmd-alt-h = 'join-with left'
    ctrl-cmd-alt-j = 'join-with down'
    ctrl-cmd-alt-k = 'join-with up'
    ctrl-cmd-alt-l = 'join-with right'

    # リサイズモードの設定（escapeのかわりにescキーを使用します）．
    [mode.resize.binding]
    h = 'resize width -50'
    l = 'resize width +50'
    k = 'resize height +50'
    j = 'resize height -50'
    esc = 'mode main'
    enter = 'mode main'
  '';
}
