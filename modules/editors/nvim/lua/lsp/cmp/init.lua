local M = {}

local has_words_before = function()
	local line, col = unpack(vim.api.nvim_win_get_cursor(0))
	return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
end

M.config = function()
	require("luasnip").filetype_extend("javascript", { "vue" })
	require("luasnip").filetype_extend("typescript", { "vue_typescript" })
	require("luasnip.loaders.from_vscode").lazy_load({ paths = { vim.fn.stdpath("config") .. "/snippets" } })
	require("luasnip.loaders.from_vscode").lazy_load()
	vim.opt.completeopt = { "menu", "menuone", "noselect" }
	-- local neogen_ok, neogen = pcall(require, "neogen")
	local cmp_ok, cmp = pcall(require, "cmp")
	local snip_ok, luasnip = pcall(require, "luasnip")
	local lspkind_ok, lspkind = pcall(require, "lspkind")
	local types = require("cmp.types")
	local str = require("cmp.utils.str")
	if not cmp_ok then
		vim.notify("nvim-cmp not okay")
		return
	end
	if not lspkind_ok then
		vim.notify("lspkind not ok")
	end
	if not snip_ok then
		vim.notify("luasnip not ok")
	end

	luasnip.config.setup({
		region_check_events = "CursorMoved",
		delete_check_events = "TextChanged",
	})

	cmp.setup({
		enabled = function()
			-- enable autocompletion in nvim-dap
			if vim.api.nvim_buf_get_option(0, "buftype") ~= "prompt" or require("cmp_dap").is_dap_buffer() then
				return true
			end
			-- disable completion in comments
			local context = require("cmp.config.context")
			-- keep command mode completion enabled when cursor is in a comment
			if vim.api.nvim_get_mode().mode == "c" then
				return true
			else
				return not context.in_treesitter_capture("comment") and not context.in_syntax_group("Comment")
			end
		end,
		-- view = {
		-- 	entries = { name = "native" },
		-- },
		formatting = {
			fields = {
				cmp.ItemField.Kind,
				cmp.ItemField.Abbr,
				cmp.ItemField.Menu,
			},
			-- if entry.source.name == "copilot" then
			-- 	vim_item.kind = "[]"
			-- 	vim_item.kind_hl_group = "CmpItemKindCopilot"
			-- 	return vim_item
			-- end
			format = lspkind.cmp_format({
				with_text = false,
				before = function(entry, vim_item)
					-- Get the full snippet (and only keep first line)
					local word = entry:get_insert_text()
					if entry.completion_item.insertTextFormat == types.lsp.InsertTextFormat.Snippet then
						word = vim.lsp.util.parse_snippet(word)
					end
					word = str.oneline(word)

					-- concatenates the string
					local max = 50
					if string.len(word) >= max then
						local before = string.sub(word, 1, math.floor((max - 3) / 2))
						word = before .. "..."
					end

					if entry.completion_item.insertTextFormat == types.lsp.InsertTextFormat.Snippet
							and string.sub(vim_item.abbr, -1, -1) == "~"
					then
						word = word .. "~"
					end
					vim_item.abbr = word

					return vim_item
				end,
			}),
		},
		snippet = {
			expand = function(args)
				luasnip.lsp_expand(args.body)
			end,
		},
		window = {
			completion = cmp.config.window.bordered({
				autocomplete = true,
				border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
				scrollbar = "║",
			}),
			documentation = cmp.config.window.bordered({
				autocomplete = true,
				border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
				scrollbar = "║",
			}),
		},
		sorting = {
			-- priority_weight = 2,
			comparators = {
				-- require("copilot_cmp.comparators").prioritize,
				-- require("copilot_cmp.comparators").score,
				cmp.config.compare.offset,
				cmp.config.compare.exact,
				cmp.config.compare.score,
				require("cmp-under-comparator").under,
				cmp.config.compare.kind,
				cmp.config.compare.sort_text,
				cmp.config.compare.length,
				cmp.config.compare.order,
			},
		},
		mapping = {
			["<C-d>"] = cmp.mapping.scroll_docs(-4),
			-- ["<C-f>"] = cmp.mapping.scroll_docs(4),
			["<C-u>"] = cmp.mapping.scroll_docs(4),
			["<C-Space>"] = cmp.mapping.complete(),
			["<C-e>"] = cmp.mapping.abort(),
			["<C-h>"] = cmp.mapping.abort(),
			["<CR>"] = cmp.mapping.confirm({
				-- behavior = cmp.ConfirmBehavior.Replace,
				select = false,
			}),
			["<C-n>"] = cmp.mapping.select_next_item(),
			["<C-p>"] = cmp.mapping.select_prev_item(),
			["<C-f>"] = cmp.mapping(function(fallback)
				if luasnip.jumpable(1) then
					luasnip.jump(1)
				else
					fallback()
				end
			end, { "i", "s" }),
			["<C-b>"] = cmp.mapping(function(fallback)
				if luasnip.jumpable(-1) then
					luasnip.jump(-1)
				else
					fallback()
				end
			end, { "i", "s" }),
			["<Tab>"] = cmp.mapping(function(fallback)
				if cmp.visible() then
					cmp.select_next_item()
				elseif luasnip.expand_or_jumpable() then
					luasnip.expand_or_jump()
				elseif has_words_before() then
					cmp.complete()
				else
					fallback()
				end
			end, { "i", "s" }),

			["<S-Tab>"] = cmp.mapping(function(fallback)
				if cmp.visible() then
					cmp.select_prev_item()
				elseif luasnip.jumpable(-1) then
					luasnip.jump(-1)
				else
					fallback()
				end
			end, { "i", "s" }),
		},
		-- --                 ﬘    m    

		sources = {
			-- { name = "copilot", group_index = 2 },
			{ name = "nvim_lsp", keyword_length = 1 },
			{ name = "nvim_lsp_signature_help" },
			{ name = "luasnip", keyword_length = 2 },
			{ name = "treesitter", keyword_length = 3 },
			{ name = "nvim_lua", keyword_length = 3 },
			{ name = "path", keyword_length = 3 },
			{ name = "cmp_git" },
			-- { name = "tmux" },
			{ name = "orgmode" },
			-- { name = 'zsh', },
			{ name = "calc" },
			{ name = "emoji" },
			{ name = "tags", keyword_length = 5, max_item_count = 5 },
			-- { name = "look", },
			-- { name = "vim-dadbod-completion" },
			{ name = "buffer", keyword_length = 5, max_item_count = 5 },
		},
	})

	cmp.setup.filetype({ "dap-repl", "dapui_watches", "dapui_hover" }, {
		sources = {
			{ name = "dap" },
		},
	})
	-- vim.api.nvim_set_hl(0, "CmpItemKindCopilot", {fg = "#6CC644"})

	cmp.setup.cmdline(":", {
		mapping = cmp.mapping.preset.cmdline(),
		window = {
			completion = cmp.config.window.bordered({ autocomplete = false }),
		},
		sources = cmp.config.sources({
			{ name = "path" },
		}, {
			{ name = "cmdline" },
		}),
	})

	cmp.setup.cmdline("/", {
		mapping = cmp.mapping.preset.cmdline(),
		window = {
			completion = cmp.config.window.bordered({ autocomplete = false }),
		},
		sources = {
			{ name = "nvim_lsp_document_symbol" },
			{ name = "buffer" },
		},
	})

	-- require("luasnip/loaders/from_vscode").lazy_load({paths={vim.fn.stdpath('config') .. "/snippets"}})

	local cmp_git_ok, _ = pcall(require, "cmp_git")
	if not cmp_git_ok then
		vim.notify("cmp_git not okay")
		return
	end
	cmp.setup.filetype("gitcommit", {
		sources = cmp.config.sources({
			{ name = "cmp_git" }, -- You can specify the `cmp_git` source if you were installed it.
		}, {
			{ name = "buffer" },
		}),
		github = {
			issues = {
				filter = "all", -- assigned, created, mentioned, subscribed, all, repos
				limit = 100,
				state = "open", -- open, closed, all
			},
			mentions = {
				limit = 100,
			},
		},
		gitlab = {
			issues = {
				limit = 100,
				state = "opened", -- opened, closed, all
			},
			mentions = {
				limit = 100,
			},
		},
	})

	local sign = function(opts)
		vim.fn.sign_define(opts.name, {
			texthl = opts.name,
			text = opts.text,
			numhl = "",
		})
	end

	sign({ name = "DiagnosticSignError", text = "✘" })
	sign({ name = "DiagnosticSignWarn", text = "▲" })
	sign({ name = "DiagnosticSignHint", text = "⚑" })
	sign({ name = "DiagnosticSignInfo", text = "" })

	_ = vim.cmd([[
  augroup DadbodSql
    au!
    autocmd FileType sql,mysql,plsql lua require('cmp').setup.buffer { sources = { { name = 'vim-dadbod-completion' } } }
  augroup END
]])

	_ = vim.cmd([[
  augroup CmpZsh
    au!
    autocmd Filetype zsh lua require'cmp'.setup.buffer { sources = { { name = "zsh" }, } }
  augroup END
]])
	vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded" })

	vim.lsp.handlers["textDocument/signatureHelp"] =
	vim.lsp.with(vim.lsp.handlers.signature_help, { border = "rounded" })
end

return M
