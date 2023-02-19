local M = {}
local copilot_ok, copilot = pcall(require, 'copilot')
if not copilot_ok then
    vim.notify('copilot not okay')
    return
end

M.config = function()
    vim.defer_fn(function()
        copilot.setup {
            cmp = {
                method = "getCompletionsCycling",
            },
            plugin_manager_path = vim.fn.stdpath("data") .. "/site/pack/packer",
            server_opts_override = {
                settings = {
                    inlineSuggest = "enable",
                    editor = {
                        showEditorCompletions = true,
                        enableAutoCompletions = true,
                    },
                    advanced = {
                        list_count = 5,
                        inlinrSuggestCount = 3,
                    }
                }
            }
        }
    end, 100)
end

return M
