format:
	stylua -v --verify lua/lux-config/

check:
	luacheck lua/lux-config
