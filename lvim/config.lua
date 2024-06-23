-- Read the docs: https://www.lunarvim.org/docs/configuration
-- Video Tutorials: https://www.youtube.com/watch?v=sFA9kX-Ud_c&list=PLhoH5vyxr6QqGu0i7tt_XoVK9v-KvZ3m6
-- Forum: https://www.reddit.com/r/lunarvim/
-- Discord: https://discord.com/invite/Xb9B4Ny

-- vim options
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.relativenumber = true

-- add your own keymapping
lvim.keys.normal_mode["<C-s>"] = ":w<cr>"
-- lvim.keys.normal_mode["<Tab>"] = ":BufferLineCycleNext<CR>"
-- lvim.keys.normal_mode["<S-Tab>"] = ":BufferLineCyclePrev<CR>"
lvim.keys.normal_mode["<S-l>"] = ":BufferLineCycleNext<CR>"
lvim.keys.normal_mode["<S-h>"] = ":BufferLineCyclePrev<CR>"

lvim.keys.normal_mode["<C-S>"] = ":w<CR>"
lvim.keys.normal_mode["<C-i>"] = false
lvim.keys.normal_mode["<C-o>"] = false

lvim.keys.insert_mode["<C-l>"] = "<End>"

-- Change theme settings
-- lvim.colorscheme = "catppuccin-mocha"
lvim.colorscheme = "catppuccin-macchiato"
-- lvim.colorscheme = "catppuccin-frappe"
-- lvim.colorscheme = "tokyonight"

lvim.builtin.nvimtree.setup.renderer.icons.show.git = false
lvim.lsp.installer.setup.automatic_installation = false


local formatters = require "lvim.lsp.null-ls.formatters"
formatters.setup {
  {
    command = "prettier",
    extra_args = { "--print-width", "100", "--trailing-comma", "es5" },
    filetypes = { "typescript", "typescriptreact", "vue", "javascript", "javascriptreact", "json", "html", "css" },
  },
}

-- -- Additional Plugins <https://www.lunarvim.org/docs/plugins#user-plugins>
lvim.plugins = {
  { "catppuccin/nvim", name = "catppuccin", priority = 1000 },
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("harpoon"):setup()
    end,

    keys = {
      { "<leader>ma", function() require("harpoon"):list():add() end,    desc = "add file to harpoon list", },
      { "<leader>mr", function() require("harpoon"):list():remove() end, desc = "remove file from harpoon list", },
      { "<leader>mR", function() require("harpoon"):list():clear() end,  desc = "clear harpoon list", },
      {
        "<C-e>",
        function()
          local harpoon = require("harpoon")
          harpoon.ui:toggle_quick_menu(harpoon:list())
        end,
        desc = "harpoon quick menu",
      },
      { "<leader>1", function() require("harpoon"):list():select(1) end, desc = "harpoon to file 1", },
      { "<leader>2", function() require("harpoon"):list():select(2) end, desc = "harpoon to file 2", },
      { "<leader>3", function() require("harpoon"):list():select(3) end, desc = "harpoon to file 3", },
      { "<leader>4", function() require("harpoon"):list():select(4) end, desc = "harpoon to file 4", },
      { "<leader>5", function() require("harpoon"):list():select(5) end, desc = "harpoon to file 5", },
    },
  },
  {
    "vhyrro/luarocks.nvim",
    priority = 1000,
    config = true,
    opts = {
      rocks = { "lua-curl", "nvim-nio", "mimetypes", "xml2lua" }
    }
  },
  {
    "rest-nvim/rest.nvim",
    ft = "http",
    dependencies = { "luarocks.nvim" },
    config = function()
      require("rest-nvim").setup()
    end,
  }
}

lvim.lsp.automatic_configuration.skipped_servers = vim.tbl_filter(function(server)
  return server ~= "sqlls"
end, lvim.lsp.automatic_configuration.skipped_servers)

require("lvim.lsp.manager").setup("sqlls", {
  cmd = { "sql-language-server", "up", "--method", "stdio" },
  filetypes = { "sql", "mysql" },
  root_dir = function() return vim.loop.cwd() end,
})

lvim.builtin.which_key.mappings["r"] = {
  name = "REST client",
  r = { "<cmd>Rest run<CR>", "Run REST under cursor" }
}

lvim.builtin.nvimtree.setup.view.side = "right"
lvim.transparent_window = true

vim.o.termguicolors = true
lvim.format_on_save = false

vim.opt.foldmethod = "expr"                     -- default is "normal"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()" -- default is ""
vim.opt.foldenable = false                      -- if this option is true and fold method option is other than normal, every time a document is opened everything will be folded.


if vim.g.neovide then
  vim.o.guifont = "JetBrainsMono NF:h13" -- text below applies for VimScript
  vim.g.neovide_cursor_animation_length = 0.03
end

-- auto-reload files when modified externally
-- https://unix.stackexchange.com/a/383044
vim.o.autoread = true
vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "CursorHoldI", "FocusGained" }, {
  command = "if mode() != 'c' | checktime | endif",
  pattern = { "*" },
})
