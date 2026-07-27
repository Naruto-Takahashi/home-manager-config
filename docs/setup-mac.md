# 🍎 macOS (darwin) セットアップ手順 (`nalt-mac`)

[README.md](../README.md) の「どれがどのOSで動くか」対応表も参照してください。

M1 Mac などの macOS 環境でシステム設定およびアプリケーション群を統合管理する手順です．
キーボード操作 (Kanata) と壁紙配色連携 (Matugen) は macOS の TCC (権限管理) の都合上，
Nixの適用だけでは完結せず，何点か手動でのGUI操作が必要です．下記の順番通りに進めてください．

```bash
mkdir -p ~/ghq/github.com/Naruto-Takahashi
cd ~/ghq/github.com/Naruto-Takahashi
git clone https://github.com/Naruto-Takahashi/nix-config.git
cd nix-config
```

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
   [matugen-palette.md](matugen-palette.md) を参照してください．

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

## この構成で有効になるもの

AeroSpace (WM) + JankyBorders，Kanata (キーリマップ，`Ctrl+Cmd`変換)，Matugen壁紙配色 (壁紙ピッカー含む)，Homebrew Cask管理。詳細は [aerospace.md](aerospace.md) / [kanata.md](kanata.md) / [matugen-palette.md](matugen-palette.md) を参照してください。

## 手動作業が残る理由 (SIP/TCC)

macOSはセキュリティ上の制約 (System Integrity Protection・Transparency Consent and Control) により，カーネル拡張の有効化やアプリへの権限付与を外部プロセスから完全に自動化することができません。このリポジトリはNixで自動化できる範囲は全て自動化していますが，「トグルを1回押す」「ダイアログでOKを押す」という最後の一手だけはどうしても人間の操作が必要です。
