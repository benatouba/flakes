local M = {}

M.config = function()
  local dap_ok, dap = pcall(require, "dap")
  if not dap_ok then
    return
  end
  dap.configurations.lua = {
    {
      type = 'nlua',
      request = 'attach',
      name = "Attach to running Neovim instance",
      host = function()
        local value = vim.fn.input('Host [127.0.0.1]: ')
        if value ~= "" then
          return value
        end
        return '127.0.0.1'
      end,
      port = function()
        local val = tonumber(vim.fn.input('Port: '))
        assert(val, "Please provide a port number")
        return val
      end,
    }
  }

  dap.adapters.nlua = function(callback, config)
    callback({ type = 'server', host = config.host, port = config.port })
  end

  local which_key_ok, which_key = pcall(require, 'which-key')
  if not which_key_ok then
    return
  end
  which_key.register({
    v = {
      name = "vimkind",
      d = {"<cmd>lua require'osv'.run_this()<cr>", "this file"},
      S = {"<cmd>lua require'osv'.launch()<cr>", "Start server"}
    }
  }, {prefix = "<leader>d"})

end

return M
