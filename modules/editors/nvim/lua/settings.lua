vim.opt.iskeyword:append("-") -- treat dash separated words as a word text object"
vim.opt.shortmess:append("c") -- Don't pass messages to |ins-completion-menu|.
vim.opt.inccommand = "split" -- Make substitution work in realtime
vim.o.hidden = true -- Required to keep multiple buffers open multiple buffers
vim.o.title = true
TERMINAL = vim.fn.expand("$TERMINAL")
DATA_PATH = vim.fn.stdpath('data')
-- vim.cmd('let &titleold="' .. TERMINAL .. '"')
vim.o.titlestring = "%<%F%=%l/%L - nvim"
vim.g.loaded = 1
vim.g.loaded_netrwPlugin = 1
vim.wo.wrap = true -- Display long lines as just one line
vim.opt.whichwrap:append("<,>,[,]") -- move to next line with theses keys
vim.o.syntax = "on" -- syntax highlighting
vim.o.pumheight = 10 -- Makes popup menu smaller
vim.o.fileencoding = "utf-8" -- The encoding written to file
vim.o.cmdheight = 0 -- More space for displaying messages
vim.o.mouse = "c" -- Enable your mouse
vim.o.splitbelow = true -- Horizontal splits will automatically be below
vim.o.termguicolors = true -- set term gui colors most terminals support this
vim.o.splitright = true -- Vertical splits will automatically be to the right
vim.o.conceallevel = 0 -- So that I can see `` in markdown files
vim.opt.ts=4 -- Insert 2 spaces for a tab
vim.opt.sw=4 -- Change the number of space characters inserted for indentation
-- vim.opt.nojoinspaces = true -- do not insert space on line join
vim.opt.list = true
vim.opt.listchars:append "nbsp:␣,trail:•,extends:⟩,precedes:⟨"
vim.bo.tabstop = 8
vim.bo.expandtab = true -- Converts tabs to spaces
vim.bo.smartindent = true -- Makes indenting smart
vim.wo.number = true -- set numbered lines
vim.wo.relativenumber = true -- set relative number
vim.wo.cursorline = true -- Enable highlighting of the current line
vim.opt.sidescrolloff = 7
vim.opt.colorcolumn = "89"
vim.o.scrolloff = 8
vim.o.showtabline = 2 -- Always show tabs
vim.o.showmode = false -- We don't need to see things like -- INSERT -- anymore
vim.o.backup = true -- backup files
vim.g.cursorhold_updatetime = 100
vim.o.writebackup = true -- backup files during writing
vim.wo.signcolumn = "yes:1" -- Always show the signcolumn, otherwise it would shift the text each time
vim.o.updatetime = 200 -- Faster completion
vim.o.timeoutlen = 200 -- By default timeoutlen is 1000 ms
vim.o.clipboard = "unnamedplus" -- Copy paste between vim and everything else
-- vim.o.winbar = "yes"
vim.opt.foldmethod= "expr"
-- vim.opt.foldexpr=nvim_treesitter#foldexpr()
-- vim.bo.ts_highlight_lua = true

vim.o.ignorecase = true -- ignore case makes searching case insensitive
vim.o.smartcase = true -- smartcase makes it so that searching becomes case sensitive if you use a capital letter
if not IsDir(DATA_PATH .. "/backup") then
	os.execute("mkdir " .. DATA_PATH .. "/backup")
end
vim.o.backupdir = DATA_PATH .. "/backup" -- set backup directory to be a subdirectory of data to ensure that backups are not written to git repos
vim.o.undodir = vim.fn.stdpath("data") .. "/undo" -- set undodir to ensure that the undofiles are not saved to git repos.
vim.o.undofile = true -- enable persistent undo (meaning if you quit Neovim and come back to a file and want to undo previous changes you can)
if not IsDir(DATA_PATH .. "/directory") then
	os.execute("mkdir " .. DATA_PATH .. "/directory")
end
vim.o.directory = DATA_PATH .. "/directory" -- Configure 'directory' to ensure that Neovim swap files are not written to repos.
vim.o.conceallevel = 0 -- Every character can be seen

-- Settings for folkes tokyo night colorscheme
vim.g.tokynight_style = "storm"
vim.g.tokyonight_transparent = true
vim.g.tokyonight_sidebars = { "terminal", "packer", "qf", "nvimtree" }
-- vim.g.tokyonight_colors = { hint = "orange", error = "#ff0000" }
vim.g.loaded_perl_provider = 0

vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  update_in_insert = false,
  underline = true,
  severity_sort = true,
  float = true,
})
