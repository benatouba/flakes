local ok, dapui = pcall(require, "dapui")
if not ok then
	vim.notify("nvim-dap-ui not okay")
	return
end

local dap_ok, dap = pcall(require, "dap")
if not dap_ok then
	vim.notify("nvim-dap not okay in nvim-dap-ui")
	return
end

local M = {}
local mappings = {
	["u"] = { "<cmd>lua require('dapui').toggle()<cr>", "Toggle UI" },
	["e"] = { "<cmd>lua require('dapui').eval()<cr>", "Evaluate Expression" },
	["F"] = { "<cmd>lua require('dapui').float_element()<cr>", "Open Floating Info" },
}

M.config = function()
	dapui.setup()
	dap.listeners.after.event_initialized['dapui_conf'] = function ()
		dapui.open()
	end
	dap.listeners.before.event_terminated['dapui_conf'] = function ()
		dapui.close()
	end
	dap.listeners.before.event_exited['dapui_conf'] = function ()
		dapui.close()
	end
	require("which-key").register(mappings, { mode = "n", prefix = "<leader>d" })
end

return M
