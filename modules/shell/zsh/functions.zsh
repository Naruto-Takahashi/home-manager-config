# =========================================================================
# Zsh 追加設定 (環境変数・オプション・キーバインド・カスタム関数)
# =========================================================================
# modules/shell/zsh/default.nix の initContent から source される実ファイル。
# --- zsh-autosuggestions設定 ---
# zsh-autosuggestionsの検索を非同期化し，ラグをゼロにする設定です．
export ZSH_AUTOSUGGEST_USE_ASYNC="true"
# 入力文字数が1文字以下の場合はサジェスト探索をスキップします（空ENTER時のラグを完全にゼロにするため）．
export ZSH_AUTOSUGGEST_MIN_SIZE=2

# --- パスおよび環境変数設定 ---
# EDITOR/VISUAL未設定だとedit-command-line ('v'キー) 等がデフォルトの
# 最小構成vi/vimにフォールバックしてしまうため明示する。
# (NixOS/Darwinホストではprograms.neovim.defaultEditorが同じ値を設定するが，
#  standalone home-manager非対応ホスト向けにも常に有効にしておく)
export EDITOR="nvim"
export VISUAL="nvim"

# 外部ツールなどのパスを追加します．
export PATH="$HOME/.local/bin:$HOME/.fzf/bin:$PATH"
export CPLUS_INCLUDE_PATH=$CPLUS_INCLUDE_PATH:/home/nalt/lib/ac-library-master
export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:$HOME/go/bin

# LS_COLORSは撤去した (旧: 固定256色のファイル種別配色)。
# `ls`は実質常にeza (エイリアス+chpwd) を使うようになっており、
# eza自体の理論値(~/.config/eza/theme.yml、matugen環境では
# ~/.cache/matugen/eza/theme.yml、yaziと同じ配色)が優先されるべきところ、
# LS_COLORSが設定されているとdi(ディレクトリ)等の一部項目がそちらに
# 引っ張られてしまうため。

# --- シェルオプション設定 ---
# ディレクトリ移動（cdなしでの移動を許可）を有効化します．
setopt auto_cd

# 履歴保存オプションの追加拡張を設定します．
setopt EXTENDED_HISTORY
setopt HIST_SAVE_NO_DUPS
# HIST_REDUCE_BLANKS は行継続の "\" による改行も余分な空白とみなして
# 1行に詰めてしまい、履歴を遡ったときに複数行コマンドが潰れる原因になるため無効化
setopt HIST_FIND_NO_DUPS
setopt HIST_NO_STORE

# システムスタック制限の解除を行います（開発時等の安定化のため）．
ulimit -s unlimited

# --- 補完およびメニュー設定 ---
# 補完選択メニュー用モジュール（complist）をロードします．
zmodload zsh/complist

[ -f "$HOME/.cargo/env" ]  && . "$HOME/.cargo/env"

# 補完メニューの挙動最適化（大文字小文字の曖昧補完，カーソル選択）を設定します．
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' menu select

# --- fzf設定 ---
# fzfオプションおよびCtrl+T，Ctrl+Rのプレビュー表示を設定します．
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --highlight-line --color=pointer:#a2c9fd,marker:#a2c9fd,prompt:#a2c9fd,info:#bbc7db,hl:#bbc7db,hl+:#bbc7db,bg+:#303030,spinner:#bbc7db'
# matugen生成のfzf配色があれば上書きします（matugen-applyが生成します）．
[[ -f ~/.cache/matugen/fzf-colors.sh ]] && source ~/.cache/matugen/fzf-colors.sh
# zoxide (cdi等) が内部で起動するfzfは既定だと見た目が微妙に異なる
# (高さ・枠線・配色がFZF_DEFAULT_OPTS通りにならない)。ghq-fzf (Ctrl+G) と
# 同じ見た目に揃えるため、_ZO_FZF_OPTSにも同じ値を渡す
# --with-nth=2..でスコア列を隠す案は試したが検索(絞り込み)が効かなくなる
# 副作用があったため不採用。スコア表示は残す
export _ZO_FZF_OPTS="$FZF_DEFAULT_OPTS"
# yaziの組み込みzoxideプラグイン(cdiとは別実装、Z/c,dキー)は_ZO_FZF_OPTSではなく
# YAZI_ZOXIDE_OPTSを読むため、同じ配色に揃えるにはこちらも必要
export YAZI_ZOXIDE_OPTS="$FZF_DEFAULT_OPTS"
export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always --line-range :500 {}'"
export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window down:3:hidden:wrap --bind '?:toggle-preview,tab:down,btab:up'"

