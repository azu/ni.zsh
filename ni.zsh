# Alternative ni written in ShellScript
# Ref https://github.com/antfu/ni
function echoRun() {
  echo "$ $@"
  eval "$@"
}

function getPackageManager() {
  # detect package manager via package.json
  if [ -f "package.json" ]; then
    local packageManager
    packageManager=$(cat package.json | jq -r .packageManager)
    if [ "$packageManager" != "null" ]; then
      # parse packageManager name from "<pkg>@<version>"
      packageManagerName=$(echo "$packageManager" | sed -e 's/@.*//')
      # supported package manager
      if [ "$packageManagerName" = "npm" ] || [ "$packageManagerName" = "pnpm" ] || [ "$packageManagerName" = "yarn" ] || [ "$packageManagerName" = "bun" ]; then
        echo "$packageManagerName"
        return
      fi
    fi
  fi

  # detect package manager via lock file
  if [ -f "pnpm-lock.yaml" ]; then
    echo "pnpm"
  elif [ -f "yarn.lock" ]; then
    echo "yarn"
  elif [ -f "package-lock.json" ]; then
    echo "npm"
  elif [ -f "bun.lockb" ]; then
    echo "bun"
  else
    echo "npm"
  fi
}

# ni - install
## npm install
## yarn install
## pnpm install
## bun install
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
      *)
        echo "Unknown subcommand: $1"
        ;;
    esac
    return
  fi
  # without argument - install
  local manager
  manager=$(getPackageManager)
  case $manager in
    npm)
      echoRun npm install
      ;;
    yarn)
      echoRun yarn install
      ;;
    pnpm)
      echoRun pnpm install
      ;;
    bun)
      echoRun bun install
      ;;
  esac
}

# ni add - add package
# $ ni add vite
## npm i vite
## yarn add vite
## pnpm add vite
## bun add vite
# $ ni @types/node --dev
## npm i @types/node -D
## yarn add @types/node -D
## pnpm add -D @types/node
## bun add -d @types/node

function ni-add() {
  local manager
  manager=$(getPackageManager)
  # normailze flag by package manager
  flag=""
  for arg in "$@"; do
    # --dev or -D
    if [ "$arg" = "-D" ] || [ "$arg" = "--dev" ] ; then
      case $manager in
        npm)
          flag="$flag --save-dev"
          ;;
        yarn)
          flag="$flag --dev"
          ;;
        pnpm)
          flag="$flag -D"
          ;;
        bun)
          flag="$flag -d"
          ;;
      esac
    else
      flag="$flag $arg"
    fi
  done
  # trim space from $flag
  flag=$(echo "$flag" | sed -e 's/^ *//')
  # execute
  case $manager in
    npm)
      echoRun npm install $flag
      ;;
    yarn)
      echoRun yarn add $flag
      ;;
    pnpm)
      echoRun pnpm add $flag
      ;;
    bun)
      echoRun bun add $flag
      ;;
  esac
}

# ni run - run scripts
# $ ni run dev --port=3000
## npm run dev -- --port=3000
## yarn run dev --port=3000
## pnpm run dev --port=3000
## bun run dev --port=3000

function ni-run(){
  local manager
  manager=$(getPackageManager)
  # npm require -- for additional args
  addtionalArgs=""
  case $manager in
    npm)
      addtionalArgs="--"
      ;;
  esac
  # execute
  case $manager in
    npm)
      echoRun npm run $addtionalArgs $@
      ;;
    yarn)
      echoRun yarn run $@
      ;;
    pnpm)
      echoRun pnpm run $@
      ;;
    bun)
      echoRun bun run $@
      ;;
  esac
}

# ni upgrade - upgrade package
## (not available for bun)
## npm upgrade
## yarn upgrade (Yarn 1)
## yarn up (Yarn Berry)
## pnpm update

function ni-upgrade(){
  local manager
  manager=$(getPackageManager)
  packageName=$1
  case $manager in
    npm)
      echoRun npm upgrade $packageName
      ;;
    yarn)
      echoRun yarn upgrade $packageName
      ;;
    pnpm)
      echoRun pnpm update $packageName
      ;;
    bun)
      echo "bun does not support upgrade"
      ;;
  esac
}

# ni upgrade-interactive - upgrade package interactively
# use https://github.com/dylang/npm-check
function ni-upgrade-interactive(){
  local manager
  manager=$(getPackageManager)
  case $manager in
    npm)
      echoRun npm-check -u
      ;;
    yarn)
      echoRun yarn upgrade-interactive --latest
      ;;
    pnpm)
      echoRun pnpm update -i
      ;;
    bun)
      echo "bun does not support upgrade"
      ;;
  esac
}
# ni remove - remove package
# $ nu remove webpack
## npm uninstall webpack
## yarn remove webpack
## pnpm remove webpack
## bun remove webpack
function ni-remove(){
  local manager
  manager=$(getPackageManager)
  case $manager in
    npm)
      echoRun npm uninstall $@
      ;;
    yarn)
      echoRun yarn remove $@
      ;;
    pnpm)
      echoRun pnpm remove $@
      ;;
    bun)
      echoRun bun remove $@
      ;;
  esac
}

# auto completion
function _ni(){
  # ni <subcommands>
  local -a subcommands
  subcommands=(
    'add:add package'
    'run:run scripts'
    'upgrade:upgrade package'
    'upgrade-interactive:upgrade package interactively'
    'remove:remove package'
  )
  _describe -t subcommands 'subcommands' subcommands
}
compdef _ni ni
