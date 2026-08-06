# rootless podman (distrobox) セットアップ手順 (`nalt-distrobox`)

[README.md](../README.md) の「どれがどのOSで動くか」対応表も参照してください。

sudo権限が無く `/nix` を作成できない共有Linuxホスト (バイト先の貸与PC等) 向けの，
CLIツールのみの軽量プロファイルです。[distrobox](https://github.com/89luca89/distrobox)
で作った rootless podman コンテナの中に通常の (`/nix` を持つ) Nixをインストールします。

他の3ホスト (`nixos` / `nalt-wsl` / `nalt-mac`) がOS本体ごと宣言的に管理するのに対し，
このホストは「sudoの無い既存Linux環境に，CLI環境だけを足す」ためのアドオン的な位置づけです。

## コンテナの`$HOME`はホストと共有しない

初期の実装ではdistroboxのデフォルト通りホストの`$HOME`をそのまま共有していましたが，
これは以下の理由から**やめました**:

- host-nativeで直接読まれるファイル (`.zshrc` / `.zshenv` / systemdユーザーユニット等) と，
  home-managerが管理する「コンテナ内`/nix/store`を指すシンボリックリンク」が同じパスで
  衝突し，`home-manager switch`のたびに壊れる
- atuin等，hostとcontainerで別バージョンのバイナリが同じデータファイル
  (`~/.local/share/atuin/*.db`) を共有すると，DBマイグレーションの不整合でエラーになる
- starship等，プロンプト描画のたびに毎回呼ばれるツールをコンテナ越しにすると
  実用速度にならない (host-nativeで別途インストールする方が良い)

`distrobox create --home <独立ディレクトリ>` でコンテナの`$HOME`をホストの実`$HOME`と
物理的に分離することで，これらの問題は構造的に発生しなくなります。

```bash
mkdir -p ~/ghq/github.com/Naruto-Takahashi
cd ~/ghq/github.com/Naruto-Takahashi
git clone https://github.com/Naruto-Takahashi/nix-config.git
cd nix-config
```

1. **distrobox のインストール** (sudo不要，`~/.local` 配下)
   ```bash
   curl -fsSL https://raw.githubusercontent.com/89luca89/distrobox/main/install | bash -s -- --prefix ~/.local
   export PATH="$HOME/.local/bin:$PATH"
   ```
2. **独立`$HOME`を持つrootless podman コンテナの作成**
   ```bash
   mkdir -p ~/distrobox-homes/nixcli-dev
   distrobox create --name nixcli --image docker.io/library/ubuntu:24.04 \
     --home ~/distrobox-homes/nixcli-dev --yes
   ```
   `--home`を付けないとホストの実`$HOME`がそのまま共有されてしまうので必須。
   UID/ユーザー名/sudoグループはホストと同じものがコンテナ内にも作られる。
3. **コンテナ内にNixをインストール** (コンテナ内はrootが使えるため `/nix` を通常通り作成可能)
   ```bash
   distrobox enter nixcli -- bash -c '
     sudo mkdir -m 0755 -p /nix && sudo chown "$(id -un)" /nix
     curl -L https://nixos.org/nix/install | sh -s -- --no-daemon
     mkdir -p ~/.config/nix
     echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
   '
   ```
4. **git/gh認証のセットアップ** (コンテナ独自の`$HOME`にはホストの認証情報が無いため)
   ```bash
   # GitHub用SSH鍵をコピー (このリポジトリはgit@github.com:...のSSH URLを使う設定のため)
   mkdir -p ~/distrobox-homes/nixcli-dev/.ssh
   cp ~/.ssh/id_ed25519 ~/.ssh/id_ed25519.pub ~/.ssh/known_hosts ~/distrobox-homes/nixcli-dev/.ssh/
   chmod 700 ~/distrobox-homes/nixcli-dev/.ssh
   chmod 600 ~/distrobox-homes/nixcli-dev/.ssh/id_ed25519
   ```
5. **リポジトリのclone** (git無しなので一時的にaptで導入)
   ```bash
   distrobox enter nixcli -- bash -c '
     sudo apt-get update -qq && sudo apt-get install -y -qq git ca-certificates
     mkdir -p ~/ghq/github.com/Naruto-Takahashi
     git clone git@github.com:Naruto-Takahashi/nix-config.git ~/ghq/github.com/Naruto-Takahashi/nix-config
   '
   ```
6. **Home Manager プロファイルの適用**
   ```bash
   distrobox enter nixcli -- bash -c '
     . ~/.nix-profile/etc/profile.d/nix.sh
     cd ~/ghq/github.com/Naruto-Takahashi/nix-config
     nix run --impure github:nix-community/home-manager -- switch --flake .#nalt-distrobox --impure
   '
   ```
   `hosts/nalt-distrobox/default.nix`の`home.homeDirectory`は`builtins.getEnv "HOME"`で
   動的に取得するようにしてあるので，独立homeのパスをリポジトリ側で書き換える必要はない。
7. **yaziの配色を生成** (このホストには壁紙連動のmatugenパイプラインが無いため，
   `theme.toml`が自動生成されない。フォールバック色で一度だけ手動生成する)
   ```bash
   distrobox enter nixcli -- bash -c '
     tmpl=~/.config/yazi/theme-template.toml
     sed -e "s/@@COMPLEMENT@@/#f2d4ad/g" -e "s/@@ERROR@@/#ffb4ab/g" \
         -e "s/@@SECONDARY@@/#bbc7db/g" -e "s/@@TERTIARY@@/#d7bde4/g" \
         -e "s/@@TEXT@@/#e1e2e8/g" -e "s/@@TRIAD@@/#f2adcb/g" \
         "$tmpl" > ~/.config/yazi/theme.toml
   '
   ```

## ホスト側からシームレスに使う

大学/職場のLmod (`module`コマンド) 環境がある場合，エクスポートされたbash関数が
コンテナ内のbashと非互換でエラーになることがある。`env -u 'BASH_FUNC_*%%'`で
該当関数を環境から除去してから`distrobox enter`する。

ホストの`~/.zshrc`(host-native手動管理版)に`nixcli`関数を定義しておくと，
普段はhost-nativeの最低限環境を使いつつ，必要な時だけ`nixcli`と打つだけで
フル機能版 (Node同梱のcopilot.lua，lrpymrpc等の開発コンテナ操作を含む) に入れる:

```bash
nixcli() {
  local dev_home="$HOME/distrobox-homes/nixcli-dev"
  env \
    -u 'BASH_FUNC__module_raw%%' -u 'BASH_FUNC_ml%%' -u 'BASH_FUNC_module%%' \
    -u 'BASH_FUNC_scl%%' -u 'BASH_FUNC_switchml%%' -u 'BASH_FUNC_which%%' \
    distrobox enter nixcli -- env \
      PATH="$dev_home/.local/state/nix/profiles/home-manager/home-path/bin:$dev_home/.nix-profile/bin:/usr/bin:/bin" \
      CONTAINER_HOST="unix:///run/user/1007/podman/podman.sock" \
      bash -c "cd \"$dev_home\" && exec zsh"
}
```

`CONTAINER_HOST`は，ホストの`podman.socket`(`systemctl --user enable --now podman.socket`で
有効化) をコンテナ内から使うための指定。コンテナ内に`podman`パッケージだけaptで入れれば，
ネストしたpodman-in-podmanを使わずにホスト側のイメージ/コンテナをそのまま操作できる
(ストレージも二重化しない)。distrobox公式には`distrobox-host-exec`を使う，より軽量な
代替方法もある ([useful_tips.md](https://github.com/89luca89/distrobox/blob/main/docs/useful_tips.md) 参照)。

`exec`はしない: 抜ける(`exit`)と自然にホストのzshへ戻ってこられるように子プロセスとして
起動する。ログインシェル自体もあえてコンテナ経由にしていない。コンテナが起動しない
トラブル時にホストへログインできなくなるリスクを避けるため。

## この構成で有効になるもの

[`profiles/base.nix`](../profiles/base.nix) のCLIツール一式 (zsh / starship / neovim / yazi /
git / lazygit / eza / bat / btop / atuin 等) がコンテナ内で完全な形 (Node同梱copilot.lua含む)
で使える。GUI/ウィンドウマネージャー・systemdユーザーサービス・カーネル入力リマップ
(kanata) 等，コンテナに乗らないものは含まれない。詳細は [neovim.md](neovim.md) /
[yazi.md](yazi.md) / [cli-tools.md](cli-tools.md) を参照。

ホスト側 (コンテナの外) には，最低限の開発環境を別途手動でインストールしておくと安全。
zsh / starship / atuin / eza / bat / git / nvim (Node無し，copilot無効) をスタンドアロン
バイナリで導入し，設定ファイルはこのリポジトリへのシンボリックリンクにする
(`home-manager`には依存しない，純粋な手動管理)。コンテナが起動しない場合の
フォールバックとして機能する。
