return {
  "neoclide/coc.nvim",
  branch = "release",
  config = function()
    -- Keymap
    -- @reference at github.com/neoclide/coc.nvim/README.md
    local opts = { noremap = true, silent = true }
    local keymap = vim.api.nvim_set_keymap

    -- Use K to show documentation in preview window
    function _G.show_docs()
        local cw = vim.fn.expand('<cword>')
        if vim.fn.index({'vim', 'help'}, vim.bo.filetype) >= 0 then
            vim.api.nvim_command('h ' .. cw)
        elseif vim.api.nvim_eval('coc#rpc#ready()') then
            vim.fn.CocActionAsync('doHover')
        else
            vim.api.nvim_command('!' .. vim.o.keywordprg .. ' ' .. cw)
        end
    end
    keymap("n", "K", '<CMD>lua _G.show_docs()<CR>', opts)

    -- Apply codeAction to the selected region
    local opts = { silent = true, nowait = true }
    keymap("x", "<leader>a", "<Plug>(coc-codeaction-selected)", opts)
    keymap("n", "<leader>a", "<Plug>(coc-codeaction-selected)", opts)

    -- Remap keys for applying codeAction at the cursor position
    keymap("n", "<leader>ac", "<Plug>(coc-codeaction-cursor)", opts)
    -- Remap keys for applying codeAction after whole buffer
    keymap("n", "<leader>as", "<Plug>(coc-codeaction-source)", opts)
    -- Remap keys for applying codeAction to the current buffer
    keymap("n", "<leader>ab", "<Plug>(coc-codeaction)", opts)
    -- Apply the most preferred quickfix action on the current line
    keymap("n", "<leader>qf", "<Plug>(coc-fix-current)", opts)
  end,
}

