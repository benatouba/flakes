-- these are all of the default values
local setup = function()
local isOk, rooter = pcall(require, 'rooter')
if not isOk then
    vim.notify('Rooter not okay')
end

rooter.setup {
    manual = true, -- wether to setup autocommand to root every time a file is opened
    echo = true, -- echo every time rooter is triggered
    patterns = { -- the patterns to find
        '.git', -- same as patterns passed to nvim_lsp.util.root_pattern(patterns...)
        '.svn', '.bashrc', '.palm.config*', 'Makefile', '_darcs', '.hg', '.bzr', 'Cargo.toml', 'go.mod', 'node_modules',
        'CMakeLists.txt', 'manage.py'
    },
    cd_command = 'lcd', -- the cd command to use, possible values are 'lcd', 'cd', and 'tcd'
    -- what to do when the rooter pattern is not found
    -- if this is 'current', will cd to the parent directory of current file
    -- if this is 'home', will cd to the home directory
    -- if this is 'none', will not do anything
    non_project_files = 'current',

    -- the start path to pass to nvim_lsp.util.root_pattern(patterns...)
    start_path = function()
        return vim.fn.expand [[%:p:h]]
    end
}
end
