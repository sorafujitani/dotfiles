# Bashの補完・履歴を設定する

Ubuntu / DebianのBash 4以上、rootまたはsudo権限が必要です。

## 1. 導入スクリプトを保存する

次の内容を、設定したい環境の `~/setup-remote-bash.sh` に保存してください。

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

## 2. Bashで実行する

```bash
bash ~/setup-remote-bash.sh && source ~/.bashrc
```

設定は `${XDG_CONFIG_HOME:-$HOME/.config}/bash/` に配置され、既存の `.bashrc` に読込み行が追加されます。次回のBash起動からは自動で有効になります。

## 3. 使う

- `Tab`：コマンド・引数・ファイル名を補完
- `Ctrl + R`：履歴を検索
- 入力中に表示される履歴候補 → `Right`：候補を確定
- 入力途中で `Up` / `Down`：入力した文字から始まる履歴を検索
