#!/usr/bin/env bash
# =========================================================================
# matugen-apply — 壁紙から matugen でパレットを抽出し、各アプリへ展開する
# =========================================================================
# 呼び出し:
#   matugen-apply <壁紙パス (win/wsl)>  YASB の wallpapers ウィジェット run_after から
#   matugen-apply --reapply             sync-win から (前回の壁紙でフル再生成)
#
# 全体の流れ (docs/matugen-palette.md も参照):
#   1. matugen がテンプレート palette.css から yasb-palette.css を生成する
#   2. 本スクリプトがそこからパレットを一度だけ抽出し、NixOS と共通の
#      modules/theming/matugen/lib/ (derive-colors.py / render-template.sh)
#      で派生色 (complement/triad/accent_pale) の計算とテンプレート
#      レンダリング (starship/lazygit/yazi) を行う
#   3. 各アプリ向けセクションが順に配色を展開する
set -euo pipefail

export PATH="$HOME/.nix-profile/bin:$PATH"

# Windows 側ユーザープロファイル (WSL から見たパス)。動的解決に失敗したら従来値
WIN_HOME="$(wslpath "$(cd /mnt/c && /mnt/c/Windows/System32/cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r')" 2>/dev/null || true)"
[[ -d "$WIN_HOME" ]] || WIN_HOME="/mnt/c/Users/tnaru"

# 多重起動ガード: 壁紙を素早く切り替えると run_after が並走し、
# 古いパレットのプロセスが後から生成物を上書きして世代が混ざるため直列化する
exec 9>"$HOME/.cache/matugen/.apply.lock"
flock 9

CACHE="$HOME/.cache/matugen/yasb-palette.css"

# -------------------------------------------------------------------------
# 1. 壁紙の決定と matugen 実行
# -------------------------------------------------------------------------
if [[ "${1:-}" != "--reapply" ]]; then
    img="${1:?usage: matugen-apply <image path (win or wsl)> | --reapply}"
    # Windowsパス (C:\...) で渡されたら WSL パスへ変換
    if [[ "$img" == *\\* || "$img" == [A-Za-z]:* ]]; then
        img="$(wslpath "$img")"
    fi
else
    # --reapply: 記録済みの壁紙があればそこから完全再生成 (テンプレート更新を反映するため)
    img=""
    [[ -f "$HOME/.cache/matugen/last-wallpaper" ]] && img="$(cat "$HOME/.cache/matugen/last-wallpaper")"
    [[ -f "$img" ]] || img=""
fi

if [[ -n "${img:-}" ]]; then
    # 手動オーバーライド (color-overrides.conf) があればそちらを優先する。
    # matugenの自動抽出は面積優先のため、面積が小さいが目立つ色 (例: クッションの
    # 深緑) を拾えないことがあり、それを人力で補正するための仕組み
    override_hex=""
    overrides_file="$HOME/.config/matugen-wsl/color-overrides.conf"
    if [[ -f "$overrides_file" ]]; then
        img_basename="$(basename "$img")"
        # 該当エントリが無い場合 grep は終了コード1を返し、pipefail 下では
        # スクリプト全体が異常終了してしまう (--source-color-index 0 の自動抽出に
        # フォールバックできず、壁紙を変えても配色が更新されない不具合になっていた)
        override_hex="$(grep -v '^\s*#' "$overrides_file" | grep "^${img_basename}=" | tail -n1 | cut -d= -f2- || true)"
    fi

    if [[ -n "$override_hex" ]]; then
        matugen color hex "$override_hex" -m dark \
            -c "$HOME/.config/matugen-wsl/config.toml"
    else
        # --source-color-index 0: 候補色の対話選択を回避し最有力色を自動採用 (非TTYで必須)
        matugen image "$img" -m dark --source-color-index 0 \
            -c "$HOME/.config/matugen-wsl/config.toml"
    fi
    printf '%s\n' "$img" > "$HOME/.cache/matugen/last-wallpaper"

    # ロック画面の壁紙もデスクトップと同じ画像に追従させる。
    # UWP の UserProfile.LockScreen API を PowerShell の WinRT 投影で呼ぶ
    # (管理者権限不要。Settings アプリと同じ経路)。画像パスは WSLENV の
    # /p フラグで Windows パスに自動変換して $env:LOCK_IMG として渡す。
    # スクリプト本体は -EncodedCommand で渡す (WSL 越しの stdin -Command - は
    # 実行されないため不可。AsTask はオーバーロード解決が効かないので
    # IAsyncOperation/IAsyncAction ともリフレクションで取得する)。
    ps_lockscreen='
      $ErrorActionPreference = "Stop"
      [Windows.System.UserProfile.LockScreen,Windows.System.UserProfile,ContentType=WindowsRuntime] | Out-Null
      [Windows.Storage.StorageFile,Windows.Storage,ContentType=WindowsRuntime] | Out-Null
      Add-Type -AssemblyName System.Runtime.WindowsRuntime
      $methods = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
          $_.Name -eq "AsTask" -and $_.GetParameters().Count -eq 1 }
      $asTaskOp     = ($methods | Where-Object { $_.GetParameters()[0].ParameterType.Name -eq ("IAsyncOperation" + [char]0x60 + "1") })[0]
      $asTaskAction = ($methods | Where-Object { $_.GetParameters()[0].ParameterType.Name -eq "IAsyncAction" })[0]
      $op = [Windows.Storage.StorageFile]::GetFileFromPathAsync($env:LOCK_IMG)
      $file = $asTaskOp.MakeGenericMethod([Windows.Storage.StorageFile]).Invoke($null, @($op)).GetAwaiter().GetResult()
      $asTaskAction.Invoke($null, @([Windows.System.UserProfile.LockScreen]::SetImageFileAsync($file))).GetAwaiter().GetResult() | Out-Null'
    WSLENV="LOCK_IMG/p:${WSLENV:-}" LOCK_IMG="$img" \
        /mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -NoProfile \
        -EncodedCommand "$(printf '%s' "$ps_lockscreen" | iconv -f UTF-8 -t UTF-16LE | base64 -w0)" \
        >/dev/null 2>&1 || true
