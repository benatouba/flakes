vim.fn.sign_define(
  "DiagnosticSignError",
  { texthl = "DiagnosticSignError", text = "", numhl = "DiagnosticSignError" }
)
vim.fn.sign_define(
  "DiagnosticSignWarning",
  { texthl = "DiagnosticSignWarning", text = "", numhl = "DiagnosticSignWarning" }
)
vim.fn.sign_define("DiagnosticSignHint", { texthl = "DiagnosticSignHint", text = "", numhl = "DiagnosticSignHint" })
vim.fn.sign_define("DiagnosticSignInfo", { texthl = "DiagnosticSignInfo", text = "", numhl = "DiagnosticSignInfo" })

-- LSP Enable diagnostics
vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
  virtual_text = false,
  underline = true,
  signs = true,
  update_in_insert = true,
  severity_sort = true,
})

local border_style = {
  { "╭", "FloatBorder" },
  { "─", "FloatBorder" },
  { "╮", "FloatBorder" },
  { "│", "FloatBorder" },
  { "╯", "FloatBorder" },
  { "─", "FloatBorder" },
  { "╰", "FloatBorder" },
  { "│", "FloatBorder" },
}

local pop_opts = { border = border_style }
vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, pop_opts)
vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, pop_opts)

local lsp_defaults = {
  flags = {
    debounce_text_changes = 150,
  },
  capabilities = require("cmp_nvim_lsp").default_capabilities(vim.lsp.protocol.make_client_capabilities()),
  on_attach = function(client, bufnr)
    vim.api.nvim_exec_autocmds("User", { pattern = "LspAttached" })
  end,
}

local lspconfig_ok, lspconfig = pcall(require, "lspconfig")
if not lspconfig_ok then
  vim.notify("lspconfig not okay in lspconfig")
  return
end

local lsp_status_ok, lsp_status = pcall(require, "lsp-status")
if not lsp_status_ok then
  vim.notify("lsp-status not okay in lspconfig")
end
lsp_status.register_progress()

lspconfig.util.default_config = vim.tbl_deep_extend("force", lspconfig.util.default_config, lsp_defaults)

local installed_servers = { "pyright" }
for _, server in ipairs(installed_servers) do
  lspconfig[server].setup({})
end

local runtime_path = vim.split(package.path, ";")
table.insert(runtime_path, "lua/?.lua")
table.insert(runtime_path, "lua/?/init.lua")
lspconfig.lua_ls.setup({
  settings = {
    Lua = {
      runtime = {
        version = "LuaJIT",
        path = runtime_path,
      },
      diagnostics = {
        enable = true,
        globals = { "vim" },
      },
      workspace = {
        library = {
          vim.api.nvim_get_runtime_file("", true),
        },
        maxPreload = 10000,
        preloadFileSize = 1000,
      },
      telemetry = {
        enable = false,
      },
    },
  },
})

lspconfig.sourcery.setup({
  filetypes = { "python" },
  init_options = {
    token = "user_re1CDsCNaWsCXRrWENblMoIhU8INKHMGuiqQDG1FG0CKWTC7Td_93Ilq7FA",
    extension_version = "vim.lsp",
    editor_version = "vim",
  },
  settings = {
    sourcery = {
      metricsEnabled = false,
    },
  },
})

lspconfig.pylsp.setup({
  plugins = {
    autopep8 = { enabled = false },
    flake8 = { enabled = false },
    pycodestyle = { enabled = false },
    pyflakes = { enabled = false },
    -- pydocstyle = {enabled = false},
    pylint = { enabled = false },
    rope_autimport = { enabled = true },
    rope_completion = { enabled = true },
    black = { enabled = false },
    yapf = { enabled = false },
    -- jedi = {auto_import_modules = ["numpy", "pandas", "salem", "matplotlib"]}
  },
})


-- local opts = {}
-- opts.capabilities = capabilities
-- opts.on_attach = lsp_status.on_attach

-- lspconfig.ansiblels.setup({})
-- lspconfig.bashls.setup({})
-- lspconfig.clangd.setup({})
-- lspconfig.cmake.setup({})
-- lspconfig.cssls.setup({})
-- lspconfig.dockerls.setup({})
-- lspconfig.fortls.setup({})
-- lspconfig.gopls.setup({})
-- -- lspconfig.grammarly.setup({})
-- lspconfig.html.setup({})
-- -- lspconfig.jedi_language_server.setup {  }
-- lspconfig.jsonls.setup({})
-- -- lspconfig.ltex.setup({})
-- lspconfig.pylsp.setup({})
-- -- lspconfig.pyright.setup {  }
-- -- lspconfig.remark_ls.setup({})
-- lspconfig.rls.setup({})
-- lspconfig.rust_analyzer.setup({})
-- lspconfig.salt_ls.setup({})
-- lspconfig.sqls.setup({})
-- lspconfig.taplo.setup({})
-- lspconfig.texlab.setup({})
-- lspconfig.tsserver.setup({})
-- lspconfig.vimls.setup({})
-- lspconfig.volar.setup({})
-- -- lspconfig.vuels.setup {  }
-- lspconfig.yamlls.setup({})

-- .init_options = {
--   config = {
--     css = {},
--     emmet = {},
--     html = {
--       suggest = {}
--     },
--     javascript = {
--       format = {}
--     },
--     stylusSupremacy = {},
--     typescript = {
--       format = {}
--     },
--     vetur = {
--       completion = {
--         autoImport = false,
--         tagCasing = "kebab",
--         useScaffoldSnippets = false
--       },
--       format = {
--         defaultFormatter = {
--           js = "prettier",
--           ts = "none"
--         },
--         defaultFormatterOptions = {},
--         scriptInitialIndent = false,
--         styleInitialIndent = false
--       },
--       useWorkspaceDependencies = false,
--       validation = {
--         script = true,
--         style = true,
--         template = true
--       }
--     }
--   }
-- }
-- lspconfig.vuels.setup { opts }
