# Bashの補完・履歴を設定する

対象はUbuntu / DebianのBash 4以上です。rootまたはsudoを使えるユーザーで実行してください。

**下の長いコードは、SSH接続先の `~/setup-remote-bash.sh` というファイルに貼り付けます。** `.bashrc`に直接貼り付ける必要はありません。

## 1. サーバーにSSH接続する

ターミナルのコマンド入力欄で実行します。`user@host`は接続先に置き換えてください。

```sh
ssh user@host
```

以降の操作は、すべてSSH接続先で行います。

## 2. 導入スクリプトのファイルを開く

SSH接続先のコマンド入力欄で実行します。

```sh
vi ~/setup-remote-bash.sh
```

新しいファイルが開いたら、`i`を押して入力モードにします。

## 3. コードを貼り付けて保存する

次のコードを `#!/usr/bin/env bash` から最後の行までコピーし、開いているviの編集画面に貼り付けてください。コードブロックを囲むバッククォートは含めません。

```bash
#!/usr/bin/env bash
set -e
if (( EUID == 0 )); then
  apt-get update
  apt-get install -y bash-completion fzf curl xz-utils
else
  sudo apt-get update
  sudo apt-get install -y bash-completion fzf curl xz-utils
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

貼り付けたら、次の順で保存してviを終了します。

1. `Esc`を押す。
2. `:wq`と入力する。
3. `Enter`を押す。

## 4. 保存したファイルを実行する

コマンド入力欄に戻ったら、次を実行します。

```bash
bash ~/setup-remote-bash.sh && source ~/.bashrc
```

sudoのパスワードを求められたら入力し、インストールが終わってコマンド入力欄に戻るまで待ちます。エラーで終了した場合は、エラーを解消してから同じコマンドを再実行してください。

この処理で通常は `~/.config/bash/interactive.bash` と `~/.config/bash/setup.sh` が配置され、既存の `.bashrc` に読込み行が追加されます。`XDG_CONFIG_HOME`を設定している場合は、その配下の`bash/`に配置されます。

## 5. 動作を確認する

次のコマンドを実行します。

```bash
echo history-check
```

その後、`Ctrl + R`を押し、`history-check`と入力してください。先ほどのコマンドが検索結果に出れば履歴検索が使えています。`Esc`で検索を閉じます。

次回のSSH接続からは自動で読み込まれるため、導入スクリプトの実行は不要です。
