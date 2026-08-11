# =========================================================================
# Vivaldi 宣言的設定モジュール
# =========================================================================
{ config, pkgs, dotfilesPath, ... }:

let
  # --- air-zenify.css (外部CSS mod) ---
  # 出典: https://github.com/ELGUAPOLIFE/Zen-Theme-CSS-for-Vivaldi-Browser
  # (MohamedxSalah/Vivaldi-Air と PaRr0tBoY/Awesome-Vivaldi の派生)
  # Vivaldi 7.9+ のネイティブUI自動非表示機能を前提としたテーマ。
  # 本文をリポジトリに手でコピペせず、Nixのfetchurl (ハッシュ検証付き) で
  # 特定コミットから取得する。DynamicNeonTab.css (ネオン配色のタブ) は
  # 現在のmatugen連携の落ち着いた配色と合わないため採用していない。
  #
  # ⚠️ 運用ポリシー: rev/hashを気軽に書き換えて「最新版に追従」しない。
  # このテーマは実際に使っているVivaldiバージョン(8.1.4087時点)との間で
  # 複数のセレクタ不一致バグが見つかっており (下記4件、すべてcustom.css側
  # で個別に上書き修正済み)、アップストリーム側がどのVivaldiバージョンを
  # 前提にしているか不明で、動くことを検証せずに追従するのは危険:
  #   1. `.auto-hide #browser ...` という子孫セレクタが実際は
  #      `#browser.auto-hide` (autoHideクラスは#browser自身に付与される)
  #      であるべきで一度もマッチしていなかった (box-shadow/margin未リセット)
  #   2. `.unified-ui .auto-hide-wrapper` の transparent 指定が同名クラスの
  #      ガラス効果定義と詳細度が同じで後勝ちしてしまうケースがあった
  #   3. 信号ボタン(.window-buttongroup)は#headerではなく常時opacity:1の
  #      #titlebarの子要素で、AirZenify本体はどちらの表示状態も制御しない
  #   4. フローティングパネル有効時の実際のクラスは `.overlay` ではなく
  #      `.expanded` で、パネル本体のガラス効果が一度も適用されていなかった
  # 本当にアップデートしたい場合は、rev/hashを書き換えた後、CDP
  # (chrome devtools protocol) で実際のDOM/computedStyleを確認しながら
  # custom.css側の上書き修正が今も必要か・新たに必要かを再監査すること。
  airZenifyRev = "cb65d550a6f68c74dc7b07ecf37388a0c7a7a3b7";
  airZenifyCss = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/ELGUAPOLIFE/Zen-Theme-CSS-for-Vivaldi-Browser/${airZenifyRev}/AirZenify.css";
    hash = "sha256-I8+/oDyz6+/06cIZ1jEtdmtRJMN7cLcL67SC/851H6Q=";
  };
in
{
  # --- VivaldiカスタムCSS設定 ---
  # Windows(Vivaldi)からWSL側のシンボリックリンクを \\wsl.localhost\...
  # 経由で直接読ませると、リンク先を辿れずリンク文字列そのもの(数十バイト)を
  # 読んでしまい、CSSが一切適用されない不具合がある (実機で確認済み。
  # mkOutOfStoreSymlinkもfetchurlの結果もどちらもシンボリックリンクのため
  # 影響を受ける)。そのため他のWindows向け設定 (wezterm/komorebi/yasb等)
  # と同じく、sync-win (cp -L で実体を解決してコピー) で
  # C:\Users\tnaru\Tools\Vivaldi\ へ配置し、Vivaldi設定のCSS UI Mods
  # DirectoryもそちらへUIから向ける。custom.css はAirZenifyにない
  # 独自要素 (信号ボタンの色・タブ高さ・アクティブタブのガラス化) に加え、
  # 上記のAirZenify側バグ4件を上書き修正する役割も持つ (詳細は
  # custom.css内の各コメント参照)。@importの順序上、air-zenify.cssより
  # 後に読み込まれるため上書きが効く。
  xdg.configFile."vivaldi/custom.css" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/modules/apps/vivaldi/css/custom.css";
    force = true;
  };
  xdg.configFile."vivaldi/air-zenify.css" = {
    source = airZenifyCss;
    force = true;
  };
}
