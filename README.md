<div align="center">

![header](https://capsule-render.vercel.app/api?type=waving&height=210&color=0:181616,35:2d4f67,65:7aa89f,100:e6c384&text=nix-config&fontColor=c5c9c5&fontSize=64&fontAlignY=36&desc=Declarative%20environments%20for%20NixOS%20%C2%B7%20WSL2%20%C2%B7%20Ubuntu%20%C2%B7%20macOS&descColor=c5c9c5&descSize=16&descAlignY=58)

[![CI](https://img.shields.io/github/actions/workflow/status/Naruto-Takahashi/nix-config/check.yml?branch=main&style=flat-square&logo=github-actions&logoColor=white&label=CI&labelColor=181616)](https://github.com/Naruto-Takahashi/nix-config/actions/workflows/check.yml)
[![NixOS](https://img.shields.io/badge/NixOS-unstable-5277C3?style=flat-square&logo=nixos&logoColor=white&labelColor=181616)](https://nixos.org)
[![Flakes](https://img.shields.io/badge/Nix-Flakes-7aa89f?style=flat-square&logo=nixos&logoColor=white&labelColor=181616)](https://nixos.wiki/wiki/Flakes)
[![Home Manager](https://img.shields.io/badge/Home-Manager-e6c384?style=flat-square&logo=nixos&logoColor=white&labelColor=181616)](https://github.com/nix-community/home-manager)
[![nix-darwin](https://img.shields.io/badge/nix-darwin-a292a3?style=flat-square&logo=apple&logoColor=white&labelColor=181616)](https://github.com/LnL7/nix-darwin)
[![Last Commit](https://img.shields.io/github/last-commit/Naruto-Takahashi/nix-config?style=flat-square&logo=git&logoColor=white&labelColor=181616&color=7fb4ca)](https://github.com/Naruto-Takahashi/nix-config/commits/main)

<br>

[![Tech Stack](https://skillicons.dev/icons?i=nix,linux,ubuntu,windows,apple,neovim,lua,bash,py,git&theme=dark)](https://github.com/Naruto-Takahashi/nix-config)

</div>

**Nix Flakes** と **Home Manager** を使用して，NixOS，Linuxデスクトップ（Ubuntu），および WSL2 環境を宣言的に一元管理するための設定ファイル群（レシピ）です．

OSレベルのシステム定義から，シェル環境，ウィンドウマネージャー，開発ツールまでを一元管理し，キーボード駆動の快適な開発環境を構築します．すべての CLI/GUI が **Matugen** により壁紙から生成された配色で統一されます．

![divider](https://capsule-render.vercel.app/api?type=rect&height=3&color=0:e6c384,50:7aa89f,100:a292a3)

## 🗺️ 設定・キーマップ詳細

各モジュールの機能やキーバインドの詳細については，以下の個別ドキュメントからご確認ください．

| 対象環境 | コンポーネント / モジュール | ガイドと詳細 | 主な役割 |
| :--- | :--- | :--- | :--- |
| **NixOS** | 🗔 Hyprland | [hyprland.md](docs/hyprland.md) | Waylandタイル操作，Matugen動的配色，Waybar連携． |
| **Windows / WSL2** | 🗔 komorebi + YASB | [komorebi.md](docs/komorebi.md) / [matugen-palette.md](docs/matugen-palette.md) | Windows側タイルウィンドウ操作，YASBステータスバー，Matugen動的配色連携． |
| **macOS** | 🗔 AeroSpace | [aerospace.nix](modules/apps/aerospace/default.nix) / [matugen-palette.md](docs/matugen-palette.md) | macOS用タイル操作，`Cmd+Ctrl`二重修飾キー，JankyBorders枠線表示，Matugen壁紙配色連携． |
| **NixOS / Desktop** | ⌨️ Kanata | [kanata.md](docs/kanata.md) | システム級キーマップ（SandS Vim風移動，Mac風IME切り替え）． |
| **共通 (App)** | 💻 WezTerm | [wezterm.md](docs/wezterm.md) | 85%半透明適用，Matugen配色タブ，Leaderキー（`Ctrl+Space`）管理． |
| **共通 (App)** | 📝 Neovim | [neovim.md](docs/neovim.md) | Lazy.nvimによる構成，高度なカスタムマクロとプラグイン群． |
| **共通 (App)** | 📁 Yazi | [yazi.md](docs/yazi.md) | Matugen配色の透過ファイラー，シェル連携による移動同期． |
| **共通 (CLI)** | 🧰 CLI小物 | [cli-tools.md](docs/cli-tools.md) | atuin履歴検索，tldr，fd，delta，btop，smasshの使い方集． |
| **NixOS ⇄ Windows** | 🖥️ Remote Desktop | [remote-desktop.md](docs/remote-desktop.md) | Tailscale + Sunshine/Moonlight による大学VPN不要の無人リモート接続． |

![divider](https://capsule-render.vercel.app/api?type=rect&height=3&color=0:e6c384,50:7aa89f,100:a292a3)

## 📂 ディレクトリ構造

```
.
├── flake.nix                  # Flake エントリーポイント（システム構成の定義）
├── hosts/                     # ホスト別の設定エントリーポイント
│   ├── nixos/                 # NixOS 設定（システム設定 ＋ Home Manager 設定）
│   ├── ubuntu/                # 一般Linux（Ubuntu）用 Home Manager スタンドアロン設定
│   ├── wsl/                   # WSL2用 Home Manager スタンドアロン設定
│   └── mac/                   # macOS用 nix-darwin + Home Manager 統合設定
├── modules/                   # 再利用可能な共通設定モジュール群
│   ├── wm/                    # ウィンドウマネージャー設定 (hyprland, komorebi, yasb)
│   ├── apps/                  # アプリケーション個別設定 (wezterm, neovim, yazi, lazygit, git, bat)
│   ├── services/              # ユーザーサービス (obsidian-mcp)
│   ├── shell/                 # シェル・端末環境 (zsh, starship, fastfetch, direnv)
│   ├── input/                 # 入力系 (kanata キーリマップ, fcitx5 日本語入力)
│   ├── theming/               # Matugen 共通ロジック / テンプレート / WSL パイプライン
│   └── desktop/               # Linux GUI 共通 (パッケージ, デスクトップエントリ, MIME)
├── profiles/                  # 全ホスト共通プロファイル (base.nix)
└── docs/                      # 各種仕様・キーマップ解説ドキュメント
```

![divider](https://capsule-render.vercel.app/api?type=rect&height=3&color=0:e6c384,50:7aa89f,100:a292a3)

## 🚀 セットアップとインストール手順 (移行ガイド)

環境の一貫性を保つため，リポジトリは必ず規定の `ghq` ディレクトリ構造配下にクローンしてください．

```bash
mkdir -p ~/ghq/github.com/Naruto-Takahashi
cd ~/ghq/github.com/Naruto-Takahashi
git clone https://github.com/Naruto-Takahashi/nix-config.git
cd nix-config
```

### A. NixOS 環境へ導入する場合

NixOSの公式インストーラで最小インストール（ユーザー名は **`nalt`** で作成）を完了した後の手順です．

1. **ハードウェア構成ファイルのコピー**  
   PC固有のハードウェア構成ファイルをリポジトリ内に上書きコピーし，Gitの追跡対象に加えます．
   ```bash
   cp /etc/nixos/hardware-configuration.nix hosts/nixos/hardware-configuration.nix
   git add hosts/nixos/hardware-configuration.nix
   ```

2. **設定の構築とシステムへの適用**  
   Flakesを利用してシステム構成と Home Manager の設定を一括適用します．
   ```bash
   sudo nixos-rebuild switch --flake .#nixos --impure
   ```

3. **システムの再起動**  
   Kanata などのシステムサービスを完全に認識させるため，適用後は一度PCを再起動してください．

4. **リモートデスクトップの初回認証（必要な場合）**  
   Tailscaleのログインや Sunshine のペアリングなど，Nixで再現されない認証ステートの初期化手順は [remote-desktop.md](docs/remote-desktop.md) を参照してください．

---

### B. Ubuntu デスクトップ環境の場合 (`nalt-ubuntu`)

Nix非搭載の通常の Ubuntu Linux に Home Manager プロファイルを導入する手順です．

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

---

### C. WSL2 (Ubuntu) 環境の場合 (`nalt-wsl`)

WSL2環境で動作させる手順です．

1. **NixのインストールとFlakesの有効化** (上記の Ubuntu 手順 1 & 2 と同様)
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

---

### D. macOS (darwin) 環境の場合 (`nalt-mac`)

M1 Mac などの macOS 環境でシステム設定およびアプリケーション群を統合管理する手順です．
キーボード操作 (Kanata) と壁紙配色連携 (Matugen) は macOS の TCC (権限管理) の都合上，
Nixの適用だけでは完結せず，何点か手動でのGUI操作が必要です．下記の順番通りに進めてください．

1. **Xcode Command Line Tools のインストール**  
   インストールされていない場合は，以下を実行して導入します．
   ```bash
   xcode-select --install
   ```

2. **Nix のインストール**  
   Determinate Nix インストーラを使用してインストールを行います．
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
   ```

3. **Homebrew のインストール**  
   Nix-darwin による Cask アプリ（AeroSpace, Vivaldi, Raycast, Alt-Tab など）の管理に
   必要となるため，事前にインストールしておきます．
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

4. **設定の構築とシステムへの適用**  
   リポジトリを `ghq` 規定位置に配置後，シンボリックリンクを作成してシステム構成を適用します．
   ```bash
    # シンボリックリンクの作成 (初回のみ)
    mv ~/.config/home-manager ~/.config/home-manager.bak
    ln -s ~/ghq/github.com/Naruto-Takahashi/nix-config ~/.config/home-manager
 
    # システムの適用と有効化 (初回起動時は nix run でブートストラップ)
    cd ~/ghq/github.com/Naruto-Takahashi/nix-config
    git add .
    sudo nix run github:LnL7/nix-darwin -- switch --flake .#nalt-mac --impure

   # 2回目以降の更新適用 (こちらが推奨・高速)
   darwin-rebuild switch --flake .#nalt-mac
   ```
   初回適用時に，Kanataバイナリを安定パス (`/usr/local/bin/kanata`) へ再署名して
   配置する自己署名証明書が自動生成されます（TCC権限をリビルドのたびに失い直さない
   ための仕組み。詳細はコメント付きで `hosts/mac/darwin.nix` を参照）．
   また同じタイミングで **Karabiner-DriverKit-VirtualHIDDevice v6.2.0**
   (Kanataの仮想キーボード出力に必須のドライバ) のダウンロード・インストール・
   システム拡張の有効化リクエストも自動で行われます（`hash`固定の`fetchurl`で
   取得するため常に同じバージョンになります。バージョンが合わないと
   `connect_failed` エラーで起動しません）。

5. **ドライバの機能拡張を有効化 (初回のみ・手動)**  
   上記でインストール・有効化リクエストまでは自動化されていますが，**実際に
   有効化するトグルはSIPの制約上どうしても手動操作が必要**です．
   `システム設定 → 一般 → ログイン項目と機能拡張 → ドライバの機能拡張` を開き，
   `Karabiner DriverKit VirtualHIDDevice` を有効化してください．

6. **Kanataへの権限付与 (初回のみ)**  
   `システム設定 → プライバシーとセキュリティ` で以下2つを許可してください．
   `/usr/local/bin/kanata` をFinderの `Cmd+Shift+G` で直接パス入力して追加する
   のが確実です．
   - **入力監視 (Input Monitoring)**
   - **アクセシビリティ (Accessibility)**

   許可後にKanataが権限を拾わない場合は，一度再起動を促してください．
   ```bash
   sudo launchctl kickstart -k system/org.nixos.kanata
   ```

7. **配色反映 (Matugen) の初回許可 (任意)**  
   `ctrl-cmd-w` (壁紙ピッカー) や `matugen-apply` を初めて実行すると，現在の壁紙を
   取得するために「システムイベント」のオートメーション許可を求めるダイアログが
   出ることがあります．許可すると以後は自動で通ります．詳細は
   [matugen-palette.md](docs/matugen-palette.md) を参照してください．

8. **AeroSpace設定の再読み込み (通常は不要)**  
   ログイン20秒後にAeroSpaceの設定リロードとborders起動を自動で行うLaunchAgent
   (`modules/apps/aerospace/default.nix`) があるため，通常は何もしなくても
   次回ログイン時に最新設定が反映されます．`darwin-rebuild switch` 直後，
   ログアウトを待たずにすぐ反映を見たい場合だけ手動でリロードしてください
   （`xdg.configFile`で生成される`aerospace.toml`はファイルを書き換えただけでは
   AeroSpace自身に反映されず，`after-startup-command`はAeroSpace自身の起動時に
   しか走らないため）．
   ```bash
   aerospace reload-config
   ```

![divider](https://capsule-render.vercel.app/api?type=rect&height=3&color=0:e6c384,50:7aa89f,100:a292a3)

<details>
<summary>📖 <b>English Translation (Click to expand)</b></summary>

# 🌌 nix-config

Declarative configurations for NixOS, Ubuntu (Desktop), WSL2, and macOS managed via **Nix Flakes**, **Home Manager**, and **nix-darwin**.

## 🗺️ Documentation & Navigation

| Target | Module | Guide | Key Functionality |
| :--- | :--- | :--- | :--- |
| **NixOS** | 🗔 Hyprland | [hyprland.md](docs/hyprland.md) | Wayland tiling, Matugen color scheme, Waybar. |
| **Windows / WSL2** | 🗔 komorebi + YASB | [komorebi.md](docs/komorebi.md) / [matugen-palette.md](docs/matugen-palette.md) | Windows-side tiling WM, YASB status bar, Matugen dynamic theming. |
| **macOS** | 🗔 AeroSpace | [aerospace.nix](modules/apps/aerospace/default.nix) / [matugen-palette.md](docs/matugen-palette.md) | macOS tiling, `Cmd+Ctrl` modifier, JankyBorders highlight, Matugen wallpaper theming. |
| **NixOS / Desktop** | ⌨️ Kanata | [kanata.md](docs/kanata.md) | System-level remap (SandS navigation, macOS-like IME). |
| **Common (App)** | 💻 WezTerm | [wezterm.md](docs/wezterm.md) | 75% transparent window, dynamic tab parsing, Leader key. |
| **Common (App)** | 📝 Neovim | [neovim.md](docs/neovim.md) | Custom config built with Lazy.nvim, optimized Vim macros. |
| **Common (App)** | 📁 Yazi | [yazi.md](docs/yazi.md) | Cyberdream transparent file manager with shell sync hook. |
| **Common (CLI)** | 🧰 CLI tools | [cli-tools.md](docs/cli-tools.md) | Usage cheatsheet for atuin, tldr, fd, delta, btop, smassh. |

## 📂 Repository Structure

* `hosts/`: Host-specific entry points (NixOS, Linux Desktop, WSL2, macOS).
* `modules/`: Shared reusable configurations (Window managers, CLI apps, Zsh configs).
* `docs/`: In-depth manuals and keyboard shortcuts mapping lists.

## 🚀 Quick Start (Setup Commands)

```bash
mkdir -p ~/ghq/github.com/Naruto-Takahashi
cd ~/ghq/github.com/Naruto-Takahashi
git clone https://github.com/Naruto-Takahashi/nix-config.git
cd nix-config
```

### NixOS Setup
1. Copy target `hardware-configuration.nix` under `hosts/nixos/`.
2. Apply changes: `sudo nixos-rebuild switch --flake .#nixos --impure`
3. Reboot to let Kanata services spin up.

### Standalone Ubuntu Setup
1. Install Nix and enable Flakes.
2. Build home profile: `nix run github:nix-community/home-manager -- switch --flake .#nalt-ubuntu --impure`
3. Enable Kanata systemd service: `systemctl --user enable --now kanata && exec zsh`

### WSL2 Setup
1. Install Nix and enable Flakes.
2. Build home profile: `nix run github:nix-community/home-manager -- switch --flake .#nalt-wsl --impure`
3. Synchronize configurations into Windows side directories: `sync-win && exec zsh`

### macOS Setup (`nalt-mac`)
Keyboard remapping (Kanata) and wallpaper-based theming (Matugen) need a few manual
GUI steps due to macOS's TCC permission model — Nix alone can't finish the setup.
1. Install Xcode Command Line Tools: `xcode-select --install`
2. Install Nix and enable Flakes.
3. Install Homebrew (required for nix-darwin cask management):
   `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
4. Setup configuration symlink:
   `mv ~/.config/home-manager ~/.config/home-manager.bak`
   `ln -s ~/ghq/github.com/Naruto-Takahashi/nix-config ~/.config/home-manager`
5. Apply and activate (First-time bootstrap):
   `sudo nix run github:LnL7/nix-darwin -- switch --flake .#nalt-mac --impure`
   (a self-signed cert is auto-generated on first activation so Kanata's TCC grants
   survive future rebuilds — see `hosts/mac/darwin.nix`. The same activation also
   downloads, installs, and requests activation for **Karabiner-DriverKit-VirtualHIDDevice
   v6.2.0** — exact version required, Kanata's Rust crate is pinned to it, and it's
   fetched via a hash-pinned `fetchurl` so it's always the same build. Karabiner-Elements
   itself is never installed — it fights Kanata via Background Task Management.)
6. Enable the driver extension (one-time, manual — this is the only step that
   can't be automated, macOS's SIP requires a human click here): open
   `System Settings → General → Login Items & Extensions → Driver Extensions` and
   enable `Karabiner DriverKit VirtualHIDDevice`.
7. Grant Kanata **Input Monitoring** and **Accessibility** permissions under
   `System Settings → Privacy & Security` (add `/usr/local/bin/kanata` via Finder's
   `Cmd+Shift+G`). If it doesn't take effect immediately:
   `sudo launchctl kickstart -k system/org.nixos.kanata`
8. First run of the wallpaper picker (`ctrl-cmd-w`) / `matugen-apply` may prompt for
   an Automation permission for "System Events" (used to detect the current
   wallpaper) — allow it once. See [matugen-palette.md](docs/matugen-palette.md).
9. Apply subsequent updates (Recommended/Fast): `darwin-rebuild switch --flake .#nalt-mac`
   A LaunchAgent (`modules/apps/aerospace/default.nix`) reloads AeroSpace's config and
   relaunches `borders` automatically ~20s after every login, so this is normally
   nothing to worry about. If you want changes reflected immediately without waiting
   for the next login, run `aerospace reload-config` yourself (`after-startup-command`
   only runs at AeroSpace's own launch, not on file changes).


</details>

<div align="center">

![footer](https://capsule-render.vercel.app/api?type=waving&height=110&color=0:e6c384,35:7aa89f,65:2d4f67,100:181616&section=footer)

</div>
