# Ubuntu デスクトップ環境セットアップ手順 (`nalt-ubuntu`)

[README.md](../README.md) の「どれがどのOSで動くか」対応表も参照してください。

Nix非搭載の通常の Ubuntu Linux に Home Manager プロファイルを導入する手順です。

```bash
mkdir -p ~/ghq/github.com/Naruto-Takahashi
cd ~/ghq/github.com/Naruto-Takahashi
git clone https://github.com/Naruto-Takahashi/nix-config.git
cd nix-config
```

1. **Nix パッケージマネージャーのインストール** (シングルユーザーモード)
   ```bash
   curl -L https://nixos.org/nix/install | sh
   . ~/.nix-profile/etc/profile.d/nix.sh
   ```

2. **Nix Flakes 機能の有効化**
   ```bash
   mkdir -p ~/.config/nix
   echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
   ```

3. **Home Manager プロファイルの適用**
   ```bash
   nix run github:nix-community/home-manager -- switch --flake .#nalt-ubuntu --impure
   ```
   > `--impure` は必須です．nixGL が `builtins.currentTime` を参照するため，純粋評価では失敗します．

4. **ユーザーサービスの登録とシェル再起動**
   ```bash
   systemctl --user daemon-reload
   systemctl --user enable --now kanata
   exec zsh
   ```

## この構成で有効になるもの

Kanata (キーリマップ，`Super`変換)，fcitx5+Mozc，共通CLI/アプリ一式 (WezTerm/Neovim/Yazi/lazygit等)。

**注意**: このリポジトリはUbuntu向けのタイルウィンドウマネージャ (Hyprland相当) を設定していません。Kanataの`Alt`長押しウィンドウ操作バインドは`Super+...`を送信しますが，それを実際に処理するWM側の設定が無いため素通りします。SandS移動・IME切替・CapsLock改修は問題なく使えます (詳細は [kanata.md](kanata.md))。Matugen壁紙配色パイプラインもUbuntu向けは未整備です。
