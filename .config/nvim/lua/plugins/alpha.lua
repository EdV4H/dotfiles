return {
  "goolord/alpha-nvim",
  config = function()
    local alpha = require("alpha")
    local dashboard = require("alpha.themes.dashboard")

    -- set header
    dashboard.section.header.val = {
      "       _____   __                        ",
      " /\\   /  _  \\_/  |_____________    ____  ",
      " \\/  /  /_\\  \\   __\\_  __ \\__  \\ _/ __ \\ ",
      " /\\ /    |    \\  |  |  | \\// __ \\\\  ___/ ",
      " \\/ \\____|__  /__|  |__|  (____  /\\___  >",
      "            \\/                 \\/     \\/ ",
      "                                         ",
    }

    alpha.setup(dashboard.opts)
    
    -- Disable folding on alpha buffer
    vim.cmd [[
      autocmd FileType alpha setlocal nofoldenable
    ]]
  end,
}
