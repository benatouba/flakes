if !filereadable($HOME . '/.config/nvim/init.lua')
	if !filereadable($HOME . '/.config/nvim/init.vim')
		echo 'Loading global setup'
		set runtimepath-=/root/.config/nvim
		luafile '/etc/xdg/nvim/init.lua'
	endif
endif
