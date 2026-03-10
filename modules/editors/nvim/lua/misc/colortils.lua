local M = {}
local isOk, colortils = pcall(require, 'colortils')
if not isOk then
	vim.notify('Colortils not okay')
	return
end

M.config = function()
	colortils.setup()
	local maps = {
		C = {
			name = "+Colors",
			c = { "<cmd>Colortils css list<cr>", "CSS Colors list" },
			d = { "<cmd>Colortils darken<cr>", "Darken" },
			g = { "<cmd>Colortils gradient<cr>", "Gradient" },
			G = { "<cmd>Colortils greyscale<cr>", "Greyscale" },
			l = { "<cmd>Colortils lighten<cr>", "Lighten" },
			p = { "<cmd>Colortils picker<cr><cr>", "Picker" },
		}
	}
	which_key.register(nmaps, {
		mode = "n", -- NORMAL mode
		prefix = "<leader>",
	})
end
