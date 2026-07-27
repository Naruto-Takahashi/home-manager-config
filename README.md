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

## どれがどのOSで動くか (対応表)

このリポジトリは4つのホスト (`nixosConfigurations.nixos` / `homeConfigurations.nalt-ubuntu` / `homeConfigurations.nalt-wsl` / `darwinConfigurations.nalt-mac`) を1つのFlakeから宣言的に管理しています．
全ホスト共通の土台は [`profiles/base.nix`](profiles/base.nix) で，そこにホストごとの [`hosts/<host>/`](hosts) が個別モジュールを足していく構造です．
**同じ「Alt長押しでウィンドウ操作」のような機能でも，OSごとに実装方式が違う**箇所があるので，表で確認してから各ドキュメントに進んでください．

凡例: ✅ 有効 / ➖ 未導入 (この構成では使っていない) / (Windows) Windows側で動作 (WSLからは同期のみ)

| 機能 / モジュール | NixOS | Ubuntu | WSL2 | macOS | 詳細ドキュメント |
| :--- | :---: | :---: | :---: | :---: | :--- |
| **タイルWM** | Hyprland ✅ | ➖ | komorebi (Windows) | AeroSpace ✅ | [hyprland.md](docs/hyprland.md) / [komorebi.md](docs/komorebi.md) / [aerospace.md](docs/aerospace.md) |
| **ステータスバー** | Waybar ✅ | ➖ | YASB (Windows) | macOS標準メニューバー | [hyprland.md](docs/hyprland.md) / [komorebi.md](docs/komorebi.md) |
| **キーボードリマップ** | Kanata ✅ | Kanata ✅※1 | AutoHotkey (Windows)※2 | Kanata ✅※3 | [kanata.md](docs/kanata.md) |
| **壁紙連動の動的配色 (Matugen)** | ✅ | ➖※4 | ✅ (Windows側) | ✅ | [matugen-palette.md](docs/matugen-palette.md) |
| **日本語入力** | fcitx5 + Mozc ✅ | fcitx5 + Mozc ✅ | Windows標準IME (kanata非搭載のため対象外) | macOS標準IME | [kanata.md](docs/kanata.md) (切替キーのみ) |
| **リモートデスクトップ (Tailscale+Sunshine)** | ✅ | ➖ | ➖ (接続元クライアント) | ➖ | [remote-desktop.md](docs/remote-desktop.md) |
| **Obsidian MCP連携** | ➖ | ➖ | ✅ | ➖ | [obsidian-mcp.md](docs/obsidian-mcp.md) |
| **Homebrew Cask管理** | ➖ | ➖ | ➖ | ✅ | [hosts/mac/darwin.nix](hosts/mac/darwin.nix) |
| **WezTerm / Neovim / Yazi / lazygit / git / eza / bat / btop / atuin / starship / gitmoji等** | ✅ | ✅ | ✅ | ✅ | [wezterm.md](docs/wezterm.md) / [neovim.md](docs/neovim.md) / [yazi.md](docs/yazi.md) / [cli-tools.md](docs/cli-tools.md) / [gitmoji.md](docs/gitmoji.md) |

※1 Ubuntu側はKanata自体は動きますが，このリポジトリではUbuntu用のタイルWMを設定していないため，`Alt`長押しのウィンドウ操作系バインド (`Super+...`) を実際に処理するWM側の設定はありません．SandS移動・IME切替・CapsLock改修は問題なく使えます．
※2 WSLからはWindows側の物理キーボードを直接掴めないため，Kanataではなく [`modules/input/ahk/main.ahk`](modules/input/ahk/main.ahk) が同等の機能を別実装しています．
※3 macOSはWM操作の変換先が`Ctrl+Cmd`（NixOS/Ubuntuは`Super`単体）になるなど，キー配線が一部異なります．詳細は[kanata.md](docs/kanata.md)の「対象OS・実装方式の違い」を参照．
※4 Ubuntu環境向けのMatugen配色パイプラインは未整備です（`modules/theming/matugen/`はWSL・Mac・NixOS向けの実装のみ）．

