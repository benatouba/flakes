local tk_ok, tk = pcall(require, "telekasten")
if not tk_ok then
	vim.notify("Telekasten not okay")
	return
end

local M = {}

M.config = function()
	local home = vim.fn.expand("~/Documents/vivere")
	local temporal = home .. "/" .. "calendar"

	tk.setup({
		home = home,
		take_over_my_home = true,
		auto_set_filetype = true,
		dailies = temporal .. "/" .. "daily",
		weeklies = temporal .. "/" .. "weekly",
		templates = home .. "/" .. "templates",
		extension = ".md",
		follow_creates_nonexisting = true,
		dailies_create_nonexisting = true,
		weeklies_create_nonexisting = true,
		template_new_note = home .. "/" .. "templates/new.md",
		template_new_daily = home .. "/" .. "templates/daily.md",
		template_new_weekly = home .. "/" .. "templates/weekly.md",
		image_link_style = "wiki",
		plug_into_calendar = true,
		calendar_opts = {
			weeknm = 4,
			calendar_monday = 1,
			calendar_mark = "left-fit",
		},
		close_after_yanking = false,
		insert_after_inserting = true,
		tag_notation = "#tag",
	})
end

return M
