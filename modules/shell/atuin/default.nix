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
{ ... }:

{
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
