local funcs = {}
AddAutocommands = function(definitions)
	-- Create autocommand groups based on the passed definitions
	--
	-- The key will be the name of the group, and each definition
	-- within the group should have:
	--    1. Trigger
	--    2. Pattern
	--    3. Text
	-- just like how they would normally be defined from Vim itself
	for group_name, definition in pairs(definitions) do
		vim.cmd("augroup " .. group_name)
		vim.cmd("autocmd!")
		for _, def in pairs(definition) do
			local command = table.concat(vim.tbl_flatten({ "autocmd", def }), " ")
			vim.cmd(command)
		end
		vim.cmd("augroup END")
	end
end

RegisterKeys = function(keys)
	local isOk, which_key = pcall(require, "which-key")
	if not isOk then
		return
	end
	which_key.register(keys)
end

--- Check if a directory exists in this path
function IsDir(path)
	-- "/" works on both Unix and Windows
	return Exists(path .. "/")
end

--- Check if a file or directory exists in this path
function Exists(file)
	local ok, err, code = os.rename(file, file)
	if not ok then
		if code == 13 then
			-- Permission denied, but it exists
			return true
		end
	end
	return ok, err
end

function funcs.reload_config()
	vim.cmd("source ~/.config/nvim/init.lua")
	vim.cmd(":PackerSync")
end

-- print stuff
P = function(v)
	print(vim.inspect(v))
	return v
end

-- reload modules
if pcall(require, "plenary") then
	RELOAD = require("plenary.reload").reload_module

	R = function(name)
		RELOAD(name)
		return require(name)
	end
end

-- lsp

function funcs.add_to_workspace_folder()
	vim.lsp.buf.add_workspace_folder()
end

function funcs.clear_references()
	vim.lsp.buf.clear_references()
end

function funcs.code_action()
	vim.lsp.buf.code_action()
end

function funcs.declaration()
	vim.lsp.buf.declaration()
	vim.lsp.buf.clear_references()
end

function funcs.definition()
	vim.lsp.buf.definition()
	vim.lsp.buf.clear_references()
end

function funcs.document_highlight()
	vim.lsp.buf.document_highlight()
end

function funcs.document_symbol()
	vim.lsp.buf.document_symbol()
end

function funcs.formatting()
	vim.lsp.buf.format({ async = true })
end

function funcs.formatting_sync()
	vim.lsp.buf.format()
end

function funcs.hover()
	vim.lsp.buf.hover()
end

function funcs.implementation()
	vim.lsp.buf.implementation()
end

function funcs.incoming_calls()
	vim.lsp.buf.incoming_calls()
end

function funcs.list_workspace_folders()
	vim.lsp.buf.list_workspace_folders()
end

function funcs.outgoing_calls()
	vim.lsp.buf.outgoing_calls()
end

function funcs.range_code_action()
	vim.lsp.buf.range_code_action()
end

function funcs.range_formatting()
	vim.lsp.buf.range_formatting()
end

function funcs.references()
	vim.lsp.buf.references()
	vim.lsp.buf.clear_references()
end

function funcs.remove_workspace_folder()
	vim.lsp.buf.remove_workspace_folder()
end

function funcs.rename()
	vim.lsp.buf.rename()
end

function funcs.signature_help()
	vim.lsp.buf.signature_help()
end

function funcs.type_definition()
	vim.lsp.buf.type_definition()
end

function funcs.workspace_symbol()
	vim.lsp.buf.workspace_symbol()
end

-- diagnostic

function funcs.get_all()
	vim.diagnostic.get()
end

function funcs.get_next()
	vim.lsp.diagnostic.get_next()
end

function funcs.get_prev()
	vim.lsp.diagnostic.get_prev()
end

function funcs.goto_next()
	vim.lsp.diagnostic.goto_next()
end

function funcs.goto_prev()
	vim.lsp.diagnostic.goto_prev()
end

function funcs.show_line_diagnostics()
	vim.lsp.diagnostic.show_line_diagnostics()
end

-- git signs

function funcs.next_hunk()
	require("gitsigns").next_hunk()
end

function funcs.prev_hunk()
	require("gitsigns").prev_hunk()
end

function funcs.stage_hunk()
	require("gitsigns").stage_hunk()
end

function funcs.undo_stage_hunk()
	require("gitsigns").undo_stage_hunk()
end

function funcs.reset_hunk()
	require("gitsigns").reset_hunk()
end

function funcs.reset_buffer()
	require("gitsigns").reset_buffer()
end

function funcs.preview_hunk()
	require("gitsigns").preview_hunk()
end

function funcs.blame_line()
	require("gitsigns").blame_line()
end

-- misc
function funcs.file_exists(name)
	local f = io.open(name, "r")
	if f ~= nil then
		io.close(f)
		return true
	else
		return false
	end
end

function funcs.check_lsp_client_active(name)
	local clients = vim.lsp.get_active_clients()
	for _, client in pairs(clients) do
		if client.name == name then
			return true
		end
	end
	return false
end

return funcs
