# Alternative ni written in ShellScript
# SPDX-License-Identifier: MIT
# Author: @azu
# Repository: https://github.com/azu/ni.zsh
# Original: https://github.com/antfu/ni
#
# Socket Firewall Integration
# ----------------------------
# This script supports Socket Firewall (https://github.com/SocketDev/sfw-free)
# for proactive protection against malicious packages.
#
# Setup:
#   1. Install Socket Firewall: npm i -g sfw
#   2. Enable in ni.zsh: export NI_USE_SOCKET_FIREWALL=1
#   3. Specify sfw path: export NI_SOCKET_FIREWALL_BIN=/path/to/sfw
#      If not set, uses 'sfw' command from PATH
#
# When enabled, all package install/add commands and npx/bunx executions
# will be automatically protected by Socket Firewall.
#
# Note: When Socket Firewall is enabled, the legacy ni-assertPackageBySocket
# function is skipped to avoid duplicate checks.

# Get Socket Firewall command path
function ni-getSocketFirewallBin() {
  # Use custom path if specified, otherwise use 'sfw' command
  echo "${NI_SOCKET_FIREWALL_BIN:-sfw}"
}

# Check if Socket Firewall (sfw) should be used
# Enabled by setting NI_USE_SOCKET_FIREWALL=1
# Requires: sfw command (npm i -g sfw) or NI_SOCKET_FIREWALL_BIN set
function ni-shouldUseSocketFirewall() {
  # Check if Socket Firewall is enabled via environment variable
  if [ -z "$NI_USE_SOCKET_FIREWALL" ]; then
    return 1
  fi

  local sfwBin
  sfwBin=$(ni-getSocketFirewallBin)

  # Check if sfw command/path is available
  if ! command -v "$sfwBin" >/dev/null 2>&1; then
    return 1
  fi
  return 0
}

function ni-echoRun() {
  local cmd="$1"
  shift
  local args="$@"

  # Check if Socket Firewall should be used for package installation commands
  # sfw supports: npm, yarn, pnpm, bun (and pip, cargo for other ecosystems)
  if ni-shouldUseSocketFirewall; then
    local sfwBin
    sfwBin=$(ni-getSocketFirewallBin)

    case $cmd in
      npm|yarn|pnpm|bun|deno)
        # Check if this is an install/add command
        if [[ "$args" =~ ^(install|add|i) ]]; then
          echo "$ sfw $cmd $args"
          eval "$sfwBin $cmd $args"
          return
        fi
        ;;
      npx|bunx)
        # npx and bunx commands should also use sfw
        echo "$ sfw $cmd $args"
        eval "$sfwBin $cmd $args"
        return
        ;;
    esac
  fi

  # Default behavior without Socket Firewall
  echo "$ $cmd $args"
  eval "$cmd $args"
}

