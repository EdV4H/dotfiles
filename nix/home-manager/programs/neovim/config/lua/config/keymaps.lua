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
keymap.set("n", "<leader>fh", ":Telescope help_tags<CR>", { desc = "Help tags" })

-- Buffer management
keymap.set("n", "<leader>bb", ":Telescope buffers<CR>", { desc = "List buffers" })
keymap.set("n", "<leader>bd", ":bdelete<CR>", { desc = "Delete buffer" })
keymap.set("n", "<leader>bn", ":bnext<CR>", { desc = "Next buffer" })
keymap.set("n", "<leader>bp", ":bprevious<CR>", { desc = "Previous buffer" })
keymap.set("n", "<leader>bD", ":bufdo bd<CR>", { desc = "Delete all buffers" })
keymap.set("n", "]b", ":bnext<CR>", { desc = "Next buffer" })
keymap.set("n", "[b", ":bprevious<CR>", { desc = "Previous buffer" })

-- Window splits and navigation
keymap.set("n", "ss", ":split<CR><C-w>w", { desc = "Split horizontal" })
keymap.set("n", "sv", ":vsplit<CR><C-w>w", { desc = "Split vertical" })
keymap.set("n", "sh", "<C-w>h", { desc = "Navigate left" })
keymap.set("n", "sk", "<C-w>k", { desc = "Navigate up" })
keymap.set("n", "sj", "<C-w>j", { desc = "Navigate down" })
keymap.set("n", "sl", "<C-w>l", { desc = "Navigate right" })
keymap.set("n", "se", "<C-w>=", { desc = "Equal splits" })
keymap.set("n", "sx", ":close<CR>", { desc = "Close split" })

-- Window resize
keymap.set("n", "<C-Up>", ":resize +2<CR>", { desc = "Increase height" })
keymap.set("n", "<C-Down>", ":resize -2<CR>", { desc = "Decrease height" })
keymap.set("n", "<C-Left>", ":vertical resize -2<CR>", { desc = "Decrease width" })
keymap.set("n", "<C-Right>", ":vertical resize +2<CR>", { desc = "Increase width" })

-- Keep Ctrl+hjkl for navigation (alternative)
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

-- Claude Code
keymap.set("n", "<leader>cc", ":ClaudeCode<CR>", { desc = "Toggle Claude Code" })
keymap.set("n", "<leader>ccc", ":ClaudeCodeContinue<CR>", { desc = "Claude Code Continue" })
keymap.set("n", "<leader>ccr", ":ClaudeCodeReview<CR>", { desc = "Claude Code Review" })