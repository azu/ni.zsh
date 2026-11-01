#!/usr/bin/env zsh
# Test that ni forwards each argument to the package manager without
# splitting, dropping, or expanding it.
# Usage: zsh test/args.zsh
#
# Package managers are replaced with shell functions that print each
# argument as <arg>, so this test does not need npm/pnpm/yarn installed.

TEST_DIR=${0:A:h}
# ni.zsh registers completion with compdef; it is not needed in this test
compdef() { : }
source "$TEST_DIR/../ni.zsh"

print-args() {
  local name="$1"
  shift
  print -rn -- "$name"
  printf '<%s>' "$@"
  print
}
npm() { print-args npm "$@" }
pnpm() { print-args pnpm "$@" }
yarn() { print-args yarn "$@" }

failures=0

# assert <dir> <expected output> <ni args...>
assert() {
  local dir="$1" expected="$2"
  shift 2
  local actual
  actual=$(cd "$TEST_DIR/$dir" && ni "$@" 2>&1)
  if [[ "$actual" == "$expected" ]]; then
    print -r -- "ok: ($dir) ni ${(q-)@}"
  else
    print -r -- "not ok: ($dir) ni ${(q-)@}"
    print -r -- "  expected:"
    print -r -- "$expected" | sed 's/^/    /'
    print -r -- "  actual:"
    print -r -- "$actual" | sed 's/^/    /'
    failures=$((failures + 1))
  fi
}

# Arguments with spaces, empty arguments, and shell metacharacters are kept as-is
assert npm \
  "$ npm run -- dev 'arg 1' '' '\$HOME' '*' '\$(echo injected)'
npm<run><--><dev><arg 1><><\$HOME><*><\$(echo injected)>" \
  run dev 'arg 1' '' '$HOME' '*' '$(echo injected)'

assert pnpm \
  "$ pnpm run dev --port 3000
pnpm<run><dev><--port><3000>" \
  run dev --port 3000

# A single argument that contains spaces is no longer split
assert pnpm \
  "$ pnpm run 'dev --port 3000'
pnpm<run><dev --port 3000>" \
  run 'dev --port 3000'

assert pnpm \
  "$ pnpm run test 'a b'
pnpm<run><test><a b>" \
  test 'a b'

# ni add keeps package arguments separate from the dev flag
assert npm \
  "$ npm install react react-dom --save-dev
npm<install><react><react-dom><--save-dev>" \
  add --dev react react-dom

assert pnpm \
  "$ pnpm add react -D
pnpm<add><react><-D>" \
  add react -D

assert pnpm \
  "$ pnpm add react
pnpm<add><react>" \
  add react

# ni upgrade passes the package name only when it is given
assert pnpm \
  "$ pnpm update react
pnpm<update><react>" \
  upgrade react

assert pnpm \
  "$ pnpm update
pnpm<update>" \
  upgrade

# "*" is passed to yarn as a literal argument, not expanded as a glob
assert yarn-berry \
  "$ yarn up --interactive '*'
yarn<up><--interactive><*>" \
  upgrade-interactive

assert pnpm \
  "$ pnpm exec eslint 'src/**/*.ts'
pnpm<exec><eslint><src/**/*.ts>" \
  exec eslint 'src/**/*.ts'

assert pnpm \
  "$ pnpm remove 'a b'
pnpm<remove><a b>" \
  remove 'a b'

# User aliases keep working because ni-echoRun still uses eval
alias pnpm='pnpm --silent'
assert pnpm \
  "$ pnpm run dev 'arg 1'
pnpm<--silent><run><dev><arg 1>" \
  run dev 'arg 1'
unalias pnpm

# Arguments that match global aliases (alias -g) are not expanded.
# The words are quoted here so that this test script itself does not expand them.
alias -g G='| grep x'
alias -g ...='../..'
assert pnpm \
  "$ pnpm run dev G ...
pnpm<run><dev><G><...>" \
  run dev 'G' '...'
unalias 'G' '...'

# Arguments that contain single quotes are kept as-is
assert pnpm \
  "$ pnpm run dev it\\'s
pnpm<run><dev><it's>" \
  run dev "it's"

# Socket Firewall wrapping keeps argument boundaries
SFW_STUB_DIR=$(mktemp -d)
cat > "$SFW_STUB_DIR/sfw" <<'EOF'
#!/bin/sh
printf 'sfw'
printf '<%s>' "$@"
printf '\n'
EOF
chmod +x "$SFW_STUB_DIR/sfw"
export NI_USE_SOCKET_FIREWALL=1
export NI_SOCKET_FIREWALL_BIN="$SFW_STUB_DIR/sfw"
assert npm \
  "$ sfw npm install 'a b' --save-dev
sfw<npm><install><a b><--save-dev>" \
  add 'a b' --dev
assert npm \
  "$ npm run -- dev 'arg 1'
npm<run><--><dev><arg 1>" \
  run dev 'arg 1'
unset NI_USE_SOCKET_FIREWALL NI_SOCKET_FIREWALL_BIN
rm -rf "$SFW_STUB_DIR"

if (( failures > 0 )); then
  print -r -- "$failures test(s) failed"
  exit 1
fi
print -r -- "all tests passed"
