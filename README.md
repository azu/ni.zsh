# Alternative `ni` written in zsh

`ni` - use the right package manager

You can run npm/yarn/pnpm/bun with same command!

- Original: <https://github.com/antfu/ni>

## Installation

### Using Zinit

```shell
zinit load azu/ni.zsh
```

### Using Antigen

```shell
antigen bundle azu/ni.zsh@main
```

### Using sheldon

```toml
[plugins.ni]
github = "azu/ni.zsh"
```

### Manually

```shell
curl https://raw.githubusercontent.com/azu/ni.zsh/main/ni.zsh > ni.zsh
source ni.zsh
```

### :warning: Troubleshooting: `command not found: compdef`

`ni.zsh` requires `compdef` command.
If you got `command not found: compdef` error, you need to enable `compinit` in your `.zshrc`.

```shell
# .zshrc
# load compdef
autoload -Uz compinit && compinit
# load ni.zsh
source /path/to/ni.zsh
```

## Supported Package Manager

- [npm](https://docs.npmjs.com/cli/)
- [yarn](https://classic.yarnpkg.com/) (yarn v1)
- [yarn-berry](https://yarnpkg.com/) (yarn v2+)
- [pnpm](https://pnpm.js.org/)
- [bun](https://bun.sh/)
- [deno](https://deno.com/) (deno v2.6+)

## Requirements

- zsh
  - require to enable `autoload -Uz compinit && compinit`
- [jq](https://stedolan.github.io/jq/)
- [npm-check](https://github.com/dylang/npm-check) if you want to use `npm` + `ni upgrade-interactive`

## Usage

```sh
ni                      -- install current package.json
ni add <pkg>            -- add package
ni remove <pkg>         -- remove package
ni run <script>         -- run scripts
ni test                 -- run test script
ni upgrade [<pkg>]      -- upgrade packages
ni upgrade-interactive  -- upgrade package interactively
ni exec <command>       -- execute command
ni dlx <pkg>            -- download package and execute command
```

## Command Table

| ni                       | npm               | yarn                       | yarn-berry                 | pnpm             | bun            | deno |
|--------------------------|-------------------|----------------------------|----------------------------|------------------|----------------| ---- |
| `ni`                     | `npm install`     | `yarn install`             | `yarn install`             | `pnpm install`   | `bun install`  | `deno install` |
| `ni add <pkg>`           | `npm install`     | `yarn add`                 | `yarn add`                 | `pnpm add`       | `bun add`      | `deno add --npm` |
| `ni remove <pkg>`        | `npm uninstall`   | `yarn remove`              | `yarn remove`              | `pnpm remove`    | `bun remove`   | `deno uninstall` |
| `ni run <script>`        | `npm run`         | `yarn run`                 | `yarn run`                 | `pnpm run`       | `bun run`      | `deno run` |
| `ni test`                | `npm run test`    | `yarn run test`            | `yarn run test`            | `pnpm run test`  | `bun run test` | `deno run test` |
| `ni upgrade`             | `npm upgrade`     | `yarn upgrade`             | `yarn up`                  | `pnpm update`    | `bun update`              | `deno outdated --update` |
| `ni upgrade-interactive` | `npm-check`**^1** | `yarn up --interactive "*"` | `yarn upgrade-interactive` | `pnpm update -i` | ○              | `deno outdated --update --interactive` |
| `ni exec <command>`      | `npm exec --no`   | `yarn <command>`           | `yarn exec`                | `pnpm exec`      | `bunx`         | ○             |
| `ni dlx <pkg>`       | `npx`             | `npx`                      | `yarn dlx`                 | `pnpm dlx`       | `bunx`         | `deno x`      |

- **^1**: require [npm-check](https://github.com/dylang/npm-check) globally.

**Notes**

- Installing devDependencies: `ni add --dev <pkg>`
- Additional arguments for `ni run`: `ni run dev --port 8080`
- Update specific package: `ni upgrade <pkg>`

## Auto Complete

```sh
ni <TAB>
```

## Experimental

### Supply chain risk detections

You can integrate [Socket Firewall](https://socket.dev/blog/introducing-socket-firewall) to detect supply chain attacks.

https://github.com/user-attachments/assets/b3b6fc24-ec80-4bd3-a699-7562d503f7b1

Socket Firewall provides proactive protection against malicious packages by scanning all package installations and executions in real-time.

**Setup:**

1. Install Socket Firewall globally:
   ```sh
   npm i -g sfw
   ```

2. Enable Socket Firewall in ni.zsh:
   ```sh
   export NI_USE_SOCKET_FIREWALL=1
   ```

3. (Optional) Specify custom sfw binary path:
   ```sh
   export NI_SOCKET_FIREWALL_BIN=/path/to/sfw
   ```
   If not set, uses `sfw` command from PATH.

**Protected commands:**

When Socket Firewall is enabled, the following commands are automatically protected:
- `ni add` / `ni` - Package installation
- `ni exec` / `ni dlx` - Package execution (`npx`, `bunx`)


## License

MIT © azu