# fzf-tab (Tab補完) は既定でFZF_DEFAULT_OPTSを読まない仕様のため明示的に有効化する。
# これでmatugen配色・枠線もビルド無しで他のfzf系ツールと揃う
zstyle ':fzf-tab:*' use-fzf-default-opts yes

# --- キーマップ・Vimモード設定 ---
# Vi Mode（Vim風キーマップ）の有効化とインサート時のバックスペース調整を行います．
bindkey -v
bindkey "^?" backward-delete-char

# コマンドラインのVim編集機能を有効化します（ノーマルモードで 'v' でエディタ起動）．
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M vicmd 'v' edit-command-line

# 補完選択メニュー中のVim風（HJKL）移動キーマップを定義します．
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char

# --- 配色環境変数設定 ---
# matugen生成のstarship配色があればそちらを優先します．
[[ -f ~/.cache/matugen/starship.toml ]] && export STARSHIP_CONFIG=~/.cache/matugen/starship.toml

# lazygitはLG_CONFIG_FILEにカンマ区切りで複数ファイルを渡すと後勝ちでマージする。
# ベース設定(customCommands等、Nix管理のconfig.yml)に対し、matugenが生成する
# 配色だけのテーマパッチ(gui.themeのみ)を重ねる。これによりcustomCommandsを
# Nix側1箇所に書くだけで済み、matugenテンプレート側と二重管理にならない。
# home-manager (programs.lazygit) はconfig.ymlをOS標準の場所に置くため、
# Linux/WSLでは ~/.config/lazygit/config.yml、Macでは
# ~/Library/Application Support/lazygit/config.yml とベースパスが異なる。
LAZYGIT_BASE_CONFIG="$HOME/.config/lazygit/config.yml"
[[ "$OSTYPE" == darwin* ]] && LAZYGIT_BASE_CONFIG="$HOME/Library/Application Support/lazygit/config.yml"
if [[ -f ~/.cache/matugen/lazygit-theme.yml ]]; then
  export LG_CONFIG_FILE="$LAZYGIT_BASE_CONFIG,$HOME/.cache/matugen/lazygit-theme.yml"
fi

# matugen生成のeza配色があればそちらを優先します (ファイル名は theme.yml 固定)．
[[ -f ~/.cache/matugen/eza/theme.yml ]] && export EZA_CONFIG_DIR=~/.cache/matugen/eza

# matugen生成のtealdeer(tldr)配色があればそちらを優先します．
[[ -f ~/.cache/matugen/tealdeer/config.toml ]] && \
  export TEALDEER_CONFIG_DIR="$HOME/.cache/matugen/tealdeer"

# ===================================================================
# カスタムシェル関数
# ===================================================================

# 1. ディレクトリを作成して即時に移動します．
mkcd() {
    mkdir -p "$1"
    cd "$1" || return
}

# 2. ディレクトリ移動 (cd) 後に自動的に eza (ls) を実行します．
# 注意: `ls`エイリアスはhome-managerの生成順序上この関数より後に定義されるため、
# ここで`ls`と書くと関数パース時点でエイリアス展開されず、
# 素の/実行ファイルのlsが実行されてしまう。直接ezaコマンドを書く。
# 対話シェル・実端末 (tty) 以外 (Claude Codeのsandboxed bash実行など、
# `zsh -c '...'` 経由でcdだけ行われるケース) では実行しない。非対話環境だと
# 出力先の扱いによってはhangすることがあり、実害の割に何も見えないため。
function chpwd() {
    [[ -o interactive ]] && [[ -t 1 ]] && eza --icons
}

