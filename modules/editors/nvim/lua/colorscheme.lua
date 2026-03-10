require("catppuccin").setup({
    flavour = "macchiato", -- latte, frappe, macchiato, mocha
    background = { -- :h background
        light = "latte",
        dark = "macchiato",
    },
    transparent_background = true,
    compile_path = vim.fn.stdpath('config') .. "lua/catppuccin"
})
vim.cmd.colorscheme 'catppuccin'
