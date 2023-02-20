require("functions")
require("keymappings")
require("settings")
require("user-defaults")
require("base")
require('autocommands')
require('colorscheme')
require('base.which-key')
require('lsp')
require('lsp.cmp').config()
require('language_parsing.treesitter')
require('base.dial').config()
require("base.nvim-tree").config()
require("nvim-surround").setup({})
require("toggleterm").setup({
	open_mapping = [[<c-\>]],
	direction = "horizontal",
	float_opts = {
		border = "single",
		width = 120,
		height = 30,
		winblend = 3,
	},
})
require("misc.neogen")
