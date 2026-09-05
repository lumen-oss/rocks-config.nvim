--[[
Example rocks.toml:
```toml
[plugins]
"neorg" = "6.0.0-1"

[config]
plugins_dir = "plugins/"
```
--]]

vim.g.rocks_config_nvim_loaded = true

---@type rocks.hooks.Action
return {
    type = "Action",
    hook = function(...)
        require("lux-config.internal").setup(...)
    end,
}
