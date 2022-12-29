# Neovim configuration guide (with lazy.nvim)

A clean, organized pre-configured neovim configuration guide in a single `init.lua`.

[For documentation check `init.lua`.](./init.lua)

If you want to start from scratch but with some helper functions you can try out [`blank.lua` file](./blank.lua).

This `init.lua` comes with the following plugins pre-configured to work, for a more detailed list check the `init.lua`
and search for `/PLUG`:

- [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) - configure LSP servers to run on your files/projects.
- [null-ls](https://github.com/jose-elias-alvarez/null-ls.nvim) - provides an LSP protocol to run your tools such as
  eslint, prettier, stylua, etc.
- [mason.nvim](https://github.com/williamboman/mason.nvim) - automatically install LSP servers and tools (like eslint,
  prettier, etc) for `lspconfig` and `null-ls` to use.
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) - fuzzy find things like files, grep code,
  buffers, etc.
- [neo-tree.nvim](https://github.com/nvim-neo-tree/neo-tree.nvim) - a simple file explorer.
- [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) - autocompletion framework to provide suggestion within buffers,
  code, attached LSP servers, etc.
- [vim-vsnip](https://github.com/hrsh7th/vim-vsnip) - snippets engine plugin and provider via
  [friendly-snippets](https://github.com/rafamadriz/friendly-snippets).
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) - mainly used to highlight code using the
  treesitter parser, a must have for cleaner looking syntax highlighting and many more features like code folding,
  smart indenting, etc.
- [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim) - a better looking statusline.
- [bufferline.nvim](https://github.com/akinsho/bufferline.nvim) - a better looking tabline for buffers.
- [which-key.nvim](https://github.com/folke/which-key.nvim) - show a tooltip to display keybinds when pressing those
  keybinds
- [Comment.nvim](https://github.com/numToStr/Comment.nvim) - add comments based on file type.
- [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) - provide git changes on the buffer.

## Motivation

This is just my take on creating just one single config file to handle all configurations for nvim. Where having
multiple files brings an overhead of maintenance of logic in different files, I wanted to take a more straight forward
approach of keeping it all in one file.

The aim is to take away the mental model of multiple files and trying to avoid jumping between files to add/update your
configurations and just use one file with a couple simple methods to manage and organize your code within it in order
to have a better nvim experience.

### Navigation

One such method is to navigate through different sections with search tags, that comes in the form of words attached
to different sections in within comments. Using `/` and searching for the tag will jump you to that section.

For example, if you want to navigate to the lazy.nvim section to add additional plugins you would then search for `/PLUG`
and it will take you to that section. The same for when you want to configure some part of your LSP configuration, you
would search for `/LSP` and you will be directed to the relevant LSP section of the code.

### Out-of-box LSP configurations + autocompletion and its plugins

LSP configurations are setup outside of lazy.nvim and loaded by default. The advantage to this is that LSP is loaded
and ready to work and not just lazy-loaded or whatever strategy a plugin manager uses in order to save time.

### Not built for speed but for efficiency

Which brings me to another point, at the end of the day this single configuration file is created for your guidance on
writing your own configuration without much of a hassle, it's by no means a way to write the most optimized nvim
configuration possible (although it loads quite fast within ~200ms on my machine 😅).

However, you are free to take this and optimize it any way you would like, in fact, I would highly encourage you do so
because in the end this is just a guide for your convenience!

## Installation

NOTE: If you have an existing config, you should make a backup of it.

### Linux/MacOS:

```sh
git clone https://github.com/creativenull/nvim-one.git ~/.config/nvim
```

### Windows

In a powershell terminal:

```sh
git clone https://github.com/creativenull/nvim-one.git ~\AppData\Local\nvim
```

## Troubleshooting

### Errors installing on first time

You can ignore those and restart nvim, the problem is usually the plugin setup being called before the plugin is even
installed.

### Treesitter highlights don't work on lua files, getting errors on every line

Try to run `:TSUpdate` to get the latest parser for lua.

### Saving file does not reload config, or run lazy.nvim to install plugins

Make sure you follow the installation method above for it to work properly, if you ran with `ln -s ...` to link the
directory to `~/.config/nvim` then it won't work for now.

Alternatively, you can try `<Leader>vs` to reload config manually.
