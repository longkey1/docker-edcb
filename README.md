# docker-edcb

[EDCB](https://github.com/xtne6f/EDCB)（Electronic Program Guide Data Capture）の Docker イメージです。日本のテレビ録画および EPG 管理システムをコンテナで実行するためのものです。

## 概要

以下のコンポーネントをまとめたイメージです：

- **[EDCB](https://github.com/xtne6f/EDCB)** - EPG 取得・録画ソフトウェア
- **[EDCB Material WebUI](https://github.com/EMWUI/EDCB_Material_WebUI)** - EDCB 向けモダン Web UI
- **[BonDriver_LinuxMirakc](https://github.com/matching/BonDriver_LinuxMirakc)** - [Mirakc](https://github.com/mirakc/mirakc) 連携用 Linux チューナードライバー

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
work-plus-s-260703
```

リリースを更新する場合はこのファイルを書き換えてください。CI/CD およびローカルビルドの両方で参照されます。

EMWUI のコミットは `.emwui-commit` に40桁のハッシュで固定しています。更新する場合は、使用するコミットのハッシュに書き換えてください。最新のコミットは次のコマンドで確認できます：

```sh
git ls-remote https://github.com/EMWUI/EDCB_Material_WebUI.git HEAD
```

リリースタグは `<EDCBのリリース名>-<EMWUIのコミットハッシュ先頭7桁>` です（例：`work-plus-s-260703-aa938f0`）。同じ組み合わせでは同じタグになります。

設定ファイルの変更をコミットしてから、次のコマンドでリリースします：

```sh
make release              # タグを確認（dry run）
make release dryrun=false # タグをプッシュして GitHub Release を作成
```

同じバージョンのイメージを作り直す場合は `make re-release tag=work-plus-s-260703-aa938f0 dryrun=false` を使用します。タグは現在の設定ファイルの組み合わせと一致する必要があります。

## ビルド

```sh
docker build \
  --build-arg EDCB_RELEASE=$(cat .edcb-release) \
  --build-arg EMWUI_COMMIT=$(cat .emwui-commit) \
  -t edcb .
```

## CI/CD

GitHub Release の公開時に GitHub Actions が自動的にビルドし、GitHub Container Registry へイメージを公開します。リリースタグが設定ファイルの組み合わせと一致することを検証し、指定した EMWUI コミットをビルドします。イメージには `latest`、`<EDCBのリリース名>-latest`、リリースタグが付与されます。
