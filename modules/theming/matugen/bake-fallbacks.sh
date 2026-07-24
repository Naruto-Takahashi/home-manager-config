#!/usr/bin/env bash
# =========================================================================
# bake-fallbacks.sh — 今の壁紙色をリポジトリの全フォールバック箇所へ焼き込む
# =========================================================================
# matugenキャッシュ (~/.cache/matugen/colors.lua, yasb-palette.css) が
# 無い環境 (初回起動・Linuxデスクトップ/mac等) では、各アプリはリポジトリに
# committed されたフォールバック配色を使う。壁紙を変えるたびにこの
# フォールバックが古いまま (=見た目が浮く) になりがちなので、このスクリプトで
# 「今のキャッシュ値」を全フォールバック箇所へ一括反映する。
#
# 使い方:
#   1. 壁紙ピッカー等で普段通り壁紙を変更する (matugen-apply が実行される)
#   2. このリポジトリのルートで: ./modules/theming/matugen/bake-fallbacks.sh
#   3. git diff で見た目を確認して commit
#
# 新しいアプリのフォールバックを追加する場合は、対応する bake_* 関数を追加し、
# main の最後で呼び出すこと。role→変数名の対応は matugen-apply.sh の
# 各セクション (komorebi/cava 等) と揃えること。
set -euo pipefail

# `sed -i` はGNU/BSDで引数の取り方が違う (BSDは-iの直後をバックアップ拡張子
# として消費するため、`sed -i -E` と書くと`-E`が拡張子として食われてしまい
# 通常のBRE解釈に落ちる)。一時ファイル経由の置換に統一して両OSで揃える。
sedi() {
  local file="${*: -1}"
  local tmp; tmp="$(mktemp)"
  sed "${@:1:$(($#-1))}" "$file" > "$tmp" && mv "$tmp" "$file"
}

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CACHE="$HOME/.cache/matugen/colors.lua"
YASB_CACHE="$HOME/.cache/matugen/yasb-palette.css"

[[ -f "$CACHE" ]] || { echo "エラー: $CACHE が無い (先に壁紙を設定してmatugen-applyを実行すること)" >&2; exit 1; }

# --- colors.lua から12キーを読む ---
lua_val() { grep -m1 "^\s*$1\s*=" "$CACHE" | grep -oE '#[0-9a-fA-F]{6}'; }
accent="$(lua_val accent)"
tertiary="$(lua_val tertiary)"
secondary="$(lua_val secondary)"
complement="$(lua_val complement)"
triad="$(lua_val triad)"
text="$(lua_val text)"
muted="$(lua_val muted)"
surface="$(lua_val surface)"
on_accent="$(lua_val on_accent)"
accent_pale="$(lua_val accent_pale)"
error="$(lua_val error)"
# shellcheck disable=SC2034  # sub_kv() 内で ${!var} 間接参照により使われる
selection_bg="$(lua_val selection_bg)"

for v in accent tertiary secondary complement triad text muted surface on_accent accent_pale error selection_bg; do
  [[ -n "${!v}" ]] || { echo "エラー: $CACHE から $v を読み取れなかった" >&2; exit 1; }
done

echo "現在のパレット:"
for v in accent tertiary secondary complement triad text muted surface on_accent accent_pale error selection_bg; do
  printf '  %-12s %s\n' "$v" "${!v}"
done

# --- 汎用ヘルパ: ファイル内の `key = "#hex"` (Lua/TOML共通の書式) を置換 ---
# 引数: ファイル キー1=変数名1 キー2=変数名2 ...
sub_kv() {
  local file="$1"; shift
  local pair key var
  for pair in "$@"; do
    key="${pair%%=*}"
    var="${pair#*=}"
    sedi -E "s/^(\s*${key}\s*=\s*)\"#[0-9a-fA-F]{6}\"/\1\"${!var}\"/" "$file"
  done
}

bake_nvim() {
  local f="$REPO_ROOT/modules/apps/neovim/nvim/lua/matugen.lua"
  sub_kv "$f" accent=accent tertiary=tertiary secondary=secondary complement=complement \
    triad=triad text=text muted=muted surface=surface on_accent=on_accent \
    accent_pale=accent_pale error=error selection_bg=selection_bg
  echo "✓ nvim/matugen.lua"
}

