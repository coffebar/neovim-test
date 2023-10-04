local lazypath = "./lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

local lazy_installed, lazy = pcall(require, "lazy")
if not lazy_installed then
  return
end

lazy.setup({
  {
    "neovim/nvim-lspconfig",
    lazy = true,
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("lspconfig").rust_analyzer.setup({})
      require("lspconfig").lua_ls.setup({
        on_init = function(client)
          local path = client.workspace_folders[1].name
          if not vim.loop.fs_stat(path .. "/.luarc.json") and not vim.loop.fs_stat(path .. "/.luarc.jsonc") then
            client.config.settings = vim.tbl_deep_extend("force", client.config.settings, {
              Lua = {
                runtime = {
                  -- Tell the language server which version of Lua you're using
                  -- (most likely LuaJIT in the case of Neovim)
                  version = "LuaJIT",
                },
                -- Make the server aware of Neovim runtime files
                workspace = {
                  checkThirdParty = false,
                  library = {
                    vim.env.VIMRUNTIME,
                    -- "${3rd}/luv/library"
                    -- "${3rd}/busted/library",
                  },
                  -- or pull in all of 'runtimepath'. NOTE: this is a lot slower
                  -- library = vim.api.nvim_get_runtime_file("", true)
                },
                telemetry = {
                  enable = false,
                },
                hint = {
                  enable = true,
                },
              },
            })

            client.notify("workspace/didChangeConfiguration", { settings = client.config.settings })
          end
          return true
        end,
      })
    end,
  },
}, {
  defaults = { lazy = false, version = nil, cond = nil },
  install = { missing = true },
})

vim.api.nvim_command("silent !cargo check")

local i = 1000
while i < 2500 do
  vim.defer_fn(function()
    vim.api.nvim_command("edit src/main.rs | cd .. | edit lua.lua | %bd | cd neovim-test")
  end, i)
  vim.defer_fn(function()
    vim.api.nvim_command("edit lua.lua | LspStop rust_analyzer")
  end, i + 100)
  i = i + 500
end

vim.defer_fn(function()
  vim.api.nvim_command("cd src | edit main.rs")
end, 3000)

vim.defer_fn(function()
  vim.api.nvim_command("cd .. | %bd | edit lua.lua")
end, 3091)
