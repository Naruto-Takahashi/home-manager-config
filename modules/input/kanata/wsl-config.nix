# =========================================================================
# Kanata Windows (WSLホスト) 用設定テキスト (プレースホルダ置換済み)
# =========================================================================
# config.kbd はプレースホルダー (cap-ctrl-action / wmmodifier- / eisu / kana)
# を含むテンプレート。Windowsでは以下に置換して使う:
#   1. cap-ctrl-action -> lctl (Windowsは素のCtrlでよい。macOSのような
#      copy/paste転写レイヤーは元々不要)
#   2. wmmodifier- -> A- (素のAlt)。これによりkanataのAlt長押しレイヤーが
#      komorebi.ahk側の既存 `!` (Alt) ホットキー群とまったく同じ信号
#      (物理Alt+文字と区別のつかないAlt+文字) を送出するため、
#      komorebi.ahkは一切変更不要で動く
#   3. eisu/kana -> ime-off/ime-on (macOS専用の仮想キーの代わりに、
#      Win32 API (ImmSetOpenStatus) 経由のIME制御が必要。kanata単体では
#      Windows上でこれを直接行えないため、既存の動作実績があるAHKの
#      ime_functions.ahkへ `cmd` アクションで委譲する)
#
# home-manager (modules/input/kanata/wsl.nix) がこのテキストをWindows側へ
# 配置する。sync-win/matugen-apply等と同じくAHK側 (modules/input/ahk/) の
# ime-off.ahk / ime-on.ahk を直接呼び出す。
let
  base = builtins.readFile ./config.kbd;

  replaced = builtins.replaceStrings
    [
      # wmmodifier-A-h 等 (alt-ctrl-layer用、Super+Alt+Hを意味する) は、
      # Windowsでは wmmodifier 自体がAltなので単純展開すると "A-A-h" という
      # 不正な二重修飾子表記になってしまう。Windows(AHK)側はこの
      # alt-ctrl-layer機能を元々実装していない (docs/kanata.md 参照)ため、
      # 素直にCtrl+Alt+Hとして解釈しておく (無害・構文的に正しい・将来
      # AHK側に対応するホットキーを足す余地も残る)。より具体的なパターンを
      # 汎用の "wmmodifier-" 置換より前に置くことで先にマッチさせる
      "wmmodifier-A-h"
      "wmmodifier-A-j"
      "wmmodifier-A-k"
      "wmmodifier-A-l"
      # hyp-tab (Alt+Tab) だけは下記コメントの理由でAHKへのcmd委譲に
      # 変えたいため、汎用の "wmmodifier-" 置換より前に置いて先にマッチさせる
      "wmmodifier-tab"
      "cap-ctrl-action"
      "wmmodifier-"
      "eisu"
      "kana"
      "process-unmapped-keys yes"
      # 本機はレジストリのScancode MapでCapsLock物理キーをF13として送出する
      # 設定にしている (main.ahkの `*F13::` コメント参照)。そのためkanataの
      # defsrcも "caps" ではなく "f13" を監視しないと物理CapsLockを一切
      # 検知できない。config.kbd内で "caps" はdefsrc行にのみ1箇所しか
      # 出現しないため単純な文字列置換で安全に対応できる
      "caps  lalt"
      # alt-layer中のspc位置 (@hyp-d = Super+D相当) をそのまま素直に
      # wmmodifier-d (= A-d) へ展開すると、Alt+SpaceがAlt+Dに化けてしまい
      # PowerToys Command Palette (Alt+Space) が起動できなくなる。
      # macOS向け (hosts/mac/default.nix) と同じく、この1箇所だけ
      # 素のAlt+Spaceパススルーに直接上書きする
      "@hyp-d "
    ]
    [
      "C-A-h"
      "C-A-j"
      "C-A-k"
      "C-A-l"
      "@alt-tab-step"
      "lctl"
      "A-"
      "@ime-off"
      "@ime-on"
      "process-unmapped-keys yes\n  danger-enable-cmd yes"
      "f13   lalt"
      "A-spc "
    ]
    base;

  # AHK側の一発実行スクリプト (modules/input/ahk/ime-off.ahk, ime-on.ahk) を
  # cmdアクションで呼び出すためのdefalias。defaliasはconfig.kbd中に複数
  # ブロックがあっても構わない仕様 (kanata公式ドキュメント参照) だが、
  # エイリアスは「参照より前に定義」されている必要がある (実機の
  # `kanata --check` で検証済み) ため、@ime-off/@ime-on を使う既存の
  # defaliasブロックより前に来るよう先頭に配置する
  imeDelegation = ''
    ;; IME制御 (Windows専用委譲): Win32 API呼び出しが必要なため、
    ;; 実績のあるAHKのime_functions.ahk (ime-off.ahk/ime-on.ahk) へ委譲する
    (defalias
      ime-off (cmd "C:/Program Files/AutoHotkey/v1.1.37.02/AutoHotkeyU64.exe" "C:/Users/tnaru/Tools/Customization/ime-off.ahk")
      ime-on  (cmd "C:/Program Files/AutoHotkey/v1.1.37.02/AutoHotkeyU64.exe" "C:/Users/tnaru/Tools/Customization/ime-on.ahk")
      ;; alt-layer中のhyp-tab (Alt+Tab) 用。kanataの仮想キー出力は
      ;; 実際にはOSレベルでAltキーが押されている状態を再現できず
      ;; (GetAsyncKeyStateで検出不可なことを実機で確認済み)、Windows標準の
      ;; Alt+Tabウィンドウ切り替え (Alt保持中はTab連打で選択、Alt解放で
      ;; 確定) が一瞬で閉じてしまう不具合になっていた。実際にAltキーを
      ;; 保持できるAHK側 (alt-tab-step.ahk) へ委譲する
      alt-tab-step (cmd "C:/Program Files/AutoHotkey/v1.1.37.02/AutoHotkeyU64.exe" "C:/Users/tnaru/Tools/Customization/alt-tab-step.ahk")
    )

  '';
in
imeDelegation + replaced
