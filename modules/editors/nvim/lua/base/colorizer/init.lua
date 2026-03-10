local isOk, colorizer = pcall(require, "colorizer")
if not isOk then
  vim.notify("Colorizer not okay")
  return
end

colorizer.setup({
  filetypes = { "*" },
  user_default_options = {
    RGB = true, -- #RGB hex codes
    RRGGBB = true, -- #RRGGBB hex codes
    RRGGBBAA = true, -- #RRGGBBAA hex codes
    names = true,
    rgb_fn = false, -- CSS rgb() and rgba() functions
    hsl_fn = false, -- CSS hsl() and hsla() functions
    css = true, -- Enable all CSS features: rgb_fn, hsl_fn, names, RGB, RRGGBB
    css_fn = true, -- Enable all CSS *functions*: rgb_fn, hsl_fn
    -- Available modes for `mode`: foreground, background,  virtualtext
    mode = "background", -- Set the display mode.
    -- Available methods are false / true / "normal" / "lsp" / "both"
    -- True is same as normal
    tailwind = true, -- Enable tailwind colors
    -- parsers can contain values used in |user_default_options|
    sass = { enable = true, parsers = { css = true } }, -- Enable sass colors
    virtualtext = "■",
  },
})
-- names    = true;         -- "Name" codes like Blue

-- colorizer.setup({
--   fileypes = { "css", "html", "vue", "javascript", "typescript" },
--   {
--     RGB = true, -- #RGB hex codes
--     RRGGBB = true, -- #RRGGBB hex codes
--     RRGGBBAA = true, -- #RRGGBBAA hex codes
--     names = true,
--     rgb_fn = true, -- CSS rgb() and rgba() functions
--     hsl_fn = true, -- CSS hsl() and hsla() functions
--     css = true, -- Enable all CSS features: rgb_fn, hsl_fn, names, RGB, RRGGBB
--     css_fn = true, -- Enable all CSS *functions*: rgb_fn, hsl_fn
--     tailwind = true,
--     sass = {
--       enable = true,
--       parsers = { "css" },
--     },
--   },
-- })
