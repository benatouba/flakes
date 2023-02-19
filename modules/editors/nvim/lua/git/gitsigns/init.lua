local isOk, gitsigns = pcall(require, "gitsigns")
if not isOk then
	vim.notify("Gitsigns not okay")
	return
end

gitsigns.setup({
	signs = {
		-- TODO add hl to colorscheme
		add = { hl = "GitSignsAdd", text = "▎", numhl = "GitSignsAddNr", linehl = "GitSignsAddLn" },
		change = { hl = "GitSignsChange", text = "▎", numhl = "GitSignsChangeNr", linehl = "GitSignsChangeLn" },
		delete = { hl = "GitSignsDelete", text = "契", numhl = "GitSignsDeleteNr", linehl = "GitSignsDeleteLn" },
		topdelete = { hl = "GitSignsDelete", text = "契", numhl = "GitSignsDeleteNr", linehl = "GitSignsDeleteLn" },
		changedelete = { hl = "GitSignsChange", text = "▎", numhl = "GitSignsChangeNr", linehl = "GitSignsChangeLn" },
	},
	numhl = true,
	linehl = true,
	keymaps = {
		buffer = true,
	},
	watch_gitdir = {
		interval = 1000,
	},
	sign_priority = 11,
	update_debounce = 200,
	status_formatter = nil, -- Use default
	on_attach = function(bufnr)
		local gs = package.loaded.gitsigns

		local function map(mode, l, r, opts)
			opts = opts or {}
			opts.buffer = bufnr
			vim.keymap.set(mode, l, r, opts)
		end

		-- Navigation
		map("n", "]g", "", {
			desc = "Git hunk",
			callback = function()
				if vim.wo.diff then
					return "]g"
				end
				vim.schedule(function()
					gs.next_hunk()
				end)
				return "<Ignore>"
			end,
			expr = true,
		})

		map("n", "[g", "", {
			desc = "Git hunk",
			callback = function()
				if vim.wo.diff then
					return "[g"
				end
				vim.schedule(function()
					gs.prev_hunk()
				end)
				return "<Ignore>"
			end,
			expr = true,
		})
	end,
})
