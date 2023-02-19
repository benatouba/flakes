local org_ok, org = pcall(require, "orgmode")
if not org_ok then
	vim.notify("orgmode not okay")
	return
end

local ts_ok, tsc = pcall(require, "nvim-treesitter.configs")
if not ts_ok then
	vim.notify("treesitter not okay in orgmode.nvim")
	return
end
-- local parser_config = tsp.get_parser_configs()
-- parser_config.org = {
-- 	install_info = {
-- 		url = "https://github.com/milisims/tree-sitter-org",
-- 		revision = "main",
-- 		files = { "src/parser.c", "src/scanner.cc" },
-- 	},
-- 	filetype = "org",
-- }

org.setup_ts_grammar()
tsc.setup({
	highlight = {
		enable = true,
		additional_vim_regex_highlighting = { "org" }, -- Required since TS highlighter doesn't support all syntax features (conceal)
	},
	ensure_installed = { "org" }, -- Or run :TSUpdate org
})
org.setup(require('management.orgmode_config'))
