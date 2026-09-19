# Bashの補完・履歴を設定する

対象はUbuntu / DebianのBash 4以上です。rootまたはsudoを使えるユーザーで実行してください。

## 1. 設定したいサーバーにSSH接続する

普段使っているターミナルで実行します。`user@host`は接続先に置き換えてください。

```sh
ssh user@host
```

## 2. SSH接続先のBashに貼り付ける

次のブロック全体をコピーし、SSH接続後のターミナルに貼り付けて実行してください。sudoのパスワードを求められたら入力します。

```bash
(
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
) && source ~/.bashrc
```

## 3. 動作を確認する

コマンドを何件か実行してから、`Ctrl + R`で履歴検索が開くことを確認してください。`Tab`で補完、入力中に表示される履歴候補は`Right`で確定できます。

次回のSSH接続からは自動で読み込まれます。
