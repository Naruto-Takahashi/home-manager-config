<div align="center">

![header](https://capsule-render.vercel.app/api?type=waving&height=210&color=0:181616,35:2d4f67,65:7aa89f,100:e6c384&text=nix-config&fontColor=c5c9c5&fontSize=64&fontAlignY=36&desc=Declarative%20environments%20for%20NixOS%20%C2%B7%20WSL2%20%C2%B7%20macOS&descColor=c5c9c5&descSize=16&descAlignY=58)

[![CI](https://img.shields.io/github/actions/workflow/status/Naruto-Takahashi/nix-config/check.yml?branch=main&style=flat-square&logo=github-actions&logoColor=white&label=CI&labelColor=181616)](https://github.com/Naruto-Takahashi/nix-config/actions/workflows/check.yml)
[![NixOS](https://img.shields.io/badge/NixOS-unstable-5277C3?style=flat-square&logo=nixos&logoColor=white&labelColor=181616)](https://nixos.org)
[![Flakes](https://img.shields.io/badge/Nix-Flakes-7aa89f?style=flat-square&logo=nixos&logoColor=white&labelColor=181616)](https://nixos.wiki/wiki/Flakes)
[![Home Manager](https://img.shields.io/badge/Home-Manager-e6c384?style=flat-square&logo=nixos&logoColor=white&labelColor=181616)](https://github.com/nix-community/home-manager)
[![nix-darwin](https://img.shields.io/badge/nix-darwin-a292a3?style=flat-square&logo=apple&logoColor=white&labelColor=181616)](https://github.com/LnL7/nix-darwin)
[![Last Commit](https://img.shields.io/github/last-commit/Naruto-Takahashi/nix-config?style=flat-square&logo=git&logoColor=white&labelColor=181616&color=7fb4ca)](https://github.com/Naruto-Takahashi/nix-config/commits/main)

<br>

[![Tech Stack](https://skillicons.dev/icons?i=nix,linux,windows,apple,neovim,lua,bash,py,git&theme=dark)](https://github.com/Naruto-Takahashi/nix-config)

</div>

**Nix Flakes** と **Home Manager** を使用して，NixOS，および WSL2 環境を宣言的に一元管理するための設定ファイル群（レシピ）です．

OSレベルのシステム定義から，シェル環境，ウィンドウマネージャー，開発ツールまでを一元管理し，キーボード駆動の快適な開発環境を構築します．すべての CLI/GUI が **Matugen** により壁紙から生成された配色で統一されます．

![divider](https://capsule-render.vercel.app/api?type=rect&height=3&color=0:e6c384,50:7aa89f,100:a292a3)

## どれがどのOSで動くか (対応表)

このリポジトリは3つのホスト (`nixosConfigurations.nixos` / `homeConfigurations.wsl` / `darwinConfigurations.mac`) を1つのFlakeから宣言的に管理しています．
全ホスト共通の土台は [`profiles/base.nix`](profiles/base.nix) で，そこにホストごとの [`hosts/<host>/`](hosts) が個別モジュールを足していく構造です．
**同じ「Alt長押しでウィンドウ操作」のような機能でも，OSごとに実装方式が違う**箇所があるので，表で確認してから各ドキュメントに進んでください．

凡例: ✅ 有効 / ➖ 未導入 (この構成では使っていない) / (Windows) Windows側で動作 (WSLからは同期のみ)

| 機能 / モジュール | NixOS | WSL2 | macOS |
| :--- | :---: | :---: | :---: |
| **タイルWM** | [Hyprland](docs/hyprland.md) ✅ | [komorebi](docs/komorebi.md) (Windows) | [AeroSpace](docs/aerospace.md) ✅ |
| **ステータスバー** | [Waybar](docs/hyprland.md) ✅ | [YASB](docs/komorebi.md) (Windows) | macOS標準メニューバー |
| **キーボードリマップ** | [Kanata](docs/kanata.md) ✅ | [AutoHotkey](docs/kanata.md) (Windows)※1 | [Kanata](docs/kanata.md) ✅※2 |
| **壁紙連動の動的配色** | [Matugen](docs/matugen-palette.md) ✅ | [Matugen](docs/matugen-palette.md) ✅ (Windows側) | [Matugen](docs/matugen-palette.md) ✅ |
| **日本語入力** | fcitx5 + Mozc ✅ | Google日本語入力 (kanata非搭載のため対象外) | macOS標準IME ([切替キー](docs/kanata.md)) |
| **リモートデスクトップ** | [Tailscale+Sunshine](docs/remote-desktop.md) ✅ | ➖ (接続元クライアント) | ➖ |
| **Obsidian MCP連携** | ➖ | [Obsidian MCP](docs/obsidian-mcp.md) ✅ | ➖ |
| **Homebrew Cask管理** | ➖ | ➖ | [darwin.nix](hosts/mac/darwin.nix) ✅ |
| [WezTerm](docs/wezterm.md) | ✅ | ✅ | ✅ |
| [Neovim](docs/neovim.md) | ✅ | ✅ | ✅ |
| [Yazi](docs/yazi.md) | ✅ | ✅ | ✅ |
| [lazygit / eza / bat / btop / atuin / starship等](docs/cli-tools.md) | ✅ | ✅ | ✅ |
| [gitmoji](docs/gitmoji.md) (git-hooks) | ✅ | ✅ | ✅ |

※1 WSLからはWindows側の物理キーボードを直接掴めないため，Kanataではなく [`modules/input/ahk/main.ahk`](modules/input/ahk/main.ahk) が同等の機能を別実装しています．
※2 macOSはWM操作の変換先が`Ctrl+Cmd`（NixOSは`Super`単体）になるなど，キー配線が一部異なります．詳細は[kanata.md](docs/kanata.md)の「対象OS・実装方式の違い」を参照．

![divider](https://capsule-render.vercel.app/api?type=rect&height=3&color=0:e6c384,50:7aa89f,100:a292a3)

## ディレクトリ構造

```
.
├── flake.nix                  # Flake エントリーポイント（システム構成の定義）
├── hosts/                     # ホスト別の設定エントリーポイント
│   ├── nixos/                 # NixOS 設定（システム設定 ＋ Home Manager 設定）
│   ├── wsl/                   # WSL2用 Home Manager スタンドアロン設定
│   └── mac/                   # macOS用 nix-darwin + Home Manager 統合設定
├── modules/                   # 再利用可能な共通設定モジュール群
│   ├── wm/                    # ウィンドウマネージャー設定 (hyprland, komorebi, yasb)
│   ├── apps/                  # アプリケーション個別設定 (wezterm, neovim, yazi, lazygit, git, bat,
│   │                          #   eza, btop, git-hooks, aerospace[Mac専用], vivaldi)
│   ├── services/              # ユーザーサービス (obsidian-mcp)
│   ├── shell/                 # シェル・端末環境 (zsh, starship, fastfetch, direnv, atuin)
│   ├── input/                 # 入力系 (kanata キーリマップ[NixOS/Mac], ahk[WSL], fcitx5 日本語入力)
│   ├── theming/                # Matugen 共通ロジック / テンプレート (lib, templates) と
│   │                          #   ホスト別パイプライン (wsl/, mac/)
│   └── desktop/               # Linux GUI 共通 (パッケージ, デスクトップエントリ, MIME)
├── profiles/                  # 全ホスト共通プロファイル (base.nix)
└── docs/                      # 各種仕様・キーマップ解説ドキュメント ([索引](docs/README.md))
```

![divider](https://capsule-render.vercel.app/api?type=rect&height=3&color=0:e6c384,50:7aa89f,100:a292a3)

## セットアップとインストール手順 (移行ガイド)

環境の一貫性を保つため，リポジトリは必ず規定の `ghq` ディレクトリ構造配下にクローンしてください．

```bash
mkdir -p ~/ghq/github.com/Naruto-Takahashi
cd ~/ghq/github.com/Naruto-Takahashi
git clone https://github.com/Naruto-Takahashi/nix-config.git
cd nix-config
```

OSごとの詳しい手順は個別ページに分けています．上の対応表で自分のホストを確認してから該当ページを開いてください．

| ホスト | セットアップ手順 | 特記事項 |
| :--- | :--- | :--- |
| **NixOS** | [docs/setup-nixos.md](docs/setup-nixos.md) | 最もシンプル。`nixos-rebuild switch`一発 |
| **WSL2** | [docs/setup-wsl.md](docs/setup-wsl.md) | 適用後に`sync-win`でWindows側へ設定を同期 |
| **macOS** | [docs/setup-mac.md](docs/setup-mac.md) | 手順が最も多い。TCC/SIPの都合で数点だけ手動のGUI操作が残る |
| **sudo無し共有Linux (rootless podman)** | [docs/setup-distrobox.md](docs/setup-distrobox.md) | CLIツールのみのアドオン的プロファイル。distroboxコンテナ内に`/nix`を作る |

![divider](https://capsule-render.vercel.app/api?type=rect&height=3&color=0:e6c384,50:7aa89f,100:a292a3)

<details>
<summary><b>English Translation (Click to expand)</b></summary>

# nix-config

Declarative configurations for NixOS, WSL2, and macOS managed via **Nix Flakes**, **Home Manager**, and **nix-darwin**.

## What runs where (OS support matrix)

This repo manages three hosts (`nixosConfigurations.nixos` / `homeConfigurations.wsl` /
`darwinConfigurations.mac`) from a single flake. All hosts
share [`profiles/base.nix`](profiles/base.nix) as a baseline, and each [`hosts/<host>/`](hosts)
adds host-specific modules on top. **The same logical feature (e.g. "hold Alt to manage windows")
is often implemented differently per OS** — check this table before diving into a doc.

Legend: ✅ enabled · ➖ not set up in this config · (Windows) runs on the Windows side (WSL only syncs to it)

| Feature / Module | NixOS | WSL2 | macOS |
| :--- | :---: | :---: | :---: |
| **Tiling WM** | [Hyprland](docs/hyprland.md) ✅ | [komorebi](docs/komorebi.md) (Windows) | [AeroSpace](docs/aerospace.md) ✅ |
| **Status bar** | [Waybar](docs/hyprland.md) ✅ | [YASB](docs/komorebi.md) (Windows) | native macOS menu bar |
| **Keyboard remapping** | [Kanata](docs/kanata.md) ✅ | [AutoHotkey](docs/kanata.md) (Windows)* | [Kanata](docs/kanata.md) ✅** |
| **Wallpaper-driven theming** | [Matugen](docs/matugen-palette.md) ✅ | [Matugen](docs/matugen-palette.md) ✅ (Windows side) | [Matugen](docs/matugen-palette.md) ✅ |
| **Japanese input** | fcitx5 + Mozc ✅ | Google Japanese Input (no Kanata here) | native macOS IME ([switch keys](docs/kanata.md)) |
| **Remote desktop** | [Tailscale+Sunshine](docs/remote-desktop.md) ✅ | ➖ (client only) | ➖ |
| **Obsidian MCP** | ➖ | [Obsidian MCP](docs/obsidian-mcp.md) ✅ | ➖ |
| **Homebrew Cask management** | ➖ | ➖ | [darwin.nix](hosts/mac/darwin.nix) ✅ |
| [WezTerm](docs/wezterm.md) | ✅ | ✅ | ✅ |
| [Neovim](docs/neovim.md) | ✅ | ✅ | ✅ |
| [Yazi](docs/yazi.md) | ✅ | ✅ | ✅ |
| [lazygit / eza / bat / btop / atuin / starship, etc.](docs/cli-tools.md) | ✅ | ✅ | ✅ |
| [gitmoji](docs/gitmoji.md) (git-hooks) | ✅ | ✅ | ✅ |

\* WSL can't grab Windows' physical keyboard directly, so [`modules/input/ahk/main.ahk`](modules/input/ahk/main.ahk)
reimplements the equivalent behavior separately instead of using Kanata.
\*\* macOS translates the WM modifier to `Ctrl+Cmd` (vs. bare `Super` on NixOS) and a few
other keys differ — see "OS別の違い" in [kanata.md](docs/kanata.md).

## Repository Structure

* `hosts/`: Host-specific entry points (NixOS, WSL2, macOS).
* `modules/`: Shared reusable configurations (Window managers, CLI apps, Zsh configs).
* `docs/`: In-depth manuals and keyboard shortcuts mapping lists.

## Quick Start

```bash
mkdir -p ~/ghq/github.com/Naruto-Takahashi
cd ~/ghq/github.com/Naruto-Takahashi
git clone https://github.com/Naruto-Takahashi/nix-config.git
cd nix-config
```

Detailed per-host setup steps live in `docs/` (Japanese only, same convention as the rest of `docs/`).
The short version:

| Host | Setup guide | One-liner |
| :--- | :--- | :--- |
| NixOS | [docs/setup-nixos.md](docs/setup-nixos.md) | `sudo nixos-rebuild switch --flake .#nixos --impure`, then reboot |
| WSL2 | [docs/setup-wsl.md](docs/setup-wsl.md) | Install Nix, `nix run github:nix-community/home-manager -- switch --flake .#wsl --impure`, then `sync-win` to push config to the Windows side |
| macOS | [docs/setup-mac.md](docs/setup-mac.md) | `sudo nix run github:LnL7/nix-darwin -- switch --flake .#mac --impure`, then a few manual TCC/SIP permission grants (unavoidable — see the guide) |
| Sudo-less shared Linux (rootless podman) | [docs/setup-distrobox.md](docs/setup-distrobox.md) | CLI-only add-on profile: `distrobox create` an Ubuntu container, install Nix inside it (real `/nix`, no sudo needed on the host), `nix run github:nix-community/home-manager -- switch --flake .#distrobox --impure` |


</details>

<div align="center">

![footer](https://capsule-render.vercel.app/api?type=waving&height=110&color=0:e6c384,35:7aa89f,65:2d4f67,100:181616&section=footer)

</div>
