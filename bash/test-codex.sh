#!/usr/bin/env bash
# Offline test: exercise the real setup block with a fake official installer.
set -euo pipefail
script_dir=$(cd "$(dirname "$0")" && pwd)
test_tmp=$(mktemp -d)
trap 'rm -rf -- "$test_tmp"' EXIT
export TEST_CODEX_FIXTURES="$test_tmp"
awk '/^# Install the complete package/ { copy=1 } copy { print } copy && /^\)$/ { exit }' \
  "$script_dir/setup.sh" > "$test_tmp/install.sh"
[[ -s $test_tmp/install.sh ]]
cat > "$test_tmp/official-install.sh" <<'INSTALLER'
#!/bin/sh
set -eu
[ "$CODEX_INSTALL_DIR" = "$HOME/.local/bin" ]
[ "$CODEX_NON_INTERACTIVE" = 1 ]
[ "${INSTALL_STATUS:-0}" = 0 ] || exit "$INSTALL_STATUS"
case "$CODEX_TEST_MACHINE" in
  x86_64|amd64|aarch64|arm64) ;;
  *) exit 2 ;;
esac
package=$CODEX_HOME/packages/standalone/current
mkdir -p "$CODEX_INSTALL_DIR" "$package/bin"
printf '{}\n' > "$package/codex-package.json"
cat > "$package/bin/codex" <<'BINARY'
#!/bin/sh
[ -s "$CODEX_HOME/packages/standalone/current/codex-package.json" ] || exit 1
if [ "$*" = 'app-server daemon pid-update-loop --check-package-ownership' ]; then
  exit "${OWNERSHIP_STATUS:-0}"
fi
printf 'codex-cli packaged-test\n'
BINARY
chmod +x "$package/bin/codex"
rm -f "$CODEX_INSTALL_DIR/codex"
ln -s "$package/bin/codex" "$CODEX_INSTALL_DIR/codex"
printf 'installed\n' >> "$HOME/installer-calls"
INSTALLER
cat > "$test_tmp/skills-install.sh" <<'SKILLS'
#!/bin/sh
[ "$1" = --skills-only ] || exit 2
printf 'installed\n' > "$HOME/skills-installed"
SKILLS

curl() {
  local url output
  while (( $# )); do
    case "$1" in
      https://*) url=$1 ;;
      --output) shift; output=$1 ;;
    esac
    shift
  done
  [[ ${FAIL_DOWNLOAD:-0} != 1 ]] || return 22
  case "$url" in
    https://chatgpt.com/codex/install.sh) cp "$TEST_CODEX_FIXTURES/official-install.sh" "$output" ;;
    https://raw.githubusercontent.com/sorafujitani/dotfiles/main/codex/install.sh) cp "$TEST_CODEX_FIXTURES/skills-install.sh" "$output" ;;
    *) printf 'Unexpected download: %s\n' "$url" >&2; return 1 ;;
  esac
}
export -f curl

for machine in x86_64 amd64 aarch64 arm64; do
  (
    export HOME="$test_tmp/$machine"
    export CODEX_HOME="$HOME/custom codex"
    export TMPDIR="$test_tmp/tmp-$machine"
    export PATH="$HOME/.local/bin:/usr/bin:/bin"
    mkdir -p "$TMPDIR"
    export CODEX_TEST_MACHINE="$machine"
    source "$test_tmp/install.sh"
    [[ -L $HOME/.local/bin/codex ]]
    [[ $(codex --version) == 'codex-cli packaged-test' ]]
    codex app-server daemon pid-update-loop --check-package-ownership
    [[ -f $HOME/skills-installed ]]
    [[ -z $(ls -A "$TMPDIR") ]]

    # --version can succeed even when the old bare binary cannot start a daemon.
    rm "$HOME/.local/bin/codex"
    printf '#!/bin/sh\n[ "$1" = --version ] || exit 1\necho "broken bare codex"\n' > "$HOME/.local/bin/codex"
    chmod +x "$HOME/.local/bin/codex"
    rm "$HOME/skills-installed"
    source "$test_tmp/install.sh"
    [[ $(codex --version) == 'codex-cli packaged-test' ]]
    codex app-server daemon pid-update-loop --check-package-ownership
    [[ $(wc -l < "$HOME/installer-calls") == 2 ]]
    [[ -f $HOME/skills-installed ]]
    [[ -z $(ls -A "$TMPDIR") ]]
  )
done

# Failed downloads/installations and unsupported hardware must propagate errors.
for failure in architecture download installer; do
  (
    export HOME="$test_tmp/$failure"
    export CODEX_HOME="$HOME/custom codex"
    export TMPDIR="$test_tmp/tmp-$failure"
    export PATH="$HOME/.local/bin:/usr/bin:/bin"
    mkdir -p "$TMPDIR" "$HOME/.local/bin"
    printf '#!/bin/sh\necho "old codex"\n' > "$HOME/.local/bin/codex"
    chmod +x "$HOME/.local/bin/codex"
    export CODEX_TEST_MACHINE=x86_64
    case "$failure" in
      architecture) export CODEX_TEST_MACHINE=riscv64; expected=2 ;;
      download) export FAIL_DOWNLOAD=1; expected=22 ;;
      installer) export INSTALL_STATUS=47; expected=47 ;;
    esac
    if bash -e "$test_tmp/install.sh"; then exit 1; else [[ $? == "$expected" ]]; fi
    [[ $(codex --version) == 'old codex' ]]
    [[ ! -e $HOME/skills-installed ]]
    [[ -z $(ls -A "$TMPDIR") ]]
  )
done

# A version string alone is not enough: reject incomplete/foreign packages.
(
  export HOME="$test_tmp/incomplete"
  export CODEX_HOME="$HOME/custom codex"
  export TMPDIR="$test_tmp/tmp-incomplete"
  export PATH="$HOME/.local/bin:/usr/bin:/bin"
  export CODEX_TEST_MACHINE=x86_64 OWNERSHIP_STATUS=48
  mkdir -p "$TMPDIR"
  if bash -e "$test_tmp/install.sh"; then exit 1; else [[ $? == 48 ]]; fi
  [[ ! -e $HOME/skills-installed ]]
  [[ -z $(ls -A "$TMPDIR") ]]
)

# A stale system command must not win when ~/.local/bin is already later in PATH.
export HOME="$test_tmp/x86_64"
export CODEX_HOME="$HOME/custom codex"
mkdir -p "$test_tmp/system-bin"
printf '#!/bin/sh\necho "stale system codex"\n' > "$test_tmp/system-bin/codex"
chmod +x "$test_tmp/system-bin/codex"
export PATH="$test_tmp/system-bin:/usr/bin:/bin:$HOME/.local/bin"
export TEST_INTERACTIVE="$script_dir/interactive.bash"
bash --noprofile --norc -ic 'source "$TEST_INTERACTIVE"; [[ $(command -v codex) == "$HOME/.local/bin/codex" ]]'
printf '%s\n' 'PASS: complete package, legacy binary repair, PATH precedence and error propagation'