fi

# -------------------------------------------------------------------------
# 2. パレット抽出 (ここで一度だけ。名前は docs/matugen-palette.md と対応)
# -------------------------------------------------------------------------
pal() { grep -m1 -- "--$1:" "$CACHE" 2>/dev/null | grep -oE '#[0-9a-fA-F]{6}' || true; }

# surfaceを白と少し混ぜた「背景に馴染む弱い色」を作る (fzfのbg+等、
# 選択行ハイライト用)。ターミナルの背景色に対して主張が弱く、
# かつ選択行の視認性は保てる程度の明度差を狙う。
blend_lighten() {
  local hex="$1" ratio="${2:-0.12}"
  python3 -c "
h = '$hex'.lstrip('#')
r, g, b = int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)
t = $ratio
r, g, b = (round(c + (255 - c) * t) for c in (r, g, b))
print(f'#{r:02x}{g:02x}{b:02x}')
"
}

# complement/triad/accent_pale の色相回転・白ブレンド計算は NixOS と共通
# (modules/theming/matugen/lib/derive-colors.py)。WSL のパレット抽出元
# (yasb-palette.css の CSS変数) は colors.lua と形式が違うため、抽出後に
# 一時 colors.lua を組み立てて渡す。
LIB="$HOME/.config/matugen-common/lib"

HAS_PALETTE=0
if [[ -f "$CACHE" ]]; then
    accent="$(pal highlight)"
    tertiary="$(pal accent-sub)"
    secondary="$(pal secondary)"
    text="$(pal text)"
    muted="$(pal subtext1)"
    surface="$(pal surface2)"
    on_accent="$(pal base)"
    error="$(pal red)"
    outline="$(pal subtext0)"
    if [[ -n "$accent" && -n "$tertiary" && -n "$secondary" && -n "$text" \
          && -n "$muted" && -n "$surface" && -n "$on_accent" ]]; then
        HAS_PALETTE=1
        base_lua="$(mktemp)"
        cat > "$base_lua" <<EOF
return {
  accent = "${accent}",
  tertiary = "${tertiary}",
  secondary = "${secondary}",
  text = "${text}",
  muted = "${muted}",
  surface = "${surface}",
  on_accent = "${on_accent}",
  error = "${error}",
}
EOF
        python3 "$LIB/derive-colors.py" "$base_lua"
        pal_lua() { grep -m1 "^\s*$1\s*=" "$base_lua" | grep -oE '#[0-9a-fA-F]{6}'; }
        complement="$(pal_lua complement)"
        triad="$(pal_lua triad)"
        accent_pale="$(pal_lua accent_pale)"
        rm -f "$base_lua"
        [[ -n "$accent_pale" ]] || accent_pale="#c7dffe"
        [[ -n "$complement" ]] || complement="#f2d4ad"
        [[ -n "$triad" ]] || triad="#f2adcb"
        [[ -n "$error" ]] || error="#ffb4ab"
        [[ -n "$outline" ]] || outline="#c3c6cf"
        # starshipのgit_branch表示と同じ色 (palettes.matugen の dark = 生のsurface)
        # の方が好まれたため、明るく混ぜずにsurfaceをそのまま使う。
        selection_bg="$surface"
    fi
