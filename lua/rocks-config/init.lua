local constants = require("rocks-config.constants")

local rocks_config = {}

---
---@param name string
local function create_plugin_heuristics(name)
    name = name:gsub("%.", "-")

    return {
        name,
        name:gsub("[%.%-]n?vim$", ""):gsub("n?vim%-", ""),
        name:gsub("%.", "-"),
        name .. "-nvim",
    }
end

function rocks_config.setup(user_configuration)
    if not user_configuration or type(user_configuration) ~= "table" then
        return
    end

    local config = vim.tbl_deep_extend("force", constants.DEFAULT_CONFIG, user_configuration or {})

    config.config.plugins_dir = config.config.plugins_dir:gsub("[%.%/%\\]+$", "")

    for name, data in pairs(user_configuration.plugins or {}) do
        local plugin_heuristics = create_plugin_heuristics(name)

        local found_custom_configuration = false

        for _, possible_match in ipairs(plugin_heuristics) do
            local search = table.concat({ config.config.plugins_dir, possible_match }, ".")

            local ok, err = pcall(require, search)

            if
                not ok
                and type(err) == "string"
                and not err:match("module%s+." .. search:gsub("%p", "%%%1") .. ".%s+not%s+found")
            then
                error(err)
            end

            found_custom_configuration = found_custom_configuration or ok
        end

        -- If there is no custom configuration defined by the user then attempt to autoinvoke the setup() function.
        if not found_custom_configuration and (config.config.auto_setup or data.config) then
            for _, possible_match in ipairs(plugin_heuristics) do
                local ok, maybe_module = pcall(require, possible_match)

                if ok and type(maybe_module) == "table" and type(maybe_module.setup) == "function" then
                    if type(data.config) == "table" then
                        maybe_module.setup(data.config)
                    elseif config.config.auto_setup or data.config == true then
                        maybe_module.setup()
                    end
                end
            end
        end
    end
end

return rocks_config
