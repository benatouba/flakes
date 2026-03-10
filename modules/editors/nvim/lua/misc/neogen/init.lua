local status_ok, neogen = pcall(require, 'neogen')
if not status_ok then return end

neogen.setup {
    enabled = true,
    jump_map = "<C-n>",
    languages = {
        lua = {template = {annotation_convention = "emmylua"}},
        python = {template = {annotation_conventions = "nummpydoc"}},
        javascript = {template = {annotation_convention = "jsdoc"}}
    }
}
