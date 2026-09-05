local health = {}

local rocks_config = require("lux-config.internal")

local function check_for_load_errors()
    vim.health.start("Checking for errors while loading configs")

    local errors = rocks_config.failed_to_load

    if #errors == 0 then
        vim.health.ok("No configuration errors.")
        return
    end

    for _, dupe in ipairs(errors) do
        local plugin_name, config_basename, error = unpack(dupe)
        vim.health.error(
            ("Error while loading config '%s.lua' for '%s'."):format(config_basename, plugin_name),
            { ("Error was: %s"):format(error) }
        )
    end
end

local function check_for_duplicates()
    vim.health.start("Checking for duplicate configuration files")

    local dupes = rocks_config.duplicate_configs_found

    if #dupes == 0 then
        vim.health.ok("No duplicate configurations found.")
        return
    end

    for _, dupe in ipairs(dupes) do
        local plugin_name, config_basename = unpack(dupe)
        vim.health.warn(
            ("Duplicate configuration found for plugin '%s' in file '%s.lua'. Skipping."):format(
                plugin_name,
                config_basename
            )
        )
    end
end

function health.check()
    check_for_load_errors()
    check_for_duplicates()
end

return health
