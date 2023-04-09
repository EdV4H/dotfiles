local opts = { noremap = ture, silent = ture }
local term_ops = { silent = true }

-- local keymap = vim.keymap
local keymap = vim.api.nvim_set_keymap

-- Remap space as leader key
keymap("", "<Space>", "<Nop>", opts)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Modes
--  normal_mode = 'n'
--  insert_mode = 'i',
--  visual_mode = 'v',
--  visual_block_mode = 'x',
--  term_mode = 't',
--  command_mode = 'c',

-- Normal --

-- ';' alternate ':'
keymap("n", ";", ":", opts)

-- do not exit visual mode on indent
keymap("v", "<", "<gv", opts)
keymap("v", ">", ">gv", opts)

-- Split window
keymap("n", "ss", ":split<Return><C-w>w", opts)
keymap("n", "sv", ":vsplit<Return><C-w>w", opts)

-- window navigation
keymap("n", "sh", "<C-w>h", opts)
keymap("n", "sk", "<C-w>k", opts)
keymap("n", "sj", "<C-w>j", opts)
keymap("n", "sl", "<C-w>l", opts)

-- nohlsearch on ESC*2
keymap("n", "<ESC><ESC>", ":<C-u>set nohlsearch<Return>", opts)

-- Fern
keymap("n", "<C-n>", ":Fern . -reveal=% -drawer -toggle -width=40<Return>", opts)

-- Terminal --

-- escape from insert on <ESC>
keymap("t", "<ESC>", [[<C-\><C-n>]], opts)