![divider](https://capsule-render.vercel.app/api?type=rect&height=3&color=0:e6c384,50:7aa89f,100:a292a3)

## ディレクトリ構造

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
│   ├── apps/                  # アプリケーション個別設定 (wezterm, neovim, yazi, lazygit, git, bat,
│   │                          #   eza, btop, git-hooks, aerospace[Mac専用], vivaldi)
│   ├── services/              # ユーザーサービス (obsidian-mcp)
│   ├── shell/                 # シェル・端末環境 (zsh, starship, fastfetch, direnv, atuin)
│   ├── input/                 # 入力系 (kanata キーリマップ[NixOS/Ubuntu/Mac], ahk[WSL], fcitx5 日本語入力)
│   ├── theming/                # Matugen 共通ロジック / テンプレート (lib, templates) と
│   │                          #   ホスト別パイプライン (wsl/, mac/)
│   └── desktop/               # Linux GUI 共通 (パッケージ, デスクトップエントリ, MIME)
├── profiles/                  # 全ホスト共通プロファイル (base.nix)
└── docs/                      # 各種仕様・キーマップ解説ドキュメント
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
| **Ubuntu (Desktop)** | [docs/setup-ubuntu.md](docs/setup-ubuntu.md) | Nix非搭載環境へのシングルユーザーインストールから |
| **WSL2** | [docs/setup-wsl.md](docs/setup-wsl.md) | 適用後に`sync-win`でWindows側へ設定を同期 |
| **macOS** | [docs/setup-mac.md](docs/setup-mac.md) | 手順が最も多い。TCC/SIPの都合で数点だけ手動のGUI操作が残る |

![divider](https://capsule-render.vercel.app/api?type=rect&height=3&color=0:e6c384,50:7aa89f,100:a292a3)

<details>
<summary><b>English Translation (Click to expand)</b></summary>

# nix-config

Declarative configurations for NixOS, Ubuntu (Desktop), WSL2, and macOS managed via **Nix Flakes**, **Home Manager**, and **nix-darwin**.

## What runs where (OS support matrix)

This repo manages four hosts (`nixosConfigurations.nixos` / `homeConfigurations.nalt-ubuntu` /
`homeConfigurations.nalt-wsl` / `darwinConfigurations.nalt-mac`) from a single flake. All hosts
share [`profiles/base.nix`](profiles/base.nix) as a baseline, and each [`hosts/<host>/`](hosts)
adds host-specific modules on top. **The same logical feature (e.g. "hold Alt to manage windows")
is often implemented differently per OS** — check this table before diving into a doc.

Legend: ✅ enabled · ➖ not set up in this config · (Windows) runs on the Windows side (WSL only syncs to it)

| Feature / Module | NixOS | Ubuntu | WSL2 | macOS | Docs |
| :--- | :---: | :---: | :---: | :---: | :--- |
| **Tiling WM** | Hyprland ✅ | ➖ | komorebi (Windows) | AeroSpace ✅ | [hyprland.md](docs/hyprland.md) / [komorebi.md](docs/komorebi.md) / [aerospace.md](docs/aerospace.md) |
| **Status bar** | Waybar ✅ | ➖ | YASB (Windows) | native macOS menu bar | [hyprland.md](docs/hyprland.md) / [komorebi.md](docs/komorebi.md) |
| **Keyboard remapping** | Kanata ✅ | Kanata ✅* | AutoHotkey (Windows)** | Kanata ✅*** | [kanata.md](docs/kanata.md) |
| **Wallpaper-driven theming (Matugen)** | ✅ | ➖**** | ✅ (Windows side) | ✅ | [matugen-palette.md](docs/matugen-palette.md) |
| **Japanese input** | fcitx5 + Mozc ✅ | fcitx5 + Mozc ✅ | native Windows IME (no Kanata here) | native macOS IME | [kanata.md](docs/kanata.md) (switch keys only) |
| **Remote desktop (Tailscale+Sunshine)** | ✅ | ➖ | ➖ (client only) | ➖ | [remote-desktop.md](docs/remote-desktop.md) |
| **Obsidian MCP** | ➖ | ➖ | ✅ | ➖ | [obsidian-mcp.md](docs/obsidian-mcp.md) |
| **Homebrew Cask management** | ➖ | ➖ | ➖ | ✅ | [hosts/mac/darwin.nix](hosts/mac/darwin.nix) |
| **WezTerm / Neovim / Yazi / lazygit / git / eza / bat / btop / atuin / starship / gitmoji, etc.** | ✅ | ✅ | ✅ | ✅ | [wezterm.md](docs/wezterm.md) / [neovim.md](docs/neovim.md) / [yazi.md](docs/yazi.md) / [cli-tools.md](docs/cli-tools.md) / [gitmoji.md](docs/gitmoji.md) |

\* Kanata itself runs fine on Ubuntu, but this repo doesn't configure a tiling WM for Ubuntu, so
the WM-facing bindings (`Super+...`) have nothing to act on them. SandS navigation, IME switching,
and the CapsLock remap all still work.
\*\* WSL can't grab Windows' physical keyboard directly, so [`modules/input/ahk/main.ahk`](modules/input/ahk/main.ahk)
reimplements the equivalent behavior separately instead of using Kanata.
\*\*\* macOS translates the WM modifier to `Ctrl+Cmd` (vs. bare `Super` on NixOS/Ubuntu) and a few
other keys differ — see "OS別の違い" in [kanata.md](docs/kanata.md).
\*\*\*\* There's no Matugen theming pipeline for Ubuntu yet (`modules/theming/matugen/` only has
WSL, Mac, and NixOS implementations).

## Repository Structure

* `hosts/`: Host-specific entry points (NixOS, Linux Desktop, WSL2, macOS).
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
| Ubuntu (Desktop) | [docs/setup-ubuntu.md](docs/setup-ubuntu.md) | Install Nix, then `nix run github:nix-community/home-manager -- switch --flake .#nalt-ubuntu --impure` |
| WSL2 | [docs/setup-wsl.md](docs/setup-wsl.md) | Same as Ubuntu but `.#nalt-wsl`, then `sync-win` to push config to the Windows side |
| macOS | [docs/setup-mac.md](docs/setup-mac.md) | `sudo nix run github:LnL7/nix-darwin -- switch --flake .#nalt-mac --impure`, then a few manual TCC/SIP permission grants (unavoidable — see the guide) |


</details>

<div align="center">

![footer](https://capsule-render.vercel.app/api?type=waving&height=110&color=0:e6c384,35:7aa89f,65:2d4f67,100:181616&section=footer)

</div>
