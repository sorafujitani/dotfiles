# update-agents

macOS/Linuxのターミナルに次のブロックを貼り付けると、インストール済みのエージェントCLIを更新します。ファイルの保存やdotfilesの導入は不要です。

Bashが必要です。更新にはインターネット接続と、各CLIの更新処理が使うnpmやHomebrewなどが必要です。更新先は各CLIの設定と配布チャネルに従います。

```bash
/bin/bash <<'BASH'
#!/bin/bash
# Update installed agent CLIs using their own updaters.
set -u

dry_run=false
case "${1:-}" in
  "") ;;
  --dry-run) dry_run=true ;;
  -h|--help)
    printf 'Usage: update-agents [--dry-run]\nUpdates installed claude, codex, pi, opencode, and grok CLIs.\n'
    exit 0
    ;;
  *) printf 'Unknown option: %s\n' "$1" >&2; exit 2 ;;
esac
if [ "$#" -gt 1 ]; then
  printf 'Usage: update-agents [--dry-run]\n' >&2
  exit 2
fi

failed=0
for agent in claude codex pi opencode grok; do
  if ! command -v "$agent" >/dev/null 2>&1; then
    printf '[SKIP] %s: not installed\n' "$agent"
    continue
  fi

  case "$agent" in
    claude|codex|grok) set -- "$agent" update ;;
    # Do not update extensions or trust project-local configuration.
    pi) set -- pi update --self --no-approve ;;
    # Let OpenCode detect its install method (including Homebrew).
    opencode) set -- opencode upgrade ;;
  esac

  printf '\n[UPDATE]'
  printf ' %s' "$@"
  printf '\n'
  if [ "$dry_run" = true ]; then
    continue
  fi
  if "$@"; then
    printf '[OK] %s\n' "$agent"
  else
    printf '[FAIL] %s\n' "$agent" >&2
    failed=$((failed + 1))
  fi
done

if [ "$failed" -gt 0 ]; then
  printf '\n%d update(s) failed.\n' "$failed" >&2
  exit 1
fi
BASH
```

未インストールのCLIは無視します。更新に失敗しても残りは続行し、終了コードは`1`になります。失敗がなければ`0`です。古いCLIなどで更新コマンドが使えない場合は、そのCLIの公式手順で更新してください。

Piの拡張機能は更新しません。

chezmoiで導入済みなら、`update-agents`でも実行できます。`update-agents --dry-run`は更新コマンドを表示するだけです。
