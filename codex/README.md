# Codexの基本設定を移植する

Codexのモデル・推論・権限などは `~/.codex/config.toml` で設定します。`CODEX_HOME` を指定している場合は、そのディレクトリの `config.toml` です。

`~/.codex/AGENTS.md` は日本語での応答など、エージェントへの文章の指示を置くファイルです。sandboxや承認ポリシーの設定には `config.toml` が必要です。

このディレクトリの `config.toml` には、現在のPCから取り出した共通設定を保存しています。権限設定は次のとおりです。

```toml
approval_policy = "never"
sandbox_mode = "danger-full-access"
default_permissions = ":danger-full-access"
```

確認待ちをせず、サンドボックスによる制限なしで実行する設定です。モデルは `gpt-6.1-sol`、推論強度は `xhigh`、Web検索は `live` です。

## 別のマシンへ適用する

設定したいマシンで次の1コマンドを実行します。curlが必要です。Linux・macOSで使えます。

```sh
curl -fL https://raw.githubusercontent.com/sorafujitani/dotfiles/main/codex/install.sh -o "$HOME/setup-codex.sh" && sh "$HOME/setup-codex.sh" --download
```

スクリプトがGitHub上のdotfilesから `config.toml` をダウンロードし、`${CODEX_HOME:-$HOME/.codex}/config.toml` へ配置します。ダウンロードに失敗した場合は既存設定を変更しません。初回導入も更新も同じコマンドです。

既存の設定は `config.toml.dotfiles-backup.日時.プロセス番号` に退避します。同じ内容なら何も変更しません。設定の一部をマージする処理ではないため、移植先の独自設定が必要なら退避ファイルを参照して追記してください。

配置前に変更対象を確認する場合は、保存済みのスクリプトで次を実行します。

```sh
sh "$HOME/setup-codex.sh" --download --dry-run
```

適用後はCodexを起動し直します。認証は各マシンで行います。ブラウザのない環境では次を実行し、表示されたURLとコードを手元のブラウザで使います。

```sh
codex login --device-auth
codex
```

認証情報・履歴・skillsは転送しません。既存のhooksにも触れません。PC固有の通知コマンド、MCP、プラグイン、信頼済みパス、デスクトップ設定、端末のキーバインドは共通設定に含めていません。

通常の `sh install.sh` は他のツールや `codex/hooks.json` などもリンクします。基本設定だけを移植する場合は、上の `codex/install.sh` を使ってください。

dotfilesを手元に配置済みの場合は、そのルートで `sh codex/install.sh` を実行すると、リポジトリ内の設定を通信なしで適用できます。

CLIの `-c`・`--sandbox`・`--ask-for-approval`、設定プロファイル、信頼済みプロジェクトの `.codex/config.toml` がある場合は、ユーザー設定より優先されます。

公式の設定説明: https://learn.chatgpt.com/docs/config-file/config-basic

ブラウザのない環境での認証: https://learn.chatgpt.com/docs/auth#login-on-headless-devices