# Support package manager
# - npm
# - yarn - v1
# - yarn-berry - v2+
# - pnpm
# - bun
# - deno - v2+
function ni-getPackageManager() {
  # cwd is argument 1, if not set, use current directory
  local cwd=${1:-$(pwd)}
  # detect package manager via package.json
  if [ -f "${cwd}/package.json" ]; then
    local packageManager
    packageManager=$(cat "${cwd}/package.json" | jq -r .packageManager)
    if [ "$packageManager" != "null" ]; then
      # parse packageManager name from "<pkg>@<version>"
      packageManagerName=$(echo "$packageManager" | sed -e 's/@.*//')
      packageManagerMajorVersion=$(echo "$packageManager" | sed -e 's/.*@//' | sed -e 's/\..*//')
      # supported package manager
      if [ "$packageManagerName" = "npm" ] || [ "$packageManagerName" = "pnpm" ] || [ "$packageManagerName" = "yarn" ] || [ "$packageManagerName" = "bun" ]; then
        # yarn and version >= 2, then  yarn-berry
        if [ "$packageManagerName" = "yarn" ] && [ "$packageManagerMajorVersion" -ge 2 ]; then
          echo "yarn-berry"
          return
        fi
        echo "$packageManagerName"
        return
      fi
    fi
  fi

  # detect package manager via lock file
  if [ -f "${cwd}/deno.lock" ]; then
    echo "deno"
  elif [ -f "${cwd}/pnpm-lock.yaml" ]; then
    echo "pnpm"
  elif [ -f "${cwd}/bun.lock" ] || [ -f "${cwd}/bun.lockb" ]; then
    # choose bun if both bun.lockb and yarn.lock exist
    # bun generate yarn.lock and bun.lockb when print=yarn is set
    # https://bun.sh/docs/install/lockfile
    echo "bun"
  elif [ -f "${cwd}/yarn.lock" ]; then
    echo "yarn"
  elif [ -f "${cwd}/package-lock.json" ]; then
    echo "npm"
  # if current directory does not contain any lock file, then check git root directory
  # Note: if current is in workspace, then use workspace package manager which is defined in root directory
  else
    local rootDir
    rootDir=$(git rev-parse --show-toplevel 2>/dev/null)
    if [ -z "$rootDir" ]; then
      # default to npm
      echo "npm"
      return
    fi
    local parentDir
    parentDir=$(dirname "$cwd")
    # if parentDir is not under of rootDir, then default to npm
    # it is out of workspace
    if [[ "$parentDir" != "$rootDir"* ]]; then
      echo "npm"
      return
    fi
    # recursive call to getPackageManager
    ret=$(ni-getPackageManager "$parentDir")
    if [ -n "$ret" ]; then
      echo "$ret"
      return
    fi
  fi
}

# ni - install
## npm install
## yarn install
## pnpm install
## bun install
## deno install
# Note: # ni <subcommand> - run subcommand
function ni() {
  # with argument - subcommand
  if [ $# -gt 0 ]; then
    case $1 in
      add)
        shift
        ni-add $@
        ;;
      run)
        shift
        ni-run $@
        ;;
      upgrade)
        shift
        ni-upgrade $@
        ;;
      upgrade-interactive)
        shift
        ni-upgrade-interactive $@
        ;;
      remove)
        shift
        ni-remove $@
        ;;
      # Special ni run <script>
      test)
        shift
        ni-run test $@
        ;;
      exec)
        shift
        ni-exec $@
        ;;
      dlx)
        shift
        ni-dlx $@
        ;;
      *)
        echo "Unknown subcommand: $1"
        ;;
    esac
    return
  fi
  # without argument - install
  local manager
  manager=$(ni-getPackageManager)
  case $manager in
    npm)
      ni-echoRun npm install
      ;;
    yarn*)
      ni-echoRun yarn install
      ;;
    pnpm)
      ni-echoRun pnpm install
      ;;
    bun)
      ni-echoRun bun install
      ;;
    deno)
      ni-echoRun deno install
      ;;
  esac
}

# ni add - add package
# $ ni add vite
## npm install vite
## yarn add vite
## pnpm add vite
## bun add vite
## deno add npm:vite
# $ ni @types/node --dev
## npm install @types/node -D
## yarn add @types/node -D
## pnpm add -D @types/node
## bun add -d @types/node

function ni-add() {
  # support both `ni add pkg --dev` and `ni add --dev pkg`
  POSITIONAL_ARGS=()
  SUPPORTED_FLGAG=()
  while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
      -D|--dev)
        shift
        SUPPORTED_FLGAG+=("--dev")
        ;;
      *)
        POSITIONAL_ARGS+=("$1")
        shift
        ;;
    esac
  done

  local manager
  manager=$(ni-getPackageManager)
  # normailze flag by package manager
  flag=""
  for arg in "${SUPPORTED_FLGAG}"; do
    # --dev or -D
    if [ "$arg" = "--dev" ] ; then
      case $manager in
        npm)
          flag="$POSITIONAL_ARGS --save-dev"
          ;;
        yarn*)
          flag="$POSITIONAL_ARGS --dev"
          ;;
        pnpm)
          flag="$POSITIONAL_ARGS -D"
          ;;
        bun)
          flag="$POSITIONAL_ARGS -d"
          ;;
      esac
    else
      flag="$POSITIONAL_ARGS $arg"
    fi
  done
  # trim space from $flag
  flag=$(echo "$flag" | sed -e 's/^ *//')
  # execute
  case $manager in
    npm)
      ni-echoRun npm install $flag
      ;;
    yarn*)
      ni-echoRun yarn add $flag
      ;;
    pnpm)
      ni-echoRun pnpm add $flag
      ;;
    bun)
      ni-echoRun bun add $flag
      ;;
    deno)
      ni-echoRun deno add $flag
      ;;
  esac
}

