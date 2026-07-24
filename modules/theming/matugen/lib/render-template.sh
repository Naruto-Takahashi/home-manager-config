#!/usr/bin/env bash
# 汎用 @@KEY@@ 置換エンジン。
# colors.lua の `key = "#hex"` 行を全部読み、テンプレート内の @@KEY@@
# (キー名を大文字化したもの) を置換して出力する。
set -euo pipefail

usage() { echo "usage: render-template.sh <template> <output> <colors.lua>" >&2; exit 1; }

TEMPLATE="${1:?}"; OUTPUT="${2:?}"; COLORS_LUA="${3:?}"
[[ -f "$TEMPLATE" ]] || { echo "template not found: $TEMPLATE" >&2; exit 1; }
[[ -f "$COLORS_LUA" ]] || { echo "colors.lua not found: $COLORS_LUA" >&2; exit 1; }

SED_ARGS=()
while IFS='=' read -r key value; do
    [[ -n "$key" ]] || continue
    upper="$(echo "$key" | tr '[:lower:]' '[:upper:]')"
    SED_ARGS+=(-e "s/@@${upper}@@/${value//\//\\/}/g")
done < <(grep -oE '^[[:space:]]*[a-z_]+[[:space:]]*=[[:space:]]*"#[0-9a-fA-F]{6}"' "$COLORS_LUA" \
    | sed -E 's/^[[:space:]]*([a-z_]+)[[:space:]]*=[[:space:]]*"(#[0-9a-fA-F]{6})"/\1=\2/')

[[ ${#SED_ARGS[@]} -gt 0 ]] || { echo "no colors parsed from $COLORS_LUA" >&2; exit 1; }

TMP="$(mktemp)"
sed "${SED_ARGS[@]}" "$TEMPLATE" > "$TMP"

if grep -q '@@[A-Z_]*@@' "$TMP"; then
    echo "warning: unresolved placeholders remain in $OUTPUT:" >&2
    grep -oE '@@[A-Z_]*@@' "$TMP" | sort -u >&2
fi

mv "$TMP" "$OUTPUT"
