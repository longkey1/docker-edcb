# docker-edcb

[EDCB](https://github.com/xtne6f/EDCB)（Electronic Program Guide Data Capture）の Docker イメージです。日本のテレビ録画および EPG 管理システムをコンテナで実行するためのものです。

## 概要

以下のコンポーネントをまとめたイメージです：

- **EDCB** - EPG 取得・録画ソフトウェア
- **EDCB Material WebUI** - EDCB 向けモダン Web UI
- **BonDriver_LinuxMirakc** - [Mirakc](https://github.com/mirakc/mirakc) 連携用 Linux チューナードライバー

## 対応プラットフォーム

- `linux/amd64`
- `linux/arm64`

## イメージ

```
ghcr.io/longkey1/edcb:latest
```

## BonDriver のバリアント

分割 BonDriver 用のシンボリックリンクが含まれています：

| ファイル | 説明 |
|----------|------|
| `BonDriver_LinuxMirakc.so` | 全チャンネル（地上波＋衛星） |
| `BonDriver_LinuxMirakc_T.so` | 地上波のみ |
| `BonDriver_LinuxMirakc_S.so` | 衛星（BS/CS）のみ |

各 `.so` に対応する `.ini` 設定ファイルも含まれます。

## 使い方

コンテナ起動時に `entrypoint.sh` が `EpgDataCap_Bon` でチャンネルスキャンを実行します：

```sh
sleep 15
/usr/local/bin/EpgDataCap_Bon -d BonDriver_LinuxMirakc.so -chscan
```

データは `/var/local/edcb` 以下に保存されます。

## EDCB リリースの管理

使用する EDCB のリリースタグは `.edcb-release` ファイルで管理しています：

```
work-plus-s-250816
```

リリースを更新する場合はこのファイルを書き換えてください。CI/CD およびローカルビルドの両方で参照されます。

## ビルド

```sh
docker build --build-arg EDCB_RELEASE=$(cat .edcb-release) -t edcb .
```

## CI/CD

`*-[0-9]*` パターンにマッチするタグのプッシュ時に GitHub Actions が自動的にビルドし、GitHub Container Registry へイメージを公開します。`.edcb-release` の内容がイメージタグにも使用されます。
