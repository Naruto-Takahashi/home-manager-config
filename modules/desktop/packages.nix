# =========================================================================
# パッケージ・アプリケーション管理宣言的モジュール
# =========================================================================
{ config, pkgs, nixgl, ... }:

{
  # --- 導入パッケージ一覧 ---
  home.packages = [
    # ターミナルで使用するフォント
    pkgs.hackgen-nf-font # WezTermで指定されているフォントです．

    # 基本CLIユーティリティ
    pkgs.eza
    pkgs.bat
    pkgs.feh
    pkgs.picom
    pkgs.ghq
    pkgs.git

    # 開発環境・コンパイラ
    pkgs.gcc
    pkgs.gnumake
    pkgs.python3
    pkgs.nodejs_22

    # クリップボード・ユーティリティ
    pkgs.xclip
    pkgs.wl-clipboard
    pkgs.kanata

    # スクリーンショットツール
    pkgs.maim # 超軽量・極めて安定したスクリーンショットツール（GPUに依存しない）です．
    pkgs.slop # maim用の美しいドラッグ範囲選択ツールです．

    # ジョークツール・装飾
    pkgs.cowsay
    pkgs.fortune
    pkgs.lolcat
    pkgs.fastfetch

    # --- カスタムパッケージ定義 ---
    
    # vivaldiのラッパーパッケージ：XRDPセッション（DISPLAY>=10）時はプロファイルを分けて多重起動できるようにします．
    (pkgs.stdenv.mkDerivation {
      name = "vivaldi-wrapped";
      phases = [ "installPhase" ];
      installPhase = ''
        mkdir -p $out/bin
        cat <<EOF > $out/bin/vivaldi
#!/usr/bin/env bash
display_num=\$(echo \$DISPLAY | cut -d: -f2 | cut -d. -f1)
if [ -f /run/current-system/sw/bin/vivaldi ]; then
  REAL_VIVALDI="/run/current-system/sw/bin/vivaldi"
elif [ -f /etc/profiles/per-user/nalt/bin/vivaldi ]; then
  REAL_VIVALDI="/etc/profiles/per-user/nalt/bin/vivaldi"
elif [ -f /usr/bin/vivaldi-stable ]; then
  REAL_VIVALDI="/usr/bin/vivaldi-stable"
else
  REAL_VIVALDI=\$(which -a vivaldi vivaldi-stable | grep -v "/.nix-profile/bin" | grep -v "/etc/profiles" | head -n 1)
fi

if [ -n "\$display_num" ] && [ "\$display_num" -ge 10 ]; then
  exec "\$REAL_VIVALDI" --user-data-dir="\$HOME/.config/vivaldi-remote" "\$@"
else
  exec "\$REAL_VIVALDI" "\$@"
fi
EOF
        chmod +x $out/bin/vivaldi
        ln -s vivaldi $out/bin/vivaldi-stable
      '';
    })
  ];
}
