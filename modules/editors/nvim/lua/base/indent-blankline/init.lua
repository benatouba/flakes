local M = {}

M.config = function()
	require("indent_blankline").setup({
		show_current_context = true,
		show_current_context_start = false,
		show_end_of_line = false,
		space_char_blankline = " ",
		show_trailing_blankline_indent = true,
	})
	vim.g.indent_blankline_buftype_exclude = { "terminal", "fugitive", "neogit" }
	vim.g.indent_blankline_filetype_exclude = { "help", "startify", "dashboard", "packer", "neogitstatus", "fugitive" }
end

return M
