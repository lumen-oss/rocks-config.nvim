local constants = require("lux-config.constants")
local toml = require("lux-config.toml")

local rocks_config = {
    duplicate_configs_found = {},
    failed_to_load = {},
}

---@type table<lux-config.rock_name, boolean>
local _configured_rocks = {}

---@class lux-config.Toml: lux-config.Config
---@field dependencies? table<lux-config.rock_name, lux-config.RockSpec>
---@field bundles? table<string, lux-config.Bundle>

---Deduplicates a table that is being used as an array of strings
---@param arr string[]
---@return string[]
local function dedup(arr)
    local res = {}
    local hash = {}

    for _, v in ipairs(arr) do
        if not hash[v] then
            table.insert(res, v)
            hash[v] = true
        end
    end

    return res
end

---Creates plugin heuristics for a given plugin
---@param name string
---@return string[]
local function create_plugin_heuristics(name)
    name = name:gsub("%.", "-")

    return dedup({
        name,
        (name:gsub("[%.%-]n?vim$", ""):gsub("n?vim%-", "")),
        (name:gsub("[%.%-]lua$", ""):gsub("n?vim%-", "")),
        (name:gsub("%.", "-")),
        name .. "-nvim",
    })
end

---Tries to get a loader function for a given module.
---Returns nil if the module is not found.
---@param mod_name string The module name to search for
---@return function | nil
local function try_get_loader_for_module(mod_name)
    ---@diagnostic disable-next-line: access-invisible
    for _, searcher in ipairs(package.loaders) do
        local loader = searcher(mod_name)
        if type(loader) == "function" then
            return loader
        end
    end
end

---Emulates Lua's require mechanism behaviour. Lua's `require` function
---returns `true` if the module returns nothing (`nil`), so we do the same.
---returns `nil` and the error message if the module fails to load.
---@param loader function The loader function
---@return unknown | nil loaded
---@return string | nil err
local function try_load_like_require(loader)
    local ok, module = pcall(loader)
    if not ok then
        return nil, module
    end

    if module == nil then
        return true
    end

    return module
end

---Tries to load a module, without panicking if it is not found.
---Returns `nil` and an error message if the module is found and loading it panics.
---@param mod_name string The module name
---@return boolean | nil loaded
---@return string | nil err
local function try_load_config(mod_name)
    -- Modules can indeed return `false` so we must check specifically
    -- for `nil`.
    if package.loaded[mod_name] ~= nil then
        return true
    end

    local loader = try_get_loader_for_module(mod_name)

    if loader == nil then
        return false
    end

    local mod, err = try_load_like_require(loader)
    if mod == nil then
        return nil, err
    end
    package.loaded[mod_name] = mod

    return true
end

---Checks if a plugin that already had a configuration loaded has
---a given duplicate candidate configuration, and registers the duplicate
---for being checked later.
---@param plugin_name string The plugin that is being configured
---@param config_basename string The basename of the configuration module.
---@param mod_name string The configuration module name to check for
local function check_for_duplicate(plugin_name, config_basename, mod_name)
    local duplicate = try_get_loader_for_module(mod_name)

    if duplicate ~= nil then
        table.insert(rocks_config.duplicate_configs_found, { plugin_name, config_basename })
    end
end

---Load a config and register any errors that happened while trying to load it.
---Returns false if the module was not found and true if it was, even if errors happened.
---@param plugin_name string The plugin that is being configured
---@param config_basename string The basename of the configuration module.
---@param mod_name string The configuration module to load.
---@return boolean
local function load_config(plugin_name, config_basename, mod_name)
    local result, err = try_load_config(mod_name)
    if result == nil and type(err) == "string" then
        -- Module was found but failed to load.
        table.insert(rocks_config.failed_to_load, { plugin_name, config_basename, err })
        return true
    end
    if type(result) ~= "boolean" then
        error(
            "lux-config.nvim: The impossible happened! Please report this bug: try_load_config did not return boolean as expected."
        )
    end
    return result
end

---@param plugin_heuristics string[]
---@param config lux-config.Config
---@param rock lux-config.RockSpec
local function auto_setup(plugin_heuristics, config, rock)
    xpcall(function()
        for _, possible_match in ipairs(plugin_heuristics) do
            local ok, maybe_module = pcall(require, possible_match)
            if ok and type(maybe_module) == "table" and type(maybe_module.setup) == "function" then
                if type(rock.config) == "table" then
                    maybe_module.setup(rock.config)
                elseif (config.config.auto_setup or rock.config == true) and rock.config ~= false then
                    maybe_module.setup()
                end
            end
        end
    end, function(err)
        table.insert(rocks_config.failed_to_load, { rock.name, "auto_setup", err })
    end)