fi

# -------------------------------------------------------------------------
# 3. YASB styles.css (MATUGEN マーカー間をパレットに差し替えて Windows へ配置)
# -------------------------------------------------------------------------
SRC="$HOME/.config/yasb/styles.css"
DEST="${WIN_HOME}/.config/yasb/styles.css"
if [[ -f "$CACHE" ]]; then
    awk -v pal="$CACHE" '
        /\/\* MATUGEN:START \*\// { print; while ((getline line < pal) > 0) print line; skip=1; next }
        /\/\* MATUGEN:END \*\//   { skip=0 }
        !skip
    ' "$SRC" > "$DEST"
else
    cp -L "$SRC" "$DEST"
fi

# 以降のセクションはパレットが揃っているときのみ実行する
if [[ "$HAS_PALETTE" == 1 ]]; then

# -------------------------------------------------------------------------
# 4. komorebi の枠色 (single/floating = accent, monocle = tertiary, unfocused = outline)
#    リロードは同期で済ませる。後段の cava (config.yaml 書き換え) が YASB の
#    全体リロードを誘発するため、komorebi のリロードと重なると YASB→komorebi
#    の named pipe 再購読が失敗し、ワークスペース表示が消える (競合の実績あり)。
# -------------------------------------------------------------------------
for f in "${WIN_HOME}/.config/komorebi/komorebi.json" "${WIN_HOME}/komorebi.json"; do
    [[ -f "$f" ]] && sed -i -E \
        -e "s/(\"single\": *\")#[0-9a-fA-F]{6}/\1${accent}/" \
        -e "s/(\"floating\": *\")#[0-9a-fA-F]{6}/\1${accent}/" \
        -e "s/(\"monocle\": *\")#[0-9a-fA-F]{6}/\1${tertiary}/" \
        -e "s/(\"unfocused\": *\")#[0-9a-fA-F]{6}/\1${outline}/" "$f"
done
"/mnt/c/Program Files/komorebi/bin/komorebic.exe" reload-configuration >/dev/null 2>&1 || true

# -------------------------------------------------------------------------
# 5. 共通 Lua パレット colors.lua (nvim / yazi / WezTerm が読む)
# -------------------------------------------------------------------------
lua_tmp="$(mktemp)"
cat > "$lua_tmp" <<LUA
-- Generated by matugen-apply (matugen) — do not edit
return {
  accent = "${accent}",
  tertiary = "${tertiary}",
  secondary = "${secondary}",
  complement = "${complement}",
  triad = "${triad}",
  text = "${text}",
  muted = "${muted}",
  surface = "${surface}",
  on_accent = "${on_accent}",
  accent_pale = "${accent_pale}",
  error = "${error}",
  selection_bg = "${selection_bg}",
}
LUA
command cp -f "$lua_tmp" "$HOME/.config/wezterm/matugen-colors.lua"
command cp -f "$lua_tmp" "${WIN_HOME}/.config/wezterm/matugen-colors.lua" 2>/dev/null || true
command cp -f "$lua_tmp" "$HOME/.cache/matugen/colors.lua"

# -------------------------------------------------------------------------
# 6. starship / 7. lazygit / 8. yazi theme.toml (NixOS と共通の
#    render-template.sh で @@プレースホルダ@@ テンプレートをレンダリング。
#    $lua_tmp を再利用する)
# -------------------------------------------------------------------------
TPL="$HOME/.config/matugen-common/templates"
STARSHIP_OUT="$HOME/.cache/matugen/starship.toml"
"$LIB/render-template.sh" "$TPL/starship.toml" "$STARSHIP_OUT" "$lua_tmp"
"$LIB/render-template.sh" "$TPL/lazygit-theme.yml" \
    "$HOME/.cache/matugen/lazygit-theme.yml" "$lua_tmp"
"$LIB/render-template.sh" "$TPL/cz.toml" \
    "$HOME/.cache/matugen/cz.toml" "$lua_tmp"
"$LIB/render-template.sh" "$HOME/.config/yazi/theme-template.toml" \
    "$HOME/.config/yazi/theme.toml" "$lua_tmp"
