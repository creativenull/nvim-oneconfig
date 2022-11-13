-- ============================================================================
-- Your custom user config variables (search: USER, CONFIG)
--
-- This is your custom user config, use this to add variables that you might
-- use in different plugins. Note, this is just an example on how I would
-- structure it, it's up to you to adjust it to your liking.
-- ============================================================================

local config = {}

-- Requirement check
if vim.fn.has 'nvim-0.8' == 0 then
	print 'Neovim >= v0.8 is required for this config'
	return
end

-- ============================================================================
-- Events (search: EVENTS, AUG, AUGROUP, AUTOCMD, AUTO)
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
-- Events (search: EVENTS, AUG, AUGROUP, AUTOCMD, AUTO)
--
-- Add your specific events/autocmds in here, but you are free to add then
-- anywhere you like.
-- ============================================================================

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

vim.filetype.add {}

-- ============================================================================
-- Vim Options (search: OPT, OPTS, OPTIONS)
--
-- Add your custom vim options with `vim.opt`. Example, show number line and
-- sign column:
--
-- vim.opt.number = true
-- vim.opt.signcolumn = 'yes'
-- ============================================================================

-- =============================================================================
-- Keymaps (search: KEYS, KEY, KEYMAPS)
--
-- Add your custom keymaps with `vim.keymap.set()`. Example, Use jk to go from
-- insert to normal mode:
--
-- vim.keymap.set('i', 'jk', '<Esc>')
-- =============================================================================

-- =============================================================================
-- User Commands (search: CMD, CMDS, COMMANDS)
--
-- You custom user commands with `vim.api.nvim_create_user_command()`, you can
-- set any commands you like or even abbreviations (which gets quite helpful
-- when making mistakes).
-- =============================================================================

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
--         Example, for `windwp/nvim-autopairs` you need to run the installer
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
local packer = require 'packer'

packer.init {
	compile_path = string.format('%s/site/plugin/packer_compiled.lua', vim.fn.stdpath 'data'),
}

packer.startup(function(use)
	use 'wbthomason/packer.nvim'

	-- Add your plugins inside this function
	-- ---

	-- Example:
	--
	-- use {
	-- 	'folke/which-key.nvim',
	-- 	commit = '61553aeb3d5ca8c11eea8be6eadf478062982ac9',
	-- 	config = function()
	-- 		require('which-key').setup {
	-- 			triggers = { '<Leader>' },
	-- 			window = {
	-- 				border = 'rounded',
	-- 			},
	-- 		}
	-- 	end,

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
--
-- For example:
--  + You need LSP servers installed? Add mason config here
--  + You need to add some UI/change look of your LSP/Statusline/Tabline/Winbar
--    etc but is tightly integrated with LSP? Add them here
-- ============================================================================

-- ============================================================================
-- Theme (search: THEME, COLOR, COLORSCHEME)
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
-- ============================================================================

-- pcall(vim.cmd, 'colorscheme catppuccin')
