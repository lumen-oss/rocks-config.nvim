if vim.g.loaded_lux_config_nvim then
    return
end

vim.g.loaded_lux_config_nvim = true

require("lux-config").configure_all()
