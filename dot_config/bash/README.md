# Bashの補完・履歴を設定する

Ubuntu / DebianのBash 4以上、rootまたはsudo権限が必要です。

## 1. 導入スクリプトを保存する

次の内容を、設定したい環境の `~/setup-remote-bash.sh` に保存してください。

```bash
#!/usr/bin/env bash
set -e

# Bootstrap downloads; setup.sh installs the remaining tools.
if (( EUID == 0 )); then
  apt-get update
  apt-get install -y curl ca-certificates
else
  sudo apt-get update
  sudo apt-get install -y curl ca-certificates
fi

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/bash"
download_dir=$(mktemp -d)
trap 'rm -rf -- "$download_dir"' EXIT
base_url=https://raw.githubusercontent.com/sorafujitani/dotfiles/main/dot_config/bash
for file in interactive.bash setup.sh; do
  curl -fL --retry 2 "$base_url/$file" -o "$download_dir/$file"
done

mkdir -p "$config_dir"
for file in interactive.bash setup.sh; do
  if [[ -e "$config_dir/$file" ]]; then
    cp -p "$config_dir/$file" "$config_dir/$file.backup.$(date +%Y%m%d%H%M%S).$$"
  fi
  cp "$download_dir/$file" "$config_dir/$file"
done
bash "$config_dir/setup.sh"
```

## 2. Bashで実行する

```bash
bash ~/setup-remote-bash.sh && source ~/.bashrc
```

設定は `${XDG_CONFIG_HOME:-$HOME/.config}/bash/` に配置され、既存の `.bashrc` に読込み行が追加されます。次回のBash起動からは自動で有効になります。

`setup.sh` が次のツールをインストールします。導入済みの環境でも、最新版に更新して再実行すれば追加されます。

```bash
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/bash"
curl -fL https://raw.githubusercontent.com/sorafujitani/dotfiles/main/dot_config/bash/setup.sh -o "$config_dir/setup.sh" &&
  bash "$config_dir/setup.sh"
```

| ツール | 用途 |
| --- | --- |
| `git` / `vim` | ソース管理・ファイル編集 |
| `rg` / `fdfind` | ファイルをまたぐ文字列検索・ファイル名検索 |
| `batcat` / `less` / `tree` | 色付きのファイル表示・長い出力の閲覧・ディレクトリ構造の表示 |
| `jq` | JSON の整形・値の抽出 |
| `tmux` | SSH 切断後も端末セッションを維持 |
| `htop` / `lsof` | CPU・メモリ・プロセスの監視、開いているファイルやポートの確認 |
| `rsync` / `unzip` | ファイルの同期・転送、ZIP の展開 |

Ubuntu / Debian では `fd-find` のコマンド名は `fdfind`、`bat` は `batcat` です。`ca-certificates` は HTTPS 通信、`xz-utils` は ble.sh の配布ファイルの展開に使います。

パッケージ情報: https://packages.ubuntu.com/noble/fd-find / https://packages.ubuntu.com/noble/bat

## 3. 使う

- `Tab`：補完候補が複数あるとき、fzf で絞り込んで選択（ble.sh と fzf が必要）
  - `vim ` の後で `Tab`：ファイル・ディレクトリの候補
  - `cd ` の後で `Tab`：ディレクトリの候補
  - 候補画面で文字入力して絞り込み、`Enter` で確定、`Esc` でキャンセル
- `Ctrl + R`：履歴を検索
- 入力中に表示される履歴候補 → `Right`：候補を確定
- 入力途中で `Up` / `Down`：入力した文字から始まる履歴を検索

通常の `Tab` は現在の入力位置に応じた候補を表示します。配下のファイルを再帰的に検索したい場合は `vim **` の後で `Tab`、ディレクトリなら `cd **` の後で `Tab` を押します。

設定を更新した既存セッションには `exec bash -l` で反映します。

fzf 連携の公式説明: https://github.com/akinomyoga/blesh-contrib/blob/master/integration/fzf.md
