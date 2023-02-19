local ll_ok, ll = pcall(require, "lualine")
if not ll_ok then
  vim.notify('lualine not okay')
  return
    end

local lsp_status_ok, lsp_status = pcall(require, "lsp-status")
if not lsp_status_ok then
	vim.notify("lsp-status not okay in lualine")
end

local lspstatus = function ()
  local status = ''
  if table.maxn(vim.lsp.buf_get_clients()) > 0 then
    status = lsp_status.status()
  end
  return status
end

local get_lsp_client = function()
  local msg = "LSP Inactive " .. lspstatus()
  local buf_ft = vim.api.nvim_buf_get_option(0, "filetype")
  local clients = vim.lsp.get_active_clients()
  if next(clients) == nil then
    return msg
  end
  local lsps = ""
  for _, client in ipairs(clients) do
    local filetypes = client.config.filetypes
    if filetypes and vim.fn.index(filetypes, buf_ft) ~= -1 then
      if lsps == "" then
        lsps = client.name
      else
        if not string.find(lsps, client.name) then
          lsps = lsps .. ", " .. client.name
        end
      end
    end
  end
  if lsps == "" then
    return msg
  else
    return lsps .. lspstatus()
  end
end

local M = {}
M.config = function()
  local config = ll.get_config()
  config.sections.lualine_c = {"filename", "lsp_progress"}
  config.sections.lualine_x = {{get_lsp_client}, 'encoding', 'fileformat', 'filetype'}
  config.options.extensions = { "quickfix", "fugitive",}
  if O.colorscheme == 'catppuccin' then
    config.options.theme = O.colorscheme
  else
    config.options.theme = "tokyonight"
  end
  ll.setup(config)
end

return M
