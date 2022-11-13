# Single file nvim configuration

A clean, organized pre-configured neovim configuration in a single `init.lua`.

[For documentation check `init.lua`.](./init.lua)

If you want to start from scratch but with some helper functions you can try out [`blank.lua` file](./blank.lua).

This `init.lua` comes with the following plugins pre-configured to work together with each other:

- [which-key.nvim](https://github.com/folke/which-key.nvim)
- [nvim-surround](https://github.com/kylechui/nvim-surround)
- [nvim-autopairs](https://github.com/windwp/nvim-autopairs)
- [Comment.nvim](https://github.com/numToStr/Comment.nvim)
- [neo-tree.nvim](https://github.com/nvim-neo-tree/neo-tree.nvim)
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)
    - [null-ls](https://github.com/jose-elias-alvarez/null-ls.nvim)
- [mason.nvim](https://github.com/williamboman/mason.nvim)
    - [mason-lspconfig.nvim](https://github.com/williamboman/mason-lspconfig.nvim)
    - [mason-tool-installer.nvim](https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim)
- [nvim-cmp](https://github.com/hrsh7th/nvim-cmp)
    - [cmp-cmdline](https://github.com/hrsh7th/cmp-cmdline)
    - [cmp-path](https://github.com/hrsh7th/cmp-path)
    - [cmp-buffer](https://github.com/hrsh7th/cmp-buffer)
    - [cmp-nvim-lsp](https://github.com/hrsh7th/cmp-nvim-lsp)
    - [lspkind-nvim](https://github.com/onsails/lspkind-nvim)
    - [cmp-vsnip](https://github.com/hrsh7th/cmp-vsnip)
- [vim-vsnip](https://github.com/hrsh7th/vim-vsnip)
    - [friendly-snippets](https://github.com/rafamadriz/friendly-snippets)
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)
- [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim)
- [bufferline.nvim](https://github.com/akinsho/bufferline.nvim)
- [indent-blankline.nvim](https://github.com/lukas-reineke/indent-blankline.nvim)
- [todo-comments.nvim](https://github.com/folke/todo-comments.nvim)
- [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim)

## Motivation

This is just my take on creating just one single config file to handle all configurations for nvim. Where having
multiple files brings an overhead of maintenance of logic in different files, I wanted to take a more straight forward
approach of keeping it all in one file.

The aim is to take away the mental model of multiple files and just use one file with a couple simple methods to manage
and organize your code within a single file in order to have a better nvim experience.

One such method is to navigate through different sections with search tags, that comes in the form of words attached
to different sections in within comments. Using `/` and searching for the tag will jump you to that section.

For example, if you want to navigate to the packer section to add additional plugins you would then search for `/PLUG`
and it will take you to that section. The same for when you want to configure some part of your LSP configuration, you
would search for `/LSP` and you will be directed to the relevant LSP section of the code.

## Installation

### Linux/MacOS:

> NOTE: If you have an existing config, you should make a backup of it.

```sh
git clone https://github.com/creativenull/nvim-one.git ~/.config/nvim
```

## Troubleshooting

### Errors installing on first time

You can ignore those and restart nvim, the problem is usually the plugin setup being called before the plugin is even
installed.

### Treesitter highlights don't work on lua files, getting errors on every line

Try to run `:TSUpdate` to get the latest parser for lua.

### Saving file does not reload config, or run packer to install plugins

Make sure you follow the installation method above for it to work properly, if you ran with `ln -s ...` to link the
directory to `~/.config/nvim` then it won't work for now.

Alternatively, you can try `<Leader>vs` to reload config manually.