# 3. 競技プログラミング用C++のコンパイル＆実行を行います．
runcpp() {
    g++ -std=c++20 -O2 "$1" -o "${1%.cpp}.out" && "./${1%.cpp}.out"
}
runcppio() {
    g++ -std=c++20 -O2 "$1" -o "${1%.cpp}.out" && "./${1%.cpp}.out" < input.txt > output.txt
}

# 4. WezTerm OSC 7サポート（新しいタブを開いた際のカレントディレクトリ同期用）を設定します．
if [[ "$TERM_PROGRAM" == "WezTerm" ]]; then
    wezterm_osc7() {
        printf "\033]7;file://%s%s\033\\" "$HOST" "$PWD"
    }
    autoload -Uz add-zsh-hook
    add-zsh-hook precmd wezterm_osc7
fi

# 5. ghq + fzfによる超高速ディレクトリジャンプを定義します．
function ghq-fzf() {
  local src=$(ghq list | fzf --bind 'tab:down,btab:up' --preview "ls -lap $(ghq root)/{} | tail -n+2 | head -n 200")
  if [ -n "$src" ]; then
    BUFFER="cd $(ghq root)/$src"
    zle accept-line
  fi
  zle reset-prompt
}
zle -N ghq-fzf
bindkey '^g' ghq-fzf
bindkey -M viins '^g' ghq-fzf
bindkey -M vicmd '^g' ghq-fzf

