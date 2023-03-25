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

## Auto Complete

```sh
ni <TAB>
```

## License

MIT ©️ azu
