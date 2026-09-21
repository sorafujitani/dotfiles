# Bashの補完・履歴を設定する

Ubuntu / DebianのBash 4以上、rootまたはsudo権限が必要です。

## VMで更新する（導入済みの場合）

SSH先で普段のユーザーとして実行します。

**Vim の更新**

```bash
curl -fL https://raw.githubusercontent.com/sorafujitani/dotfiles/main/dot_vimrc -o "$HOME/.vimrc"
```

Vim を開き直して反映します。権限エラーの対処は「4. Vim の設定を更新する」を参照してください。

**Bash・補完・ツールの更新**

```bash
bash ~/setup-remote-bash.sh && exec bash -l
```

fzf.vim の導入・更新は Bash のセットアップで行います。Vim でも使う場合は上の両方を実行してください。

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
bash ~/setup-remote-bash.sh && exec bash -l
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
| `bash-completion` / `fzf` | Bash の補完・候補や履歴の絞り込み |
| `curl` / `xz` | HTTP 通信・ダウンロード、XZ ファイルの圧縮・展開 |
| `git` / `vim` | ソース管理・ファイル編集 |
| `fzf.vim` | Vim 内でファイル・履歴・文字列を絞り込み |
| `rg` / `fdfind` | ファイルをまたぐ文字列検索・ファイル名検索 |
| `batcat` / `less` / `tree` | 色付きのファイル表示・長い出力の閲覧・ディレクトリ構造の表示 |
| `jq` | JSON の整形・値の抽出 |
| `tmux` | SSH 切断後も端末セッションを維持 |
| `herdr` | ワークスペース・タブ・ペインで端末やエージェントを管理 |
| `htop` / `lsof` | CPU・メモリ・プロセスの監視、開いているファイルやポートの確認 |
| `rsync` / `unzip` | ファイルの同期・転送、ZIP の展開 |
| `strace` | プロセスが行うシステムコールの調査 |
| `ps` / `pgrep` / `pstree` / `fuser` | プロセスの一覧・検索・親子関係、ファイルの使用者を確認 |
| `free` / `vmstat` | メモリ・CPU・I/O の状態を確認 |
| `tcpdump` / `dig` / `ss` / `ip` | 通信・DNS・接続状態の調査 |
| `ncdu` | ディスク使用量の調査 |
| `file` / `zip` | ファイル形式の確認・ZIP の作成 |
| `shellcheck` | シェルスクリプトの問題を検出 |

Ubuntu / Debian では `fd-find` のコマンド名は `fdfind`、`bat` は `batcat` です。`ca-certificates` は HTTPS 通信、`xz-utils` は ble.sh の配布ファイルの展開に使います。

`dig` は `dnsutils`、`ss`・`ip` は `iproute2`、`ps`・`pgrep`・`free`・`vmstat` は `procps`、`pstree`・`fuser` は `psmisc` に含まれます。

パッケージ情報: https://packages.ubuntu.com/noble/fd-find / https://packages.ubuntu.com/noble/bat

herdr は公式インストーラーで `~/.local/bin` に導入します。導入済みなら再インストールせず、起動は `herdr`、更新は `herdr update` です。
公式: https://herdr.dev/

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

## 4. Vim の設定を更新する

セットアップで fzf.vim と対応版 fzf を `~/.vim/dotfiles` に導入します。Vim を開き直すと使えます。`sudo vim` でも、普段のユーザーの vimrc を読み込む設定なら利用できます。

| キー | 検索対象 |
| --- | --- |
| `Ctrl + P` | ファイル |
| `Ctrl + G` | カレントディレクトリ配下の文字列（入力ごとに rg で検索） |
| `Ctrl + B` | 開いているバッファ |
| `Ctrl + L` | 最近開いたファイル |
| `Ctrl + F` | 現在のバッファの行 |
| `Space` → `:` | コマンド履歴 |
| `Space` → `f` → `h` | ヘルプ |

候補は文字入力で絞り込み、`Enter` で開き、`Esc` で閉じます。検索範囲は Vim の `:pwd` で確認し、`:cd ~/private_isu` などで変更できます。プラグイン未導入時は従来の検索に戻ります。

公式: https://github.com/junegunn/fzf.vim

挿入モードで `()`・`[]`・`{}`・ダブルクォート・シングルクォート・バッククォートを自動補完します。閉じ文字の入力で次へ進み、空のペアは `Backspace` でまとめて削除できます。

Bash のセットアップでは vimrc は更新されません。SSH先で普段のユーザーとして実行してください。

```bash
curl -fL https://raw.githubusercontent.com/sorafujitani/dotfiles/main/dot_vimrc -o "$HOME/.vimrc"
```

`Permission denied` が出て、`.vimrc` の所有者が root になっていたら、自分に戻して再実行します。

```bash
ls -l "$HOME/.vimrc"
sudo chown "$(id -un):$(id -gn)" "$HOME/.vimrc"
curl -fL https://raw.githubusercontent.com/sorafujitani/dotfiles/main/dot_vimrc -o "$HOME/.vimrc"
```

Vim を開き直すか、開いている Vim で `:source ~/.vimrc` を実行すると反映されます。
`sudo vim` の場合は `:source /home/isucon/.vimrc` のように、普段のユーザーのパスを指定してください。
