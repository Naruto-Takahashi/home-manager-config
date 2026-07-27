# リモートデスクトップ (Tailscale + Sunshine + Moonlight)

大学VPNを使わずに，外部ネットワーク（自宅など）のWindows端末から研究室のNixOSマシンへ無人リモート接続するための構成です．

## 構成の概要

```
Windows ノート ──(Tailscale: NAT越えVPN)──> NixOS (研究室PC)
   Moonlight  ─────────────────────────────>  Sunshine (KMSキャプチャ + NVENC)
   ssh        ─────────────────────────────>  openssh (復旧・保守用)
```

- **Tailscale**: 両端が外向き接続のみでメッシュVPNを張るため，大学のNAT/ファイアウォールを越えられる（インバウンドポート開放・大学VPNとも不要）．
- **Sunshine**: KMS（カーネルレベル）で画面をキャプチャするため，Waylandコンポジタ（Hyprland/GNOME）に依存せず，ログイン画面すら配信できる．NVENCによるハードウェアエンコードで低遅延．
- **SSH**: Sunshineが落ちたときの復旧経路．Tailscale経由のみ到達可能で，大学LANには公開していない．
- 自動ログイン + スリープ無効化により，**再起動後も無操作でリモート接続可能な状態に復帰**する．

## NixOS側の設定 (nix-config管理)

すべて `hosts/nixos/default.nix` に宣言済み．新しいマシンでは通常のNixOSセットアップ手順（README参照）を踏むだけで以下が有効になる．

| 設定 | 内容 |
| :--- | :--- |
| `services.tailscale` | Tailscale有効化．`tailscale0` を信頼インターフェースに指定 |
| `services.sunshine` | 自動起動・`capSysAdmin`（KMSキャプチャ用）・CUDA対応パッケージ（NVENC） |
| `services.openssh` | 大学LAN非公開（`openFirewall = false`），Tailscale経由のみ |
| `services.displayManager.autoLogin` | 再起動後にセッションを自動開始（getty無効化のバグ回避付き） |
| `systemd.targets.sleep` ほか | サスペンド系を全無効化し，無人中の切断を防止 |
| `hyprland.conf` の `exec-once` | HyprlandがsystemdのGraphical Session Targetを起動しないため，Sunshineを明示起動 |

## 初回セットアップ手順（新しいマシンで1回だけ必要な手動作業）

構成はNixで再現されるが，**認証情報はマシン上のステート**なので以下は毎回手動で行う．

### 1. NixOS側

```bash
# 1. Tailscaleにログイン（表示されるURLをブラウザで開いて認証）
sudo tailscale up

# 2. 自分のTailscale IPを確認（Moonlight登録時に使う）
tailscale ip -4
```

ブラウザで `https://localhost:47990` を開き（自己署名証明書の警告は「詳細設定→続行」で進む），SunshineのWeb UIユーザー名とパスワードを設定する．

### 2. Windows側

1. [Tailscale](https://tailscale.com/download/windows) をインストールし，NixOS側と**同じアカウント**でログイン
2. [Moonlight](https://github.com/moonlight-stream/moonlight-qt/releases) をインストール（`MoonlightSetup-x.x.x.exe`．AppImageはLinux用なので不要）
3. Moonlightの「+」からNixOSマシンの **Tailscale IP** を手動追加
   - LAN内の自動検出（mDNS）で追加すると大学LANのIPで登録され，ファイアウォールに弾かれてオフライン表示になるので必ずTailscale IPを指定する
4. 表示された4桁PINを，NixOS側の Sunshine Web UI（PINタブ）に入力して承認

### 3. 動作確認

- Moonlightにホストがオンライン表示され，接続するとデスクトップが操作できること
- **再起動テスト**: NixOSマシンを再起動し，何も触らずに1〜2分待ってからMoonlightで接続できること（Tailscaleの経路確立に少し時間がかかる）

## 運用メモ

- **日本語入力**: Kanataは Sunshineの仮想キーボード（"Keyboard passthrough"）も掴むため，リモートからの左右Altタップでも ローカル同様にIME切り替えが効く．Windows側のIMEは必ず半角英数（オフ）にしておくこと．
- **電源**: 遠隔から電源は入れられない．離席時はシャットダウンしない．BIOS/UEFIの「AC Power Loss後にPower On」を有効にしておくと停電後も自動復帰する．
- **SSH復旧**: Sunshineが応答しないときは `ssh nalt@<Tailscale IP>` で入って `systemctl --user restart sunshine`．
- **セキュリティ**: SunshineとSSHはTailscale経由でのみ到達可能．SSHは既に鍵認証のみ (`PasswordAuthentication = false`，`hosts/nixos/default.nix`) に絞ってある．
- **クライアント解除**: Sunshine Web UIのPINタブから登録済みデバイスを個別に削除できる．
