#!/usr/bin/env python3
"""Suggest wallpaper accent colors closer to human visual impression.

matugen (Material Color Utilities) picks colors by pixel population, so a
small-but-eye-catching region (e.g. a deep green cushion against a gray
wall) can be missed entirely. This script ranks quantized candidate colors
by a saliency score combining three perceptual signals:

  1. Global color contrast (Cheng et al. 2015): how different a color is
     from the rest of the image, weighted by each other color's frequency.
     Distance uses CIEDE2000, the standard perceptual color-difference
     formula (properly de-emphasizes pure lightness/shadow contrast
     compared to naive Euclidean Lab distance).
  2. Chroma: near-neutral colors (grays, shadows, blown highlights) are
     penalized, since "impressive" colors are usually saturated ones.
  3. Spatial compactness: colors scattered as isolated noise pixels across
     the frame are penalized relative to colors forming a coherent region
     (a real object), using the pixel coordinates from quantization.

Dependencies: ImageMagick (convert) + Python stdlib only.
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
    xn, yn, zn = x / 0.95047, y / 1.0, z / 1.08883

    def f(t: float) -> float:
        return t ** (1 / 3) if t > 0.008856 else (7.787 * t + 16 / 116)

    fx, fy, fz = f(xn), f(yn), f(zn)
    L = 116 * fy - 16
    a = 500 * (fx - fy)
    b_ = 200 * (fy - fz)
    return L, a, b_


def ciede2000(lab1: tuple[float, float, float], lab2: tuple[float, float, float]) -> float:
    """CIEDE2000 perceptual color difference (standard reference formula)."""
    L1, a1, b1 = lab1
    L2, a2, b2 = lab2

    kL = kC = kH = 1.0
    C1 = math.hypot(a1, b1)
    C2 = math.hypot(a2, b2)
    Cbar = (C1 + C2) / 2

    G = 0.5 * (1 - math.sqrt(Cbar ** 7 / (Cbar ** 7 + 25 ** 7))) if Cbar > 0 else 0
    a1p = a1 * (1 + G)
    a2p = a2 * (1 + G)
    C1p = math.hypot(a1p, b1)
    C2p = math.hypot(a2p, b2)

    def hue_angle(ap: float, b: float) -> float:
        if ap == 0 and b == 0:
            return 0.0
        h = math.degrees(math.atan2(b, ap))
        return h + 360 if h < 0 else h

    h1p = hue_angle(a1p, b1)
    h2p = hue_angle(a2p, b2)

    dLp = L2 - L1
    dCp = C2p - C1p

    if C1p * C2p == 0:
        dhp = 0.0
    elif abs(h2p - h1p) <= 180:
        dhp = h2p - h1p
    elif h2p - h1p > 180:
        dhp = h2p - h1p - 360
    else:
        dhp = h2p - h1p + 360
    dHp = 2 * math.sqrt(C1p * C2p) * math.sin(math.radians(dhp) / 2)

    Lbarp = (L1 + L2) / 2
    Cbarp = (C1p + C2p) / 2

    if C1p * C2p == 0:
        hbarp = h1p + h2p
    elif abs(h1p - h2p) <= 180:
        hbarp = (h1p + h2p) / 2
    elif h1p + h2p < 360:
        hbarp = (h1p + h2p + 360) / 2
    else:
        hbarp = (h1p + h2p - 360) / 2

    T = (1 - 0.17 * math.cos(math.radians(hbarp - 30))
         + 0.24 * math.cos(math.radians(2 * hbarp))
         + 0.32 * math.cos(math.radians(3 * hbarp + 6))
         - 0.20 * math.cos(math.radians(4 * hbarp - 63)))

    d_theta = 30 * math.exp(-(((hbarp - 275) / 25) ** 2))
    Rc = 2 * math.sqrt(Cbarp ** 7 / (Cbarp ** 7 + 25 ** 7)) if Cbarp > 0 else 0
    Sl = 1 + (0.015 * (Lbarp - 50) ** 2) / math.sqrt(20 + (Lbarp - 50) ** 2)
    Sc = 1 + 0.045 * Cbarp
    Sh = 1 + 0.015 * Cbarp * T
    Rt = -math.sin(math.radians(2 * d_theta)) * Rc

    return math.sqrt(
        (dLp / (kL * Sl)) ** 2
        + (dCp / (kC * Sc)) ** 2
        + (dHp / (kH * Sh)) ** 2
        + Rt * (dCp / (kC * Sc)) * (dHp / (kH * Sh))
    )


def quantized_pixels(image_path: str, colors: int = 48, size: int = 150) -> list[tuple[int, int, int, int]]:
    """Downsample + posterize via ImageMagick, return (x, y, rgb) pixels (parsed from txt: format).

    -sample (nearest-neighbor) instead of -resize (filtered/interpolated) is used:
    it's 2-3x faster on large wallpapers (no convolution), and as a bonus it doesn't
    blend small regions into their surroundings, which better preserves the true
    color of small-but-salient objects.
    """
    out = subprocess.run(
        [
            "convert", image_path,
            "-sample", f"{size}x{size}",
            "+dither", "-colors", str(colors),
            "txt:-",
        ],
        capture_output=True, text=True, check=True,
    ).stdout
    pixels = []
    for line in out.splitlines():
        if line.startswith("#"):
            continue
        # e.g. "12,34: (155,164,175)  #9CA4AF  srgb(...)"
        try:
            coord, rest = line.split(":", 1)
            x, y = (int(v) for v in coord.split(","))
            rgb_part = rest.split("(", 1)[1].split(")", 1)[0]
            r, g, b = (int(float(v)) for v in rgb_part.split(","))
            pixels.append((x, y, r, g, b))
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
        print("error: could not read pixels from image", file=sys.stderr)
        return 1

    total = len(pixels)
    max_x = max(p[0] for p in pixels) or 1
    max_y = max(p[1] for p in pixels) or 1
    diag = math.hypot(max_x, max_y)

    freq: dict[tuple[int, int, int], int] = {}
    positions: dict[tuple[int, int, int], list[tuple[int, int]]] = {}
    for x, y, r, g, b in pixels:
        c = (r, g, b)
        freq[c] = freq.get(c, 0) + 1
        positions.setdefault(c, []).append((x, y))

    # Drop noise-level colors (<0.5% of pixels), but keep the full set for
    # the "background" side of the global-contrast distance sum
    min_count = max(1, int(total * 0.005))
    all_colors = {c: n for c, n in freq.items() if n >= min_count}
    lab_cache = {c: rgb_to_lab(*c) for c in all_colors}

    def chroma(c: tuple[int, int, int]) -> float:
        _, a, b = lab_cache[c]
        return math.hypot(a, b)

    def compactness(c: tuple[int, int, int]) -> float:
        """1.0 = pixels tightly clustered (a real object), ~0 = scattered noise."""
        pts = positions[c]
        if len(pts) < 2:
            return 1.0
        mx = sum(p[0] for p in pts) / len(pts)
        my = sum(p[1] for p in pts) / len(pts)
        spread = math.sqrt(sum((p[0] - mx) ** 2 + (p[1] - my) ** 2 for p in pts) / len(pts))
        return 1.0 / (1.0 + spread / diag * 4)

    scores = []
    for c, n in all_colors.items():
        contrast = sum(
            (on / total) * ciede2000(lab_cache[c], lab_cache[other])
            for other, on in all_colors.items() if other != c
        )
        score = contrast * (chroma(c) ** 2) * compactness(c)
        scores.append((score, c, n / total))

    scores.sort(key=lambda t: t[0], reverse=True)

    print(f"{'RANK':<6}{'HEX':<10}{'AREA%':<8}{'SCORE':<10}PREVIEW")
    for i, (score, (r, g, b), area) in enumerate(scores[:top_n], start=1):
        hexcode = f"#{r:02X}{g:02X}{b:02X}"
        swatch = f"\033[48;2;{r};{g};{b}m    \033[0m"
        print(f"{i:<6}{hexcode:<10}{area * 100:<8.1f}{score:<10.1f}{swatch}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
