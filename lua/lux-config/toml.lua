---@mod lux-config.toml Reads and parses ~/.config/nvim/lux.toml

local M = {}

---@class lux-config.DependencyEntry
---@field version? string
---@field opt? boolean
---@field config? string | boolean | table

---@param dependencies table<string, string | lux-config.DependencyEntry>
---@return table<string, lux-config.RockSpec>
local function normalize_dependencies(dependencies)
    local plugins = {}
    for name, spec in pairs(dependencies or {}) do
        if type(spec) == "string" then
            plugins[name] = { name = name, version = spec, opt = false }
        elseif type(spec) == "table" then
            plugins[name] = {
                name = name,
                version = spec.version,
                opt = spec.opt == true,
                config = spec.config,
            }
        end
    end
    return plugins
end

---@return lux-config.Toml | nil
function M.get()
    local toml_path = vim.fs.joinpath(vim.fn.stdpath("config"), "lux.toml")
    local fh = io.open(toml_path, "r")
    if not fh then
        return nil
    end
    local content = fh:read("*a")
    fh:close()

    local toml = require("toml_edit").parse_as_tbl(content)
    local neovim = toml.neovim or {}

    return {
        plugins = normalize_dependencies(toml.dependencies),
        config = neovim.config,
        bundles = neovim.bundles,
    }
end

return M
