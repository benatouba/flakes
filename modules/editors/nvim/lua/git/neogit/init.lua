local isOk, neogit = pcall(require, "neogit")
if not isOk then
    vim.notify('Neogit not okay')
end

neogit.setup {
    disable_signs = false,
    disable_context_highlighting = false,
    -- customize displayed signs
    signs = {
        -- { CLOSED, OPENED }
        section = {">", "v"},
        item = {">", "v"},
        hunk = {"", ""}
    },
    integrations = {diffview = true},
    -- override/add mappings
    mappings = {
        -- modify status buffer mappings
        status = {
            -- Adds a mapping with "B" as key that does the "BranchPopup" command
            ["B"] = "BranchPopup",
            -- Removes the default mapping of "s"
            ["s"] = ""
        }
    }
}
