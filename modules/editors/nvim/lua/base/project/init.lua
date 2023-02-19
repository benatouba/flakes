-- these are all of the default values
local M = {}

M.setup = function()
    local isOk, project = pcall(require, 'project_nvim')
    if not isOk then
        vim.notify('Project.nvim not okay')
    end

    project.setup{
        detection_methods = { "lsp", "pattern", "=src", ">projects", ">scripts", "pillar", ".git", "=nvim"},
        ignore_lsp = { 'null-ls', "salt-lsp"},
        exclude_dirs = { "*/node_modules/*" },
    }
    require('telescope').load_extension('projects')
end

return M
