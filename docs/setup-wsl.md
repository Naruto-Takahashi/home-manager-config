# 🪟 WSL2 (Ubuntu) セットアップ手順 (`nalt-wsl`)

[README.md](../README.md) の「どれがどのOSで動くか」対応表も参照してください。

```bash
mkdir -p ~/ghq/github.com/Naruto-Takahashi
cd ~/ghq/github.com/Naruto-Takahashi
git clone https://github.com/Naruto-Takahashi/nix-config.git
cd nix-config
```

1. **NixのインストールとFlakesの有効化** ([Ubuntu手順](setup-ubuntu.md) の 1 & 2 と同様)
2. **Home Manager プロファイルの適用**
   ```bash
   nix run github:nix-community/home-manager -- switch --flake .#nalt-wsl --impure
   ```
3. **Windows側への設定ファイル同期**
   WSL2環境下で管理される WezTerm や komorebi / YASB の設定を Windows ホストに反映するため，以下の同期コマンドを実行します．
   ```bash
   sync-win
   exec zsh
   ```

## この構成で有効になるもの

キーボードリマップは(WSLからはWindows側のキーボードを直接掴めないため)Kanataではなく [AutoHotkey](../modules/input/ahk/main.ahk) が担当します。komorebi (WM) + YASB (ステータスバー) はWindows側で動作し，`sync-win`で設定を配置します。Matugen壁紙配色はWSL側で完結します (壁紙選択→配色反映)。Obsidian MCP連携もこのホストのみ有効です。詳細は [komorebi.md](komorebi.md) / [kanata.md](kanata.md) / [matugen-palette.md](matugen-palette.md) を参照してください。
