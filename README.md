# dotfiles

ツールごとの設定と単体スクリプトを管理します。`install.sh`が設定場所から各ファイルへリンクを張るため、コピーによる同期は不要です。

## 配置

| リポジトリ内 | 配置先 |
| --- | --- |
| `claude/` | `~/.claude/` |
| `codex/` | `~/.codex/` |
| `pi/` | `~/.pi/` |
| `omp/` | `~/.omp/` |
| `zsh/.zshrc` | `~/.zshrc` |
| `zsh/.zshenv` | `~/.zshenv` |
| `zsh/.zprofile` | `~/.zprofile` |
| `vim/.vimrc` | `~/.vimrc` |
| `scripts/` | `~/.local/bin/` |
| `AGENTS.md` | `~/AGENTS.md` |
| その他の対応ツール | `~/.config/<ツール名>/` |

`nvim/`、`wezterm/`、`ghostty/`、`herdr/`、`bash/`などは、そのまま設定ディレクトリに対応します。内部のファイル名と階層は各ツールが読み込む形です。

対応ツールは`install.sh`に列挙しています。`XDG_CONFIG_HOME`が指定されていれば、`~/.config`の代わりにその絶対パスを使います。

## 使い方

リポジトリのルートで実行します。先に変更内容を確認し、問題がなければ適用してください。適用対象は対応ツールの全ファイルです。

```sh
sh install.sh --dry-run
sh install.sh
```

ディレクトリ全体ではなく、ファイル単位でリンクします。設定場所にしかない認証情報や履歴はそのまま残します。

- 既存ファイルは、同じ場所の`元の名前.dotfiles-backup.日時.プロセス番号`へ退避します。
- 同じリンクがあれば何もしません。再実行しても退避ファイルは増えません。
- ツールやスキルのディレクトリが既存のリンクなら、その配下はスキップします。別の管理元は置き換えません。
- `.config`など共通の親ディレクトリがリンクの場合は、何も変更せず終了します。配置先を確認してください。

リンクを辿って編集すると、設定場所とリポジトリのどちらからでも同じファイルが変わります。ファイルを追加した場合やリポジトリを移動した場合は、再実行してください。削除したファイルの古いリンクは、自動では消しません。

元へ戻す場合は、対象のリンクを削除し、退避ファイルを元の名前に戻してください。適用途中でエラーになった場合、それまでに作成済みのリンクは残ります。

更新コマンドは、保存せずリポジトリからも実行できます。

```sh
sh scripts/update-agents --dry-run
sh scripts/update-agents
```

インストール済みのClaude Code・Codex・Pi・OpenCode・Grokを更新します。未インストールは無視し、更新に失敗しても残りは続行します。各CLIの更新処理には通信やnpmなどが必要です。

Bashの導入は [bash/README.md](bash/README.md) を参照してください。

Codexのモデル・sandbox・承認設定だけを別のマシンへ移植する場合は、[codex/README.md](codex/README.md) のダウンロードコマンドを使ってください。

設定したいマシンで次を実行します。

```sh
curl -fL https://raw.githubusercontent.com/sorafujitani/dotfiles/main/codex/install.sh -o "$HOME/setup-codex.sh" && sh "$HOME/setup-codex.sh" --download
```

## 注意

設定内のパスや依存ツールは、利用環境に合わせて確認してください。`claude/skills/difit`と`difit-review`は外部の`~/.agents/skills/`を参照するリンクです。利用する場合は、リンク先のスキルが別途必要です。

アプリによる設定ファイルの置き換えで、リンクは外れることがあります。内容を確認してから再実行してください。

このリポジトリは公開用です。commit前に差分を確認し、`~/.secrets`、`~/.secretsenv.yml`、認証情報を含むファイルは追加しないでください。