end

---Check if any errors were registered during setup.
---@return number
local function errors_found()
    return #rocks_config.duplicate_configs_found + #rocks_config.failed_to_load
end

---@return lux-config.Toml
local function get_config()
    local lux_toml = toml.get()
    local config = vim.tbl_deep_extend("force", {}, constants.DEFAULT_CONFIG, lux_toml or {})
    ---@cast config lux-config.Toml
    return config
end

---@param rock lux-config.rock_name | lux-config.RockSpec The rock to configure
---@param config? lux-config.Config
function rocks_config.configure(rock, config)
    config = config or get_config()
    if type(rock) == "string" then
        if _configured_rocks[rock] then
            return
        end
        local all_plugins = config.dependencies
        ---@cast all_plugins table<string, lux-config.RockSpec>
        if not all_plugins[rock] then
            vim.notify(("[lux-config.nvim]: Plugin %s not found in lux.toml"):format(rock), vim.log.levels.ERROR)
            return
        end
        rock = all_plugins[rock]
    end
    ---@cast rock lux-config.RockSpec
    local name = rock.name
    if _configured_rocks[name] then
        return
    end
    _configured_rocks[name] = true

    local plugin_heuristics = create_plugin_heuristics(name)

    local found_custom_configuration = false

    for _, possible_match in ipairs(plugin_heuristics) do
        local mod_name = table.concat({ config.config.plugins_dir, possible_match }, ".")

        if found_custom_configuration then
            check_for_duplicate(name, possible_match, mod_name)
        else
            local ok = load_config(name, possible_match, mod_name)
            found_custom_configuration = found_custom_configuration or ok
        end
    end

    -- If there is no custom configuration defined by the user
    -- then check for a rock config or attempt to auto-invoke the setup() function.
    if not found_custom_configuration then
        if type(rock.config) == "string" then
            xpcall(require, function(err)
                table.insert(rocks_config.failed_to_load, { name, rock.config, err })
            end, rock.config)
        elseif
            type(rock.config) == "table"
            or rock.config == true
            or config.config.auto_setup and rock.config ~= false
        then
            auto_setup(plugin_heuristics, config, rock)
        end
    end
end

---@param config lux-config.Toml
---@param rock_name string
---@return lux-config.RockSpec | nil
local function get_rock_from_config(config, rock_name)
    return (config.dependencies or {})[rock_name]
end

---@class lux-config.Bundle
---@field items lux-config.rock_name[]
---@field config? string

---@param config lux-config.Toml
---@param bundle_name string
---@param bundle lux-config.Bundle
local function load_bundle(config, bundle_name, bundle)
    if type(bundle.config) ~= "nil" and type(bundle.config) ~= "string" then
        vim.schedule(function()
            vim.notify(
                string.format(
                    "[lux-config.nvim]: Bundle '%s' has invalid `config` variable. Expected string pointing to a valid path, got %s instead...",
                    bundle_name,
                    type(bundle.config)
                ),
                vim.log.levels.ERROR
            )
        end)
        bundle.config = nil
    end
    local mod_name = bundle.config ~= nil and bundle.config
        or table.concat({ config.config.plugins_dir, bundle_name }, ".")

    local result, err = try_load_config(mod_name)
    if result then
        for _, plugin in ipairs(bundle.items) do
            _configured_rocks[plugin] = true
        end
    elseif result == nil and type(err) == "string" then
        vim.notify(
            string.format(
                [[
[lux-config.nvim]: Bundle '%s' failed to load ('checkhealth lux-config' for details).
Falling back to loading plugins from the bundle individually...
]],
                bundle_name
            ),
            vim.log.levels.WARN
        )
        table.insert(rocks_config.failed_to_load, { bundle_name, vim.inspect(bundle.items), err })
    else
        vim.notify(
            string.format(
                [[
[lux-config.nvim]: Bundle '%s' has no specified configuration file.
Falling back to loading plugins from the bundle individually...
]],
                bundle_name
            ),
            vim.log.levels.WARN
        )
    end
end