# 5.5. atuinの履歴DBを実物のfzfで検索します (Ctrl+R)。
# atuin自身のTUIをfzf風に再現するのはソースパッチが必要で運用コストが
# 高すぎたため撤廃した (modules/shell/atuin/default.nix参照)。atuinは
# 履歴の記録・同期バックエンドとしてのみ使い、検索UIはfzfそのものに
# 任せることで、fzfのネイティブな枠線・ハイライト設定 (FZF_DEFAULT_OPTS、
# matugen追従) がそのまま使える。
function atuin-fzf() {
  local response key selected
  # --read0/--print0: `\`継続の複数行コマンドは実際に改行込みで1件の履歴として
  # 保存されているため、改行区切り(fzfのデフォルト)で渡すと複数候補に分解されて
  # しまう。NUL区切りにすることで1コマンド=1候補として扱う (fzfは--read0時、
  # 複数行の候補もそのまま複数行表示してくれる)。
  # Ctrl+R (fzf内): global(全履歴) → directory(現在のディレクトリのみ) →
  # session(現在のシェルセッションのみ) → globalの順にトグルする。以前の
  # atuin自身のTUIにあった「UI内Ctrl+Rでフィルタを切り替える」挙動の代替。
  # (atuin searchにはhost単位のフィルタフラグが無いため3段階まで)
  # モード名は旧パッチ同様、外枠のタイトルとして埋め込む (--border-label)。
  # atuin-history-colored (modules/shell/atuin/default.nix) が終了コードに
  # 応じた緑(成功)/赤(失敗)の●を先頭に付けて出力する。fzfの reload() は
  # 新しいシェルプロセスで動くためこのzsh関数を直接呼べず、実行可能ファイル
  # として切り出してある。--ansi で色付きドットを実際の色として表示する。
  # 各候補は "装飾付き表示\x01生コマンド" の2フィールド。fzfは--ansiでも
  # 選択結果からANSIエスケープコードを取り除いてしまい、●という文字だけが
  # BUFFERに混入してコマンドが実行できなくなる実害があったため、
  # --delimiter/--with-nthで表示は1列目(装飾込み)だけに絞りつつ、
  # 実際に使うのは常に2列目(無加工の生コマンド)にしている。
  # Ctrl+O: 選択中のコマンドを削除する。`atuin search --delete <query>`は
  # 非対話実行だとファジー検索が不安定で、意図しない無関係なコマンドまで
  # 巻き込んで削除してしまう実害を検証で確認した (クエリの再検索に依存し、
  # 選択した行そのものを厳密に指すわけではないため)。そのためここでは独自の
  # 削除ロジックを組まず、atuin公式のインタラクティブTUI (atuin search -i)
  # を選択中のコマンドをクエリとして起動する。あちらは実際に選んだ行のID
  # に対して削除するため安全。atuin-delete-entry (modules/shell/atuin/default.nix)
  # が起動直後のフォーカス移動 (atuin側のCtrl-O) と、ユーザーがCtrl-Dで
  # 削除した後のEscによる画面閉じまでを自動化し、実際の削除操作(Ctrl-D)
  # のみユーザーの手動操作として残す。TUIを閉じると現在のフィルタモードを
  # 保ったままこちらの一覧を再読み込みする。
  # Enter: 選択したコマンドをその場で即実行する。Tab: 従来のEnterと同じく
  # バッファに詰めるだけで実行はしない (編集してから使いたい場合用)。
  # --expect=tab で押されたキー名を出力の1行目に、以降を選択されたエントリ
  # そのものにして返してもらい (デフォルトのEnterでは1行目は空)、どちらが
  # 押されたかで動作を分岐する。
  response=$(atuin-history-colored | fzf --read0 --ansi -q "$LBUFFER" \
    --delimiter=$'\x01' --with-nth=1 \
    --expect=tab \
    --border-label ' GLOBAL ' \
    --bind 'ctrl-r:transform:case "$FZF_BORDER_LABEL" in
      " GLOBAL ") echo "reload(atuin-history-colored --filter-mode directory)+change-border-label( DIRECTORY )" ;;
      " DIRECTORY ") echo "reload(atuin-history-colored --filter-mode session)+change-border-label( SESSION )" ;;
      *) echo "reload(atuin-history-colored)+change-border-label( GLOBAL )" ;;
    esac' \
    --bind 'ctrl-o:execute(atuin-delete-entry {2})+transform:case "$FZF_BORDER_LABEL" in
      " DIRECTORY ") echo "reload(atuin-history-colored --filter-mode directory)" ;;
      " SESSION ") echo "reload(atuin-history-colored --filter-mode session)" ;;
      *) echo "reload(atuin-history-colored)" ;;
    esac')
  key=${response%%$'\n'*}
  selected=${response#*$'\n'}
  if [[ -n $selected ]]; then
    # 1列目(装飾込み表示)を捨て、2列目(生コマンド)だけをバッファへ反映する
    BUFFER=${selected#*$'\x01'}
    CURSOR=$#BUFFER
    if [[ $key != tab ]]; then
      zle accept-line
      return
    fi
  fi
  zle reset-prompt
}
zle -N atuin-fzf
bindkey '^r' atuin-fzf
bindkey -M viins '^r' atuin-fzf
bindkey -M vicmd '^r' atuin-fzf

# 6. zsh-syntax-highlighting用のカスタムカラースタイルを設定します．
# Kanagawa Dragon 系の落ち着いた色に合わせる（ネオンな green/red,bold を回避）
typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[command]='fg=#98bb6c,bold'
ZSH_HIGHLIGHT_STYLES[alias]='fg=#98bb6c,bold'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#98bb6c,bold'
ZSH_HIGHLIGHT_STYLES[function]='fg=#98bb6c,bold'
ZSH_HIGHLIGHT_STYLES[precommand]='fg=#98bb6c,bold'
ZSH_HIGHLIGHT_STYLES[arg0]='fg=#98bb6c,bold'
ZSH_HIGHLIGHT_STYLES[hashed-command]='fg=#98bb6c,bold'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#e46876,bold'

# 7. Windowsとの設定同期を行います（WSL環境用）．
function sync-win() {
    echo "Syncing WezTerm config..."
    cp ~/.config/wezterm/*.lua /mnt/c/Users/tnaru/.config/wezterm/
    mkdir -p /mnt/c/Users/tnaru/Tools/Customization
    # main.ahk (modules/input/ahk) がエントリポイントで、komorebi.ahkは
    # そこから絶対パスで#Includeされる。存在する場合だけ同期します．
    if [ -d ~/.config/ahk ]; then
        echo "Syncing AutoHotkey scripts..."
        cp -rL ~/.config/ahk/* /mnt/c/Users/tnaru/Tools/Customization/
    fi
    echo "Syncing Komorebi config..."
    mkdir -p /mnt/c/Users/tnaru/.config/komorebi
    cp -L ~/.config/komorebi/komorebi.json /mnt/c/Users/tnaru/.config/komorebi/
    cp -L ~/.config/komorebi/komorebi.ahk /mnt/c/Users/tnaru/.config/komorebi/
    cp -L ~/.config/komorebi/applications.json /mnt/c/Users/tnaru/.config/komorebi/
    # 読み込みの確実性を高めるため，ホーム直下にも配置します．
    cp -L ~/.config/komorebi/komorebi.json /mnt/c/Users/tnaru/
    cp -L ~/.config/komorebi/applications.json /mnt/c/Users/tnaru/
    rm -f "/mnt/c/Users/tnaru/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup/komorebi.ahk"
    # スタートアップ・環境構築スクリプトの同期を行います．
    cp -L ~/.config/komorebi/startup.ps1 /mnt/c/Users/tnaru/Tools/Customization/
    cp -L ~/.config/komorebi/setup-windows.ps1 /mnt/c/Users/tnaru/Tools/Customization/
    echo "Syncing YASB config..."
    mkdir -p /mnt/c/Users/tnaru/.config/yasb
    cp -rL ~/.config/yasb/* /mnt/c/Users/tnaru/.config/yasb/
    # matugen生成済みパレットがあればstyles.cssに再適用します．
    [ -x ~/.local/bin/matugen-apply ] && ~/.local/bin/matugen-apply --reapply
    echo "Syncing Vivaldi CSS..."
    mkdir -p /mnt/c/Users/tnaru/Tools/Vivaldi
    cp -L ~/.config/vivaldi/custom.css /mnt/c/Users/tnaru/Tools/Vivaldi/custom.css
    echo "Done."
}

# 8. 最新のスクリーンショットをAntigravityチャットへ連携します（撮影した ~/Pictures/Screenshots/ 下の最新画像を同期）．
function agy-ss() {
    local ss_dir="$HOME/Pictures/Screenshots"
    local latest_file=$(ls -t "$ss_dir"/Screenshot*.png 2>/dev/null | head -n 1)
    if [ -n "$latest_file" ]; then
        cp "$latest_file" "$ss_dir/latest.png"
        if command -v pbcopy >/dev/null 2>&1; then
            echo -n "$latest_file" | pbcopy
        elif command -v wl-copy >/dev/null 2>&1; then
            echo -n "$latest_file" | wl-copy
        elif command -v xclip >/dev/null 2>&1; then
            echo -n "$latest_file" | xclip -selection clipboard
        fi
        echo "最新のスクリーンショットを登録しました！"
        echo "  元ファイル: $latest_file"
        echo "  -> $ss_dir/latest.png としてコピーしました．"
        echo "  （クリップボードにコピーしたため，チャットへ Ctrl+V で直接貼り付け可能です）"
    else
        echo "スクリーンショットが見つかりませんでした．($ss_dir)"
    fi
}

# 9. 現在の壁紙に対する matugen 抽出色を手動で上書きします．
# (matugenは面積優先で色を選ぶため、面積の小さい印象的な色を拾えないことがある)
function matugen-set-color() {
    local hex="${1:?usage: matugen-set-color '#rrggbb' (現在の壁紙の抽出色を上書き)}"
    local wallpaper
    wallpaper="$(cat "$HOME/.cache/matugen/last-wallpaper" 2>/dev/null)"
    if [ -z "$wallpaper" ]; then
        echo "現在の壁紙が記録されていません．先に壁紙を設定してください．" >&2
        return 1
    fi
    local wp_name="$(basename "$wallpaper")"
    local overrides_file="$HOME/.config/matugen-wsl/color-overrides.conf"
    grep -v "^${wp_name}=" "$overrides_file" > "${overrides_file}.tmp" 2>/dev/null || true
    mv "${overrides_file}.tmp" "$overrides_file"
    echo "${wp_name}=${hex}" >> "$overrides_file"
    echo "登録しました: ${wp_name} -> ${hex}"
    matugen-apply --reapply
}
