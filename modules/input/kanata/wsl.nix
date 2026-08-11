# =========================================================================
# Kanata Windows(WSLホスト)向け宣言的設定モジュール
# =========================================================================
# AHKのSandS/CapsLock/Alt実装がキー状態の取りこぼしで「押されっぱなし」に
# なる不具合があったため、この用途に特化した低レベルキーボードフックである
# kanataへ移行する試み。AHK側の該当コードは削除せず残してあり
# (modules/input/ahk/main.ahk 参照)、kanataを止めれば即座にAHKの実装へ
# ロールバックできる。
#
# バイナリは kanata_windows_gui_winIOv2_cmd_allowed_x64.exe を採用:
#   - gui: コンソールウィンドウを表示しない
#   - winIOv2: 標準のWindows低レベルフック方式。Interceptionドライバ
#     (要管理者権限・要再起動・2026年時点でキーボード再接続後にOS再起動が
#     必要になる既知の不具合あり) は導入しない。特に本機はSurfaceの
#     着脱式キーボードを使うため、再接続で問題が起きうるInterception版は
#     現時点では避ける判断とした。より確実な動作が必要になった場合は
#     wintercept版への切り替えを検討する
#   - cmd_allowed: IME制御をAHKへ委譲する (cmd)アクションに必要
{ config, pkgs, dotfilesPath, ... }:

let
  kanataWindows = pkgs.stdenvNoCC.mkDerivation {
    pname = "kanata-windows";
    version = "1.12.0";
    src = pkgs.fetchurl {
      url = "https://github.com/jtroo/kanata/releases/download/v1.12.0/windows-binaries-x64.zip";
      sha256 = "sha256-E5R+14z6MoS/74VOPFQsdKs2Yja3L9n34Dn4Y43urZ0=";
    };
    nativeBuildInputs = [ pkgs.unzip ];
    unpackPhase = "unzip $src -d .";
    installPhase = ''
      mkdir -p $out
      cp kanata_windows_gui_winIOv2_cmd_allowed_x64.exe $out/kanata.exe
    '';
  };
in
{
  home.file.".local/bin/kanata-windows.exe".source = "${kanataWindows}/kanata.exe";

  # config.kbd はビルド時に生成される (プレースホルダ置換済みの静的テキスト)
  # ため mkOutOfStoreSymlink ではなく通常の home.file.text にしている。
  # wsl-config.nix を編集したら home-manager switch が必要
  xdg.configFile."kanata-wsl/config.kbd".text = import ./wsl-config.nix;

  # IME制御委譲用の一発実行AHKスクリプト。main.ahkと同じくsync-winで
  # ~/.config/ahk 配下ごとWindows側へコピーされる (modules/input/ahk/default.nix)
  xdg.configFile."ahk/ime-off.ahk" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/modules/input/ahk/ime-off.ahk";
    force = true;
  };
  xdg.configFile."ahk/ime-on.ahk" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/modules/input/ahk/ime-on.ahk";
    force = true;
  };
}
