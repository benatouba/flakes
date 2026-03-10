local status_ok, dap = pcall(require, "dap")
if not status_ok then
	vim.notify("nvim-dap not okay")
	return
end

local data = {
	breakpoint = {
		text = "",
		texthl = "LspDiagnosticsSignError",
		linehl = "",
		numhl = "",
	},
	breakpoint_rejected = {
		text = "",
		texthl = "LspDiagnosticsSignHint",
		linehl = "",
		numhl = "",
	},
	stopped = {
		text = "",
		texthl = "LspDiagnosticsSignInformation",
		linehl = "DiagnosticUnderlineInfo",
		numhl = "LspDiagnosticsSignInformation",
	},
}

local mappings = {}
mappings["d"] = {
	name = "+Debug",
	b = { "<cmd>lua require'dap'.toggle_breakpoint()<cr>", "Toggle Breakpoint" },
	B = { "<cmd>lua require'dap'.set_breakpoint(vim.fn.input('BP Condition: '))<cr>", "Conditional Breakpoint" },
	c = { "<cmd>lua require'dap'.continue()<cr>", "Continue" },
	C = { "<cmd>lua require'dap'.run_to_cursor()<cr>", "Run To Cursor" },
	d = { "<cmd>lua require'dap'.disconnect()<cr>", "Disconnect" },
	g = { "<cmd>lua require'dap'.session()<cr>", "Get Session" },
	i = { "<cmd>lua require'dap'.step_into()<cr>", "Step Into" },
	l = {
		"<cmd>lua require'dap'.set_breakpoint(nil, nil, vim.fn.input('Log point message: '))<cr>",
		"Log Point Message",
	},
	o = { "<cmd>lua require'dap'.step_over()<cr>", "Step Over" },
	O = { "<cmd>lua require'dap'.step_out()<cr>", "Step Out" },
	p = { "<cmd>lua require'dap'.pause.toggle()<cr>", "Pause" },
	q = { "<cmd>lua require'dap'.close()<cr>", "Quit" },
	r = { "<cmd>lua require'dap'.repl.toggle()<cr>", "Toggle Repl" },
	S = { "<cmd>lua require'dap'.step_back()<cr>", "Step Back" },
	s = {
		name = "search",
		b = { "<cmd>lua require'telescope'.extensions.dap.list_breakpoints{}<cr>", "Breakpoints" },
		c = { "<cmd>lua require'telescope'.extensions.dap.commands{}<cr>", "Commands" },
		C = { "<cmd>lua require'telescope'.extensions.dap.commands{}<cr>", "Configurations" },
		f = { "<cmd>lua require'telescope'.extensions.dap.commands{}<cr>", "frames" },
		v = { "<cmd>lua require'telescope'.extensions.dap.commands{}<cr>", "Variables" },
	},
	x = { "<cmd>lua require'dap'.clear_breakpoints()<cr>", "Toggle Repl" },
}

local M = {}

M.config = function()
	vim.fn.sign_define("DapBreakpoint", data.breakpoint)
	vim.fn.sign_define("DapBreakpointRejected", data.breakpoint_rejected)
	vim.fn.sign_define("DapStopped", data.stopped)

	dap.defaults.fallback.terminal_win_cmd = "50vsplit new"
	require("nvim-dap-virtual-text").setup()
	require("which-key").register(mappings, { mode = "n", prefix = "<leader>" })
end
return M
