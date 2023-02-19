local M = {}

M.config = function()
	local isOk, nvim_tree = pcall(require, "nvim-tree")
	if not isOk then
		vim.notify("Nvim-tree not okay")
		return
	end

	vim.o.termguicolors = true

	local tree_cb = require("nvim-tree.config").nvim_tree_callback

	nvim_tree.setup({
		diagnostics = {
			enable = true,
			icons = {
				hint = "",
				info = "",
				warning = "",
				error = "",
			},
		},
		renderer = {
			icons = {
				glyphs = {
					default = "",
					symlink = "",
					git = {
						unstaged = "✗",
						staged = "✓",
						unmerged = "",
						renamed = "➜",
						deleted = "",
						untracked = "U",
						ignored = "◌",
					},
					folder = {
						default = "",
						open = "",
						empty = "",
						empty_open = "",
						symlink = "",
					},
				},
				show = {
					file = true,
					folder = true,
					folder_arrow = true,
					git = true,
				},
			},
			indent_markers = {
				enable = true,
			},
			highlight_git = true,
			highlight_opened_files = "icon",
			-- root_folder_modifier = true,
		},
		actions = {
			open_file = {
				resize_window = true,
				quit_on_open = true,
			},
		},
		git = {
			ignore = true,
		},
		respect_buf_cwd = true,
		-- nvim_tree_gitignore = true,
		-- nvim_tree_hide_dotfiles = false,
		open_on_tab = true,
		open_on_setup = true,
		-- nvim_tree_ignore = { ".git", "node_modules", ".cache" },
		ignore_ft_on_setup = {
			"python",
			"lua",
			"vue",
			"javascript",
			"conf",
			"txt",
			"sls",
			"typescript",
			"java",
			"fortran",
			"markdown",
		},
		view = {
			width = 50,
			mappings = {
				list = {
					{ key = { "l", "<CR>", "o" }, mode = "n", cb = tree_cb("edit") },
					{ key = "h", mode = "n", cb = tree_cb("close_node") },
					{ key = "v", mode = "n", cb = tree_cb("vsplit") },
				},
			},
		},
	})
end

local view = require("nvim-tree.view")

M.toggle_tree = function()
	if view.win_open() then
		require("nvim-tree").close()
		if package.loaded["bufferline.state"] then
			require("bufferline.state").set_offset(0)
		end
	else
		if package.loaded["bufferline.state"] then
			-- require'bufferline.state'.set_offset(31, 'File Explorer')
			require("bufferline.state").set_offset(31, "")
		end
		require("nvim-tree").find_file(true)
	end
end

return M
