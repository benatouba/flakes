local execute = vim.api.nvim_command
local fn = vim.fn

local install_path = fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"

local packer_ok, _ = pcall(require, "packer")
if fn.empty(fn.glob(install_path)) > 0 then
	fn.system({
		"git",
		"clone",
		"https://github.com/wbthomason/packer.nvim",
		install_path,
	})
	execute("packadd packer.nvim")
	if not packer_ok then
		vim.notify("Packer not okay")
		return
	end
	execute("PackerSync")
end

if not packer_ok then
	vim.notify("Packer not okay")
	return
end

vim.cmd("autocmd BufWritePost plugins.lua PackerCompile profile=true")

return require("packer").startup({
	function(use)
		-- Packer can manage itself as an optional plugin
		use("wbthomason/packer.nvim") -- plugin manager
		use("nvim-lua/popup.nvim") -- handle popup (important)
		use("nvim-lua/plenary.nvim") -- most important functions (very important)
		use({
			"rcarriga/nvim-notify",
			config = function()
				vim.notify = require("notify")
				require("telescope").load_extension("notify")
			end,
			after = "telescope.nvim",
		})
		use({
			"Tastyep/structlog.nvim",
			deactivate = false,
			requires = "rcarriga/nvim-notify",
			after = "nvim-notify",
			config = function()
				require("base.structlog")
			end,
		})
		use({
			"lewis6991/impatient.nvim",
			config = function()
				require("impatient")
			end,
		})

		use({
			"nvim-telescope/telescope-fzf-writer.nvim",
			after = "telescope.nvim",
		})
		use({
			"whiteinge/diffconflicts",
		})
		use({
			"nvim-telescope/telescope-fzf-native.nvim",
			run = "make",
			after = "telescope.nvim",
			config = function()
				require("telescope").load_extension("fzf")
			end,
		})
		use({
			"nvim-telescope/telescope-frecency.nvim",
			requires = {
				"tami5/sql.nvim",
				{
					"zane-/howdoi.nvim",
					config = function()
						require("telescope").load_extension("howdoi")
					end,
				},
			},
			after = "telescope.nvim",
			-- config = function() require('telescope').load_extension('frecency') end,
		})
		use({
			"nvim-telescope/telescope.nvim",
			config = function()
				require("base.telescope").config()
			end,
			-- cmd = "Telescope",
			-- event = "InsertEnter",
		})
		use({
			"ahmedkhalf/project.nvim",
			config = function()
				require("base.project").setup()
			end,
			after = "telescope.nvim",
		})

		-- help me find my way  around
		use("folke/which-key.nvim")

		-- Color
		use({ "christianchiarulli/nvcode-color-schemes.vim", opt = true })
		use({
			"nvchad/nvim-colorizer.lua",
			config = function()
				require("colorizer").setup()
			end,
			event = "BufReadPost",
		})
		use("sheerun/vim-polyglot")

		-- Icons and visuals
		use("kyazdani42/nvim-web-devicons")
		use({
			"lukas-reineke/indent-blankline.nvim",
			config = function()
				require("base.indent-blankline").config()
			end,
		})

		-- Status Line and Bufferline
		--[[ use({
			"NTBBloodbath/galaxyline.nvim",
			config = function()
				require("base.galaxyline")
			end,
		}) ]]
		use({
			"nvim-lualine/lualine.nvim",
			requires = {
				{ "kyazdani42/nvim-web-devicons", opt = true },
				"nvim-lua/lsp-status.nvim",
				"arkav/lualine-lsp-progress",
			},
			config = function()
				require("base.lualine").config()
			end,
		})
		use("romgrk/barbar.nvim")
		use({
			"kyazdani42/nvim-tree.lua",
			-- opt = true,
			config = function()
				require("base.nvim-tree").config()
			end,
			-- cmd = "NvimTreeToggle"
		})
		-- use({ "ms-jpq/chadtree", branch = "chad", run = ":CHADdeps" })

		-- manipulation
		use({
			"monaqa/dial.nvim",
			config = function()
				require("base.dial").config()
			end,
		}) -- increment/decrement basically everything
		use({
			"numToStr/Comment.nvim",
			config = function()
				require("base.comment_nvim").config()
			end,
		})
		use({ "mbbill/undotree", opt = true, cmd = "UndotreeToggle" })
		use({
			"kylechui/nvim-surround",
			config = function()
				require("nvim-surround").setup({})
			end,
		})

		-- language specific
		use("saltstack/salt-vim")
		use("Glench/Vim-Jinja2-Syntax")

		if O.language_parsing then
			-- Treesitter
			use({
				"nvim-treesitter/nvim-treesitter",
				run = ":TSUpdate",
			})
			use({
				"nvim-treesitter/nvim-treesitter-refactor",
				after = "nvim-treesitter",
			})
			use({
				"nvim-treesitter/nvim-treesitter-textobjects",
				after = "nvim-treesitter",
			})
			use({ "p00f/nvim-ts-rainbow", after = "nvim-treesitter" })
			use({ "windwp/nvim-ts-autotag", after = "nvim-treesitter" })
			use({
				"windwp/nvim-autopairs",
				after = "nvim-treesitter",
				config = function()
					require("language_parsing.autopairs")
				end,
			})
			use({
				"JoosepAlviste/nvim-ts-context-commentstring",
				after = "nvim-treesitter",
			})
		end

		if O.lsp then
			use({
				"ray-x/lsp_signature.nvim",
				config = function()
					require("lsp_signature").setup({
						handler_opts = { border = "single" },
						max_width = 80,
					})
				end,
			})
			use({
				"williamboman/mason.nvim",
				"williamboman/mason-lspconfig.nvim",
				"jayp0521/mason-null-ls.nvim",
				{
					"neovim/nvim-lspconfig",
					config = function()
						require("lsp")
					end,
				},
				-- event = { "CmdlineEnter", "InsertEnter" },
			})
			use({
				"hrsh7th/nvim-cmp",
				-- event = "InsertEnter",
				requires = {
					"hrsh7th/cmp-buffer",
					"hrsh7th/cmp-nvim-lsp",
					"hrsh7th/cmp-nvim-lsp-document-symbol",
					"hrsh7th/cmp-nvim-lsp-signature-help",
					"hrsh7th/cmp-path",
					"hrsh7th/cmp-nvim-lua",
					"hrsh7th/cmp-calc",
					"hrsh7th/cmp-emoji",
					"hrsh7th/cmp-cmdline",
					"rcarriga/cmp-dap",
					"petertriho/cmp-git",
					"andersevenrud/compe-tmux",
					"ray-x/cmp-treesitter",
					"lukas-reineke/cmp-under-comparator",
					"lukas-reineke/cmp-rg",
					{ "David-Kunz/cmp-npm", filetype = { "javascript", "vue", "typescript" } },
					"L3MON4D3/LuaSnip",
					"saadparwaiz1/cmp_luasnip",
					{ "kdheepak/cmp-latex-symbols", ft = "latex" },
					"f3fora/cmp-spell",
					"quangnguyen30192/cmp-nvim-tags",
					"octaltree/cmp-look",
					"tamago324/cmp-zsh",
					"onsails/lspkind-nvim",
				},
				config = function()
					require("lsp.cmp").config()
				end,
			})
			use({
				"rafamadriz/friendly-snippets",
				after = "LuaSnip",
				config = function()
					require("luasnip").filetype_extend("vue", { "html", "javascript", "pug", "vue" })
				end,
			})
			use({
				"jose-elias-alvarez/nvim-lsp-ts-utils",
				-- after = "nvim-lspconfig",
				ft = {
					"javascript",
					"javascriptreact",
					"javascript.jsx",
					"typescript",
					"typescriptreact",
					"typescript.tsx",
				},
			})
			use({ "folke/trouble.nvim", cmd = "TroubleToggle" })
			use({
				"jose-elias-alvarez/null-ls.nvim",
				-- event = { "BufReadPost", "InsertEnter" },
				-- fn = { "edit", "e" },
				-- cmd = { "LspStart", "LspInfo", "TSUpdate" },
				-- config = function()
				-- require("null-ls").setup()
				-- require("lsp.null-ls").config()
				-- end,
			})
		end

		if O.git then -- Git (helpers)
			use({
				"tpope/vim-fugitive",
				opt = false,
				-- cmd = {"G", "Git push", "Git pull", "Gdiffsplit!", "Gvdiffsplit!"}
			})
			use({
				"TimUntersberger/neogit",
				requires = { "sindrets/diffview.nvim" },
				cmd = "Neogit",
			})
			use({
				"lewis6991/gitsigns.nvim",
				config = function()
					require("git.gitsigns")
				end,
				event = "BufReadPost",
				-- disable = true
			}) -- fails on startup. TODO: activate when #205 is fixed
		end

		if O.test then
			use({
				"nvim-neotest/neotest",
				requires = {
					"nvim-neotest/neotest-python",
					"marilari88/neotest-vitest",
					"nvim-neotest/neotest-vim-test",
					"vim-test/vim-test",
					"nvim-lua/plenary.nvim",
					"nvim-treesitter/nvim-treesitter",
					"antoinemadec/FixCursorHold.nvim",
				},
				config = function()
					require("test.neotest").config()
				end,
			})
		end

		if O.dap then -- debug adapter protocol
			use({
				"mfussenegger/nvim-dap",
				requires = {
					"theHamsta/nvim-dap-virtual-text",
				},
				config = function()
					require("debug.dap").config()
				end,
			})
			use({
				"mfussenegger/nvim-dap-python",
				ft = "python",
				config = function()
					require("debug.dap_python").config()
				end,
			})
			use({
				"rcarriga/nvim-dap-ui",
				after = "nvim-dap",
				config = function()
					require("debug.dapui").config()
				end,
			})
			-- use({ "Pocco81/DAPInstall.nvim", after = "nvim-dap" })
			use({
				"jbyuki/one-small-step-for-vimkind",
				after = "nvim-dap",
				ft = "lua",
				config = function()
					require("debug.one_small_step_for_vimkind").config()
				end,
			})
			use({
				"nvim-telescope/telescope-dap.nvim",
				config = function()
					require("telescope").load_extension("dap")
				end,
			})
		end

		if O.project_management then
			use({
				"nvim-orgmode/orgmode.nvim",
				-- keys = "<leader>o",
				config = function()
					require("management.orgmode")
				end,
			})
			use({
				"renerocksai/telekasten.nvim",
				after = "telescope.nvim",
				requires = { "renerocksai/calendar-vim" },
				config = function()
					require("management.telekasten").config()
				end,
			})
		end

		if O.misc then
			use("kevinhwang91/nvim-bqf")
			use("andymass/vim-matchup")
			use({
				"GustavoKatel/sidebar.nvim",
				config = function()
					require("sidebar-nvim").setup({
						bindings = {
							["q"] = function()
								require("sidebar-nvim").close()
							end,
						},
					})
				end,
			})
			use({
				"folke/todo-comments.nvim",
				config = function()
					require("todo-comments").setup()
				end,
			})
			use({
				"numtostr/FTerm.nvim",
				disable = true,
				-- config = function() require("FTerm") end
			})
			use({
				"akinsho/toggleterm.nvim",
				tag = "*",
				config = function()
					require("toggleterm").setup({
						open_mapping = [[<c-\>]],
						direction = "horizontal",
						float_opts = {
							border = "single",
							width = 120,
							height = 30,
							winblend = 3,
						},
					})
				end,
			})
			use({
				"danymat/neogen",
				config = function()
					require("misc.neogen")
				end,
				requires = "nvim-treesitter/nvim-treesitter",
			})
			use({
				"benatouba/colortils.nvim",
				cmd = "Colortils",
				disable = true,
				config = function()
					require("misc.colortils").config()
				end,
			})
		end
		use("wuelnerdotexe/vim-enfocado")
		use({
			"folke/tokyonight.nvim",
			config = function()
				require("tokyonight").setup({
					style = "night",
					transparent = true,
					hide_inactive_statusline = false,
				})
			end,
		})
		use({
			"catppuccin/nvim",
			as = "catppuccin",
			config = function()
				require("catppuccin").setup({
					flavour = "mocha", -- mocha, macchiato, frappe, latte
					integrations = {
						cmp = true,
						barbar = true,
						gitsigns = true,
						harpoon = false,
						lsp_saga = true,
						lsp_trouble = true,
						markdown = true,
						mason = true,
						neogit = true,
						neotest = true,
						noice = true,
						notify = true,
						nvimtree = true,
						telekasten = true,
						telescope = true,
						treesitter = true,
						treesitter_context = true,
						ts_rainbow = true,
						vimwiki = true,
						which_key = true,
						dap = {
							enabled = true,
							enable_ui = true,
						},
						indent_blankline = {
							enabled = true,
							colored_indent_levels = false,
						},
					},
				})
			end,
		})
		use({
			"ThePrimeagen/refactoring.nvim",
			requires = {
				{ "nvim-lua/plenary.nvim" },
				{ "nvim-treesitter/nvim-treesitter" },
			},
			config = function()
				require("misc.refactoring").config()
				require("misc.refactoring").maps()
			end,
		})
		use({ "iamcco/markdown-preview.nvim", ft = "markdown", run = "cd app && yarn install" })
		use({ "szw/vim-maximizer" })
		use({
			"anuvyklack/windows.nvim",
			requires = {
				"anuvyklack/middleclass",
				-- "anuvyklack/animation.nvim",
			},
			config = function()
				vim.o.winwidth = 10
				vim.o.winminwidth = 10
				vim.o.equalalways = false
				require("windows").setup()
			end,
		})
		use({ "dstein64/vim-startuptime" })
		use({
			"kevinhwang91/nvim-hlslens",
			config = function()
				require("hlslens").setup({
					calm_down = true,
				})
			end,
		})
		if O.notebooks then
			use({
					"bfredl/nvim-ipy",
					ft='ipynb',
					config = function ()
						require('notebooks.nvim-ipy').config()
					end
				})
		end
	end,

	config = {
		profile = {
			enable = true,
			threshold = 1, -- the amount in ms that a plugins load time must be over for it to be included in the profile
		},
		compile_path = O.packer_compile_path,
	},
})
