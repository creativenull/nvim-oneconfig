# Single file nvim config

A clean, organized neovim config written only on one file.

## Installation

### Linux/MacOS:

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
