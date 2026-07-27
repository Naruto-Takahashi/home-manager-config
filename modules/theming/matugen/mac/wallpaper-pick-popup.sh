#!/usr/bin/env bash
# =========================================================================
# wallpaper-pick-popup (mac) — サムネイルグリッドのポップアップウィンドウ
# (Vivaldiのapp-mode) で壁紙を選び、即座に壁紙とmatugen配色を反映する。
# =========================================================================
# 実体は wallpaper-pick-gui.py (ローカルHTTPサーバ)。選択後はサーバが自動終了する。
set -euo pipefail

export PATH="/etc/profiles/per-user/$USER/bin:$HOME/.nix-profile/bin:/opt/homebrew/bin:$PATH"

GUI_PY="$HOME/.config/matugen-mac/wallpaper-pick-gui.py"

# python3側が起動直後にポート番号を1行だけ標準出力するので、
# それをログファイル経由で受け取ってからブラウザを開く。
LOG="$(mktemp)"
nohup python3 "$GUI_PY" >"$LOG" 2>/dev/null &
disown

port=""
for _ in $(seq 1 50); do
    port="$(head -n1 "$LOG" 2>/dev/null || true)"
    [[ -n "$port" ]] && break
    sleep 0.1
done
rm -f "$LOG"

if [[ -z "$port" ]]; then
    echo "wallpaper-pick-popup: サーバの起動に失敗しました" >&2
    exit 1
fi

# --user-data-dir で毎回まっさらなプロファイルを使う。共有プロファイルだと
# Chromium(Vivaldi)がapp-modeウィンドウの直前の状態(ネイティブフルスクリーン化
# したことがあるなど)を記憶して復元してしまい、AeroSpaceの管理外
# (ネイティブフルスクリーンは独立したSpaceになるため)になってしまう。
PROFILE_DIR="$(mktemp -d)"
open -na "Vivaldi" --args \
    --app="http://127.0.0.1:${port}" \
    --user-data-dir="$PROFILE_DIR" \
    --window-position=200,120 \
    --window-size=900,720
