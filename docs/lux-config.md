# Configuration

`lux-config.nvim` lets you configure your plugins from `lux.toml`.

## Requirements

- `lux.nvim`

## Installation

```
:Lux add lux-config.nvim
```

## Initialization order

`lux-config.nvim` loads plugin configs automatically at startup, via a
`plugin/` script sourced from Neovim's `'packpath'`. If configs must be loaded
before any other plugin, call `configure_all` explicitly at the top of your
`init.lua`:

```lua
require("lux-config").configure_all()
```

## Usage

Add a `[neovim.config]` table to your `lux.toml`:

```toml
[dependencies]
"neorg" = "7.0.0"
"sweetie.nvim" = "1.0.0"

[neovim.config]
plugins_dir = "plugins/"
auto_setup = false
```

### `plugins_dir`

The subdirectory of `nvim/lua` (default: `plugins`) in which to look for plugin
configs. For each plugin in `[dependencies]`, a matching config module is
loaded if found. A config file may be named after the plugin, or by removing the
`.[n]vim` suffix or `[n]vim-` prefix.

### `<plugin>.config`

Call a plugin's `setup` function by setting `config` on the `[dependencies]`
entry, provided none of the options are Lua functions:

```toml
[dependencies]
lualine = ">= 3.0.0"

[dependencies.lualine.config]
options = { icons_enabled = true, theme = "auto" }
```

`config` can also be a string pointing to a Lua module (relative to `nvim/lua`).

### `auto_setup`

When `auto_setup = true`, `lux-config` calls `require('<plugin>').setup()` for
plugins without a config. Set `config = true` or `config = false` on a
dependency to override this per plugin.

## Plugin bundles

```toml
[dependencies]
"neodev.nvim" = "scm"
"nvim-lspconfig" = "0.1.7"
"nvim-cmp" = { git = "hrsh7th/nvim-cmp" }

[neovim.bundles.lsp]
items = [ "neodev.nvim", "nvim-lspconfig", "nvim-cmp" ]
```

Configs are not loaded for `opt = true` plugins, nor for bundles containing
one. Override with `load_opt_plugins = true`, or configure on demand:

```lua
require("lux-config").configure("foo.nvim")
vim.cmd.packadd("foo.nvim")
```

## Neovim configuration

```toml
[neovim.config]
colorscheme = "kanagawa"

[neovim.config.options]
number = true
```

## Lua API

- `require("lux-config").configure_all()` - load configs for all plugins
- `require("lux-config").configure("foo.nvim")` - load configs for one plugin
