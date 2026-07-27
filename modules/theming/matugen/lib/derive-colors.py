#!/usr/bin/env python3
"""colors.lua に accent 由来の派生色 (complement/triad/accent_pale) を
追記する (冪等)。

WSL の matugen-apply.sh に元々あった計算式をそのまま移植したもの。
"""
import colorsys
import re
import sys


def rotate_hue(hex_color: str, amount: float) -> str:
    h = hex_color.lstrip("#")
    r, g, b = (int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))
    hh, l, s = colorsys.rgb_to_hls(r, g, b)
    r, g, b = colorsys.hls_to_rgb((hh + amount) % 1.0, l, s * 0.75)
    return "#%02x%02x%02x" % (round(r * 255), round(g * 255), round(b * 255))


def blend_white(hex_color: str, amount: float) -> str:
    h = hex_color.lstrip("#")
    r, g, b = (int(h[i:i + 2], 16) for i in (0, 2, 4))
    return "#%02x%02x%02x" % tuple(round(v + (255 - v) * amount) for v in (r, g, b))


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: derive-colors.py <colors.lua>", file=sys.stderr)
        return 1

    path = sys.argv[1]
    with open(path) as f:
        text = f.read()

    m = re.search(r'^\s*accent\s*=\s*"(#[0-9a-fA-F]{6})"', text, re.MULTILINE)
    if not m:
        print("accent key not found, skipping", file=sys.stderr)
        return 0
    accent = m.group(1)

    additions = []
    if not re.search(r"^\s*complement\s*=", text, re.MULTILINE):
        additions.append(f'  complement = "{rotate_hue(accent, 0.5)}",')
    if not re.search(r"^\s*triad\s*=", text, re.MULTILINE):
        additions.append(f'  triad = "{rotate_hue(accent, 0.3333333)}",')
    if not re.search(r"^\s*accent_pale\s*=", text, re.MULTILINE):
        additions.append(f'  accent_pale = "{blend_white(accent, 0.4)}",')
    if not re.search(r"^\s*selection_bg\s*=", text, re.MULTILINE):
        # fzf の選択行背景。surface をそのまま使う
        # (starship の git_branch 表示と同じ色に揃えるため)。
        sm = re.search(r'^\s*surface\s*=\s*"(#[0-9a-fA-F]{6})"', text, re.MULTILINE)
        if sm:
            additions.append(f'  selection_bg = "{sm.group(1)}",')

    if not additions:
        return 0

    text = re.sub(
        r'(^\s*tertiary\s*=\s*"#[0-9a-fA-F]{6}",)',
        lambda mo: mo.group(1) + "\n" + "\n".join(additions),
        text,
        count=1,
        flags=re.MULTILINE,
    )
    with open(path, "w") as f:
        f.write(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
