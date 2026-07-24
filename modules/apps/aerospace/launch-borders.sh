#!/usr/bin/env bash
# =========================================================================
# aerospace-launch-borders — JankyBorders (borders) をmatugenパレットの
# accent/muted色で(再)起動する。
# =========================================================================
# matugenキャッシュ (~/.cache/matugen/colors.lua) があればそこから
# accent/muted を読み、無ければWSL側のフォールバック(青ベース)と同じ色を使う。
# AeroSpaceのafter-startup-commandと、matugen-apply (mac) の両方から呼ばれる。
#
# borders は既に起動中のインスタンスがあれば、同じコマンドを再実行するだけで
# IPC経由で設定を生きたまま更新する (kill不要。killすると次のインスタンスが
# 上がるまでの一瞬、枠ハイライトが消える)。未起動なら通常通り新規起動する。
set -euo pipefail

COLORS="$HOME/.cache/matugen/colors.lua"
accent="a2c9fd"
muted="c3c6cf"

if [[ -f "$COLORS" ]]; then
    a="$(grep -m1 '^\s*accent\s*=' "$COLORS" | grep -oE '#[0-9a-fA-F]{6}' | tr -d '#' || true)"
    m="$(grep -m1 '^\s*muted\s*=' "$COLORS" | grep -oE '#[0-9a-fA-F]{6}' | tr -d '#' || true)"
    [[ -n "$a" ]] && accent="$a"
    [[ -n "$m" ]] && muted="$m"
fi

if pgrep -x borders >/dev/null 2>&1; then
    /opt/homebrew/bin/borders "active_color=0xff${accent}" "inactive_color=0xff${muted}" width=6.0
else
    /opt/homebrew/bin/borders "active_color=0xff${accent}" "inactive_color=0xff${muted}" width=6.0 &
    disown
fi
