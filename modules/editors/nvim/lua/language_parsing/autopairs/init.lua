-- if not package.loaded['nvim-autopairs'] then

--   return
-- end
local status_ok, autopairs = pcall(require, "nvim-autopairs")
if not status_ok then return end
local Rule = require "nvim-autopairs.rule"
local cond = require('nvim-autopairs.conds')

-- skip it, if you use another global object
_G.MUtils = {}

vim.g.completion_confirm_key = ""
MUtils.completion_confirm = function()
    if vim.fn.pumvisible() ~= 0 then
        if vim.fn.complete_info()["selected"] ~= -1 then
            return vim.fn["cmp.mappings.confirm"](autopairs.esc "<cr>")
        else
            return autopairs.esc "<cr>"
        end
    else
        return autopairs.autopairs_cr()
    end
end

autopairs.setup {
    check_ts = true,
    ts_config = {
        lua = {"string"}, -- it will not add pair on that treesitter node
        javascript = {"template_string"},
        java = false -- don't check treesitter on java
    }
}

require("nvim-treesitter.configs").setup {autopairs = {enable = true}}

local ts_conds = require "nvim-autopairs.ts-conds"

-- press % => %% is only inside comment or string
autopairs.add_rules {
    Rule("%", "%", "lua"):with_pair(ts_conds.is_ts_node {"string", "comment"}),
    Rule("$", "$", "lua"):with_pair(ts_conds.is_not_ts_node {"function"}),
    Rule("$", "$",{"tex", "latex"}),
    Rule("%", "%", "sls")
}
