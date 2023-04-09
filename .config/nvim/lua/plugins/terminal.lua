return {
  "akinsho/toggleterm.nvim",
  version = "*",
  config = function()
    require("toggleterm").setup({
      open_mapping = [[tt]],
      insert_mappings = false,
      terminal_mappings = false,
    })

    -- lazygit
    local Terminal = require("toggleterm.terminal").Terminal
    local lazygit = Terminal:new({
      cmd = "lazygit",
      hidden = true,
      direction = "float",
      float_opts = {
        border = "curved",
        width = 120,
        height = 30,
      },
    })

    function _lazygit_toggle()
      lazygit:toggle()
    end

    vim.api.nvim_set_keymap("n", "<leader>lg", ":lua _lazygit_toggle()<CR>", { noremap = true, silent = true })
  end,
}
