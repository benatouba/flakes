O = {
    language_parsing = true,
    lsp = false,
    git = false,
    snippets = false,
    test = false,
    dap = false,
    misc = false,

    auto_close_tree = 0,
    auto_complete = true,
    colorscheme = 'catppuccin',
    wrap_lines = false,
    shell = 'bash',
    mapleader = " ",
    packer_compile_path = vim.fn.stdpath('config')..'/lua/packer_compiled.lua',
    galaxyline = {
        colors = {
            alt_bg = "#2E2E2E",
            grey = "#858585",
            blue = "#569CD6",
            green = "#608B4E",
            yellow = "#DCDCAA",
            orange = "#FF8800",
            purple = "#C586C0",
            magenta = "#D16D9E",
            cyan = "#4EC9B0",
            red = "#D16969",
            error_red = "#F44747",
            warning_orange = "#FF8800",
            info_yellow = "#FFCC66",
            hint_blue = "#9CDCFE"
        }
    },

    -- @usage pass a table with your desired languages
    treesitter = {
        ensure_installed = "all",
        ignore_install = {"haskell"},
        highlight = {enabled = true},
        playground = {enabled = true},
        rainbow = {enabled = true}
    },
    diagnostics = {
        virtual_text = {active = true, spacing = 0, prefix = ""},
        signs = true,
        underline = true
    },

    org = {agenda_files = {}, default_notes_file = ''},
    formatters = {}
}

DATA_PATH = vim.fn.stdpath('data')
CACHE_PATH = vim.fn.stdpath('cache')

P = function(v)
    local logger = require("structlog").get_logger("INFO:")
    return logger:info(v)
end

if pcall(require, "plenary") then
    RELOAD = require("plenary.reload").reload_module

    R = function(name)
        RELOAD(name)
        return require(name)
    end
end