bake_wezterm() {
  local f="$REPO_ROOT/modules/apps/wezterm/wezterm.lua"
  sub_kv "$f" accent=accent tertiary=tertiary secondary=secondary complement=complement \
    triad=triad text=text muted=muted surface=surface on_accent=on_accent \
    accent_pale=accent_pale error=error
  echo "✓ wezterm/wezterm.lua"
}

bake_yazi_pal() {
  local f="$REPO_ROOT/modules/apps/yazi/init.lua"
  sub_kv "$f" accent=accent tertiary=tertiary secondary=secondary complement=complement \
    triad=triad text=text muted=muted surface=surface on_accent=on_accent \
    accent_pale=accent_pale error=error
  echo "✓ yazi/init.lua"
}

bake_yazi_template() {
  # theme-template.toml は本来@@PLACEHOLDER@@のみのはずだが、過去に生の色が
  # 紛れ込んだ実績があるため、念のためチェックする
  local f="$REPO_ROOT/modules/apps/yazi/theme-template.toml"
  if grep -qE '"#[0-9a-fA-F]{6}"' "$f"; then
    echo "⚠ yazi/theme-template.toml に生の色コードが残っている (プレースホルダー化すべき):" >&2
    grep -nE '"#[0-9a-fA-F]{6}"' "$f" >&2
  fi
}

bake_starship() {
  local f="$REPO_ROOT/modules/shell/starship/starship.toml"
  sedi -E \
    -e "s/^(accent = )\"#[0-9a-fA-F]{6}\"/\1\"${accent}\"/" \
    -e "s/^(accent_pale = )\"#[0-9a-fA-F]{6}\"/\1\"${accent_pale}\"/" \
    -e "s/^(tertiary = )\"#[0-9a-fA-F]{6}\"/\1\"${tertiary}\"/" \
    -e "s/^(secondary = )\"#[0-9a-fA-F]{6}\"/\1\"${secondary}\"/" \
    -e "s/^(muted = )\"#[0-9a-fA-F]{6}\"/\1\"${muted}\"/" \
    -e "s/^(dark = )\"#[0-9a-fA-F]{6}\"/\1\"${surface}\"/" \
    -e "s/^(on_accent = )\"#[0-9a-fA-F]{6}\"/\1\"${on_accent}\"/" \
    "$f"
  echo "✓ shell/starship/starship.toml"
}

bake_atuin() {
  local f="$REPO_ROOT/modules/theming/matugen/fallbacks/atuin-theme.toml"
  sedi -E \
    -e "s/^(Base = )\"#[0-9a-fA-F]{6}\"/\1\"${text}\"/" \
    -e "s/^(Title = )\"#[0-9a-fA-F]{6}\"/\1\"${accent}\"/" \
    -e "s/^(Important = )\"#[0-9a-fA-F]{6}\"/\1\"${accent}\"/" \
    -e "s/^(Annotation = )\"#[0-9a-fA-F]{6}\"/\1\"${tertiary}\"/" \
    -e "s/^(Guidance = )\"#[0-9a-fA-F]{6}\"/\1\"${tertiary}\"/" \
    -e "s/^(Muted = )\"#[0-9a-fA-F]{6}\"/\1\"${muted}\"/" \
    -e "s/^(AlertWarn = )\"#[0-9a-fA-F]{6}\"/\1\"${secondary}\"/" \
    "$f"
  # AlertInfo/AlertError は固定の成功/失敗セマンティックカラーなので触らない
  echo "✓ matugen/fallbacks/atuin-theme.toml"
}

