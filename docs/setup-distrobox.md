# rootless podman (distrobox) セットアップ手順 (`nalt-distrobox`)

[README.md](../README.md) の「どれがどのOSで動くか」対応表も参照してください。

sudo権限が無く `/nix` を作成できない共有Linuxホスト (研究室のサーバー等) 向けの，
CLIツールのみの軽量プロファイルです。[distrobox](https://github.com/89luca89/distrobox)
で作った rootless podman コンテナの中に通常の (`/nix` を持つ) Nixをインストールし，
ホストの `$HOME` をそのままコンテナと共有することで，コンテナ内のNeovim/Yazi等から
ホストの実ファイルを透過的に編集できるようにします。

他の3ホスト (`nixos` / `nalt-wsl` / `nalt-mac`) がOS本体ごと宣言的に管理するのに対し，
このホストは「sudoの無い既存Linux環境に，CLI環境だけを足す」ためのアドオン的な位置づけです。

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
2. **rootless podman コンテナの作成**
   ```bash
   distrobox create --name nixcli --image docker.io/library/ubuntu:24.04 --yes
   ```
   distroboxは`$HOME`を自動でコンテナと共有し，ホストと同じUID/ユーザー名でコンテナ内ユーザーを作成します。
3. **コンテナ内にNixをインストール** (コンテナ内はrootが使えるため `/nix` を通常通り作成可能)
   ```bash
   distrobox enter nixcli -- bash -lc '
     sudo mkdir -m 0755 -p /nix && sudo chown "$(id -un)" /nix
     curl -L https://nixos.org/nix/install | sh -s -- --no-daemon
     mkdir -p ~/.config/nix
     echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
   '
   ```
4. **Home Manager プロファイルの適用**
   ```bash
   distrobox enter nixcli -- bash -lc '
     cd ~/ghq/github.com/Naruto-Takahashi/nix-config
     nix run --impure github:nix-community/home-manager -- switch --flake .#nalt-distrobox --impure
   '
   ```
   既存の手動設定ファイルと衝突する場合は `HOME_MANAGER_BACKUP_EXT=<拡張子>` を先頭に付けてバックアップさせてください。

## ホスト側からシームレスに使う

大学のLmod (`module`コマンド) 環境がある場合，エクスポートされたbash関数がコンテナ内の
bashと非互換でエラーになることがあります。ホスト側の呼び出しラッパーでは
`env -u 'BASH_FUNC_*%%'` で該当関数を環境から除去してから `distrobox enter` してください。

`~/.local/bin/` に以下のようなラッパーを置くと，ホストで普段通り `nvim` 等と打つだけで
コンテナ内のNix管理版 (Node同梱のcopilot.lua等，フル機能) が透過的に起動します。
コンテナ内のPATHの先頭にhome-managerのプロファイルbinを差し込むことで，
`~/.local/bin` (ホスト版バイナリ，`$HOME`はコンテナと共有) より優先させ，
ラッパー自身をコンテナ内から再帰的に呼んでしまう事故も防いでいます。

```bash
#!/usr/bin/env bash
exec env \
  -u 'BASH_FUNC__module_raw%%' -u 'BASH_FUNC_ml%%' -u 'BASH_FUNC_module%%' \
  -u 'BASH_FUNC_scl%%' -u 'BASH_FUNC_switchml%%' -u 'BASH_FUNC_which%%' \
  distrobox enter nixcli -- env \
    PATH="$HOME/.local/state/nix/profiles/home-manager/home-path/bin:$HOME/.nix-profile/bin:$PATH" \
    "$@"
```

ログインシェル (zsh) 自体はあえてコンテナ経由にしていません。コンテナが起動しない
トラブル時にホストへログインできなくなるリスクを避けるためです。

## この構成で有効になるもの

[`profiles/base.nix`](../profiles/base.nix) のCLIツール一式 (zsh / starship / neovim / yazi /
git / lazygit / eza / bat / btop / atuin 等) のみが対象です。GUI/ウィンドウマネージャー・
systemdユーザーサービス・カーネル入力リマップ (kanata) 等，コンテナに乗らないものは
含まれません。詳細は [neovim.md](neovim.md) / [yazi.md](yazi.md) / [cli-tools.md](cli-tools.md) を参照してください。
