#!/usr/bin/env python3
"""wallpaper-pick-gui (mac) — サムネイルグリッドのポップアップから壁紙を選び、
即座にmacOSの壁紙とmatugen配色を反映する。

WSL側のYASB「wallpapersウィジェット」(クリックで壁紙+配色を即反映するポップアップ)
のMac版。GUIツールキットに依存せず、ローカルHTTPサーバ+ブラウザのapp-mode
ウィンドウ (Vivaldi --app=) で同等のUXを実現する。

呼び出し元 (wallpaper-pick-popup.sh) がポート0(空きポート自動選択)で起動し、
選択が終わる(またはユーザーがウィンドウを閉じる)とプロセスごと終了する。
"""
import html
import http.server
import mimetypes
import os
import socket
import subprocess
import sys
import threading
import urllib.parse

WALLPAPER_DIR = os.path.realpath(
    os.environ.get("MATUGEN_WALLPAPER_DIR", os.path.expanduser("~/Pictures/Wallpapers"))
)
MATUGEN_APPLY = os.path.expanduser("~/.local/bin/matugen-apply")
EXTS = {".png", ".jpg", ".jpeg", ".webp", ".heic", ".bmp"}


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
  body {{ margin: 0; padding: 16px; background: #1a1110; font-family: -apple-system, sans-serif; }}
  h1 {{ color: #f1dedc; font-size: 14px; font-weight: 600; margin: 0 0 12px; }}
  .grid {{ display: grid; grid-template-columns: repeat(auto-fill, minmax(180px, 1fr)); gap: 10px; }}
  .card {{ cursor: pointer; border-radius: 10px; overflow: hidden; border: 2px solid transparent;
           background: #271d1c; transition: border-color .15s, transform .1s; }}
  .card:hover {{ border-color: #ffb3ac; transform: scale(1.02); }}
  .card.selected {{ border-color: #ffb3ac; opacity: .5; pointer-events: none; }}
  .card img {{ display: block; width: 100%; height: 120px; object-fit: cover; }}
  .status {{ position: fixed; inset: 0; display: none; align-items: center; justify-content: center;
             background: rgba(26,17,16,.9); color: #f1dedc; font-size: 16px; }}
  .status.show {{ display: flex; }}
</style></head>
<body>
  <h1>壁紙を選択 ({count}枚)</h1>
  <div class="grid">{cards}</div>
  <div class="status" id="status">配色を反映中…</div>
<script>
document.querySelectorAll('.card').forEach(function (el) {{
  el.addEventListener('click', function () {{
    document.querySelectorAll('.card').forEach(function (c) {{ c.classList.add('selected'); }});
    document.getElementById('status').classList.add('show');
    fetch('/select?name=' + encodeURIComponent(el.dataset.name))
      .then(function () {{ setTimeout(function () {{ window.close(); }}, 600); }});
  }});
}});
</script>
</body></html>
"""


def render_page() -> bytes:
    names = list_wallpapers()
    cards = "".join(
        '<div class="card" data-name="{n}"><img src="/img?name={n}" loading="lazy"></div>'.format(
            n=urllib.parse.quote(name)
        )
        for name in names
    )
    if not names:
        cards = '<p style="color:#d8c2bf">{}に画像が見つかりません</p>'.format(html.escape(WALLPAPER_DIR))
    return PAGE_TEMPLATE.format(count=len(names), cards=cards).encode("utf-8")


def apply_wallpaper(path: str):
    # macOSの壁紙をすべてのデスクトップ(スペース)に設定する
    osa = (
        'tell application "System Events" to tell every desktop to set picture to '
        '(POSIX file "{}")'.format(path.replace('"', '\\"'))
    )
    subprocess.run(["osascript", "-e", osa], check=False)
    # 配色一式 (WezTerm/nvim/yazi/starship/.../AeroSpace枠線) を追従
    subprocess.run([MATUGEN_APPLY, path], check=False)


class Handler(http.server.BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass  # 端末を汚さない

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path == "/":
            body = render_page()
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
        elif parsed.path == "/img":
            qs = urllib.parse.parse_qs(parsed.query)
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
        elif parsed.path == "/select":
            qs = urllib.parse.parse_qs(parsed.query)
            try:
                path = safe_path(qs["name"][0])
            except (KeyError, ValueError):
                self.send_error(404)
                return
            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.end_headers()
            self.wfile.write(b"ok")
            # レスポンスを返してから適用する (ブラウザ側の待機体験を優先)。
            # 適用完了後にサーバごと終了する (このピッカーは1回選んだら役目を終える)。
            threading.Thread(target=self._apply_and_exit, args=(path,), daemon=True).start()
        else:
            self.send_error(404)

    def _apply_and_exit(self, path: str):
        apply_wallpaper(path)
        threading.Timer(1.5, lambda: os._exit(0)).start()


def main():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind(("127.0.0.1", 0))
        port = s.getsockname()[1]
    server = http.server.ThreadingHTTPServer(("127.0.0.1", port), Handler)
    print(port, flush=True)
    server.serve_forever()


if __name__ == "__main__":
    sys.exit(main())
