# Alternative ni written in zsh

`ni` - use the right package manager

You can run npm/yarn/pnpm/bun with same command!

- Original: <https://github.com/antfu/ni>

## Installation

```shell
curl https://raw.githubusercontent.com/azu/ni.zsh/main/ni.zsh > ni.zsh
source ni.zsh
```

- [ ] correct distribution

## Supports

- npm
- yarn v1
- pnpm
- bun

## Requirements

- `ni upgrade-interactive` require [npm-check](https://github.com/dylang/npm-check) command

## Usage

```sh
ni                      -- install current package.json
ni add <pkg>            -- add package
ni remove <pkg>         -- remove package
ni run <script>         -- run scripts
ni test                 -- run test script
ni upgrade              -- upgrade packages
ni upgrade-interactive  -- upgrade package interactively
```

## Command Table


| ni                 | npm             | yarn                       | pnpm             | bun            |
| ------------------------ | --------------- | -------------------------- | ---------------- | -------------- |
| `ni`                     | `npm install`   | `yarn install`             | `pnpm install`   | `bun install`  |
| `ni add <pkg>`           | `npm install`   | `yarn add`                 | `pnpm add`       | `bun add`      |
| `ni remove <pkg>`        | `npm uninstall` | `yarn remove`              | `pnpm remove`    | `bun remove`   |
| `ni run <script>`        | `npm run`       | `yarn run`                 | `pnpm run`       | `bun run`      |
| `ni test`                | `npm test`      | `yarn run test`            | `pnpm run test`  | `bun run test` |
| `ni upgrade`             | `npm upgrade`   | `yarn upgrade`             | `pnpm update`    | ○              |
| `ni upgrade-interactive` | `npm-check`     | `yarn upgrade-interactive` | `pnpm update -i` | ○              |

## Auto Complete

```sh
ni <TAB>
```

## License

MIT ©️ azu
