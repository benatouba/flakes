local ok, dap_py = pcall(require, "dap-python")
if not ok then
	vim.notify("dap-python not ok")
	return
end

local M = {}

local mappings = {
	["m"] = { "<cmd>lua require('dap-python').test_method()<CR>", "Test Method" },
	["f"] = { "<cmd>lua require('dap-python').test_class()<CR>", "Test Class" },
}

M.config = function()
	dap_py.setup(vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python")
	dap_py.test_runner = "pytest"
	require("which-key").register(mappings, { mode = "n", prefix = "<leader>d" })
	require("which-key").register({
		["ds"] = { "<ESC><cmd>lua require('dap-python').debug_selection()<CR>", "Debug Selection" },
	}, { mode = "v", prefix = "" })
end

return M
