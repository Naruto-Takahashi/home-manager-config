#!/usr/bin/env bash
# =========================================================================
# nalt-distrobox ホスト用コンテナ (nixcli) のブートストラップスクリプト
# =========================================================================
# sudo無しでこのホストにCLI環境 (nix-configのnalt-distroboxプロファイル) を
# 持ち込むための、独立$HOMEを持つrootless podmanコンテナを1コマンドで作る。
#
# 使い方:
#   bash hosts/nalt-distrobox/bootstrap.sh
#
# 環境変数で上書き可能:
#   NIXCLI_NAME=nixcli               コンテナ名
#   NIXCLI_HOME=~/distrobox-homes/nixcli-dev   独立$HOMEのパス
#
# 元々distrobox.ini + `distrobox assemble create`で宣言的にやろうとしたが、
# 使用したdistrobox 1.8.2.5で --additional-packages と --init-hooks を
# 同時に使うとコマンド生成が壊れるバグ (init-hooks値にシングルクォートの
# ネストがあると"sh: line 1: <container-id-hash>: command not found"に
# なる) を踏んだため、素の`distrobox create`を直接呼ぶ形にしている。
# 同じ理由でinit-hooksもクォートを含まない最小限 (/nixの作成のみ) に
# 留めてあり、Nixのインストール自体はこのスクリプトの後半で
# (rootではなく実際にログインした状態で) 行う。
set -euo pipefail

NIXCLI_NAME="${NIXCLI_NAME:-nixcli}"
NIXCLI_HOME="${NIXCLI_HOME:-$HOME/distrobox-homes/nixcli-dev}"

if ! command -v distrobox >/dev/null 2>&1; then
  echo "distroboxが見つかりません。先にインストールしてください:" >&2
  echo "  curl -fsSL https://raw.githubusercontent.com/89luca89/distrobox/main/install | bash -s -- --prefix ~/.local" >&2
  exit 1
fi

echo "[bootstrap] コンテナ '$NIXCLI_NAME' を作成 (home: $NIXCLI_HOME)"
mkdir -p "$NIXCLI_HOME"
distrobox create --name "$NIXCLI_NAME" --image docker.io/library/ubuntu:24.04 \
  --home "$NIXCLI_HOME" \
  --additional-packages "git ca-certificates podman build-essential" \
  --init-hooks "mkdir -m 0755 -p /nix && chown $(id -un) /nix" \
  --yes

echo "[bootstrap] 初回起動 (パッケージインストール等，数分かかる)"
distrobox enter "$NIXCLI_NAME" -- bash -c 'echo "[bootstrap] コンテナ起動完了"'

echo "[bootstrap] Nixをシングルユーザーモードでインストール"
distrobox enter "$NIXCLI_NAME" -- bash -c '
  curl -L https://nixos.org/nix/install | sh -s -- --no-daemon
  mkdir -p ~/.config/nix
  echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
'

cat <<EOF

[bootstrap] 完了。続きは docs/setup-distrobox.md の手順3以降 (SSH鍵のコピー，
リポジトリのclone，home-manager switch，yaziテーマ生成) を参照してください。
EOF
