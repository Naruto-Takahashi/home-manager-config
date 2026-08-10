#!/usr/bin/env python3
"""壁紙から「人間の目に印象的な色」に近い候補を提案する。

matugen (Material Color Utilities) は基本的に画像内の面積 (出現頻度) が
多い色を優先して抽出するため、面積は小さいが視覚的にコントラストの強い
色 (例: グレーの壁を背景にした深緑のクッション) を拾えないことがある。

ここでは Cheng et al. (2015) の "global color contrast" に基づく
簡易的な顕著性 (saliency) スコアを使う:

    Sal(c) = Σ_i freq(c_i) * distance_Lab(c, c_i)   (i ≠ c)

画像全体に対して「他の色とどれだけ違うか」を頻度で重み付けして合計する。
背景を占める色 (グレーや空など) は互いに似ているためスコアが低く、
少数だが画像の主流から色相・彩度が離れた色 (=人間が目を引かれやすい色)
ほどスコアが高くなる。

依存は ImageMagick (convert) と Python 標準ライブラリのみ。
"""
import math
import subprocess
import sys


def srgb_to_linear(c: float) -> float:
    c /= 255.0
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def rgb_to_lab(r: int, g: int, b: int) -> tuple[float, float, float]:
    rl, gl, bl = srgb_to_linear(r), srgb_to_linear(g), srgb_to_linear(b)
    # sRGB -> XYZ (D65)
    x = rl * 0.4124 + gl * 0.3576 + bl * 0.1805
    y = rl * 0.2126 + gl * 0.7152 + bl * 0.0722
    z = rl * 0.0193 + gl * 0.1192 + bl * 0.9505
    # D65 白色点で正規化
    xn, yn, zn = x / 0.95047, y / 1.0, z / 1.08883

    def f(t: float) -> float:
        return t ** (1 / 3) if t > 0.008856 else (7.787 * t + 16 / 116)

    fx, fy, fz = f(xn), f(yn), f(zn)
    L = 116 * fy - 16
    a = 500 * (fx - fy)
    b_ = 200 * (fy - fz)
    return L, a, b_


# 明度 (L) の差は「影/ハイライト」のような構造的コントラストを過剰に
# 拾ってしまうため、色相・彩度 (a, b) の差に比べて重みを弱める。
# 人間が「印象的な色」と感じるのは主に色みの違いであり、単純な明暗差ではない
LIGHTNESS_WEIGHT = 0.3


def lab_distance(c1: tuple[float, float, float], c2: tuple[float, float, float]) -> float:
    dl = (c1[0] - c2[0]) * LIGHTNESS_WEIGHT
    da = c1[1] - c2[1]
    db = c1[2] - c2[2]
    return math.sqrt(dl * dl + da * da + db * db)


def quantized_pixels(image_path: str, colors: int = 32, size: int = 100) -> list[tuple[int, int, int]]:
    """ImageMagickでリサイズ+減色し、ピクセル列を返す (txt:形式をパース)"""
    out = subprocess.run(
        [
            "convert", image_path,
            "-resize", f"{size}x{size}",
            "+dither", "-colors", str(colors),
            "txt:-",
        ],
        capture_output=True, text=True, check=True,
    ).stdout
    pixels = []
    for line in out.splitlines():
        if line.startswith("#"):
            continue
        # 例: "0,0: (155,164,175)  #9CA4AF  srgb(...)"
        try:
            rgb_part = line.split("(", 1)[1].split(")", 1)[0]
            r, g, b = (int(float(v)) for v in rgb_part.split(","))
            pixels.append((r, g, b))
        except (IndexError, ValueError):
            continue
    return pixels


def main() -> int:
    if len(sys.argv) < 2:
        print("usage: suggest-accent.py <image path> [top_n]", file=sys.stderr)
        return 1
    image_path = sys.argv[1]
    top_n = int(sys.argv[2]) if len(sys.argv) > 2 else 5

    pixels = quantized_pixels(image_path)
    if not pixels:
        print("画像からピクセルを取得できませんでした", file=sys.stderr)
        return 1

    total = len(pixels)
    freq: dict[tuple[int, int, int], int] = {}
    for p in pixels:
        freq[p] = freq.get(p, 0) + 1

    # ノイズ的な極少数色 (0.5%未満) は除外する。ただし距離計算の「背景」
    # としては全色 (グレー・黒・白含む) を残す
    min_count = max(1, int(total * 0.005))
    all_colors = {c: n for c, n in freq.items() if n >= min_count}
    lab_cache = {c: rgb_to_lab(*c) for c in all_colors}

    candidates = all_colors

    # 影/黒つぶれのような「明度は違うが無彩色に近い」色が単純な加重距離の和では
    # 勝ってしまうため、その色自体の彩度 (a-b平面の原点からの距離) で
    # スコアを補正する。彩度が高いほど「色として印象的」という直感に合わせる
    def chroma(c: tuple[int, int, int]) -> float:
        _, a, b = lab_cache[c]
        return math.hypot(a, b)

    scores = []
    for c, n in candidates.items():
        sal = 0.0
        for other, on in all_colors.items():
            if other == c:
                continue
            sal += (on / total) * lab_distance(lab_cache[c], lab_cache[other])
        sal *= math.sqrt(chroma(c) + 1)
        scores.append((sal, c, n / total))

    scores.sort(key=lambda t: t[0], reverse=True)

    print(f"{'順位':<4}{'HEX':<10}{'面積%':<8}{'顕著性スコア':<10}{'プレビュー'}")
    for i, (sal, (r, g, b), area) in enumerate(scores[:top_n], start=1):
        hexcode = f"#{r:02X}{g:02X}{b:02X}"
        swatch = f"\033[48;2;{r};{g};{b}m    \033[0m"
        print(f"{i:<4}{hexcode:<10}{area * 100:<7.1f}{sal:<10.1f}{swatch}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
