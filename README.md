# Single file nvim config

A clean, organized neovim config written only on one file.

## Motivation

This is just my take on creating just one single config file to handle all your configurations for nvim. Where having
multiple files mean that you now have to maintain your logic in different files, I want to take the approach on keeping
it all in one file, since a nvim config shouldn't be a chore or a project that you want to keep up-to-date every hour.

The aim is to take away the mental model of multiple files and use one file with couple simple techniques to manage your
user and plugin configs.

One technique that is in this init file is having tags that you can search through different sections. This was inspired
from my own config where I section off particular logic and be able to search them with `/` in nvim.

Each section is documented to describe what goes in there, check the [init.lua](./init.lua) file to go through them,
but the shorter explanation is below:

- `USER` or `CONFIG` - Navigate to your custom variables that will be used within your init file
- `FUNC` or `FUNCTIONS` - Navigate to your custom functions that will be used within your init file
- `EVENTS`, `AUG`, `AUGROUP`, `AUTOCMD` or `AUTO` - Navigate to your custom autocmds for your config or plugins
- `FT` or `FILETYPE` - Navigate to your custom filetype configurations
- `OPT`, `OPTS` or `OPTIONS` - Navigate to your custom vim options that are set with `vim.opt`
- `KEYS`, `KEY` or `KEYMAPS` - Navigate to your custom keybind/keymap that are set with `vim.keymap.set`
- `CMD`, `CMDS` or `COMMANDS` - Navigate to your custom user commands that are set with `vim.api.nvim_create_user_command`
- `PLUG`, `PLUGS` or `PLUGINS` - Navigate to your plugin manager list set with packer.nvim
- `LSP` or `LSPCONFIG` - Navigate to your custom builtin nvim-lsp config, this is separate because
- `THEME`, `COLOR` or `COLORSCHEME` - Navigate to your custom theme configuration

## Installation

### Linux/MacOS:

> NOTE: If you have an existing config, you should make a backup of it with: `mv ~/.config/nvim ~/.config/nvim_bk`

```sh
git clone https://github.com/creativenull/nvim-one.git ~/.config/nvim
```

## Troubleshooting

### Errors installing on first time

You can ignore those and restart nvim, the problem is usually the plugin setup being called before the plugin is even
installed.

### Treesitter higlights don't work on lua files, getting errors on every line

Try to run `:TSUpdate` to get the latest parser for lua.

### Saving file does not reload config, or run packer to install plugins

Make sure you follow the installation method above for it to work properly, if you ran with `ln -s ...` to link the
directory to `~/.config/nvim` then it won't work for now.

Alternatively, you can try `<Leader>vs` to reload config manually.
