# リモートのBashに補完・履歴を追加する

Ubuntu / DebianのBash 4以上が対象です。SSH先で次のブロックを貼り付けてください。Macからのファイル転送は不要です。

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

`setup.sh`は、履歴候補と補完メニューを提供するble.shをユーザーディレクトリに導入します。既存の`.bashrc`とログイン設定をバックアップして読込み行を追加します。再実行しても読込み行は重複しません。Linux以外では設定を変更せず終了します。

| 操作 | 動作 |
|---|---|
| 入力中に表示される候補 → `Right` | 履歴候補を確定 |
| `Tab` | コマンド・引数・ファイル名の補完 |
| `Ctrl + R` | fzfで履歴を検索 |
| 入力途中で`Up` / `Down` | 入力した文字から始まる履歴を検索 |
| 同じユーザーの複数セッション | ble.shの履歴を共有 |

設定と履歴は実行したリモートマシンに保存します。Macの履歴やzshctlのスニペットは取り込みません。

一時的に無効にするには、`.bashrc`の`# dotfiles portable bash`直下にある読込み行をコメントアウトし、SSH接続し直してください。

導入元: https://github.com/akinomyoga/ble.sh