bake_btop() {
  local f="$REPO_ROOT/modules/theming/matugen/fallbacks/btop.theme"
  sedi -E \
    -e "s/(theme\[main_bg\]=)\"#[0-9a-fA-F]{6}\"/\1\"${surface}\"/" \
    -e "s/(theme\[main_fg\]=)\"#[0-9a-fA-F]{6}\"/\1\"${text}\"/" \
    -e "s/(theme\[title\]=)\"#[0-9a-fA-F]{6}\"/\1\"${text}\"/" \
    -e "s/(theme\[hi_fg\]=)\"#[0-9a-fA-F]{6}\"/\1\"${accent}\"/" \
    -e "s/(theme\[selected_bg\]=)\"#[0-9a-fA-F]{6}\"/\1\"${accent}\"/" \
    -e "s/(theme\[selected_fg\]=)\"#[0-9a-fA-F]{6}\"/\1\"${on_accent}\"/" \
    -e "s/(theme\[inactive_fg\]=)\"#[0-9a-fA-F]{6}\"/\1\"${muted}\"/" \
    -e "s/(theme\[graph_text\]=)\"#[0-9a-fA-F]{6}\"/\1\"${muted}\"/" \
    -e "s/(theme\[meter_bg\]=)\"#[0-9a-fA-F]{6}\"/\1\"${surface}\"/" \
    -e "s/(theme\[div_line\]=)\"#[0-9a-fA-F]{6}\"/\1\"${muted}\"/" \
    -e "s/(theme\[(proc_misc|cpu_box|cached_start|process_start)\]=)\"#[0-9a-fA-F]{6}\"/\1\"${tertiary}\"/" \
    -e "s/(theme\[(mem_box|temp_start|cpu_start|free_start|used_start)\]=)\"#[0-9a-fA-F]{6}\"/\1\"${triad}\"/" \
    -e "s/(theme\[(net_box|download_start)\]=)\"#[0-9a-fA-F]{6}\"/\1\"${complement}\"/" \
    -e "s/(theme\[(proc_box|upload_start)\]=)\"#[0-9a-fA-F]{6}\"/\1\"${secondary}\"/" \
    -e "s/(theme\[(temp_mid|cpu_mid|available_start|used_mid|process_mid)\]=)\"#[0-9a-fA-F]{6}\"/\1\"${accent}\"/" \
    -e "s/(theme\[(temp_end|cpu_end|used_end|process_end)\]=)\"#[0-9a-fA-F]{6}\"/\1\"${error}\"/" \
    "$f"
  echo "✓ matugen/fallbacks/btop.theme"
}

bake_eza() {
  local f="$REPO_ROOT/modules/apps/eza/theme.yml"
  # 拡張子グループごとのrole (directory=secondary, ドキュメント系=tertiary,
  # スクリプト/メディア系=complement, Web/データ系=triad, コンパイル言語/
  # アーカイブ=error) は modules/theming/matugen/templates/eza-theme.yml の
  # コメント割当に準拠。各ロールの「現在ファイル中の色」をコメント直後の
  # 最初の色コードから検出し、そのロールの新しい値へ一括置換する
  local cur
  cur="$(grep -m1 'directory:' "$f" | grep -oE '#[0-9a-fA-F]{6}')"
  [[ -n "$cur" ]] && sedi "s/${cur}/${secondary}/g" "$f"
  cur="$(grep -A1 -m1 'ドキュメント・テキスト・インフラ系' "$f" | grep -oE '#[0-9a-fA-F]{6}' | head -1)"
  [[ -n "$cur" ]] && sedi "s/${cur}/${tertiary}/g" "$f"
  cur="$(grep -A1 -m1 'スクリプト・メディア系' "$f" | grep -oE '#[0-9a-fA-F]{6}' | head -1)"
  [[ -n "$cur" ]] && sedi "s/${cur}/${complement}/g" "$f"
  cur="$(grep -A1 -m1 'Web・データ系' "$f" | grep -oE '#[0-9a-fA-F]{6}' | head -1)"
  [[ -n "$cur" ]] && sedi "s/${cur}/${triad}/g" "$f"
  cur="$(grep -A1 -m1 'コンパイル言語・アーカイブ' "$f" | grep -oE '#[0-9a-fA-F]{6}' | head -1)"
  [[ -n "$cur" ]] && sedi "s/${cur}/${error}/g" "$f"
  echo "✓ apps/eza/theme.yml"
}

