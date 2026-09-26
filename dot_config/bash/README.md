# Bashの補完・履歴を設定する

Ubuntu / DebianのBash 4以上、curl、rootまたはsudo権限が必要です。

## VMで更新する（導入済みの場合）

SSH先で普段のユーザーとして実行します。

**Vim の更新**

```bash
curl -fL https://raw.githubusercontent.com/sorafujitani/dotfiles/main/dot_vimrc -o "$HOME/.vimrc"
```

Vim を開き直して反映します。権限エラーの対処は「4. Vim の設定を更新する」を参照してください。

**Bash・補完・ツールの更新**

```bash
curl -fL https://raw.githubusercontent.com/sorafujitani/dotfiles/main/dot_config/bash/install.sh -o "$HOME/setup-remote-bash.sh" && bash "$HOME/setup-remote-bash.sh" && exec bash -l
```

fzf.vim の導入・更新は Bash のセットアップで行います。Vim でも使う場合は上の両方を実行してください。

## 1. 導入スクリプトを保存する

初回導入・更新は、設定したい環境で次の一コマンドを実行します。スクリプトの保存から実行まで行うため、次の「2」の操作は不要です。

```bash
curl -fL https://raw.githubusercontent.com/sorafujitani/dotfiles/main/dot_config/bash/install.sh -o "$HOME/setup-remote-bash.sh" && bash "$HOME/setup-remote-bash.sh" && exec bash -l
```

普段のユーザーとして実行してください。パッケージの導入時にsudoを使います。設定だけでなく、下表のツールもインストールします。

既存の `interactive.bash` と `setup.sh` は、同じディレクトリの `.backup.*` ファイルに退避してから更新します。ダウンロードに失敗した場合は、設定を置き換えずに終了します。

curlがない場合は、先に `sudo apt-get update && sudo apt-get install -y curl ca-certificates` を実行してください。rootの場合はsudoを外します。

## 2. Bashで実行する

```bash
bash ~/setup-remote-bash.sh && exec bash -l
```

設定は `${XDG_CONFIG_HOME:-$HOME/.config}/bash/` に配置され、既存の `.bashrc` に読込み行が追加されます。次回のBash起動からは自動で有効になります。

`setup.sh` が次のツールをインストールします。導入済みの環境でも、上の一コマンドで設定を更新し、不足するツールを追加できます。

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
| `percona-toolkit` | `pt-query-digest` などで MySQL のスロークエリを分析 |
| `pprotein` / `pprotein-agent` | プロファイルとログの収集・閲覧 |
| `alp` / `slp` | pprotein から呼び出す HTTP・SQL ログ分析 |

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

## 5. pprotein で性能を調べる

セットアップは Linux の amd64 / arm64 向けに、pprotein v1.2.4、alp v1.0.21、slp v0.2.1 を `~/.local/bin` に導入します。既存のコマンドは上書きせず、自動起動もしません。

**起動前に、ファイアウォールなどで 9000・19000 番ポートへの接続元を制限してください。** 本体と agent は全インターフェースで待ち受けます。認証のない管理画面やログ取得先をインターネットへ公開しないでください。

解析用の VM で本体を起動します。結果は作業ディレクトリの `data/` に保存されます。

```bash
mkdir -p "$HOME/pprotein"
cd "$HOME/pprotein"
pprotein
```

手元の端末から SSH 転送し、ブラウザで `http://localhost:9000` を開きます。`user@host` は解析用 VM の接続先に置き換えてください。

```bash
ssh -N -L 9000:127.0.0.1:9000 user@host
```

計測対象の VM では、別の端末で agent を起動します。ログのパスは環境に合わせて変更し、実行ユーザーに読取り権限を付けてください。

```bash
PPROTEIN_HTTPLOG=/var/log/nginx/access.log \
PPROTEIN_SLOWLOG=/var/log/mysql/mysql-slow.log \
pprotein-agent
```

画面の収集設定に、agent の取得先を登録します。同じ VM なら次の URL を使えます。別の VM なら `127.0.0.1` をその VM のプライベートアドレスに置き換えてください。

- HTTP ログ: `http://127.0.0.1:19000/debug/log/httplog`
- SQL ログ: `http://127.0.0.1:19000/debug/log/slowlog`

HTTP ログは LTSV 形式、SQL ログは MySQL のスロークエリログが必要です。セットアップは Nginx・MySQL のログ設定を変更しません。

Go アプリの計測には、対象アプリ自身に pprof または pprotein の連携を組み込んでください。単独起動した agent のプロファイルは、対象アプリのものではありません。

起動した本体・agent は、それぞれの端末で `Ctrl + C` を押すと停止します。

公式: https://github.com/kaz/pprotein
