-- ============================================================================
-- Your custom user config variables
--
-- This is your custom user config, use this to add variables that you might
-- use in different plugins. Note, this is just an example on how I would
-- structure it, it's up to you to adjust it to your liking.
--
-- Tags: USER, CONFIG
-- ============================================================================

local config = {
	plugin = {
		url = 'https://github.com/wbthomason/packer.nvim',
		filepath = string.format('%s/site/pack/packer/start/packer.nvim', vim.fn.stdpath 'data'),
	},
	undo_dir = string.format('%s/undo', vim.fn.stdpath 'cache'),
	options = {
		column_limit = '120',
	},
	keymap = {
		leader = ' ',
	},
	autocmd = {
		group = vim.api.nvim_create_augroup('UserCustomGroup', {}),
	},
	lsp = {
		fmt_on_save = true,
		fmt_opts = { async = false, timeout = 2500 },

		-- Use this to conditionally set a keybind for formatting
		-- code a lsp server defined here. Because some servers do
		-- not have that capability or you would rather exclusively
		-- use null-ls.
		--
		-- NOTE: Null-ls is enabled by default for formatting, so you
		-- don't need to add null-ls here.
		fmt_allowed_servers = {
			'denols',
			'pylsp',
		},

		-- For mason.nvim
		servers = {
			'gopls',
			'graphql',
			'prismals',
			'pylsp',
			'sumneko_lua',
			'tsserver',
			'volar',
		},
		tools = {
			'eslint_d',
			'stylua',
		},
	},
}

-- Requirement check
if vim.fn.has 'nvim-0.8' == 0 then
	print 'Neovim >= v0.8 is required for this config'
	return
end

-- ============================================================================
-- Functions
--
-- These are utility functions that is used for convenience, do not remove but
-- you are welcome to add your own functions that can be used anywhere in this
-- file.
--
-- Tags: FUNC, FUNCTIONS
-- ============================================================================

---Ensure that the undo directory is created before we user it.
---@param dir string
---@return nil
local function ensure_undo_dir(dir)
	if vim.fn.isdirectory(dir) == 0 then
		if vim.fn.has 'win32' == 1 then
			vim.fn.system { 'mkdir', '-Recurse', dir }
		else
			vim.fn.system { 'mkdir', '-p', dir }
		end
	end
end

---Ensure packer is installed, and return if successful or not
---@return boolean
local function ensure_packer()
	if vim.fn.empty(vim.fn.glob(config.plugin.filepath)) > 0 then
		vim.fn.system { 'git', 'clone', '--depth', '1', config.plugin.url, config.plugin.filepath }
		vim.cmd 'packadd packer.nvim'

		return true
	end

	return false
end

---Reload the config file, this is tightly interoped with packer.nvim
---@return nil
local function reload_config()
	-- Check if LSP servers are running and terminate, if running
	local attached_clients = vim.lsp.get_active_clients()
	if not vim.tbl_isempty(attached_clients) then
		for _, client in pairs(attached_clients) do
			-- The exception is null-ls as it does not restart after
			-- reloading the init.lua file
			if client.name ~= 'null-ls' then
				vim.lsp.stop_client(client.id)
			end
		end
	end

	vim.api.nvim_command 'source $MYVIMRC'

	-- Install any plugins needed to be installed
	-- and compile to faster boot up
	require('packer').install()
	require('packer').compile()
end

---Register a keymap to format code via LSP
---@param key string The key to trigger formatting, eg "<Leader>p"
---@param name string The LSP client name
---@param bufnr number The buffer handle of LSP client
---@return nil
local function register_lsp_fmt_keymap(key, name, bufnr)
	vim.keymap.set('n', key, function()
		vim.lsp.buf.format(vim.tbl_extend('force', config.lsp.fmt_opts, { name = name, bufnr = bufnr }))
	end, { desc = string.format('Format current buffer [LSP - %s]', name), buffer = bufnr })
end

---Register the write event to format code via LSP
---@param name string The LSP client name
---@param bufnr number The buffer handle of LSP client
---@return nil
local function register_lsp_fmt_autosave(name, bufnr)
	vim.api.nvim_create_autocmd('BufWritePre', {
		group = config.autocmd.group,
		buffer = bufnr,
		callback = function()
			vim.lsp.buf.format(vim.tbl_extend('force', config.lsp.fmt_opts, { name = name, bufnr = bufnr }))
		end,
		desc = string.format('Format on save [LSP - %s]', name),
	})
