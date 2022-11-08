-- ============================================================================
-- Your custom user config variables (search: USER, CONFIG)
--
-- This is your custom user config, use this to add variables that you might
-- use in different plugins. Note, this is just an example on how I would
-- structure it, it's up to you to adjust it to your liking.
-- ============================================================================

local config = {
	plugin = {
		url = "https://github.com/wbthomason/packer.nvim",
		filepath = string.format("%s/site/pack/packer/start/packer.nvim", vim.fn.stdpath("data")),
	},
	undo_dir = string.format("%s/undo", vim.fn.stdpath("cache")),
	keymap = {
		leader = " ",
	},
	autocmd = {
		group = vim.api.nvim_create_augroup("UserCustomGroup", {}),
	},
	lsp = {
		fmt_on_save = true,
		fmt_opts = { async = false, timeout = 2500 },

		-- I use this to conditionally set a keybind for formatting my
		-- code from an LSP server or not. Because some servers do not
		-- have that capability or you would rather use null-ls.
		fmt_allowed_servers = {},

		-- For mason.nvim
		servers = {
			"tsserver",
			"sumneko_lua",
			"prismals",
			"graphql",
			"volar",
		},
		tools = {
			"stylua",
			"eslint_d",
		},
	},
}

-- ============================================================================
-- Functions (search: FUNC, FUNCTIONS)
--
-- These are utility functions that is used for convenience, do not remove but
-- you are welcome to add your own functions that can be used anywhere in this
-- file.
-- ============================================================================

---Ensure that the undo directory is created before we user it.
---@param dir string
---@return nil
local function ensure_undo_dir(dir)
	if vim.fn.isdirectory(dir) == 0 then
		if vim.fn.has("win32") == 1 then
			vim.fn.system({ "mkdir", "-Recurse", dir })
		else
			vim.fn.system({ "mkdir", "-p", dir })
		end
	end
end

---Ensure packer is installed, and return if successful or not
---@return boolean
local function ensure_packer()
	if vim.fn.empty(vim.fn.glob(config.plugin.filepath)) > 0 then
		vim.fn.system({ "git", "clone", "--depth", "1", config.plugin.url, config.plugin.filepath })
		vim.cmd("packadd packer.nvim")

		return true
	end

	return false
end

---Reload the config file, this is tightly interoped with packer.nvim
---@return nil
local function reload_config()
	-- Check if LSP servers are running and terminate if they are
	local attached_clients = vim.lsp.get_active_clients()

	if not vim.tbl_isempty(attached_clients) then
		for _, client in pairs(attached_clients) do
			if client.name ~= "null-ls" then
				vim.lsp.stop_client(client.id)
			end
		end
	end

	vim.api.nvim_command("source $MYVIMRC")

	require("packer").install()
	require("packer").compile()
end

---Register a keymap to format code via LSP
---@param key string The key to trigger formatting, eg "<Leader>p"
---@param name string The LSP client name
---@param bufnr number The buffer handle of LSP client
---@return nil
local function register_lsp_fmt_keymap(key, name, bufnr)
	vim.keymap.set("n", key, function()
		vim.lsp.buf.format(vim.tbl_extend("force", config.lsp.fmt_opts, { name = name, bufnr = bufnr }))
	end, { desc = string.format("Format current buffer [LSP - %s]", name), buffer = bufnr })
end

---Register the write event to format code via LSP
---@param name string The LSP client name
---@param bufnr number The buffer handle of LSP client
---@return nil
local function register_lsp_fmt_autosave(name, bufnr)
	vim.api.nvim_create_autocmd("BufWritePre", {
		group = config.autocmd.group,
		buffer = bufnr,
		callback = function()
			vim.lsp.buf.format(vim.tbl_extend("force", config.lsp.fmt_opts, { name = name, bufnr = bufnr }))
		end,
		desc = string.format("Format on save [LSP - %s]", name),
	})
end

-- ============================================================================
-- Events (search: EVENTS, AUG, AUGROUP, AUTOCMD, AUTO)
--
-- Add your specific events/autocmds in here, but you are free to add then
-- anywhere you like.
-- ============================================================================

