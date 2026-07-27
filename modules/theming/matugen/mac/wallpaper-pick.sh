#!/usr/bin/env bash
# =========================================================================
# wallpaper-pick (mac) — fzfで壁紙画像をプレビューしながら選び、即座に
# デスクトップ壁紙とmatugen配色(WezTerm/nvim/yazi/starship/...とAeroSpace枠線)
# へ反映する。WSL版 (modules/theming/matugen/wsl/wallpaper-pick.sh) のMac版。
# =========================================================================
set -euo pipefail

export PATH="/etc/profiles/per-user/$USER/bin:$HOME/.nix-profile/bin:/opt/homebrew/bin:$PATH"

WALLPAPER_DIR="${MATUGEN_WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}"
mkdir -p "$WALLPAPER_DIR"

# 普段のシェル(zsh)と同じ見た目にする。functions.zsh と同じ順で
# 静的フォールバック→matugenキャッシュ(あれば上書き)のFZF_DEFAULT_OPTSを読む。
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --highlight-line --color=pointer:#a2c9fd,marker:#a2c9fd,prompt:#a2c9fd,info:#bbc7db,hl:#bbc7db,hl+:#bbc7db,bg+:#303030'
[[ -f "$HOME/.cache/matugen/fzf-colors.sh" ]] && source "$HOME/.cache/matugen/fzf-colors.sh"

# WezTerm imgcat (実画像) はfzfのプレビュー再描画でエスケープシーケンスが
# 崩れて表示されないことがあるため使わず、再描画に強いchafaのシンボル
# (テキストブロック) 表示に固定する。
PREVIEW='chafa --format symbols --size=60x30 {} 2>/dev/null || echo "(no preview)"'

sel="$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \
        \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.heic' -o -iname '*.bmp' \) \
        | sort |
      fzf --preview "$PREVIEW" --preview-window='right:60%' \
          --prompt='wallpaper> ' --height=100% --border \
          --header='TAB/矢印: 移動, ENTER: 決定 (即座に配色反映), ESC: キャンセル')" || exit 0
[[ -n "$sel" ]] || exit 0

# macOSの壁紙をすべてのデスクトップ(スペース)に設定する
osascript -e "tell application \"System Events\" to tell every desktop to set picture to (POSIX file \"$sel\")"

# 配色一式 (WezTerm/nvim/yazi/starship/lazygit/btop/eza/fzf/AeroSpace枠線) を追従
"$HOME/.local/bin/matugen-apply" "$sel"
