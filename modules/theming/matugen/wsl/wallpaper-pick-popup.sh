#!/usr/bin/env bash
# =========================================================================
# wallpaper-pick-popup (wsl) — サムネイルグリッドのポップアップウィンドウ
# (Vivaldiのapp-mode) で壁紙を選び、即座に壁紙とmatugen配色を反映する。
# 選択後は色候補もそのウィンドウ内でクリックして試せる。
# =========================================================================
# 実体は wallpaper-pick-gui.py (WSL側のローカルHTTPサーバ)。
# WindowsのVivaldiからは WSL2 のlocalhostフォワーディングで
# http://localhost:<port> に到達できる (追加設定不要)。
# komorebi.ahk の ALT+W から呼ばれる。
set -euo pipefail

export PATH="$HOME/.nix-profile/bin:$PATH"

GUI_PY="$HOME/.config/matugen-wsl/wallpaper-pick-gui.py"

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

VIVALDI='C:\Users\tnaru\AppData\Local\Vivaldi\Application\vivaldi.exe'
PROFILE_DIR_WIN="C:\\Users\\tnaru\\AppData\\Local\\Temp\\wallpaper-pick-profile-$$"

/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -NoProfile -Command "
  Start-Process -FilePath '${VIVALDI}' -ArgumentList '--app=http://localhost:${port}','--user-data-dir=${PROFILE_DIR_WIN}','--window-position=200,120','--window-size=900,760'
"
