local constants = require("rocks-config.constants")

local rocks_config = {}

---
---@param name string
local function create_plugin_heuristics(name)
    name = name:gsub("%.", "-")

    return {
        name,
        name:gsub("[%.%-]n?vim$", ""):gsub("n?vim%-", ""),
        name .. "-nvim",
    }
end

function rocks_config.setup(user_configuration)
    local config = vim.tbl_deep_extend("force", constants.DEFAULT_CONFIG, user_configuration or {})

    config.config.plugins_dir = config.config.plugins_dir:gsub("[%.%/%\\]+$", "")

    for name, _ in pairs(user_configuration.plugins or {}) do
        local plugin_heuristics = create_plugin_heuristics(name)

        for _, possible_match in ipairs(plugin_heuristics) do
            local search = table.concat({ config.config.plugins_dir, possible_match }, ".")

            local ok, err = pcall(require, search)

            if not ok and type(err) == "string" and not err:match("module%s+." .. search:gsub("%p", "%%%1") .. ".%s+not%s+found") then
                error(err)
            end
        end
    end
end

return rocks_config
