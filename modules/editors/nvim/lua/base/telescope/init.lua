local M = {}

M.config = function()
    local telescope_ok, telescope = pcall(require, 'telescope')
    if not telescope_ok then
        vim.notify("Telescope could not be initiated")
        return
    end

    local actions = require('telescope.actions')
    local sorters = require('telescope.sorters')
    local previewers = require 'telescope.previewers'
    telescope.setup {
        defaults = {
            find_command = { 'grep', '--line-number', '--column', '--ignore-case', '--color' },
            -- prompt_prefix = " ",
            prompt_prefix = " ",
            selection_caret = " ",
            entry_prefix = "  ",
            initial_mode = "insert",
            selection_strategy = "reset",
            sorting_strategy = "descending",
            layout_strategy = "horizontal",
            file_sorter = sorters.get_fzy_sorter,
            file_ignore_patterns = { 'parser.c' },
            generic_sorter = require 'telescope.sorters'.get_generic_fuzzy_sorter,
            path_display = {},
            winblend = 0,
            layout_config = {
                width = 0.75,
                -- preview_cutoff = 120,
                horizontal = { mirror = false },
                vertical = { mirror = false },
                prompt_position = "bottom",
            },
            pickers = {
                find_files = {
                    find_command = { "fd", "--type", "f", "--strip-cwd-prefix" }
                },
            },
            border = {},
            borderchars = { '─', '│', '─', '│', '╭', '╮', '╯', '╰' },
            color_devicons = true,
            use_less = true,
            set_env = { ['COLORTERM'] = 'truecolor' }, -- default = nil,
            file_previewer = previewers.vim_buffer_cat.new,
            grep_previewer = previewers.vim_buffer_vimgrep.new,
            qflist_previewer = previewers.vim_buffer_qflist.new,

            -- Developer configurations: Not meant for general override
            buffer_previewer_maker = previewers.buffer_previewer_maker,
            mappings = {
                i = {
                    ["<C-j>"] = actions.move_selection_next,
                    ["<C-k>"] = actions.move_selection_previous,
                    ["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
                    -- To disable a keymap, put [map] = false
                    -- So, to not map "<C-n>", just put
                    ["<c-h>"] = actions.which_key,
                    ["<esc>"] = actions.close,

                    -- Otherwise, just set the mapping to the function that you want it to be.
                    -- ["<C-i>"] = actions.select_horizontal,

                    -- Add up multiple actions
                    ["<CR>"] = actions.select_default + actions.center

                    -- You can perform as many actions in a row as you like
                    -- ["<CR>"] = actions.select_default + actions.center + my_cool_custom_action,
                },
                n = {
                    ["<C-j>"] = actions.move_selection_next,
                    ["<C-k>"] = actions.move_selection_previous,
                    ["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
                    -- ["<C-i>"] = my_cool_custom_action,
                }
            }
        },
        extensions = {
            projects = {
                detection_methods = { "lsp", "pattern", ".git", "Makefile", "*.sln", "build/env.sh" }
            },
            fzy_native = {
                override_generic_sorter = true,
                override_file_sorter = true,
            },
            fzf_writer = {
                use_highlighter = false,
                minimum_grep_characters = 6,
            },
            frecency = {
                show_scores = true,
                show_unindexed = false,
                ignore_patterns = { "*.git/*", "*/tmp/*", "*.svn/*" },
                workspaces = {
                    ["conf"] = vim.fn.environ()["HOME"] .. "/.config/nvim/",
                    ["nvim"] = vim.fn.environ()["HOME"] .. "/.config/nvim",
                    ["palm_mpich"] = "/sim/palm/mpich",
                    ["palm_intel"] = "/sim/palm/intel",
                    ["salt"] = "/srv",
                },
            },
            fzf = {
                override_generic_sorter = false, -- override the generic sorter
                override_file_sorter = true, -- override the file sorter
                case_mode = "smart_case", -- or "ignore_case" or "respect_case"
                -- the default case_mode is "smart_case"
            }
        }
    }

end

return M
