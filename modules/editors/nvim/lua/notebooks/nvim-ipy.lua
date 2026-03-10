local M = {}

local wk_ok, wk = pcall(require, "which-key")
if not wk_ok then
	vim.notify("which-key not okay in nvim-ipy")
end

local connectToKernel = function()
	local handle = io.popen('pyenv version-name')
	local kernel = handle:read("*a")
	handle:close()
	vim.api.nvim_command("call IPyConnect('--kernel'" .. kernel .. "'--no-window')")
end

local addFilepathToSyspath = function()
	local filepath = vim.api.nvim_exec([[
		expand('%:p:h')
		]])
	vim.api.nvim_command("call IPyRun('import sys; sys.path.append(\"'" .. filepath .. "'\")')")
	vim.notify('Added ' .. filepath .. ' to pythons sys.path')
end

M.config = function()
	local nmaps = {
		N = {
			name = "Notebooks",
			["c"] = { '<cmd>ConnectToKernel<cr>', "Connect to Kernel" },
			["p"] = { '<cmd>AddFilepathToSyspath<cr>', "Add Filepath to syspath" },
			["q"] = { '<cmd>RunQtConsole<cr>', "Qt Console" },
			["x"] = { '<cmd>call IPyRun("close(\\"all\\")", 1)<cr>', "Close all" },
		},
	}

	wk.register(nmaps, {
		mode = "n", -- NORMAL mode
		prefix = "<leader>",
	})
	vim.api.nvim_create_user_command(
		'ConnectToKernel',
		function()
			connectToKernel()
		end,
		{ nargs = 0 }
	)
	vim.api.nvim_create_user_command(
		'RunQtConsole',
		function()
			os.execute('jupyter qtconsole --existing')
		end,
		{ nargs = 0 }
	)
	vim.api.nvim_create_user_command(
		'AddFilepathToSyspath',
		function()
			addFilepathToSyspath()
		end,
		{ nargs = 0 }
	)
end

return M