-- From vim defaults.vim
-- ---
-- When editing a file, always jump to the last known cursor position.
-- Don't do it when the position is invalid, when inside an event handler
-- (happens when dropping a file on gvim) and for a commit message (it's
-- likely a different one than last time).
vim.api.nvim_create_autocmd("BufReadPost", {
	group = config.autocmd.group,
	callback = function(args)
		local valid_line = vim.fn.line([['"]]) >= 1 and vim.fn.line([['"]]) < vim.fn.line("$")
		local not_commit = vim.b[args.buf].filetype ~= "commit"

		if valid_line and not_commit then
			vim.cmd([[normal! g`"]])
		end
	end,
	desc = "Go the to last known position when opening a new buffer",
})

-- Show a highlight when yanking text
vim.api.nvim_create_autocmd("TextYankPost", {
	group = config.autocmd.group,
	callback = function()
		vim.highlight.on_yank({ higroup = "IncSearch", timeout = 300 })
	end,
	desc = "Show a highlight on yank",
})

-- Reload config and packer compile on saving the init.lua file
vim.api.nvim_create_autocmd("BufWritePost", {
	group = config.autocmd.group,
	pattern = string.format("%s/init.lua", vim.fn.stdpath("config")),
	callback = reload_config,
	desc = "Reload config file and packer compile",
})

-- ============================================================================
-- File Type Configurations (search: FT, FILETYPE)
--
-- Add any file type changes you want to do. This works in the same way you
-- would add your configurations in a ftdetect/<filetype>.lua or in
-- ftplugin/<filetype>.lua
--
-- For most cases, you will use vim.filetype.add() to make your adjustments.
-- Check `:help vim.filetype.add` for more documentation and
-- `:edit $VIMRUNTIME/lua/vim/filetype.lua` for examples.
-- ============================================================================

vim.filetype.add({
	extension = {
		js = "javascriptreact",
		podspec = "ruby",
		mdx = "markdown",
	},
	filename = {
		Podfile = "ruby",
	},
})

-- ============================================================================
-- Vim Options (search: OPT, OPTS, OPTIONS)
--
-- Add your custom vim options here.
-- ============================================================================

ensure_undo_dir(config.undo_dir)

-- Completion
vim.opt.completeopt = { "menu", "menuone", "noselect" }
vim.opt.shortmess:append("c")

-- Search
vim.opt.showmatch = true
vim.opt.smartcase = true
vim.opt.ignorecase = true
vim.opt.path = { "**" }
vim.opt.wildignore = { "*.git/*", "*node_modules/*", "*vendor/*", "*dist/*", "*build/*" }

-- Editor
vim.opt.colorcolumn = "120"
vim.opt.expandtab = true
vim.opt.lazyredraw = true
vim.opt.foldenable = false
vim.opt.spell = false
vim.opt.wrap = false
vim.opt.scrolloff = 1
vim.opt.shiftwidth = 4
vim.opt.smartindent = true
vim.opt.softtabstop = 4
vim.opt.tabstop = 4
vim.opt.wildignorecase = true

-- System
vim.opt.undodir = config.undo_dir
vim.opt.history = 10000
vim.opt.backup = false
vim.opt.swapfile = false
vim.opt.undofile = true
vim.opt.undolevels = 10000
vim.opt.updatetime = 500

-- UI
vim.opt.cmdheight = 2
vim.opt.number = true
vim.opt.showtabline = 2
vim.opt.signcolumn = "yes"
vim.opt.termguicolors = true
vim.opt.laststatus = 3

-- =============================================================================
-- Keymaps (search: KEYS, KEY, KEYMAPS)
--
-- Add your custom keymaps here.
-- =============================================================================

vim.g.mapleader = config.keymap.leader

-- Unbind default bindings for arrow keys, trust me this is for your own good
vim.keymap.set("", "<Up>", "")
vim.keymap.set("", "<Down>", "")
vim.keymap.set("", "<Left>", "")
vim.keymap.set("", "<Right>", "")
vim.keymap.set("i", "<Up>", "")
vim.keymap.set("i", "<Down>", "")
vim.keymap.set("i", "<Left>", "")
vim.keymap.set("i", "<Right>", "")

-- Resize window panes, we can use those arrow keys
-- to help use resize windows - at least we give them some purpose
vim.keymap.set("n", "<Up>", "<Cmd>resize +2<CR>")
vim.keymap.set("n", "<Down>", "<Cmd>resize -2<CR>")
vim.keymap.set("n", "<Left>", "<Cmd>vertical resize -2<CR>")
vim.keymap.set("n", "<Right>", "<Cmd>vertical resize +2<CR>")

-- Map Esc, to perform quick switching between Normal and Insert mode
vim.keymap.set("i", "jk", "<Esc>")

-- Map escape from terminal input to Normal mode
vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]])
vim.keymap.set("t", "<C-[>", [[<C-\><C-n>]])

-- Disable highlights
vim.keymap.set("n", "<Leader><CR>", "<Cmd>noh<CR>")

-- List all buffers
vim.keymap.set("n", "<Leader>bl", "<Cmd>buffers<CR>")

-- Go to next buffer
vim.keymap.set("n", "<C-l>", "<Cmd>bnext<CR>")
vim.keymap.set("n", "<Leader>bn", "<Cmd>bnext<CR>")

-- Go to previous buffer
vim.keymap.set("n", "<C-h>", "<Cmd>bprevious<CR>")
vim.keymap.set("n", "<Leader>bp", "<Cmd>bprevious<CR>")

-- Close the current buffer, and more?
vim.keymap.set("n", "<Leader>bd", "<Cmd>bp<Bar>sp<Bar>bn<Bar>bd<CR>")

-- Close all buffer, except current
vim.keymap.set("n", "<Leader>bx", "<Cmd>%bd<Bar>e#<Bar>bd#<CR>")

-- Move a line of text Alt+[j/k]
vim.keymap.set("n", "<M-j>", "mz:m+<CR>`z")
vim.keymap.set("n", "<M-k>", "mz:m-2<CR>`z")
vim.keymap.set("v", "<M-j>", [[:m'>+<CR>`<my`>mzgv`yo`z]])
vim.keymap.set("v", "<M-k>", [[:m'<-2<CR>`>my`<mzgv`yo`z]])

-- Edit vimrc
vim.keymap.set("n", "<Leader>ve", "<Cmd>edit $MYVIMRC<CR>")

-- Source the vimrc to reflect changes
vim.keymap.set("n", "<Leader>vs", "<Cmd>ConfigReload<CR>")

-- Reload file
vim.keymap.set("n", "<Leader>r", "<Cmd>edit!<CR>")

-- List all maps
vim.keymap.set("n", "<Leader>mn", "<Cmd>nmap<CR>")
vim.keymap.set("n", "<Leader>mv", "<Cmd>vmap<CR>")
vim.keymap.set("n", "<Leader>mi", "<Cmd>imap<CR>")
vim.keymap.set("n", "<Leader>mt", "<Cmd>tmap<CR>")
vim.keymap.set("n", "<Leader>mc", "<Cmd>cmap<CR>")

-- Copy/Paste from sytem clipboard
vim.keymap.set("v", "p", [["_dP]])
vim.keymap.set("v", "<Leader>y", [["+y]])
vim.keymap.set("n", "<Leader>y", [["+y]])
vim.keymap.set("n", "<Leader>p", [["+p]])

-- =============================================================================
-- User Commands (search: CMD, CMDS, COMMANDS)
--
-- You custom user commands, you can set any commands you like or even
-- abbreviations (which gets quite helpful when making mistakes).
-- =============================================================================

vim.api.nvim_create_user_command("Config", "edit $MYVIMRC", { desc = "Open config" })
vim.api.nvim_create_user_command("ConfigReload", reload_config, { desc = "Reload config" })

-- Command Abbreviations, I can't release my shift key fast enough :')
vim.cmd("cnoreabbrev Q  q")
vim.cmd("cnoreabbrev Qa qa")
vim.cmd("cnoreabbrev W  w")
vim.cmd("cnoreabbrev Wq wq")

-- ============================================================================
-- Plugins (search: PLUG, PLUGS, PLUGINS)
--
-- Add your plugins in here along with their configurations. However, the
-- exception is for LSP configurations which is done separately further below.
--
-- A quick guide on how to install plugins with packer.nvim:
--
--     + Visit any vim plugin repository on GitHub (or GitLab, etc)
--
--     + Copy the first and second path of the URL:
--         For example, if `https://github.com/bluz71/vim-moonfly-colors`
--         then just copy `bluz71/vim-moonfly-colors`
--
--         If you are using GitLab or any other git server, then you will have to
--         copy the entire URL and
--         not just the last two paths of the URL.
--
--     + Add what you copied into the use() function
--
--     + If you have to pass options to the plug, then use a table instead
--         Example, for `junegunn/fzf` you need to run the installer
--         so call with:
--             use({
--                 "windwp/nvim-autopairs",
--             	   commit = "6b6e35fc9aca1030a74cc022220bc22ea6c5daf4",
--             	   config = function()
--                     require("nvim-autopairs").setup({})
--             	   end,
--             })
-- ============================================================================

local packer_bootstrap = ensure_packer()
local packer = require("packer")

packer.init({
	compile_path = string.format("%s/site/plugin/packer_compiled.lua", vim.fn.stdpath("data")),
})

packer.startup(function(use)
	-- Add your plugins inside this function
	-- ---

	use({ "wbthomason/packer.nvim", commit = "6afb67460283f0e990d35d229fd38fdc04063e0a" })

	use({
		"kylechui/nvim-surround",
		tag = "v1.0.0",
		config = function()
			require("nvim-surround").setup({})
		end,
	})

	use({
		"windwp/nvim-autopairs",
		commit = "6b6e35fc9aca1030a74cc022220bc22ea6c5daf4",
		config = function()
			require("nvim-autopairs").setup({})
		end,
	})

	use({
		"numToStr/Comment.nvim",
		commit = "ad7ffa8ed2279f1c8a90212c7d3851f9b783a3d6",
		config = function()
			require("Comment").setup()
		end,
	})

	use({
		"folke/todo-comments.nvim",
		commit = "530eb3a896e9eef270f00f4baafa102361afc93b",
		requires = "nvim-lua/plenary.nvim",
		config = function()
			require("todo-comments").setup({})
		end,
	})

	-- File explorer
	use({
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v2.x",
		requires = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
			"MunifTanjim/nui.nvim",
		},
		config = function()
			-- If you want icons for diagnostic errors, you'll need to define them somewhere:
			vim.fn.sign_define("DiagnosticSignError", { text = " ", texthl = "DiagnosticSignError" })
			vim.fn.sign_define("DiagnosticSignWarn", { text = " ", texthl = "DiagnosticSignWarn" })
			vim.fn.sign_define("DiagnosticSignInfo", { text = " ", texthl = "DiagnosticSignInfo" })
			vim.fn.sign_define("DiagnosticSignHint", { text = "", texthl = "DiagnosticSignHint" })

			require("neo-tree").setup({
				close_if_last_window = true,
			})

			vim.keymap.set(
				"n",
				"<Leader>ff",
				"<Cmd>Neotree reveal toggle right<CR>",
				{ desc = "Toggle file tree (neo-tree)" }
			)
		end,
	})

	-- File finder
	use({
		"nvim-telescope/telescope.nvim",
		tag = "0.1.0",
		requires = "nvim-lua/plenary.nvim",
		config = function()
			local t_builtin = require("telescope.builtin")

			vim.keymap.set("n", "<C-p>", function()
				t_builtin.find_files()
			end, {
				desc = "Open file finder (telescope)",
			})

			vim.keymap.set("n", "<C-t>", function()
				t_builtin.live_grep()
			end, { desc = "Open text search (telescope)" })
		end,
	})

	-- LSP + Tools + Debug + Auto-completion
	use({
		"neovim/nvim-lspconfig",
		requires = {
			-- Linter/Formatter
			"jose-elias-alvarez/null-ls.nvim",
			-- Tool installer
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",
			-- UI/Aesthetics
			"glepnir/lspsaga.nvim",
		},
	})

	use({
		"hrsh7th/nvim-cmp",
		requires = {
			-- Cmdline completions
			"hrsh7th/cmp-cmdline",
			-- Path completions
			"hrsh7th/cmp-path",
			-- Buffer completions
			"hrsh7th/cmp-buffer",
			-- LSP completions
			"hrsh7th/cmp-nvim-lsp",
			"onsails/lspkind-nvim",
			-- vnsip completions
			"hrsh7th/cmp-vsnip",
			"hrsh7th/vim-vsnip",
			"rafamadriz/friendly-snippets",
		},
		config = function()
			local cmp = require("cmp")

			vim.g.vsnip_filetypes = {
				javascriptreact = { "javascript" },
				typescriptreact = { "typescript" },
			}

			local function has_words_before()
				local line, col = unpack(vim.api.nvim_win_get_cursor(0))
				return col ~= 0
					and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
			end

			local function feedkey(key, mode)
				vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, true, true), mode, true)
			end

			cmp.setup({
				snippet = {
					expand = function(args)
						vim.fn["vsnip#anonymous"](args.body)
					end,
				},

				mapping = {
					["<C-Space>"] = cmp.mapping.complete({}),
					["<C-y>"] = cmp.mapping.confirm({ select = true, behavior = cmp.ConfirmBehavior.Replace }),
					["<CR>"] = cmp.mapping.confirm({ select = true, behavior = cmp.ConfirmBehavior.Replace }),
					["<Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item()
						elseif vim.fn["vsnip#available"](1) == 1 then
							feedkey("<Plug>(vsnip-expand-or-jump)", "")
						elseif has_words_before() then
							cmp.complete()
						else
							fallback() -- The fallback function sends a already mapped key. In this case, it's probably `<Tab>`.
						end
					end, { "i", "s" }),

					["<C-n>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item()
						elseif vim.fn["vsnip#available"](1) == 1 then
							feedkey("<Plug>(vsnip-expand-or-jump)", "")
						elseif has_words_before() then
							cmp.complete()
						else
							fallback() -- The fallback function sends a already mapped key. In this case, it's probably `<Tab>`.
						end
					end, { "i", "s" }),

					["<S-Tab>"] = cmp.mapping(function()
						if cmp.visible() then
							cmp.select_prev_item()
						elseif vim.fn["vsnip#jumpable"](-1) == 1 then
							feedkey("<Plug>(vsnip-jump-prev)", "")
						end
					end, { "i", "s" }),

					["<C-p>"] = cmp.mapping(function()
						if cmp.visible() then
							cmp.select_prev_item()
						elseif vim.fn["vsnip#jumpable"](-1) == 1 then
							feedkey("<Plug>(vsnip-jump-prev)", "")
						end
					end, { "i", "s" }),
				},

				sources = cmp.config.sources({
					{ name = "nvim_lsp" },
					{ name = "vsnip" }, -- For vsnip users.
				}, {
					{ name = "buffer" },
					{ name = "path" },
				}),

				window = {
					-- completion = cmp.config.window.bordered(),
					documentation = cmp.config.window.bordered("rounded"),
				},

				formatting = {
					format = require("lspkind").cmp_format({
						mode = "symbol_text",
						menu = {
							buffer = "[BUF]",
							nvim_lsp = "[LSP]",
							vsnip = "[SNIP]",
							path = "[PATH]",
						},
					}),
				},
			})

			-- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
			cmp.setup.cmdline({ "/", "?" }, {
				mapping = cmp.mapping.preset.cmdline(),
				sources = {
					{ name = "buffer" },
				},
			})

			-- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
			cmp.setup.cmdline(":", {
				mapping = cmp.mapping.preset.cmdline(),
				sources = cmp.config.sources({
					{ name = "path" },
				}, {
					{ name = "cmdline" },
				}),
			})
		end,
	})

	-- Treesitter
	use({
		"nvim-treesitter/nvim-treesitter",
		requires = { "nvim-treesitter/nvim-treesitter-textobjects", opt = true },
		run = function()
			require("nvim-treesitter.install").update({ with_sync = true })
		end,
		config = function()
			vim.cmd("packadd nvim-treesitter-textobjects")
			require("nvim-treesitter.configs").setup({
				ensure_installed = {
					"graphql",
					"javascript",
					"json",
					"lua",
					"help",
					"prisma",
					"tsx",
					"typescript",
				},
				highlight = { enable = true },
				textobjects = {
					select = { enable = true },
				},
			})
		end,
	})

	-- UI
	use({
		"nvim-lualine/lualine.nvim",
		commit = "3325d5d43a7a2bc9baeef2b7e58e1d915278beaf",
		requires = { { "nvim-tree/nvim-web-devicons", commit = "9061e2d355ecaa2b588b71a35e7a11358a7e51e1" } },
		config = function()
			require("lualine").setup({})
		end,
	})

	use({
		"akinsho/bufferline.nvim",
		tag = "v3.*",
		requires = { { "nvim-tree/nvim-web-devicons", commit = "9061e2d355ecaa2b588b71a35e7a11358a7e51e1" } },
		config = function()
			require("bufferline").setup({})
		end,
	})

	-- Themes
	use("bluz71/vim-moonfly-colors")
	use({
		"catppuccin/nvim",
		as = "catppuccin",
		config = function()
			require("catppuccin").setup({
				flavour = "mocha",
				transparent_background = true,
				custom_highlights = {
					WinSeparator = { bg = "NONE", fg = "#eeeeee" },
				},
			})
		end,
	})

	-- Automatically set up your configuration after cloning packer.nvim
	-- Put this at the end after all plugins
	if packer_bootstrap then
		packer.sync()
	end
end)

if packer_bootstrap then
	return
end

-- ============================================================================
-- LSP Configuration (search: LSP, LSPCONFIG)
--
-- LSP Server configurations goes here. This is also where you should add any
-- logic that concerns the builtin LSP client.
-- For example:
-- + You need LSP servers installed? Add mason config in here
-- + You need to add some UI/change look of your LSP/Statusline/Tabline/Winbar etc? Add them here
-- ============================================================================

-- LSP Saga Config
-- ---
require("lspsaga").init_lsp_saga({ border_style = "rounded" })

-- mason.nvim Config
-- ---
require("mason").setup()
require("mason-tool-installer").setup({
	ensure_installed = config.lsp.tools,
	automatic_installation = true,
})
require("mason-lspconfig").setup({
	ensure_installed = config.lsp.servers,
	automatic_installation = true,
})

-- nvim-lspconfig Config
-- ---
local lspconfig = require("lspconfig")

local float_opts = {
	border = "rounded",
	width = 80,
}

-- Global diagnostic config
vim.diagnostic.config({
	update_in_insert = false,
	float = {
		source = true,
		border = float_opts.border,
		width = float_opts.width,
	},
})

-- Window options
require("lspconfig.ui.windows").default_options.border = float_opts.border

-- Hover options
vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, float_opts)

-- Signature help options
vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
	border = float_opts.border,
})

local capabilities = require("cmp_nvim_lsp").default_capabilities()

local function on_attach(client, bufnr)
	-- Omnifunc backup
	vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

	-- LSP Keymaps
	-- vim.keymap.set("n", "<Leader>la", vim.lsp.buf.code_action, { desc = "LSP Code Actions", buffer = bufnr })
	vim.keymap.set("n", "<Leader>la", "<Cmd>Lspsaga code_action<CR>", { desc = "LSP Code Actions", buffer = bufnr })
	vim.keymap.set("n", "<Leader>ld", vim.lsp.buf.definition, { desc = "LSP Go-to Definition", buffer = bufnr })
	-- vim.keymap.set("n", "<Leader>lh", vim.lsp.buf.hover, { desc = "LSP Hover Information", buffer = bufnr })
	vim.keymap.set("n", "<Leader>lh", "<Cmd>Lspsaga hover_doc<CR>", { desc = "LSP Hover Information", buffer = bufnr })
	-- vim.keymap.set("n", "<Leader>lr", vim.lsp.buf.rename, { desc = "LSP Rename", buffer = bufnr })
	vim.keymap.set("n", "<Leader>lr", "<Cmd>Lspsaga rename<CR>", { desc = "LSP Rename", buffer = bufnr })
	vim.keymap.set("n", "<Leader>ls", vim.lsp.buf.signature_help, { desc = "LSP Signature Help", buffer = bufnr })
	vim.keymap.set("n", "<Leader>le", vim.diagnostic.setloclist, { desc = "LSP Show All Diagnostics", buffer = bufnr })
	vim.keymap.set("n", "<Leader>lw", function()
		vim.diagnostic.open_float({ bufnr = bufnr, scope = "line" })
	end, { desc = "Show LSP Line Diagnostic", buffer = bufnr })

	-- LSP Saga doesn't show the source name, where the error is coming from
	--
	-- vim.keymap.set(
	-- 	"n",
	-- 	"<Leader>lw",
	-- 	"<Cmd>Lspsaga show_line_diagnostics<CR>",
	-- 	{ desc = "Show LSP line diagnostics", buffer = bufnr }
	-- )

	if
		vim.tbl_contains(config.lsp.fmt_allowed_servers, client.name)
		and client.server_capabilities.documentFormattingProvider
	then
		register_lsp_fmt_keymap("<Leader>lf", client.name, bufnr)

		if config.lsp.fmt_on_save then
			register_lsp_fmt_autosave(client.name, bufnr)
		end
	end
end

local lspconfig_setup_defaults = {
	capabilities = capabilities,
	on_attach = on_attach,
}

-- Lua
local lua_rtp = vim.split(package.path, ";")
table.insert(lua_rtp, "lua/?.lua")
table.insert(lua_rtp, "lua/?/init.lua")
lspconfig.sumneko_lua.setup(vim.tbl_extend("force", lspconfig_setup_defaults, {
	settings = {
		Lua = {
			runtime = {
				version = "LuaJIT",
				path = lua_rtp,
			},
			diagnostics = { globals = { "vim" } },
			workspace = {
				library = vim.api.nvim_get_runtime_file("", true),
				checkThirdParty = false,
			},
			telemetry = { enable = false },
		},
	},
}))

-- Web Development
lspconfig.tsserver.setup(lspconfig_setup_defaults)
lspconfig.graphql.setup(lspconfig_setup_defaults)
lspconfig.prismals.setup(lspconfig_setup_defaults)
lspconfig.volar.setup(vim.tbl_extend("force", lspconfig_setup_defaults, {
	init_options = {
		typescript = {
			tsdk = string.format("%s/node_modules/typescript/lib", vim.fn.getcwd()),
		},
	},
}))

-- Null-ls Config
-- ---
local nls = require("null-ls")
nls.setup({
	sources = {
		nls.builtins.diagnostics.eslint_d,
		nls.builtins.formatting.prettier,
		nls.builtins.formatting.stylua.with({
			extra_args = {
				"--column-width",
				"100",
				"--line-endings",
				"Unix",
				"--indent-width",
				"2",
				"--quote-style",
				"AutoPreferSingle",
				"--call-parentheses",
				"None",
			},
		}),
	},
	on_attach = function(client, bufnr)
		register_lsp_fmt_keymap("<Leader>lf", client.name, bufnr)

		if config.lsp.fmt_on_save then
			register_lsp_fmt_autosave(client.name, bufnr)
		end
	end,
})

-- ============================================================================
-- Theme (search: THEME, COLOR, COLORSCHEME)
--
-- Colorscheme always goes last.
-- ============================================================================

pcall(vim.cmd, "colorscheme catppuccin")