bake_lazygit() {
  local f="$REPO_ROOT/modules/apps/lazygit/default.nix"
  sedi -E \
    -e "s/(activeBorderColor = \[ )\"#[0-9a-fA-F]{6}\"/\1\"${accent}\"/" \
    -e "s/(inactiveBorderColor = \[ )\"#[0-9a-fA-F]{6}\"/\1\"${muted}\"/" \
    -e "s/(searchingActiveBorderColor = \[ )\"#[0-9a-fA-F]{6}\"/\1\"${tertiary}\"/" \
    -e "s/(optionsTextColor = \[ )\"#[0-9a-fA-F]{6}\"/\1\"${tertiary}\"/" \
    -e "s/(selectedLineBgColor = \[ )\"#[0-9a-fA-F]{6}\"/\1\"${surface}\"/" \
    -e "s/(cherryPickedCommitBgColor = \[ )\"#[0-9a-fA-F]{6}\"/\1\"${surface}\"/" \
    -e "s/(cherryPickedCommitFgColor = \[ )\"#[0-9a-fA-F]{6}\"/\1\"${complement}\"/" \
    -e "s/(unstagedChangesColor = \[ )\"#[0-9a-fA-F]{6}\"/\1\"${error}\"/" \
    -e "s/(defaultFgColor = \[ )\"#[0-9a-fA-F]{6}\"/\1\"${text}\"/" \
    "$f"
  echo "✓ apps/lazygit/default.nix"
}

bake_cz() {
  local f="$REPO_ROOT/modules/apps/git-hooks/cz.toml"
  sedi -E \
    -e "s/(\[\"(qmark|answer|pointer|highlighted)\", \"fg:)#[0-9a-fA-F]{6}( bold\"\])/\1${accent}\3/" \
    -e "s/(\[\"selected\", \"fg:)#[0-9a-fA-F]{6}(\"\])/\1${tertiary}\2/" \
    -e "s/(\[\"separator\", \"fg:)#[0-9a-fA-F]{6}(\"\])/\1${secondary}\2/" \
    -e "s/(\[\"disabled\", \"fg:)#[0-9a-fA-F]{6}( italic\"\])/\1${muted}\2/" \
    "$f"
  echo "✓ apps/git-hooks/cz.toml"
}

bake_komorebi() {
  local f="$REPO_ROOT/modules/wm/komorebi/komorebi.json"
  local outline="${muted}" # matugen-apply.sh実行時のoutline(subtext0)相当。近似値としてmutedを使う
  sedi -E \
    -e "s/(\"single\": *)\"#[0-9a-fA-F]{6}\"/\1\"${accent}\"/" \
    -e "s/(\"floating\": *)\"#[0-9a-fA-F]{6}\"/\1\"${accent}\"/" \
    -e "s/(\"monocle\": *)\"#[0-9a-fA-F]{6}\"/\1\"${tertiary}\"/" \
    -e "s/(\"unfocused\": *)\"#[0-9a-fA-F]{6}\"/\1\"${outline}\"/" \
    "$f"
  echo "✓ wm/komorebi/komorebi.json"
}

bake_yasb_cava() {
  local f="$REPO_ROOT/modules/wm/yasb/config.yaml"
  sedi -E \
    -e "s/(foreground: \")#[0-9a-fA-F]{6}/\1${tertiary}/" \
    -e "s/(gradient_color_1: ')#[0-9a-fA-F]{6}/\1${tertiary}/" \
    -e "s/(gradient_color_2: ')#[0-9a-fA-F]{6}/\1${tertiary}/" \
    -e "s/(gradient_color_3: ')#[0-9a-fA-F]{6}/\1${accent}/" \
    "$f"
  echo "✓ wm/yasb/config.yaml (cava)"
}

