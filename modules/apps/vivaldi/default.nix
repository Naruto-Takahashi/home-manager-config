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
  # 特定コミットから取得する。更新したいときは下のrev/hashを書き換えるだけでよい。
  # DynamicNeonTab.css (ネオン配色のタブ) は現在のmatugen連携の落ち着いた
  # 配色と合わないため採用していない。
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
  # 独自要素 (信号ボタンの色・タブ高さ) のみ持つ。
  xdg.configFile."vivaldi/custom.css" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/modules/apps/vivaldi/css/custom.css";
    force = true;
  };
  xdg.configFile."vivaldi/air-zenify.css" = {
    source = airZenifyCss;
    force = true;
  };
}
