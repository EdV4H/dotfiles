local uv, api, fn = vim.loop, vim.api, vim.fn

local pkg = {}
pkg.__index = pkg

function pkg:load_modules_packages()
  local modules_dir = self.helper.path_join(self.config_path, 'lua', 'modules')
  self.repos = {}

  local list = vim.fs.find('package.lua', { path = modules_dir, type = 'file', limit = 10 })
  if #list == 0 then
    return
  end

  local disable_modules = {}

  if fn.exists('g:disable_modules') == 1 then
    disable_modules = vim.split(vim.g.disable_modules, ',', { trimempty = true })
  end

  for _, f in pairs(list) do
    local _, pos = f:find(modules_dir)
    f = f:sub(pos - 6, #f - 4)
    if not vim.tbl_contains(disable_modules, f) then
      require(f)
    end
  end
end

function pkg:boot_strap_manual()
  self.helper = require('core.helper')
  self.data_path = self.helper.data_path()
  self.config_path = self.helper.config_path()
  local lazy_path = self.helper.path_join(self.data_path, 'lazy', 'lazy.nvim')
  local state = uv.fs_stat(lazy_path)
  if not state then
    local cmd = '!git clone https://github.com/folke/lazy.nvim ' .. lazy_path
    api.nvim_command(cmd)
  end
  vim.opt.rtp:prepend(lazy_path) -- rtp = runtimepath
  local lazy = require('lazy')
  local opts = {
    lockfile = self.helper.path_join(self.data_path, 'lazy-lock.json'),
  }
  self:load_modules_packages()
  lazy.setup(self.repos, opts)

  for k, v in pairs(self) do
    if type(v) ~= 'function' then
      self[k] = nil
    end
  end
end

function pkg.package(repo)
  if not pkg.repos then
    pkg.repos = {}
  end
  table.insert(pkg.repos, repo)
end

function pkg:boot_strap()
  self.helper = require('core.helper')
  self.data_path = self.helper.data_path()
  local lazy_path = self.helper.path_join(self.data_path, 'lazy', 'lazy.nvim')
  if not uv.fs_stat(lazy_path) then
    vim.fn.system({
      "git",
      "clone",
      "--filter=blob:none",
      "https://github.com/folke/lazy.nvim.git",
      "--branch=stable", -- latest stable release
      lazypath,
    })
  end
  vim.opt.rtp:prepend(lazy_path)
  local lazy = require('lazy')
  local opts = {
    lockfile = self.helper.path_join(self.data_path, 'lazy-lock.json'),
    lazy = true,
  }
  lazy.setup('modules', opts)
end

return pkg