# ni run - run scripts
# $ ni run dev --port=3000
## npm run dev -- --port=3000
## yarn run dev --port=3000
## pnpm run dev --port=3000
## bun run dev --port=3000
## deno run dev --port=3000
function ni-run(){
  local manager
  manager=$(ni-getPackageManager)
  # npm require -- for additional args
  additionalArgs=""
  case $manager in
    npm)
      additionalArgs="--"
      ;;
  esac
  # execute
  case $manager in
    npm)
      ni-echoRun npm run $additionalArgs $@
      ;;
    yarn*)
      ni-echoRun yarn run $@
      ;;
    pnpm)
      ni-echoRun pnpm run $@
      ;;
    bun)
      ni-echoRun bun run $@
      ;;
    deno)
      ni-echoRun deno run $@
      ;;
  esac
}

# ni upgrade - upgrade package
## (not available for bun)
## npm upgrade
## yarn upgrade (Yarn 1)
## yarn up (Yarn Berry)
## pnpm update
## [ ] deno
function ni-upgrade(){
  local manager
  manager=$(ni-getPackageManager)
  packageName=$1
  case $manager in
    npm)
      ni-echoRun npm upgrade $packageName
      ;;
    yarn)
      ni-echoRun yarn upgrade $packageName
      ;;
    yarn-berry)
      ni-echoRun yarn up $packageName
      ;;
    pnpm)
      ni-echoRun pnpm update $packageName
      ;;
    bun)
      # https://bun.sh/blog/bun-v0.8.0
      ni-echoRun bun update $packageName
      ;;
    deno)
      echo "deno does not support upgrade command"
      ;;
  esac
}

# ni upgrade-interactive - upgrade package interactively
# use https://github.com/dylang/npm-check
function ni-upgrade-interactive(){
  local manager
  manager=$(ni-getPackageManager)
  case $manager in
    npm)
      ni-echoRun npm-check -u
      ;;
    yarn)
      ni-echoRun yarn upgrade-interactive --latest
      ;;
    yarn-berry)
      ni-echoRun 'yarn up --interactive "*"'
      ;;
    pnpm)
      ni-echoRun pnpm --recursive update -i --latest
      ;;
    bun)
      echo "bun does not support upgrade interactive command"
      ;;
    deno)
      echo "deno does not support upgrade interactive command"
      ;;
  esac
}
# ni remove - remove package
# $ nu remove webpack
## npm uninstall webpack
## yarn remove webpack
## pnpm remove webpack
## bun remove webpack
## deno uninstall npm:webpack
function ni-remove(){
  local manager
  manager=$(ni-getPackageManager)
  case $manager in
    npm)
      ni-echoRun npm uninstall $@
      ;;
    yarn*)
      ni-echoRun yarn remove $@
      ;;
    pnpm)
      ni-echoRun pnpm remove $@
      ;;
    bun)
      ni-echoRun bun remove $@
      ;;
    deno)
      ni-echoRun deno uninstall $@
      ;;
  esac
}

