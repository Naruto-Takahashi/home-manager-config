#!/usr/bin/env python3
"""wallpaper-pick-gui (wsl) — サムネイルグリッドのポップアップから壁紙を選び、
Windows壁紙とmatugen配色を即座に反映する。選択後は顕著性ベースの色候補
(suggest-accent.py) を表示し、クリックだけで手動オーバーライドも試せる。

modules/theming/matugen/mac/wallpaper-pick-gui.py のWSL版。GUIツール
キットに依存せず、ローカルHTTPサーバ+ブラウザのapp-modeウィンドウ
(WSL側でサーバを立て、Windows側のVivaldiから127.0.0.1にアクセスする。
WSL2のlocalhostフォワーディング機能により追加設定なしで到達できる)
で同等のUXを実現する。

呼び出し元 (wallpaper-pick-popup.sh) がポート0(空きポート自動選択)で起動し、
Vivaldiのウィンドウを閉じるまで動き続ける (選択後も自動終了しない。
色候補を試しながら比較できるようにするため)。
"""
import html
import http.server
import json
import mimetypes
import os
import re
import socket
import subprocess
import sys
import urllib.parse

WALLPAPER_DIR = os.path.realpath(
    os.environ.get("MATUGEN_WALLPAPER_DIR", "/mnt/c/Users/tnaru/Pictures/wallpapers")
)
MATUGEN_APPLY = os.path.expanduser("~/.local/bin/matugen-apply")
SUGGEST_PY = os.path.expanduser(
    "~/ghq/github.com/Naruto-Takahashi/nix-config/modules/theming/matugen/lib/suggest-accent.py"
)
OVERRIDES_FILE = os.path.expanduser("~/.config/matugen-wsl/color-overrides.conf")
POWERSHELL = "/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe"
EXTS = {".png", ".jpg", ".jpeg", ".webp", ".bmp"}


def list_wallpapers():
    if not os.path.isdir(WALLPAPER_DIR):
        return []
    names = [f for f in os.listdir(WALLPAPER_DIR) if os.path.splitext(f)[1].lower() in EXTS]
    return sorted(names)


def safe_path(name: str) -> str:
    """WALLPAPER_DIR配下のファイル名のみを許可する (パストラバーサル対策)。"""
    p = os.path.realpath(os.path.join(WALLPAPER_DIR, name))
    if os.path.dirname(p) != WALLPAPER_DIR or not os.path.isfile(p):
        raise ValueError("invalid path")
    return p


