vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.fillchars = { eob = " " }
vim.opt.cursorline = true

vim.opt.fileencoding = "utf-8"
vim.opt.clipboard = "unnamedplus"


vim.opt.confirm = true
vim.opt.swapfile = false
-- vim.opt.cmdheight = 0
vim.opt.showcmd = false

vim.opt.updatetime = 100
vim.opt.ttimeoutlen = 1

vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.wrap = false
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.signcolumn = "yes"
vim.opt.foldenable = false

vim.g.mapleader = " "
vim.keymap.set('n', '<leader>o', ":update<CR> :source<CR>")
vim.keymap.set('n', '<leader>w', ":write<CR>")
vim.keymap.set('n', '<leader>q', ":quit<CR>")
vim.keymap.set('n', '<leader>r', ":restart<CR>")
vim.keymap.set('n', '<leader><leader>', ":Pick files<CR>")
vim.keymap.set('n', '<leader>d', ":Oil<CR>")
vim.keymap.set('n', 'zz', ":wq<CR>")

vim.keymap.set('n', 'bn', ":bnext<CR>")
vim.keymap.set('n', 'bp', ":bprevious<CR>")
vim.keymap.set('n', 'bd', ":bdelete<CR>")


vim.diagnostic.config({
    underline = false,
    severity_sort = true,
    update_in_insert = false,
    float = { source = "if_many" },
    jump = { float = true },
})

vim.keymap.set('n', '<leader>l', vim.diagnostic.open_float)


local gh = function (x)
    return "https://github.com/" .. x
end

local cb = function (x)
    return "https://codeberg.org/" .. x
end

vim.pack.add({
    { src = gh("neovim/nvim-lspconfig") },
    { src = gh("vossenwout/guts.nvim")},
    { src = gh("wtfox/luna.nvim")},
    { src = gh("mason-org/mason.nvim") },
    { src = gh("nvim-treesitter/nvim-treesitter") },
    { src = gh("nvim-tree/nvim-web-devicons") },
    { src = gh("nvim-lualine/lualine.nvim") },
    { src = gh("nvim-mini/mini.pick") },
    { src = gh("stevearc/oil.nvim") },
    { src = gh("saghen/blink.lib") },
    { src = gh("saghen/blink.cmp") },
    { src = gh("sudoscrawl/midnight.nvim") },
    { src = gh("MeanderingProgrammer/render-markdown.nvim")},
    { src = gh("akinsho/bufferline.nvim")},
    { src = gh("lewis6991/gitsigns.nvim")},
    { src = gh("ajbucci/ipynb.nvim")},
})


require("mini.pick").setup()
require("oil").setup()
require("mason").setup()
-- require("noice").setup()
require("render-markdown").setup({})
require("bufferline").setup()
require("gitsigns").setup()
require("ipynb").setup()

vim.lsp.enable({ "lua_ls", "ty"})
require("nvim-treesitter").setup({
    ensure_installed = {
        "lua",
        "python",
        "bash",
        "json",
        "javascript",
        "c",
    },
    highlight = {
        enable = true
    },

    indent = {
        enable = true
    }
})


vim.api.nvim_create_autocmd("FileType", {
  callback = function()
    pcall(vim.treesitter.start)

    vim.bo.indentexpr =
      "v:lua.require'nvim-treesitter'.indentexpr()"

    vim.wo.foldexpr =
      "v:lua.vim.treesitter.foldexpr()"

    vim.wo.foldmethod = "expr"
  end,
})


local cmp = require("blink.cmp")
cmp.build():pwait()
cmp.setup({
  keymap = {
    preset = "default",
  },

  appearance = {
    nerd_font_variant = "mono",
  },

  completion = {
    documentation = {
      auto_show = true,
    },
  },

  sources = {
    default = { "lsp", "path", "snippets", "buffer" },
  },

  fuzzy = {
    implementation = "prefer_rust_with_warning",
  },
})

require("lualine").setup()

vim.opt.termguicolors = true
vim.cmd("colorscheme guts")
vim.lsp.buf.hover()