# ni exec - execute command
# $ ni exec envinfo
## npm exec envinfo
## yarn exec envinfo
## pnpm exec envinfo
## bunx envinfo
## [ ] deno 
function ni-exec(){
  local manager
  manager=$(ni-getPackageManager)
  case $manager in
    npm)
      # https://docs.npmjs.com/cli/v8/commands/npm-exec
      ni-echoRun npm exec --no -- $@
      ;;
    yarn)
      # yarn v1 does not support exec
      ni-echoRun yarn $@
      ;;
    yarn-berry)
      ni-echoRun yarn exec $@
      ;;
    pnpm)
      ni-echoRun pnpm exec $@
      ;;
    bun)
      ni-echoRun bunx $@
      ;;
    deno)
      echo "deno does not support exec command"
      ;;
  esac
}

# ni dlx -- download and execute command
# $ ni dlx envinfo
## npx envinfo
## yarn dlx envinfo
## pnpm dlx envinfo
## bunx envinfo
## [ ] deno
function ni-dlx(){
  local manager
  manager=$(ni-getPackageManager)
  case $manager in
    npm)
      ni-echoRun npx $@
      ;;
    yarn)
      # yarn v1 does not support dlx
      ni-echoRun npx $@
      ;;
    yarn-berry)
      ni-echoRun yarn dlx $@
      ;;
    pnpm)
      ni-echoRun pnpm dlx $@
      ;;
    bun)
      ni-echoRun bunx $@
      ;;
    deno)
      echo "deno does not support dlx command"
      ;;
  esac
}


# auto completion
function _ni(){
  local context state state_descr line
  typeset -A opt_args

  if ! command -v jq >/dev/null 2>&1; then
    _message -e "jq command is required to use ni.zsh"
    return 1
  fi

  _arguments -C \
    '1: :->cmds' \
    '*:: :->args'

  case "$state" in
    cmds)
      # ni <subcommands>
      local -a subcommands
      subcommands=(
        'add:add package'
        'run:run scripts'
        'test:run test script'
        'upgrade:upgrade package'
        'upgrade-interactive:upgrade package interactively'
        'remove:remove package'
        'exec:execute command'
        'dlx:download package and execute command'
      )
      _describe -t subcommands 'subcommands' subcommands
      ;;
    args)
      case $line[1] in
        add)
          # ni add <package>
          _arguments \
            '--dev[Install as development dependency]' \
            '-D[Install as development dependency]'
          ;;
        remove|upgrade)
          # ni remove <package>
          # ni upgrade <package>
          if [ -f "package.json" ]; then
            local -a packages
            packages=(${(f)"$(cat package.json | jq -r '.dependencies // {} | to_entries | .[] | select(.key != "") | "\(.key):\(.value)"')"})
            packages+=(${(f)"$(cat package.json | jq -r '.devDependencies // {} | to_entries | .[] | select(.key != "") | "\(.key):\(.value)"')"})
            _describe -t packages 'packages' packages
          fi
          ;;
        run)
          # ni run <script>
          if [ -f "package.json" ]; then
            local -a script_entries
            local key value escaped_key
            while IFS=$'\t' read -r key value; do
              escaped_key=${key//:/\\:}
              script_entries+=("$escaped_key:$value")
              done < <(cat package.json | jq -r '.scripts | to_entries | .[] | select(.key != "") | "\(.key)\t\(.value)"')
            _describe -t scripts 'scripts' script_entries
          elif [ -f "deno.json" ]; then
            local -a task_entries
            local key value escaped_key
            while IFS=$'\t' read -r key value; do
              escaped_key=${key//:/\\:}
              task_entries+=("$escaped_key:$value")
            done < <(cat deno.json | jq -r '.tasks | to_entries | .[] | select(.key != "") | "\(.key)\t\(.value)"')
            _describe -t tasks 'tasks' task_entries
          else
            _files
          fi
          ;;
        exec)
          # ni exec <command>
          if [ -d "$PWD/node_modules/.bin" ]; then
            _files -W "$PWD/node_modules/.bin" -g '*(-x)'
          else
            _files
          fi
          ;;
      esac
      ;;
  esac
}

compdef _ni ni