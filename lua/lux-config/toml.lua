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
    local config_dir = vim.fn.stdpath("config")
    ---@cast config_dir string
    local toml_path = vim.fs.joinpath(config_dir, "lux.toml")
    local fd = vim.uv.fs_open(toml_path, "r", 438)
    if not fd then
        vim.schedule(function()
            vim.notify(("lux-config: failed to read %s"):format(toml_path), vim.log.levels.ERROR)
        end)
        return nil
    end
    local stat = vim.uv.fs_fstat(fd)
    if not stat then
        vim.uv.fs_close(fd)
        vim.schedule(function()
            vim.notify(("lux-config: failed to read %s"):format(toml_path), vim.log.levels.ERROR)
        end)
        return nil
    end
    local content = vim.uv.fs_read(fd, stat.size, 0)
    vim.uv.fs_close(fd)

    ---@diagnostic disable-next-line: unresolved-require
    local toml = require("toml_edit").parse_as_tbl(content)
    local neovim = toml.neovim or {}

    return {
        dependencies = normalize_dependencies(toml.dependencies),
        config = neovim.config,
        bundles = neovim.bundles,
    }
end

return M
