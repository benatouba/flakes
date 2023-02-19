local defaultOpts = { silent = true, remap = false }
-- vim.keymap.set('n', '<C-j>', 'ciW<CR><Esc>:if match( @", "^\\s*$") < 0<Bar>exec "norm P-$diw+"<Bar>endif<CR>', {remap = false, silent = true, expr = true})
local function map(mode, lhs, rhs, opts)
    local options = { remap = false, silent = true }
    if opts then
        options = vim.tbl_extend("force", options, opts)
    end
    vim.keymap.set(mode, lhs, rhs, options)
end

map("n", "Y", "y$", defaultOpts) -- yank to end of line
map("n", "<leader>u", ":call UpdatePlugins()<CR>", defaultOpts) -- update all plugins with packer
map("", "Q", "<Nop>", defaultOpts) -- no ex mode
map("", "q:", ":q", defaultOpts) -- fix my typing
map("n", "<leader>br", ":syntax sync fromstart<cr>:redraw!<cr>", defaultOpts) -- treesitter fails sometimes
map("n", "n", "nzzzv", defaultOpts)
map("n", "N", "Nzzzv", defaultOpts)

-- better window movement
-- map('n', '<C-h>', '<C-w>h', {silent = true})
-- map('n', '<C-j>', '<C-w>j', {silent = true})
-- map('n', '<C-k>', '<C-w>k', {silent = true})
-- map('n', '<C-l>', '<C-w>l', {silent = true})
map("n", "<esc>", ":nohlsearch<CR>")
-- map('n', 'gs', '<cmd>lua vim.lsp.buf.signature_help()<CR>')
-- map('n', '[d', '<cmd>lua vim.diagnostic.goto_prev { wrap = false }<cr>')
-- map('n', ']d', '<cmd>lua vim.diagnostic.goto_next { wrap = false }<cr>')

local isOk, hlslens = pcall(require, "hlslens")
if not isOk then
    vim.notify("hlslens not okay")
    return
end

map("n", "n", "<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>", {})
map("n", "N", "<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>", {})
map("n", "g*", "g*<Cmd>lua require('hlslens').start()<CR>", {})
map("n", "g#", "g#<Cmd>lua require('hlslens').start()<CR>", {})

map("n", "*", "", {
    callback = function()
        vim.fn.execute("normal! *N")
        hlslens.start()
    end,
})

map("n", "#", "", {
    callback = function()
        vim.fn.execute("normal! #N")
        hlslens.start()
    end,
})

map("n", "<leader>CR", "", {
    -- silent = true,
    desc = "Reload Config",
    callback = function()
        vim.cmd([[
          source $MYVIMRC
        ]])
        vim.notify("Nvim config successfully reloaded", vim.log.levels.INFO, { title = "nvim-config" })
    end,
})

map("t", "<C-j>", "<C-\\><C-N><C-w>j", { remap = false })
map("t", "<C-k>", "<C-\\><C-N><C-w>k", { remap = false })
map("t", "<Esc>", "<C-\\><C-n>", { remap = false })

map("n", "<C-Up>", ":resize +2<CR>")
map("n", "<C-Down>", ":resize -2<CR>")
map("n", "<C-Left>", ":vertical resize +2<CR>")
map("n", "<C-Right>", ":vertical resize -2<CR>")

-- switch buffer
map("n", "<c-l>", ":BufferNext<CR>")
map("n", "<c-h>", ":BufferPrevious<CR>")
map("i", "<c-l>", ":BufferNext<CR>")
map("i", "<c-h>", ":BufferPrevious<CR>")
map("t", "<C-l>", "<C-\\><C-N><C-w>:BufferNext<CR>", { remap = false })
map("t", "<C-h>", "<C-\\><C-N><C-w>:BufferPrevious<CR>", { remap = false })

-- move selected line / block in  v mode
map("x", "K", ":move '<-2<CR>gv-gv'<ESC>")
map("x", "J", ":move '>+1<CR>gv-gv'<ESC>")

-- TAB completion
map("i", "<C-TAB>", "cmp#complete()")

-- vim.cmd([[
--     cnoreabbrev W w
--     cnoreabbrev W! w!
--     cnoreabbrev Wq wq
--     cnoreabbrev wQ wq
--     cnoreabbrev WQ wq
--     cnoreabbrev Wa wa
--     cnoreabbrev Q q
--     cnoreabbrev Q! q!
--     cnoreabbrev Qall! qall!
--     cnoreabbrev Qall qall
-- ]])
