local keymap = require('core.keymap')
local nmap, imap, cmap, vmap, xmap, tmap = keymap.nmap, keymap.imap, keymap.cmap, keymap.vmap, keymap.xmap, keymap.tmap
local silent, noremap = keymap.silent, keymap.noremap
local opts = keymap.new_opts
local cmd, cu = keymap.cmd, keymap.cu

-- Use space as leader key
vim.g.mapleader = ' '

-- leaderkey
nmap({ ' ', '', opts(noremap) })
xmap({ ' ', '', opts(noremap) })

-- base keymap

nmap({
  -- ';' swap ':'
  { ';', ':', opts(noremap) },
  { ':', ';', opts(noremap) },
  -- nohlsearch
  { '<leader>q', cu('set nohlsearch'), opts(noremap) },
  -- Split window
  { 'ss', cmd('split') .. '<C-w>w', opts(noremap) },
  { 'sv', cmd('vsplit') .. '<C-w>w', opts(noremap) },
  -- Window navigation
  { 'sh', '<C-w>h', opts(noremap) },
  { 'sk', '<C-w>k', opts(noremap) },
  { 'sj', '<C-w>j', opts(noremap) },
  { 'sl', '<C-w>l', opts(noremap) },
  -- Unify Y with D or C
  { 'Y', 'y$', opts(noremap) },
  -- Automatically move to the end of pasted text
  { 'p', 'p`]', opts(noremap, silent) },
})

vmap({
  -- Do not exit visual mode on indent
  { '<', '<gv', opts(noremap) },
  { '>', '>gv', opts(noremap) },
  -- Automatically move to the end of pasted text
  { 'y', 'y`]', opts(noremap, silent) },
  { 'p', 'p`]', opts(noremap, silent) },
})

tmap(
  -- Escape from insert on <C-q>
  { '<C-q>', [[<C-\><C-n>]], opts(noremap, silent) }
)

-- folke/lazy.nvim

nmap({
  { '<leader>pi', cmd('Lazy install'), opts(noremap, silent) },
  { '<leader>pu', cmd('Lazy update'), opts(noremap, silent) },
})

-- akinsho/bufferline.nvim

nmap({
  { '<leader>bc', cmd('bd'), opts(noremap) },
  { '<leader>bpc', cmd('BufferLinePickClose'), opts(noremap) },
  { '<leader>bC', cmd('BufferLineCloseOthers'), opts(noremap) },
  { '<S-l>', cmd('BufferLineCycleNext'), opts(noremap) },
  { '<S-h>', cmd('BufferLineCyclePrev'), opts(noremap) },
  { '<leader>bsd', cmd('BufferLineSortByDirectory'), opts(noremap) },
})

-- nvim-telescope/telescope.nvim

local builtin = require('telescope.builtin')

nmap({
  { '<leader>ff', builtin.find_files, opts(noremap) },
  { '<leader>fg', builtin.live_grep, opts(noremap) },
  { '<leader>fb', builtin.buffers, opts(noremap) },
  { '<leader>fh', builtin.help_tags, opts(noremap) },
  -- file browser extension
  { '<leader>e', cmd('Telescope file_browser path=%:p:h select_buffer=true'), opts(noremap) },
})

-- buitin lsp and Lspsaga keymap is in modules/lsp/config.lua
-- TODO: define buffer option for keymap util and migrate keymap options
