# nvim-lspconfig

nvim-lspconfig is a "data only" repo, providing basic, default [Nvim LSP client](https://neovim.io/doc/user/lsp.html)
configurations for various LSP servers. View [all configs](doc/configs.md) or `:help lspconfig-all` from Nvim.

## Important ⚠️

* These configs are **best-effort and supported by the community (you).** See [contributions](#contributions).
* The configs live in [`lsp/`](./lsp/).
    * Upgrade to Nvim 0.11+ and use `vim.lsp.enable('…')` (not `require'…'.pyright.setup{}`) to enable a config.
* The configs in `lua/lspconfig/` are *deprecated* and will be removed.
    * Upgrade to Nvim 0.11+ and use `vim.lsp.enable('…')` (not `require'…'.pyright.setup{}`) to enable a config.
* Ask questions on [GitHub Discussions](https://github.com/neovim/neovim/discussions), not the issue tracker.
* If you found a bug in Nvim LSP (`:help lsp`), [report it to Neovim core](https://github.com/neovim/neovim/issues/new?assignees=&labels=bug%2Clsp&template=lsp_bug_report.yml).
    * **Do not** report it here. Only configuration data lives here.
* This repo only provides *configurations*. Its programmatic API is deprecated and must not be used externally.
    * The "framework" parts (*not* the configs) of nvim-lspconfig [will be upstreamed to Nvim core](https://github.com/neovim/neovim/issues/28479).

## Install

[![LuaRocks](https://img.shields.io/luarocks/v/neovim/nvim-lspconfig?logo=lua&color=purple)](https://luarocks.org/modules/neovim/nvim-lspconfig)

* Requires Nvim 0.11+. Support for Nvim 0.10 will be removed. Update Nvim and nvim-lspconfig before reporting an issue.
* Install nvim-lspconfig using Vim's "packages" feature:
  ```
  git clone https://github.com/neovim/nvim-lspconfig ~/.config/nvim/pack/nvim/start/nvim-lspconfig
  ```
* Or if you have Nvim 0.12 (in development), you can use the builtin plugin manager:
  ```lua
  vim.pack.add{
    { src = 'https://github.com/neovim/nvim-lspconfig' },
  }
  ```
* Or use a 3rd-party plugin manager (consult the documentation for your plugin manager).

## Quickstart

1. Install a language server, e.g. [pyright](doc/configs.md#pyright)
   ```bash
   npm i -g pyright
   ```
2. Add the language server setup to your init.lua.
    - Nvim 0.11+ (see [vim.lsp.config](#vimlspconfig))
      ```lua
      vim.lsp.enable('pyright')
      ```
    - Nvim 0.10 (legacy, **not supported**)
      ```lua
      require'lspconfig'.pyright.setup{}
      ```
3. Ensure your project/workspace contains a root marker as specified in `:help lspconfig-all`.
4. Open a code file in Nvim. LSP will attach and provide diagnostics.
   ```
   nvim main.py
   ```
5. Run `:checkhealth lsp` to see the status or to troubleshoot.

Read `:help lspconfig` for details. Read `:help lspconfig-all` for the full list of server-specific details.
For servers not on your `$PATH` (e.g., `jdtls`, `elixirls`), you must manually set the `cmd` parameter, see [vim.lsp.config](#vimlspconfig).

## Configuration

Nvim sets default options and mappings when LSP is active in a buffer:
* [:help lsp-defaults](https://neovim.io/doc/user/lsp.html#lsp-defaults)
* [:help diagnostic-defaults](https://neovim.io/doc/user/diagnostic.html#diagnostic-defaults)

To customize, see:
* [:help lsp-attach](https://neovim.io/doc/user/lsp.html#lsp-attach)
* [:h lsp-buf](https://neovim.io/doc/user/lsp.html#lsp-buf)

Extra settings can be specified for each LSP server:

- Nvim 0.11+: You can extend a config as follows (see [vim.lsp.config](#vimlspconfig);
  you can also copy any config directly from [`lsp/`](./lsp/) and put it in a local `lsp/` directory in your 'runtimepath').
  ```lua
  vim.lsp.config('rust_analyzer', {
    -- Server-specific settings. See `:help lsp-quickstart`
    settings = {
      ['rust-analyzer'] = {},
    },
  })
  ```
- Nvim 0.10 (legacy, **not supported**)
  ```lua
  local lspconfig = require('lspconfig')
  lspconfig.rust_analyzer.setup {
    -- Server-specific settings. See `:help lspconfig-setup`
    settings = {
      ['rust-analyzer'] = {},
    },
  }
  ```

## Troubleshooting

The most common reasons a language server does not start or attach are:

1. Language server is not installed. nvim-lspconfig does not install language servers for you. You should be able to run the `cmd` defined in each server's Lua module from the command line and see that the language server starts. If the `cmd` is an executable name instead of an absolute path to the executable, ensure it is on your path.
2. Missing filetype plugins. Certain languages are not detected by Vim/Nvim because they have not yet been added to the filetype detection system. Ensure `:set filetype?` shows the filetype and not an empty value.
3. Not triggering root detection. **Some** language servers require a "workspace", which is found by looking for an ancestor directory that contains a "root marker". The most common root marker is `.git/`, but each config defines other "root marker" names. Root markers/directories are listed in [doc/configs.md](doc/configs.md).

## Bug reports

If you found a bug with LSP functionality, [report it to Neovim core](https://github.com/neovim/neovim/issues/new?assignees=&labels=bug%2Clsp&template=lsp_bug_report.yml).

Before reporting a bug, check your logs and the output of `:LspInfo`. Add the following to your init.vim to enable logging:

```lua
vim.lsp.set_log_level("debug")
```

Attempt to run the language server, and open the log with:

```
:LspLog
```
Most of the time, the reason for failure is present in the logs.

## Commands

* `:LspInfo` (alias to `:checkhealth vim.lsp`) shows the status of active and configured language servers.
* `:LspStart <config_name>` Start the requested server name. Will only successfully start if the command detects a root directory matching the current config.
* `:LspStop [<client_id_or_name>]` Stops the given server. Defaults to stopping all servers active on the current buffer. To force stop add `++force`
* `:LspRestart [<client_id_or_name>]` Restarts the given client, and attempts to reattach to all previously attached buffers. Defaults to restarting all active servers.

## Contributions

If a language server is missing from [configs.md](doc/configs.md), contributing
a new configuration for it helps others, especially if the server requires special setup. Follow these steps:

1. Read [CONTRIBUTING.md](CONTRIBUTING.md).
2. Create a new file at `lsp/<server_name>.lua`.
    - Copy an [existing config](https://github.com/neovim/nvim-lspconfig/tree/master/lsp)
      to get started. Most configs are simple. For an extensive example see
      [texlab.lua](https://github.com/neovim/nvim-lspconfig/blob/master/lsp/texlab.lua).
3. Ask questions on [GitHub Discussions](https://github.com/neovim/neovim/discussions) or in the [Neovim Matrix room](https://app.element.io/#/room/#neovim:matrix.org).

## Release process

To publish a release:

- Create and push a new [tag](https://github.com/neovim/nvim-lspconfig/tags).
- After pushing the tag, a [GitHub action](./.github/workflows/release.yml)
  will automatically package the plugin and publish the release to LuaRocks.

## License

Copyright Neovim contributors. All rights reserved.

nvim-lspconfig is licensed under the terms of the Apache 2.0 license.

See [LICENSE.md](./LICENSE.md)
