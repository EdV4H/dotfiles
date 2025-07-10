-- Basic keymaps

local keymap = vim.keymap

-- Swap ; and :
keymap.set({"n", "v"}, ";", ":", { desc = "Command mode" })
keymap.set({"n", "v"}, ":", ";", { desc = "Repeat last f/F/t/T" })

-- File explorer
keymap.set("n", "<leader>e", ":Telescope file_browser<CR>", { desc = "File browser" })

-- Telescope
keymap.set("n", "<leader>ff", ":Telescope find_files<CR>", { desc = "Find files" })
keymap.set("n", "<leader>fg", ":Telescope live_grep<CR>", { desc = "Live grep" })
keymap.set("n", "<leader>fb", ":Telescope buffers<CR>", { desc = "Find buffers" })
keymap.set("n", "<leader>fh", ":Telescope help_tags<CR>", { desc = "Help tags" })

-- Window navigation
keymap.set("n", "<C-h>", "<C-w>h", { desc = "Navigate left" })
keymap.set("n", "<C-j>", "<C-w>j", { desc = "Navigate down" })
keymap.set("n", "<C-k>", "<C-w>k", { desc = "Navigate up" })
keymap.set("n", "<C-l>", "<C-w>l", { desc = "Navigate right" })

-- Move lines
keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move line down" })
keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move line up" })

-- Keep cursor centered
keymap.set("n", "<C-d>", "<C-d>zz")
keymap.set("n", "<C-u>", "<C-u>zz")
keymap.set("n", "n", "nzzzv")
keymap.set("n", "N", "Nzzzv")

-- Lazygit
keymap.set("n", "<leader>lg", ":LazyGit<CR>", { desc = "Open LazyGit" })
keymap.set("n", "<leader>lgc", ":LazyGitConfig<CR>", { desc = "LazyGit Config" })
keymap.set("n", "<leader>lgf", ":LazyGitFilter<CR>", { desc = "LazyGit Filter" })
keymap.set("n", "<leader>lgb", ":LazyGitFilterCurrentFile<CR>", { desc = "LazyGit Current File" })

-- Theme switcher (using Telescope)
keymap.set("n", "<leader>th", ":Telescope colorscheme<CR>", { desc = "Switch theme" })