---@param bundle_name string The name of the bundle
function rocks_config.load_bundle(bundle_name)
    local config = get_config()
    ---@type string, lux-config.Bundle?
    ---@diagnostic disable-next-line: call-non-callable
    local _, bundle = vim.iter(config.bundles or {}):find(function(name)
        if name == bundle_name then
            return true
        end
        return false
    end)
    if not bundle then
        vim.schedule(function()
            vim.notify(string.format("[lux-config.nvim]: Bundle '%s' not found.", bundle_name), vim.log.levels.ERROR)
        end)
        return
    end

    ---@param rock_name string
    ---@return lux-config.RockSpec | nil
    local function get_rock(rock_name)
        return get_rock_from_config(config, rock_name)
    end
    ---@param item string
    ---@diagnostic disable-next-line: call-non-callable
    local nonexistent_bundle_item = vim.iter(bundle.items):find(function(item)
        return get_rock(item) == nil
    end)
    if nonexistent_bundle_item then
        vim.schedule(function()
            vim.notify(
                string.format(
                    [[
[lux-config.nvim]: Bundle '%s' has invalid plugin '%s'.
Did you make a typo, or is the plugin not installed?
]],
                    bundle_name,
                    nonexistent_bundle_item
                ),
                vim.log.levels.ERROR
            )
        end)
        return
    end
    load_bundle(config, bundle_name, bundle)
end

---@param rock_spec lux-config.rock_name | lux-config.RockSpec
---@return string | nil, lux-config.rock_name[] | nil
function rocks_config.get_bundle(rock_spec)
    local rock_name = type(rock_spec) == "string" and rock_spec or rock_spec.name
    local config = get_config()
    ---@type string, lux-config.Bundle | nil
    ---@diagnostic disable-next-line: call-non-callable
    local name, bundle = vim.iter(config.bundles or {}):find(function(_, b)
        if vim.list_contains(b.items, rock_name) then
            return true
        end
        return false
    end)
    return name, bundle and bundle.items
end

---@param all_plugins? table<lux-config.rock_name, lux-config.RockSpec>
function rocks_config.configure_all(all_plugins)
    local config = get_config()

    ---@param rock_name string
    ---@return lux-config.RockSpec | nil
    local function get_rock(rock_name)
        return get_rock_from_config(config, rock_name)
    end

    ---@diagnostic disable-next-line: inject-field
    config.config.plugins_dir = config.config.plugins_dir:gsub("[%.%/%\\]+$", "")
    if type(config.config.options) == "table" then
        for key, value in pairs(config.config.options) do
            vim.opt[key] = value
        end
    end

    if type(config.bundles) == "table" then
        for bundle_name, bundle in pairs(config.bundles) do
            if type(bundle) == "table" and type(bundle.items) == "table" then
                ---@param item string
                ---@diagnostic disable-next-line: call-non-callable
                local nonexistent_bundle_item = vim.iter(bundle.items):find(function(item)
                    return get_rock(item) == nil
                end)
                if nonexistent_bundle_item then
                    vim.notify(
                        string.format(
                            [[
[lux-config.nvim]: Bundle '%s' has invalid plugin '%s'.
Did you make a typo, or is the plugin not installed?
]],
                            bundle_name,
                            nonexistent_bundle_item
                        ),
                        vim.log.levels.ERROR
                    )
                    goto continue
                end

                local is_opt_bundle = not config.config.load_opt_plugins
                    ---@param item string
                    ---@diagnostic disable-next-line: call-non-callable
                    and vim.iter(bundle.items):any(function(item)
                        local rock = get_rock(item)
                        ---@cast rock lux-config.RockSpec
                        return rock.opt
                    end)
                if is_opt_bundle then
                    goto continue
                end

                load_bundle(config, bundle_name, bundle)
            end

            ::continue::
        end
    end

    all_plugins = all_plugins or config.dependencies or {}
    for _, rock_spec in pairs(all_plugins) do
        ---@cast rock_spec lux-config.RockSpec
        if not rock_spec.opt or config.config.load_opt_plugins then
            rocks_config.configure(rock_spec, config)
        end
    end

    if type(config.config.colorscheme or config.config.colourscheme) == "string" then
        pcall(vim.cmd.colorscheme, config.config.colorscheme or config.config.colourscheme)
    end

    local error_count = errors_found()
    if error_count > 0 then
        vim.notify(
            string.format(
                "%d issue(s) found while loading plugin configs. Run :checkhealth lux-config for more info.",
                error_count
            ),
            vim.log.levels.WARN
        )
    end
end

return rocks_config
