local neotest_ok, neotest = pcall(require, "neotest")
if not neotest_ok then
  vim.notify("Neotest not okay")
  return
end

local M = {}

function M.config()
  local lib = require("neotest.lib")
  local get_env = function()
    local env = {}
    local file = ".env"
    if not lib.files.exists(file) then
      return {}
    end

    for _, line in ipairs(vim.fn.readfile(file)) do
      for name, value in string.gmatch(line, "(%S+)=['\"]?(.*)['\"]?") do
        local str_end = string.sub(value, -1, -1)
        if str_end == "'" or str_end == '"' then
          value = string.sub(value, 1, -2)
        end

        env[name] = value
      end
    end
    return env
  end

  neotest.setup({
    -- log_level = vim.log.level.WARN,
    status = {
      virtual_text = true,
      signs = true,
    },
    icons = {
      running_animated = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
    },
    strategies = {
      integrated = {
        width = 180,
      },
    },
    adapters = {
      require("neotest-python")({
        dap = { justMyCode = true },
        args = { "--log-level", "DEBUG" },
        runner = "pytest",
      }),
      require("neotest-vitest")({
        ignore_file_types = { "python" },
      }),
      require("neotest-vim-test")({
        ignore_file_types = { "python" },
      }),
    },
  })

  local mappings = {
    ["<leader>dr"] = function()
      neotest.run.run({ vim.fn.expand("%:p"), env = get_env() })
    end,
    ["<leader>ds"] = function()
      for _, adapter_id in ipairs(neotest.run.adapters()) do
        neotest.run.run({ suite = true, adapter = adapter_id, env = get_env() })
      end
    end,
    ["<leader>dw"] = function()
      neotest.watch.watch()
    end,
    ["<leader>dx"] = function()
      neotest.run.stop()
    end,
    ["<leader>dn"] = function()
      neotest.run.run({ env = get_env() })
    end,
    ["<leader>dd"] = function()
      neotest.run.run({ strategy = "dap", env = get_env() })
    end,
    ["<leader>dl"] = neotest.run.run_last,
    ["<leader>dD"] = function()
      neotest.run.run_last({ strategy = "dap" })
    end,
    ["<leader>da"] = neotest.run.attach,
    ["<leader>do"] = function()
      neotest.output.open({ enter = true })
    end,
    ["<leader>dO"] = function()
      neotest.output.open({ enter = true, short = true })
    end,
    ["<leader>dp"] = neotest.summary.toggle,
    ["<leader>dm"] = neotest.summary.run_marked,
    ["[n"] = function()
      neotest.jump.prev({ status = "failed" })
    end,
    ["]n"] = function()
      neotest.jump.next({ status = "failed" })
    end,
  }

  for keys, mapping in pairs(mappings) do
    vim.api.nvim_set_keymap("n", keys, "", { callback = mapping, noremap = true })
  end

  local mappings = {
    t = {
      name = "+test",
      a = { "<cmd>lua require('neotest').run.attach()<CR>", "Attach to nearest" },
      A = { "<cmd>lua require('neotest').run.adapters()<CR>", "Adapter list" },
      d = { "<cmd>lua require('neotest').run.run({strategy = 'dap', env = get_env() })<CR>", "Debug Test" },
      f = { "<cmd>lua require('neotest').run.run({ vim.fn.expand('%'), env = get_env() })<CR>", "Test File" },
      l = { "<cmd>lua require('neotest').run.run_last<CR>", "Last Test" },
      o = { "<cmd>lua require('neotest').output.open({ enter = true })<CR>", "Output" },
      O = { "<cmd>lua require('neotest').output.open({ enter = true, short = true })<CR>", "Output" },
      s = { "<cmd>lua require('neotest').summary.toggle<CR>", "Summary" },
      t = { "<cmd>lua require('neotest').run.run()<CR>", "Test Nearest" },
      w = { "<cmd>lua require('neotest').watch.watch()<CR>", "watch" },
      x = { "<cmd>lua require('neotest').run.stop()<CR>", "Stop" },
    },
  }
  require("which-key").register(mappings, { mode = "n", prefix = "<leader>" })

  local jumps = {
    ["[T"] = { "<cmd>lua require('neotest').jump.prev({ status = 'failed' })<CR>", "Test (failed)" },
    ["]T"] = { "<cmd>lua require('neotest').jump.next({ status = 'failed' })<CR>", "Test (failed)" },
  }
  require("which-key").register(jumps, { mode = "n", prefix = "" })
end
return M
