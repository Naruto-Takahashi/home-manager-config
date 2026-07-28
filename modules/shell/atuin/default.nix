# =========================================================================
# atuin (シェル履歴の記録・同期) 宣言的設定モジュール
# =========================================================================
# atuinはシェル履歴の記録・暗号化同期のバックエンドとしてのみ使う。
# 検索UI (Ctrl+R) は atuin 自身のTUIを使わず、実物のfzfにパイプする
# (modules/shell/zsh/functions.zsh の atuin-fzf)。
#
# 過去はatuin自身のTUIをfzf風に見せるためソースパッチ
# (fzf-style.patch) を当てていたが、atuinの内部レンダリング実装の
# リファクタで毎回パッチが壊れ、バージョンアップのたびに手動で
# 当て直す必要があり運用コストが高すぎたため撤廃した。
# fzfは元々枠線色・ハイライト等をネイティブオプションで持つため、
# 「fzf風の見た目」が欲しいだけなら素のfzfを使えばパッチは不要になる。
{ pkgs, ... }:

let
  # --- atuin-history-colored ---
  # atuin-fzf (modules/shell/zsh/functions.zsh) が使う、終了コードに応じて
  # 緑(成功)/赤(失敗)の●を先頭に付けた履歴一覧を出力するヘルパー。
  # fzfの `reload()` アクションは新しいシェルプロセスを起動するため、
  # インタラクティブzshで定義した関数を直接呼べない (atuin-fzf内で生の
  # パイプラインを複数箇所に重複させていたのはこの制約のため)。
  # 実行可能ファイルとしてPATHに置くことでこの制約を回避する。
  atuin-history-colored = pkgs.writeShellApplication {
    name = "atuin-history-colored";
    runtimeInputs = [ pkgs.atuin pkgs.gawk ];
    text = ''
      # $@ で --filter-mode directory / --filter-mode session をそのまま
      # atuinへ中継できる (Ctrl+Rでの GLOBAL → DIRECTORY → SESSION 切り替え用)。
      #
      # `atuin history list` ではなく `atuin search` (クエリ無し=全件) を
      # 使う。search はデフォルトで重複コマンドを除外してくれる
      # (--include-duplicatesを付けない限り)。同じコマンドを何度も打った
      # 履歴が1件に畳まれ、一覧が探しやすくなる。
      #
      # 色は #98bb6c (成功) / #e46876 (失敗) — zsh-syntax-highlighting の
      # command/unknown-token と同じ固定値 (functions.zsh 参照)。真の色
      # (24bit ANSI, \033[38;2;R;G;Bm) を使い，ターミナルの配色スキーム
      # 依存の汎用緑/赤 (\033[32m 等) には頼らずどこでも同じ色で表示する。
      #
      # 各候補は "装飾付き表示\x01生コマンド" の2フィールド構成にする。
      # fzfは --ansi でも選択結果からANSIエスケープコードを取り除いてしまい，
      # 見た目の●という文字だけがBUFFERに混入してコマンドが壊れる実害が
      # あったため，表示用フィールドを装飾で汚しても実際に使うのは常に
      # \x01より後ろの生コマンド(無加工)、という形にして回避している。
      atuin search --format '{exit}\t{command}' --print0 "$@" | awk -v RS='\0' -v ORS='\0' '
      {
        sep = index($0, "\t")
        ec = substr($0, 1, sep - 1)
        cmd = substr($0, sep + 1)
        if (cmd == "") next
        sym = (ec == "0") ? "\033[38;2;152;187;108m\xe2\x97\x8f\033[0m" : "\033[38;2;228;104;118m\xe2\x97\x8f\033[0m"
        printf "%s %s\x01%s%s", sym, cmd, cmd, ORS
      }'
    '';
  };

  # --- atuin-delete-entry ---
  # atuin-fzf (Ctrl+O) が使う、atuin本家のインタラクティブTUI (atuin search -i)
  # を「選択中のコマンドをクエリにして」開くヘルパー。
  # atuin search -iにクエリを渡して起動すると検索ボックス側にフォーカスが
  # ある状態で始まり、そのままではCtrl-Dでの削除が効かない。一度Ctrl-O
  # (0x0f) を押してフォーカスを結果リストへ移す必要があると、atuinバイナリ
  # に埋め込まれたヘルプ文字列 ("<ctrl-o>: search<ctrl-d>: delete") から
  # 確認済み。この「フォーカス移動」自体は何も変更しない操作なので自動送信
  # して手間を減らすが、実際の削除操作(Ctrl-D)自体はユーザーの手動操作の
  # まま残す (誤爆防止。atuin search --deleteでのクエリ指定削除は非対話
  # 実行だとファジー検索が不安定で無関係な履歴を巻き込む実害を確認済みの
  # ため、独自の削除ロジックは組まずatuin本家TUIに委ねている)。
  #
  # ユーザーがCtrl-Dを押すと削除は実行されるが、atuinのTUIはそのまま
  # 検索/一覧画面に留まり、Escで抜けるまで元のfzf側に戻ってこない。
  # 削除自体は既にユーザーの意思で実行済みなので、その直後のEsc(画面を
  # 閉じるだけの操作)は自動化しても誤爆リスクが無い。expectのinteractで
  # ユーザーが打ったCtrl-D (\x04) を検知したら、それをそのままatuinへ
  # 転送しつつ (=削除を実行させる)、少し待ってEsc (\x1b) を追加送信して
  # TUIごと閉じ、fzf側の一覧再読み込みへ自動的に戻す。
  atuin-delete-entry = pkgs.writeTextFile {
    name = "atuin-delete-entry";
    destination = "/bin/atuin-delete-entry";
    executable = true;
    text = ''
      #!${pkgs.expect}/bin/expect
      set query [lindex $argv 0]
      spawn ${pkgs.atuin}/bin/atuin search -i -- $query
      # atuinのTUIが描画・入力受付を開始する前にCtrl-Oを送ると無視される
      # ことがあったため、送信前に少し待つ。
      after 400
      send "\x0f"
      interact {
        "\x04" {
          send -- "\x04"
          after 300
          send -- "\x1b"
        }
      }
    '';
  };
in
{
  home.packages = [ atuin-history-colored atuin-delete-entry ];

  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    # atuin自身のTUI起動キーは使わない (Ctrl+Rはatuin-fzfが担当、
    # ↑キーは通常のzsh履歴のまま維持する)
    flags = [ "--disable-up-arrow" "--disable-ctrl-r" ];
    settings = {
      update_check = false;
    };
  };
}