PAGE_TEMPLATE = """<!doctype html>
<html><head><meta charset="utf-8"><title>wallpaper picker</title>
<style>
  :root {{ color-scheme: dark; }}
  body {{ margin: 0; padding: 16px; background: #14161b; font-family: -apple-system, "Segoe UI", sans-serif; }}
  h1 {{ color: #e3e5ea; font-size: 14px; font-weight: 600; margin: 0 0 12px; }}
  .grid {{ display: grid; grid-template-columns: repeat(auto-fill, minmax(180px, 1fr)); gap: 10px; }}
  .card {{ cursor: pointer; border-radius: 10px; overflow: hidden; border: 2px solid transparent;
           background: #1e2128; transition: border-color .15s, transform .1s; }}
  .card:hover {{ border-color: #a2c9fd; transform: scale(1.02); }}
  .card.selected {{ border-color: #a2c9fd; }}
  .card img {{ display: block; width: 100%; height: 120px; object-fit: cover; }}
  .status {{ position: fixed; inset: 0; display: none; align-items: center; justify-content: center;
             background: rgba(20,22,27,.9); color: #e3e5ea; font-size: 16px; z-index: 10; }}
  .status.show {{ display: flex; }}
  #suggestions {{ margin-top: 18px; padding-top: 14px; border-top: 1px solid #2a2d35; display: none; }}
  #suggestions.show {{ display: block; }}
  #suggestions h2 {{ color: #c3c6cf; font-size: 12px; font-weight: 600; margin: 0 0 10px; }}
  .swatches {{ display: flex; gap: 8px; flex-wrap: wrap; }}
  .swatch {{ width: 64px; cursor: pointer; text-align: center; }}
  .swatch .box {{ width: 64px; height: 44px; border-radius: 8px; border: 2px solid transparent; }}
  .swatch:hover .box {{ border-color: #a2c9fd; }}
  .swatch.applied .box {{ border-color: #95d5a7; }}
  .swatch .hex {{ color: #9aa0ac; font-size: 10px; margin-top: 4px; font-family: monospace; }}
  .manual {{ margin-top: 12px; display: flex; gap: 6px; align-items: center; }}
  .manual input {{ background: #1e2128; border: 1px solid #2a2d35; border-radius: 6px; color: #e3e5ea;
                    padding: 6px 8px; font-family: monospace; width: 110px; }}
  .manual button, .reset {{ background: #2a2d35; border: none; border-radius: 6px; color: #e3e5ea;
                             padding: 6px 10px; cursor: pointer; }}
  .manual button:hover, .reset:hover {{ background: #343842; }}
</style></head>
<body>
  <h1>壁紙を選択 ({count}枚)</h1>
  <div class="grid">{cards}</div>

  <div id="suggestions">
    <h2>色候補 (顕著性スコア順。クリックで適用)</h2>
    <div class="swatches" id="swatches"></div>
    <div class="manual">
      <input type="text" id="manualHex" placeholder="#RRGGBB" maxlength="7">
      <button onclick="applyManual()">適用</button>
      <button class="reset" onclick="resetColor()">自動抽出に戻す</button>
    </div>
  </div>

  <div class="status" id="status">反映中…</div>
<script>
var currentName = null;

function setStatus(show) {{
  document.getElementById('status').classList.toggle('show', show);
}}

function selectWallpaper(name) {{
  currentName = name;
  document.querySelectorAll('.card').forEach(function (c) {{ c.classList.remove('selected'); }});
  document.querySelector('.card[data-name="' + CSS.escape(name) + '"]').classList.add('selected');
  setStatus(true);
  // /select (壁紙反映) と /suggest (色候補計算) は互いに独立しているため並列実行する
  // (直列だと合計待ち時間になり体感が重かった)
  Promise.all([
    fetch('/select?name=' + encodeURIComponent(name)),
    loadSuggestions(name),
  ]).then(function () {{ setStatus(false); }});
}}

function loadSuggestions(name) {{
  return fetch('/suggest?name=' + encodeURIComponent(name))
    .then(function (r) {{ return r.json(); }})
    .then(function (list) {{
      var box = document.getElementById('swatches');
      box.innerHTML = '';
      list.forEach(function (item) {{
        var el = document.createElement('div');
        el.className = 'swatch';
        el.innerHTML = '<div class="box" style="background:' + item.hex + '"></div>' +
                        '<div class="hex">' + item.hex + '</div>';
        el.addEventListener('click', function () {{ applyColor(item.hex, el); }});
        box.appendChild(el);
      }});
      document.getElementById('suggestions').classList.add('show');
    }});
}}

function applyColor(hex, el) {{
  if (!currentName) return;
  setStatus(true);
  fetch('/apply-color?name=' + encodeURIComponent(currentName) + '&hex=' + encodeURIComponent(hex))
    .then(function () {{
      setStatus(false);
      document.querySelectorAll('.swatch').forEach(function (s) {{ s.classList.remove('applied'); }});
      if (el) el.classList.add('applied');
    }});
}}

function applyManual() {{
  var v = document.getElementById('manualHex').value.trim();
  if (/^#[0-9a-fA-F]{{6}}$/.test(v)) applyColor(v, null);
}}

function resetColor() {{
  if (!currentName) return;
  setStatus(true);
  fetch('/reset-color?name=' + encodeURIComponent(currentName))
    .then(function () {{
      setStatus(false);
      document.querySelectorAll('.swatch').forEach(function (s) {{ s.classList.remove('applied'); }});
    }});
}}

document.querySelectorAll('.card').forEach(function (el) {{
  el.addEventListener('click', function () {{ selectWallpaper(el.dataset.name); }});
}});
</script>
</body></html>
"""


def render_page() -> bytes:
    names = list_wallpapers()
    cards = "".join(
        '<div class="card" data-name="{n}"><img src="/img?name={n}" loading="lazy"></div>'.format(
            n=html.escape(name, quote=True)
        )
        for name in names
    )
    if not names:
        cards = '<p style="color:#c3c6cf">{}に画像が見つかりません</p>'.format(html.escape(WALLPAPER_DIR))
    return PAGE_TEMPLATE.format(count=len(names), cards=cards).encode("utf-8")