# eza (ls) のファイル種別配色。ファイル名は theme.yml 固定でないと
# eza に認識されないため専用ディレクトリに置く (EZA_CONFIG_DIR で参照、
# modules/shell/zsh/functions.zsh 参照)。
mkdir -p "$HOME/.cache/matugen/eza"
"$LIB/render-template.sh" "$TPL/eza-theme.yml" \
    "$HOME/.cache/matugen/eza/theme.yml" "$lua_tmp"

# tealdeer (tldr) の配色: tealdeer は "#hex" を受け付けず rgb {r,g,b} 形式が
# 必要なため専用スクリプトで生成する。zsh が TEALDEER_CONFIG_DIR でこちらを優先。
mkdir -p "$HOME/.cache/matugen/tealdeer"
python3 "$LIB/tealdeer-config.py" "$lua_tmp" "$HOME/.cache/matugen/tealdeer/config.toml"

# btop のテーマ (color_theme = "matugen" 固定で、このファイルの中身だけを
# 差し替える。フォールバック版は home-manager の activation が同パスへ配置)
mkdir -p "$HOME/.config/btop/themes"
"$LIB/render-template.sh" "$TPL/btop.theme" \
    "$HOME/.config/btop/themes/matugen.theme" "$lua_tmp"
rm -f "$lua_tmp"

# Windows (PowerShell) 向け starship 変種: custom.ssh_host は POSIX sh 依存で
# Windows では動かない (プロンプト遅延の原因) ため、静的な PS
# セグメントに置き換えて配置する
WIN_STARSHIP="${WIN_HOME}/.config/starship.toml"
awk '
    /^\$\{custom\.ssh_host\}\\$/ {
        print "[ PS ](fg:on_accent bg:secondary bold)[\xee\x82\xb0](fg:secondary bg:accent)\\"
        next
    }
    /^\[custom\.ssh_host\]/ { skip=1 }
    skip && /^\[username\]/ { skip=0 }
    !skip
' "$STARSHIP_OUT" > "${WIN_STARSHIP}.tmp" 2>/dev/null \
    && rm -f "$WIN_STARSHIP" \
    && mv "${WIN_STARSHIP}.tmp" "$WIN_STARSHIP" || true

# -------------------------------------------------------------------------
# 9. fzf (Ctrl+G の ghq ジャンプ等のハイライト配色。Material role のみで
#    完結するため NixOS 側も matugen ネイティブテンプレートのまま)
#    selection_bg は上のセクション2で計算済み
# -------------------------------------------------------------------------
cat > "$HOME/.cache/matugen/fzf-colors.sh.tmp" <<SH
# Generated by matugen-apply (matugen) — do not edit
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --highlight-line --color=pointer:${accent},marker:${accent},prompt:${accent},info:${tertiary},hl:${tertiary},hl+:${tertiary},bg+:${selection_bg},spinner:${tertiary}'
SH
mv "$HOME/.cache/matugen/fzf-colors.sh.tmp" "$HOME/.cache/matugen/fzf-colors.sh"

# -------------------------------------------------------------------------
# 10. cava (YASB config.yaml 内の波形色): tertiary 基調 + accent へのグラデーション
#     config.yaml の書き換えは YASB の watch_config が全体リロードを誘発する
#     ため、必ず最後に実行する (セクション4のコメント参照)
# -------------------------------------------------------------------------
cfg="${WIN_HOME}/.config/yasb/config.yaml"
if [[ -f "$cfg" ]]; then
    # 先に旧 cava を殺しておく (sed 後の自動リロードが新色で再起動する。
    # sed 後に kill すると再起動済みの新 cava を殺してしまう)
    "/mnt/c/Windows/System32/taskkill.exe" /IM cava.exe /F >/dev/null 2>&1 || true
    # sed -i は rename 置換で inode が変わり YASB の watch_config が
    # 外れるため、tmp に生成して同一 inode へ上書きする (truncate+write)
    cfg_tmp="$(mktemp)"
    sed -E \
        -e "s/(foreground: \")#[0-9a-fA-F]{6}/\1${tertiary}/" \
        -e "s/(gradient_color_1: ')#[0-9a-fA-F]{6}/\1${tertiary}/" \
        -e "s/(gradient_color_2: ')#[0-9a-fA-F]{6}/\1${tertiary}/" \
        -e "s/(gradient_color_3: ')#[0-9a-fA-F]{6}/\1${accent}/" "$cfg" > "$cfg_tmp"
    cat "$cfg_tmp" > "$cfg"
    rm -f "$cfg_tmp"
fi

fi  # HAS_PALETTE
