local M = {}

M.config = function()
	local ref_ok, ref = pcall(require, "refactoring")
	if not ref_ok then
		vim.notify("Refactoring.nvim not okay")
		return
	end
	ref.setup({})
	-- load refactoring Telescope extension
	require("telescope").load_extension("refactoring")
end

-- telescope refactoring helper
-- local function refactor(prompt_bufnr)
-- 	local content = require("telescope.actions.state").get_selected_entry(prompt_bufnr)
-- 	require("telescope.actions").close(prompt_bufnr)
-- 	require("refactoring").refactor(content.value)
-- end


-- M.refactors = function()
-- 	local opts = require("telescope.themes").get_cursor() -- set personal telescope options
-- 	require("telescope.pickers").new(opts, {
-- 		prompt_title = "refactors",
-- 		finder = require("telescope.finders").new_table({
-- 			results = require("refactoring").get_refactors(),
-- 		}),
-- 		sorter = require("telescope.config").values.generic_sorter(opts),
-- 		attach_mappings = function(_, map)
-- 			map("i", "<CR>", refactor)
-- 			map("n", "<CR>", refactor)
-- 			return true
-- 		end,
-- 	}):find()
-- end
--
M.maps = function()
	local wk_ok, wk = pcall(require, "which-key")
	if not wk_ok then
		vim.notify("which-key not ok in refactoring.nvim")
		return
	end

	local vmaps = {
		["r"] = {
			name = "+refactor",
			e = { "<Esc><Cmd>lua require('refactoring').refactor('Extract Function')<CR>", "Extract Function" },
			f = { "<Esc><Cmd>lua require('refactoring').refactor('Extract Function To File')<CR>", "Extract Function to File" },
			i = { "<Esc><Cmd>lua require('refactoring').refactor('Inline Variable')<CR>", "Inline Variable" },
			v = { "<Esc><Cmd>lua require('refactoring').refactor('Extract Variable')<CR>", "Extract Variable" },
			t = { "<Esc><Cmd>lua require('telescope').extensions.refactoring.refactors()<CR>", "Extract to Telescope" },
			r = { "<cmd>lua require('refactoring').select_refactor()<CR>", "Select Refactor" },
		},
	}
	wk.register(vmaps, { expr = false, silent = true, prefix = "<leader>", mode = "v" })

	local nmaps = {
		["r"] = {
			name = "+refactor",
			b = { "<cmd>lua require('refactoring').refactor('Extract Block')<CR>", "Block" },
			f = { "<cmd>lua require('refactoring').refactor('Extract Block to File')<CR>", "block to File" },
			i = { "<cmd>lua require('refactoring').refactor('Inline Variable')<CR>", "Inline variable" },
		},
	}
	wk.register(nmaps, { expr = false, silent = true, prefix = "<leader>", mode = "n" })
end

return M