def set_windows_wallpaper(wsl_path: str):
    win_path = subprocess.run(
        ["wslpath", "-w", wsl_path], capture_output=True, text=True, check=True
    ).stdout.strip()
    # C# コード自体に {} が含まれるため str.format は使わず単純結合する
    ps = (
        "Add-Type -TypeDefinition 'using System.Runtime.InteropServices; "
        "public class WP { [DllImport(\"user32.dll\", CharSet=CharSet.Unicode)] "
        "public static extern bool SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni); }';"
        "[WP]::SystemParametersInfo(20, 0, '" + win_path.replace("'", "''") + "', 3) | Out-Null"
    )
    subprocess.run([POWERSHELL, "-NoProfile", "-Command", ps], check=False)


def apply_wallpaper(wsl_path: str):
    set_windows_wallpaper(wsl_path)
    subprocess.run([MATUGEN_APPLY, wsl_path], check=False)


def reapply():
    subprocess.run([MATUGEN_APPLY, "--reapply"], check=False)


def set_override(basename: str, hexcode: str):
    lines = []
    if os.path.isfile(OVERRIDES_FILE):
        with open(OVERRIDES_FILE) as f:
            lines = [
                line for line in f.read().splitlines()
                if not re.match(r"^" + re.escape(basename) + r"=", line)
            ]
    lines.append(f"{basename}={hexcode}")
    with open(OVERRIDES_FILE, "w") as f:
        f.write("\n".join(lines) + "\n")


def clear_override(basename: str):
    if not os.path.isfile(OVERRIDES_FILE):
        return
    with open(OVERRIDES_FILE) as f:
        lines = [
            line for line in f.read().splitlines()
            if not re.match(r"^" + re.escape(basename) + r"=", line)
        ]
    with open(OVERRIDES_FILE, "w") as f:
        f.write("\n".join(lines) + "\n")


def suggest_colors(path: str, top_n: int = 6):
    out = subprocess.run(
        [sys.executable, SUGGEST_PY, path, str(top_n)],
        capture_output=True, text=True, check=True,
    ).stdout
    results = []
    for line in out.splitlines()[1:]:  # ヘッダ行を飛ばす
        m = re.match(r"^\d+\s+(#[0-9A-Fa-f]{6})\s+([\d.]+)\s+([\d.]+)", line)
        if m:
            results.append({"hex": m.group(1), "area": float(m.group(2)), "score": float(m.group(3))})
    return results


class Handler(http.server.BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass  # 端末を汚さない

    def _json(self, obj, status=200):
        body = json.dumps(obj).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        qs = urllib.parse.parse_qs(parsed.query)

        if parsed.path == "/":
            body = render_page()
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return

        if parsed.path == "/img":
            try:
                path = safe_path(qs["name"][0])
            except (KeyError, ValueError):
                self.send_error(404)
                return
            ctype = mimetypes.guess_type(path)[0] or "application/octet-stream"
            with open(path, "rb") as f:
                data = f.read()
            self.send_response(200)
            self.send_header("Content-Type", ctype)
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)
            return

        if parsed.path == "/select":
            try:
                path = safe_path(qs["name"][0])
            except (KeyError, ValueError):
                self.send_error(404)
                return
            apply_wallpaper(path)
            self._json({"ok": True})
            return

        if parsed.path == "/suggest":
            try:
                path = safe_path(qs["name"][0])
            except (KeyError, ValueError):
                self.send_error(404)
                return
            try:
                self._json(suggest_colors(path))
            except subprocess.CalledProcessError:
                self._json([])
            return

        if parsed.path == "/apply-color":
            try:
                name = qs["name"][0]
                path = safe_path(name)
                hexcode = qs["hex"][0]
            except (KeyError, ValueError):
                self.send_error(404)
                return
            if not re.match(r"^#[0-9A-Fa-f]{6}$", hexcode):
                self.send_error(400)
                return
            set_override(os.path.basename(path), hexcode)
            reapply()
            self._json({"ok": True})
            return

        if parsed.path == "/reset-color":
            try:
                name = qs["name"][0]
                path = safe_path(name)
            except (KeyError, ValueError):
                self.send_error(404)
                return
            clear_override(os.path.basename(path))
            reapply()
            self._json({"ok": True})
            return

        self.send_error(404)


def main():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind(("127.0.0.1", 0))
        port = s.getsockname()[1]
    server = http.server.ThreadingHTTPServer(("127.0.0.1", port), Handler)
    print(port, flush=True)
    server.serve_forever()


if __name__ == "__main__":
    sys.exit(main())