end

-- ============================================================================
-- Events
--
-- Add your specific events/autocmds in here, but you are free to add then
-- anywhere you like. Example, show a highlight when yanking text:
--
--      vim.api.nvim_create_autocmd('TextYankPost', {
--      	group = config.autocmd.group,
--      	callback = function()
--      		vim.highlight.on_yank { higroup = 'IncSearch', timeout = 300 }
--      	end,
--      	desc = 'Show a highlight on yank',
--      })
--
-- Tags: AU, AUG, AUGROUP, AUTOCMD, EVENTS
-- ============================================================================

-- From vim defaults.vim
-- ---
-- When editing a file, always jump to the last known cursor position.
-- Don't do it when the position is invalid, when inside an event handler
-- (happens when dropping a file on gvim) and for a commit message (it's
-- likely a different one than last time).
vim.api.nvim_create_autocmd('BufReadPost', {
	group = config.autocmd.group,
	callback = function(args)
		local valid_line = vim.fn.line [['"]] >= 1 and vim.fn.line [['"]] < vim.fn.line '$'
		local not_commit = vim.b[args.buf].filetype ~= 'commit'

		if valid_line and not_commit then
			vim.cmd [[normal! g`"]]
		end
	end,
	desc = 'Go the to last known position when opening a new buffer',
})

-- Show a highlight when yanking text
vim.api.nvim_create_autocmd('TextYankPost', {
	group = config.autocmd.group,
	callback = function()
		vim.highlight.on_yank { higroup = 'IncSearch', timeout = 300 }
	end,
	desc = 'Show a highlight on yank',
})

-- Reload config and packer compile on saving the init.lua file
vim.api.nvim_create_autocmd('BufWritePost', {
	group = config.autocmd.group,
	pattern = string.format('%s/init.lua', vim.fn.stdpath 'config'),
	callback = reload_config,
	desc = 'Reload config file and packer compile',
})

-- ============================================================================
-- File Type Configurations
--
-- Add any file type changes you want to do. This works in the same way you
-- would add your configurations in a ftdetect/<filetype>.lua or in
-- ftplugin/<filetype>.lua
--
-- For most cases, you will use vim.filetype.add() to make your adjustments.
-- Check `:help vim.filetype.add` for more documentation and
-- `:edit $VIMRUNTIME/lua/vim/filetype.lua` for examples.
--
-- Tags: FT, FILETYPE
-- ============================================================================

vim.filetype.add {
	extension = {
		js = 'javascriptreact',
		podspec = 'ruby',
		mdx = 'markdown',
	},
	filename = {
		Podfile = 'ruby',
	},
}

-- ============================================================================
-- Vim Options
--
-- Add your custom vim options with `vim.opt`. Example, show number line and
-- sign column:
--
-- vim.opt.number = true
-- vim.opt.signcolumn = 'yes'
--
-- Tags: OPT, OPTS, OPTIONS
-- ============================================================================

ensure_undo_dir(config.undo_dir)

-- Completion
vim.opt.completeopt = { 'menu', 'menuone', 'noselect' }
vim.opt.shortmess:append 'c'

-- Search
vim.opt.showmatch = true
vim.opt.smartcase = true
vim.opt.ignorecase = true
vim.opt.path = { '**' }
vim.opt.wildignore = { '*.git/*', '*node_modules/*', '*vendor/*', '*dist/*', '*build/*' }

-- Editor
vim.opt.colorcolumn = { config.options.column_limit }
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
vim.opt.signcolumn = 'yes'
vim.opt.termguicolors = true
vim.opt.laststatus = 3
vim.opt.fillchars:append { eob = ' ' }

-- =============================================================================
-- Keymaps
--
-- Add your custom keymaps with `vim.keymap.set()`. Example, Use jk to go from
-- insert to normal mode:
--
-- vim.keymap.set('i', 'jk', '<Esc>')
--
-- Tags: KEY, KEYS, KEYMAPS
-- =============================================================================

vim.g.mapleader = config.keymap.leader

-- Unbind default bindings for arrow keys, trust me this is for your own good
vim.keymap.set('', '<Up>', '')
vim.keymap.set('', '<Down>', '')
vim.keymap.set('', '<Left>', '')
vim.keymap.set('', '<Right>', '')
vim.keymap.set('i', '<Up>', '')
vim.keymap.set('i', '<Down>', '')
vim.keymap.set('i', '<Left>', '')
vim.keymap.set('i', '<Right>', '')

-- Resize window panes, we can use those arrow keys
-- to help use resize windows - at least we give them some purpose
vim.keymap.set('n', '<Up>', '<Cmd>resize +2<CR>')
vim.keymap.set('n', '<Down>', '<Cmd>resize -2<CR>')
vim.keymap.set('n', '<Left>', '<Cmd>vertical resize -2<CR>')
vim.keymap.set('n', '<Right>', '<Cmd>vertical resize +2<CR>')

-- Map Esc, to perform quick switching between Normal and Insert mode
vim.keymap.set('i', 'jk', '<Esc>')

-- Map escape from terminal input to Normal mode
vim.keymap.set('t', '<Esc>', [[<C-\><C-n>]])
vim.keymap.set('t', '<C-[>', [[<C-\><C-n>]])

-- Disable highlights
vim.keymap.set('n', '<Leader><CR>', '<Cmd>noh<CR>', { desc = 'Disable search highlight' })

-- List all buffers
vim.keymap.set('n', '<Leader>bl', '<Cmd>buffers<CR>', { desc = 'Show buffers' })

-- Go to next buffer
vim.keymap.set('n', '<C-l>', '<Cmd>bnext<CR>', { desc = 'Next buffer' })
vim.keymap.set('n', '<Leader>bn', '<Cmd>bnext<CR>', { desc = 'Next buffer' })

-- Go to previous buffer
vim.keymap.set('n', '<C-h>', '<Cmd>bprevious<CR>', { desc = 'Previous buffer' })
vim.keymap.set('n', '<Leader>bp', '<Cmd>bprevious<CR>', { desc = 'Previous buffer' })

-- Close the current buffer, and more?
vim.keymap.set('n', '<Leader>bd', '<Cmd>bp<Bar>sp<Bar>bn<Bar>bd<CR>', { desc = 'Close current buffer' })

-- Close all buffer, except current
vim.keymap.set('n', '<Leader>bx', '<Cmd>%bd<Bar>e#<Bar>bd#<CR>', { desc = 'Close all buffers except current' })

-- Edit vimrc
vim.keymap.set('n', '<Leader>ve', '<Cmd>edit $MYVIMRC<CR>', { desc = 'Open init.lua' })

-- Source the vimrc to reflect changes
vim.keymap.set('n', '<Leader>vs', '<Cmd>ConfigReload<CR>', { desc = 'Reload init.lua' })

-- Reload file
vim.keymap.set('n', '<Leader>r', '<Cmd>edit!<CR>', { desc = 'Reload current buffer with the file' })

-- Copy/Paste from sytem clipboard
vim.keymap.set('v', 'p', [["_dP]], { desc = 'Paste from yanked contents only' })
vim.keymap.set('v', '<Leader>y', [["+y]], { desc = 'Yank from system clipboard' })
vim.keymap.set('n', '<Leader>y', [["+y]], { desc = 'Yank from system clipboard' })
vim.keymap.set('n', '<Leader>p', [["+p]], { desc = 'Paste from system clipboard' })

-- =============================================================================
-- User Commands
--
-- You custom user commands with `vim.api.nvim_create_user_command()`, you can
-- set any commands you like or even abbreviations (which gets quite helpful
-- when making mistakes).
--
-- Tags: CMD, CMDS, COMMANDS
-- =============================================================================

vim.api.nvim_create_user_command('Config', 'edit $MYVIMRC', { desc = 'Open config' })
vim.api.nvim_create_user_command('ConfigReload', reload_config, { desc = 'Reload config' })

-- Command Abbreviations, I can't release my shift key fast enough :')
vim.cmd 'cnoreabbrev Q  q'
vim.cmd 'cnoreabbrev Qa qa'
vim.cmd 'cnoreabbrev W  w'
vim.cmd 'cnoreabbrev Wq wq'

-- ============================================================================
-- Plugins
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
--         Example, for `windwp/nvim-autopairs` you need to run the installer
--         so call with:
--             use({
--                 "windwp/nvim-autopairs",
--             	   commit = "6b6e35fc9aca1030a74cc022220bc22ea6c5daf4",
--             	   config = function()
--                     require("nvim-autopairs").setup({})
--             	   end,
--             })
--
-- Tags: PLUG, PLUGS, PLUGINS
-- ============================================================================

local packer_bootstrap = ensure_packer()
local packer = require 'packer'

packer.init {
	compile_path = string.format('%s/site/plugin/packer_compiled.lua', vim.fn.stdpath 'data'),
}

packer.startup(function(use)
	use { 'wbthomason/packer.nvim', commit = '6afb67460283f0e990d35d229fd38fdc04063e0a' }

	-- Add your list of plugins below
	-- ---

	use {
		'folke/which-key.nvim',
		commit = '61553aeb3d5ca8c11eea8be6eadf478062982ac9',
		config = function()
			require('which-key').setup {
				triggers = { '<Leader>' },
				window = {
					border = 'rounded',
				},
			}
		end,
	}

	use {
		'editorconfig/editorconfig-vim',
		commit = '30ddc057f71287c3ac2beca876e7ae6d5abe26a0',
	}

	use {
		'mattn/emmet-vim',
		commit = 'def5d57a1ae5afb1b96ebe83c4652d1c03640f4d',
		config = function()
			vim.g.user_emmet_leader_key = '<C-q>'
		end,
	}

	use {
		'kylechui/nvim-surround',
		tag = 'v1.0.0',
		config = function()
			require('nvim-surround').setup {}
		end,
	}

	use {
		'windwp/nvim-autopairs',
		commit = '6b6e35fc9aca1030a74cc022220bc22ea6c5daf4',
		config = function()
			require('nvim-autopairs').setup {}
		end,
	}

	use {
		'numToStr/Comment.nvim',
		commit = 'ad7ffa8ed2279f1c8a90212c7d3851f9b783a3d6',
		config = function()
			require('Comment').setup()
		end,
	}

	-- File explorer
	use {
		'nvim-neo-tree/neo-tree.nvim',
		branch = 'v2.x',
		requires = {
			{ 'nvim-lua/plenary.nvim', commit = '4b7e52044bbb84242158d977a50c4cbcd85070c7' },
			{ 'nvim-tree/nvim-web-devicons', commit = '9061e2d355ecaa2b588b71a35e7a11358a7e51e1' }, -- not strictly required, but recommended
			{ 'MunifTanjim/nui.nvim', commit = 'd12a6977846b2fa978bff89b439e509320854e10' },
		},
		config = function()
			-- If you want icons for diagnostic errors, you'll need to define them somewhere:
			vim.fn.sign_define('DiagnosticSignError', { text = ' ', texthl = 'DiagnosticSignError' })
			vim.fn.sign_define('DiagnosticSignWarn', { text = ' ', texthl = 'DiagnosticSignWarn' })
			vim.fn.sign_define('DiagnosticSignInfo', { text = ' ', texthl = 'DiagnosticSignInfo' })
			vim.fn.sign_define('DiagnosticSignHint', { text = '', texthl = 'DiagnosticSignHint' })

			require('neo-tree').setup {
				close_if_last_window = true,
			}

			vim.keymap.set(
				'n',
				'<Leader>ff',
				'<Cmd>Neotree reveal toggle right<CR>',
				{ desc = 'Toggle file tree (neo-tree)' }
			)
		end,
	}

	-- File finder
	use {
		'nvim-telescope/telescope.nvim',
		tag = '0.1.0',
		requires = { 'nvim-lua/plenary.nvim', commit = '4b7e52044bbb84242158d977a50c4cbcd85070c7' },
		config = function()
			local t_builtin = require 'telescope.builtin'

			vim.keymap.set('n', '<C-p>', function()
				t_builtin.find_files()
			end, {
				desc = 'Open file finder (telescope)',
			})

			vim.keymap.set('n', '<C-t>', function()
				t_builtin.live_grep()
			end, { desc = 'Open text search (telescope)' })
		end,
	}

	-- LSP + Tools + Debug + Auto-completion
	use {
		'neovim/nvim-lspconfig',
		commit = '2b802ab1e94d595ca5cc7c55f9d1fb9b17f9754c',
		requires = {
			-- Linter/Formatter
			{ 'jose-elias-alvarez/null-ls.nvim', commit = '07d4ed4c6b561914aafd787453a685598bec510f' },
			-- Tool installer
			{ 'williamboman/mason.nvim', commit = 'd85d71e910d1b2c539d17ae0d47dad48f8f3c8a7' },
			{ 'williamboman/mason-lspconfig.nvim', commit = 'a910b4d50f7a32d2f9057d636418a16843094b7c' },
			{ 'WhoIsSethDaniel/mason-tool-installer.nvim', commit = '27f61f75a71bb3c2504a17e02b571f79cae43676' },
			-- UI/Aesthetics
			{ 'glepnir/lspsaga.nvim', commit = '201dbbd13d6bafe1144475bbcae9efde224e07ec' },
			{ 'j-hui/fidget.nvim', commit = '2cf9997d3bde2323a1a0934826ec553423005a26' },
		},
	}

	use {
		'hrsh7th/nvim-cmp',
		commit = 'aee40113c2ba3ab158955f233ca083ca9958d6f8',
		requires = {
			-- Cmdline completions
			{ 'hrsh7th/cmp-cmdline', commit = '8bc9c4a34b223888b7ffbe45c4fe39a7bee5b74d' },
			-- Path completions
			{ 'hrsh7th/cmp-path', commit = '91ff86cd9c29299a64f968ebb45846c485725f23' },
			-- Buffer completions
			{ 'hrsh7th/cmp-buffer', commit = '3022dbc9166796b644a841a02de8dd1cc1d311fa' },
			-- LSP completions
			{ 'hrsh7th/cmp-nvim-lsp', commit = '78924d1d677b29b3d1fe429864185341724ee5a2' },
			{ 'onsails/lspkind-nvim', commit = 'c68b3a003483cf382428a43035079f78474cd11e' },
			-- vnsip completions
			{ 'hrsh7th/cmp-vsnip', commit = '1ae05c6c867d9ad44bce811056e861e0d5c531cb' },
			{ 'hrsh7th/vim-vsnip', commit = 'ceeee48145d27f0b3986ab6f75f52a2449974603' },
			{ 'rafamadriz/friendly-snippets', commit = 'c93311fbcc840210a2c0db574177d84a35a2c9c1' },
		},
		config = function()
			local cmp = require 'cmp'

			vim.g.vsnip_filetypes = {
				javascriptreact = { 'javascript' },
				typescriptreact = { 'typescript' },
			}

			local function has_words_before()
				local line, col = unpack(vim.api.nvim_win_get_cursor(0))
				return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match '%s' == nil
			end

			local function feedkey(key, mode)
				vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, true, true), mode, true)
			end

			cmp.setup {
				snippet = {
					expand = function(args)
						vim.fn['vsnip#anonymous'](args.body)
					end,
				},

				mapping = {
					['<C-Space>'] = cmp.mapping.complete {},
					['<C-y>'] = cmp.mapping.confirm { select = true, behavior = cmp.ConfirmBehavior.Replace },
					['<CR>'] = cmp.mapping.confirm { select = true, behavior = cmp.ConfirmBehavior.Replace },
					['<Tab>'] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item()
						elseif vim.fn['vsnip#available'](1) == 1 then
							feedkey('<Plug>(vsnip-expand-or-jump)', '')
						elseif has_words_before() then
							cmp.complete()
						else
							fallback() -- The fallback function sends a already mapped key. In this case, it's probably `<Tab>`.
						end
					end, { 'i', 's' }),

					['<C-n>'] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item()
						elseif vim.fn['vsnip#available'](1) == 1 then
							feedkey('<Plug>(vsnip-expand-or-jump)', '')
						elseif has_words_before() then
							cmp.complete()
						else
							fallback() -- The fallback function sends a already mapped key. In this case, it's probably `<Tab>`.
						end
					end, { 'i', 's' }),

					['<S-Tab>'] = cmp.mapping(function()
						if cmp.visible() then
							cmp.select_prev_item()
						elseif vim.fn['vsnip#jumpable'](-1) == 1 then
							feedkey('<Plug>(vsnip-jump-prev)', '')
						end
					end, { 'i', 's' }),

					['<C-p>'] = cmp.mapping(function()
						if cmp.visible() then
							cmp.select_prev_item()
						elseif vim.fn['vsnip#jumpable'](-1) == 1 then
							feedkey('<Plug>(vsnip-jump-prev)', '')
						end
					end, { 'i', 's' }),
				},

				sources = cmp.config.sources({
					{ name = 'nvim_lsp' },
					{ name = 'vsnip' }, -- For vsnip users.
				}, {
					{ name = 'buffer' },
					{ name = 'path' },
				}),

				window = {
					-- completion = cmp.config.window.bordered(),
					documentation = cmp.config.window.bordered 'rounded',
				},

				formatting = {
					format = require('lspkind').cmp_format {
						mode = 'symbol_text',
						menu = {
							buffer = '[BUF]',
							nvim_lsp = '[LSP]',
							vsnip = '[SNIP]',
							path = '[PATH]',
						},
					},
				},
			}

			-- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
			cmp.setup.cmdline({ '/', '?' }, {
				mapping = cmp.mapping.preset.cmdline(),
				sources = {
					{ name = 'buffer' },
				},
			})

			-- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
			cmp.setup.cmdline(':', {
				mapping = cmp.mapping.preset.cmdline(),
				sources = cmp.config.sources({
					{ name = 'path' },
				}, {
					{ name = 'cmdline' },
				}),
			})
		end,
	}

	-- Treesitter
	use {
		'nvim-treesitter/nvim-treesitter',
		commit = '2072692aaa4b6da7c354e66c2caf4b0a8f736858',
		-- We make treesitter extenstions optional so we can ensure it's loaded properly
		-- before we call treesitter setup in `config` below using packadd
		requires = {
			{
				'nvim-treesitter/nvim-treesitter-textobjects',
				commit = '1f1cdc892b9b2f96afb1bddcb49ac1a12b899796',
				opt = true,
			},
			{
				'nvim-treesitter/nvim-treesitter-context',
				commit = '0dd5eae6dbf226107da2c2041ffbb695d9e267c1',
				opt = true,
			},
		},
		run = function()
			require('nvim-treesitter.install').update { with_sync = true }
		end,
		config = function()
			vim.cmd 'packadd nvim-treesitter-textobjects'

			require('nvim-treesitter.configs').setup {
				ensure_installed = {
					'graphql',
					'javascript',
					'json',
					'lua',
					'help',
					'prisma',
					'tsx',
					'typescript',
				},
				highlight = { enable = true },
				textobjects = {
					select = { enable = true },
				},
			}
		end,
	}

	-- UI
	use {
		'nvim-lualine/lualine.nvim',
		commit = '3325d5d43a7a2bc9baeef2b7e58e1d915278beaf',
		requires = {
			{ 'nvim-tree/nvim-web-devicons', commit = '9061e2d355ecaa2b588b71a35e7a11358a7e51e1' },
		},
		config = function()
			local function attached_lsp_clients()
				local clients = vim.lsp.get_active_clients()

				if vim.tbl_isempty(clients) then
					return ''
				end

				-- We only want unique names from attached clients
				local unique_client_names = {}
				for _, client in pairs(clients) do
					local name = ' ' .. client.name
					if name == 'null-ls' then
						name = ' ' .. client.name
					end

					unique_client_names[name] = true
				end

				return table.concat(vim.tbl_keys(unique_client_names), ', ')
			end

			require('lualine').setup {
				options = {
					component_separators = { left = '', right = '' },
					section_separators = { left = '', right = '' },
				},
				sections = {
					lualine_a = {
						{ 'mode', separator = { left = '' }, right_padding = 2 },
					},
					lualine_b = { 'filename', { 'branch', icon = '' } },
					lualine_c = { 'diff' },
					lualine_x = {},
					lualine_y = {
						'filetype',
						{
							'diagnostics',
							sources = { 'nvim_diagnostic' },
							sections = { 'error', 'warn' },
						},
					},
					lualine_z = { { attached_lsp_clients, separator = { right = '' }, left_padding = 2 } },
				},
				inactive_sections = {
					lualine_a = { 'filename' },
					lualine_b = {},
					lualine_c = {},
					lualine_x = {},
					lualine_y = {},
					lualine_z = { 'location' },
				},
				tabline = {},
				extensions = {},
			}
		end,
	}

	use {
		'akinsho/bufferline.nvim',
		tag = 'v3.*',
		requires = {
			{ 'nvim-tree/nvim-web-devicons', commit = '9061e2d355ecaa2b588b71a35e7a11358a7e51e1' },
		},
		config = function()
			require('bufferline').setup {}
		end,
	}

	use {
		'lukas-reineke/indent-blankline.nvim',
		commit = 'db7cbcb40cc00fc5d6074d7569fb37197705e7f6',
		config = function()
			vim.g.indent_blankline_show_first_indent_level = false
		end,
	}

	use {
		'folke/todo-comments.nvim',
		commit = '530eb3a896e9eef270f00f4baafa102361afc93b',
		requires = { 'nvim-lua/plenary.nvim', commit = '4b7e52044bbb84242158d977a50c4cbcd85070c7' },
		config = function()
			require('todo-comments').setup {}
		end,
	}

	use {
		'lewis6991/gitsigns.nvim',
		branch = 'release',
		config = function()
			require('gitsigns').setup()
		end,
	}

	-- Themes
	use 'bluz71/vim-moonfly-colors'
	use 'w3barsi/barstrata.nvim'
	use 'LunarVim/darkplus.nvim'
	use 'projekt0n/github-nvim-theme'
	use 'navarasu/onedark.nvim'
	use 'folke/tokyonight.nvim'
	use { 'rose-pine/neovim', as = 'rose-pine' }
	use { 'catppuccin/nvim', as = 'catppuccin' }

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
-- LSP Configuration
--
-- LSP Server configurations goes here. This is also where you should add any
-- logic that concerns the builtin LSP client.
--
-- For example:
--  + You need LSP servers installed? Add mason config here
--  + You need to add some UI/change look of your LSP/Statusline/Tabline/Winbar
--    etc but is tightly integrated with LSP? Add them here
--
-- Tags: LSPCONFIG
-- ============================================================================

-- fidget.nvim Config
-- ---
require('fidget').setup {}

-- LSP Saga Config
-- ---
require('lspsaga').init_lsp_saga { border_style = 'rounded' }

-- mason.nvim Config
-- ---
require('mason').setup()
require('mason-tool-installer').setup {
	ensure_installed = config.lsp.tools,
	automatic_installation = true,
}
require('mason-lspconfig').setup {
	ensure_installed = config.lsp.servers,
	automatic_installation = true,
}

-- nvim-lspconfig Config
-- ---
local lspconfig = require 'lspconfig'

local float_opts = {
	border = 'rounded',
	width = 80,
}

-- Global diagnostic config
vim.diagnostic.config {
	update_in_insert = false,
	float = {
		source = true,
		border = float_opts.border,
		width = float_opts.width,
	},
}

-- Window options
require('lspconfig.ui.windows').default_options.border = float_opts.border

-- Hover options
vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(vim.lsp.handlers.hover, float_opts)

-- Signature help options
vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(vim.lsp.handlers.signature_help, {
	border = float_opts.border,
})

local capabilities = require('cmp_nvim_lsp').default_capabilities()

local function on_attach(client, bufnr)
	-- Omnifunc backup
	vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

	-- LSP Keymaps
	vim.keymap.set('n', '<Leader>la', '<Cmd>Lspsaga code_action<CR>', { desc = 'LSP Code Actions', buffer = bufnr })
	vim.keymap.set('n', '<Leader>ld', vim.lsp.buf.definition, { desc = 'LSP Go-to Definition', buffer = bufnr })
	vim.keymap.set('n', '<Leader>lh', '<Cmd>Lspsaga hover_doc<CR>', { desc = 'LSP Hover Information', buffer = bufnr })
	vim.keymap.set('n', '<Leader>lr', '<Cmd>Lspsaga rename<CR>', { desc = 'LSP Rename', buffer = bufnr })
	vim.keymap.set('n', '<Leader>ls', vim.lsp.buf.signature_help, { desc = 'LSP Signature Help', buffer = bufnr })
	vim.keymap.set('n', '<Leader>le', vim.diagnostic.setloclist, { desc = 'LSP Show All Diagnostics', buffer = bufnr })
	vim.keymap.set('n', '<Leader>lw', function()
		vim.diagnostic.open_float { bufnr = bufnr, scope = 'line' }
	end, { desc = 'Show LSP Line Diagnostic', buffer = bufnr })

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
		register_lsp_fmt_keymap('<Leader>lf', client.name, bufnr)

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
local lua_rtp = vim.split(package.path, ';')
table.insert(lua_rtp, 'lua/?.lua')
table.insert(lua_rtp, 'lua/?/init.lua')
lspconfig.sumneko_lua.setup(vim.tbl_extend('force', lspconfig_setup_defaults, {
	settings = {
		Lua = {
			runtime = {
				version = 'LuaJIT',
				path = lua_rtp,
			},
			diagnostics = { globals = { 'vim' } },
			workspace = {
				library = vim.api.nvim_get_runtime_file('', true),
				checkThirdParty = false,
			},
			telemetry = { enable = false },
		},
	},
}))

-- Web Development
-- ---
-- We only want to attach to a node/frontend project with it matches
-- package.json, jsconfig.json or tsconfig.json file
local lspconfig_node_options = { root_dir = require('lspconfig.util').root_pattern { 'package.json' } }
lspconfig.tsserver.setup(vim.tbl_extend('force', lspconfig_setup_defaults, lspconfig_node_options))
lspconfig.graphql.setup(vim.tbl_extend('force', lspconfig_setup_defaults, lspconfig_node_options))
lspconfig.prismals.setup(vim.tbl_extend('force', lspconfig_setup_defaults, lspconfig_node_options))
lspconfig.volar.setup(vim.tbl_extend('force', lspconfig_setup_defaults, lspconfig_node_options, {
	init_options = {
		typescript = {
			tsdk = string.format('%s/node_modules/typescript/lib', vim.fn.getcwd()),
		},
	},
}))

-- We want to only attach to a deno project when it matches only
-- deno.json or deno.jsonc file
local lspconfig_deno_options = { root_dir = require('lspconfig.util').root_pattern { 'deno.json', 'deno.jsonc' } }
lspconfig.denols.setup(vim.tbl_extend('force', lspconfig_setup_defaults, lspconfig_deno_options))

-- Python
-- ---
lspconfig.pylsp.setup(lspconfig_setup_defaults)

-- Go
-- ---
lspconfig.gopls.setup(lspconfig_setup_defaults)

-- Null-ls Config
-- ---
local nls_node_options = {
	condition = function(utils)
		return utils.root_has_file { 'package.json', 'tsconfig.json', 'jsconfig.json' }
	end,
}

local nls = require 'null-ls'
nls.setup {
	sources = {
		-- We only want to have eslint and prettier to run when it matches_error
		-- a root file
		nls.builtins.diagnostics.eslint_d.with(nls_node_options),
		nls.builtins.formatting.prettier.with(nls_node_options),

		-- Custom stylua just for this init.lua file
		nls.builtins.formatting.stylua.with {
			extra_args = {
				'--column-width',
				config.options.column_limit,
				'--line-endings',
				'Unix',
				'--indent-width',
				'2',
				'--quote-style',
				'AutoPreferSingle',
				'--call-parentheses',
				'None',
			},
		},
	},
	on_attach = function(client, bufnr)
		register_lsp_fmt_keymap('<Leader>lf', client.name, bufnr)

		if config.lsp.fmt_on_save then
			register_lsp_fmt_autosave(client.name, bufnr)
		end
	end,
}

-- ============================================================================
-- Theme
--
-- Colorscheme and their configuration comes last.
--
-- If you want to change some highlights that is separate to the ones provided
-- by another colorscheme, then you will have to add these changes within the
-- ColorScheme autocmd.
--
-- Example, to change WinSeparator highlight:
--
--      vim.api.nvim_create_autocmd('ColorScheme', {
--      	group = config.autocmd.group,
--      	callback = function()
--      		vim.api.nvim_set_hl(0, 'WinSeparator', { bg = 'NONE', fg = '#eeeeee' })
--      	end,
--      })
--
--
-- NOTE: if a colorscheme already has a lua setup() that helps you change
-- highlights to your desired colors then use that instead of creating a
-- ColorScheme autocmd. Only use the autocmd route when it's not supported.
--
-- Tags: THEME, COLOR, COLORSCHEME
-- ============================================================================

pcall(function()
	-- Theme configuration goes in here
	-- ---

	-- Example:
	--
	require('catppuccin').setup {
		flavour = 'mocha',
		custom_highlights = {
			WinSeparator = { bg = 'NONE', fg = '#eeeeee' },
		},
	}

	vim.cmd 'colorscheme catppuccin'
end)