bake_yasb_styles() {
  # MATUGEN:START..END ブロックは yasb-palette.css をそのまま丸ごと差し替える
  # (matugen-apply.sh のsection3と同じロジック)
  local f="$REPO_ROOT/modules/wm/yasb/styles.css"
  [[ -f "$YASB_CACHE" ]] || { echo "⚠ $YASB_CACHE が無いためyasb/styles.cssはスキップ" >&2; return; }
  local tmp; tmp="$(mktemp)"
  awk -v pal="$YASB_CACHE" '
    /\/\* MATUGEN:START \*\// { print; while ((getline line < pal) > 0) print line; skip=1; next }
    /\/\* MATUGEN:END \*\//   { skip=0 }
    !skip
  ' "$f" > "$tmp"
  mv "$tmp" "$f"
  # ルート変数ブロック外にある壁紙ギャラリーの背景(surface系)も合わせる
  sedi -E \
    -e "s/(background-color: )#[0-9a-fA-F]{6};(\s*$)/\1${surface};\2/" \
    "$f"
  echo "✓ wm/yasb/styles.css"
}

bake_functions_zsh() {
  local f="$REPO_ROOT/modules/shell/zsh/functions.zsh"
  sedi -E \
    -e "s/(pointer:)#[0-9a-fA-F]{6}/\1${accent}/" \
    -e "s/(marker:)#[0-9a-fA-F]{6}/\1${accent}/" \
    -e "s/(prompt:)#[0-9a-fA-F]{6}/\1${accent}/" \
    -e "s/(info:)#[0-9a-fA-F]{6}/\1${secondary}/" \
    -e "s/(hl:)#[0-9a-fA-F]{6}/\1${secondary}/" \
    -e "s/(hl\+:)#[0-9a-fA-F]{6}/\1${secondary}/" \
    "$f"
  echo "✓ shell/zsh/functions.zsh (FZF_DEFAULT_OPTS)"
}

bake_base_nix_tealdeer() {
  local f="$REPO_ROOT/profiles/base.nix"
  python3 - "$f" "$text" "$accent" "$muted" "$tertiary" "$secondary" << 'PYEOF'
import re, sys
f, text, accent, muted, tertiary, secondary = sys.argv[1:7]

def hex_to_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

roles = {
    "text": text,
    "accent": accent,
    "muted": muted,
    "tertiary": tertiary,
    "secondary": secondary,
}
with open(f, encoding="utf-8") as fh:
    content = fh.read()

for role, hexval in roles.items():
    r, g, b = hex_to_rgb(hexval)
    # `# text #xxxxxx` のようなコメント直後の行にある rgb = { r = ..; g = ..; b = ..; }; を置換
    pattern = re.compile(
        r'(rgb = \{ r = )\d+(; g = )\d+(; b = )\d+(; \};\s*# ' + role + r' )#[0-9a-fA-F]{6}'
    )
    content = pattern.sub(lambda m: f"{m.group(1)}{r}{m.group(2)}{g}{m.group(3)}{b}{m.group(4)}#{hexval.lstrip('#')}", content)

with open(f, "w", encoding="utf-8") as fh:
    fh.write(content)
PYEOF
  echo "✓ profiles/base.nix (tealdeer)"
}

bake_matugen_apply_safety_net() {
  local f="$REPO_ROOT/modules/theming/matugen/wsl/matugen-apply.sh"
  sedi -E \
    -e "s/(accent_pale=)\"#[0-9a-fA-F]{6}\"/\1\"${accent_pale}\"/" \
    -e "s/(complement=)\"#[0-9a-fA-F]{6}\"/\1\"${complement}\"/" \
    -e "s/(triad=)\"#[0-9a-fA-F]{6}\"/\1\"${triad}\"/" \
    -e "s/(error=)\"#[0-9a-fA-F]{6}\"/\1\"${error}\"/" \
    -e "s/(outline=)\"#[0-9a-fA-F]{6}\"/\1\"${muted}\"/" \
    "$f"
  echo "✓ matugen/wsl/matugen-apply.sh (derive失敗時セーフティネット)"
}

main() {
  bake_nvim
  bake_wezterm
  bake_yazi_pal
  bake_yazi_template
  bake_starship
  bake_atuin
  bake_btop
  bake_eza
  bake_lazygit
  bake_cz
  bake_komorebi
  bake_yasb_cava
  bake_yasb_styles
  bake_functions_zsh
  bake_base_nix_tealdeer
  bake_matugen_apply_safety_net
  echo
  echo "完了。git diff で結果を確認してください。"
}

main "$@"
