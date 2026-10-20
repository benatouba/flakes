-- Use NUL-separated paths, not the ambiguous newline-based chooser format.
local selection = ya.sync(function()
	local paths = {}
	for _, url in pairs(cx.active.selected) do
		paths[#paths + 1] = tostring(url)
	end
	if #paths == 0 then
		local hovered = cx.active.current.hovered
		if not hovered then
			return paths
		elseif hovered.cha.is_dir then
			ya.emit("enter", {})
			return paths
		end
		paths[1] = tostring(hovered.url)
	end
	return paths
end)

return {
	entry = function()
		local paths = selection()
		if #paths == 0 then
			return
		end
		local ok, err = fs.write(Url(os.getenv("MAIL_PICKER_OUTPUT")), table.concat(paths, "\0") .. "\0")
		if not ok then
			ya.notify({ title = "Mail attachments", content = tostring(err), level = "error", timeout = 5 })
			return
		end
		ya.emit("quit", {})
	end,
}
