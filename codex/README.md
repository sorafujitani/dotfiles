# Codexの基本設定とAgent Skillsを導入する

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

Ubuntu / DebianでVim・Bash・Codex本体と設定・公開スキルをまとめて導入する場合は、[一括導入の手順](../bash/README.md#vmで導入更新する)を使います。旧方式の実行ファイルだけが入っている場合も、公式の完全パッケージへ更新します。

設定とスキルだけを適用する場合は、次の1コマンドを実行します。curlとgitが必要です。Linux・macOSで使えます。

```sh
curl -fL https://raw.githubusercontent.com/sorafujitani/dotfiles/main/codex/install.sh -o "$HOME/setup-codex.sh" && sh "$HOME/setup-codex.sh" --download
```

スクリプトがGitHub上のdotfilesから `config.toml` をダウンロードし、`${CODEX_HOME:-$HOME/.codex}/config.toml` へ配置します。あわせて `sorafujitani/skills` の `main` を取得し、Agent Skillsを導入します。取得に失敗した場合は既存の `config.toml` を変更しません。初回導入と更新は同じコマンドを使います。このコマンドはCodex本体をインストールしません。

既存の設定は `config.toml.dotfiles-backup.日時.プロセス番号` に退避します。設定が同じ内容なら設定ファイルは変更せず、スキルの更新だけ行います。設定の一部をマージする処理ではないため、移植先の独自設定が必要なら退避ファイルを参照して追記してください。

配置前に変更対象を確認する場合は、保存済みのスクリプトで次を実行します。

```sh
sh "$HOME/setup-codex.sh" --download --dry-run
```

適用後はCodexを起動し直します。認証は各マシンで行います。ブラウザのない環境では次を実行し、表示されたURLとコードを手元のブラウザで使います。

```sh
codex login --device-auth
codex
```

認証情報・履歴は転送しません。スキルは公開リポジトリから取得し、各スキルの依存CLIや認証は別途準備します。既存のhooksにも触れません。PC固有の通知コマンド、MCP、プラグイン、信頼済みパス、デスクトップ設定、端末のキーバインドは共通設定に含めていません。

通常の `sh install.sh` は他のツールや `codex/hooks.json` などもリンクします。基本設定とスキルを導入する場合は、上の `codex/install.sh` を使ってください。

dotfilesを手元に配置済みの場合は、そのルートで `sh codex/install.sh` を実行すると、リポジトリ内の設定を適用し、GitHubからスキルを取得します。設定だけを通信なしで適用する場合は `sh codex/install.sh --without-skills` を実行します。

CLIの `-c`・`--sandbox`・`--ask-for-approval`、設定プロファイル、信頼済みプロジェクトの `.codex/config.toml` がある場合は、ユーザー設定より優先されます。

公式の設定説明: https://learn.chatgpt.com/docs/config-file/config-basic

ブラウザのない環境での認証: https://learn.chatgpt.com/docs/auth#login-on-headless-devices

## Agent Skillsの配置と更新

公開元: https://github.com/sorafujitani/skills

スキルの実体は `~/ghq/github.com/sorafujitani/skills` にcloneします。直下に `SKILL.md` がある各ディレクトリを `~/.agents/skills/<名前>` へリンクします。`CODEX_HOME` を変更していても、共有スキルの配置先は `~/.agents/skills` です。ローカルだけの未公開スキルは対象になりません。

再実行すると `main` をfast-forwardで更新します。既存checkoutの変更・独自コミット・別ブランチがある場合は停止し、手動での整理を求めます。同名の既存スキル（`${CODEX_HOME:-$HOME/.codex}/skills` 内も含む）は上書きせず、`[SKIP]` と表示します。

設定を変えず、スキルだけを導入・更新する場合:

```sh
sh "$HOME/setup-codex.sh" --skills-only
```

設定だけを導入する場合は `--download --without-skills`、変更予定の確認は `--dry-run` を指定します。dry-runではスキルを取得せず、配置予定先を表示します。

Codexを起動し直し、`/skills` または `$private-isu-tuning` で確認できます。
公式のスキル配置仕様: https://learn.chatgpt.com/docs/build-skills
