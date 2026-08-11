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
  # Vivaldi設定のCSS UI Mods Directoryを ~/.config/vivaldi (home-manager管理)
  # に向けている (Settings > Appearance > Custom UI Modification)。
  # \\wsl.localhost\... 経由でWindows側から直接参照されるため、
  # home-manager switch すればWSL/Windows間の同期は不要で即座に反映される。
  # custom.css はAirZenifyにない独自要素 (信号ボタンの色・タブ高さ) のみ持つ。
  xdg.configFile."vivaldi/custom.css" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/modules/apps/vivaldi/css/custom.css";
    force = true;
  };
  xdg.configFile."vivaldi/air-zenify.css" = {
    source = airZenifyCss;
    force = true;
  };
}
