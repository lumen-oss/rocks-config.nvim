local api = require("lux-config")

local tempdir = vim.fn.tempname()
vim.system({ "rm", "-r", tempdir }):wait()
vim.system({ "mkdir", "-p", tempdir .. "/lua/plugins" }):wait()
vim.g.rocks_nvim = {
    rocks_path = tempdir,
    config_path = vim.fs.joinpath(tempdir, "rocks.toml"),
}

describe("Lua API", function()
    it("Loads configs", function()
        local config_content = [[
[plugins]
"foo.nvim" = "1.0.0"
"bar.nvim" = "1.0.0"
"bad-nvim" = "1.0.0"
"bad2-nvim" = "1.0.0"
"opt1.nvim" = { version = "1.0.0", opt = true }
"opt2.nvim" = { version = "1.0.0", opt = true }
"opt3.nvim" = { version = "1.0.0", opt = true }

[bundles.baz]
items = [ "bar.nvim" ]
[bundles.bad_bundle]
items = [ "bad2-nvim" ]

[bundles.opt_bundle]
items = [
  "opt1.nvim",
  "opt2.nvim",
  "opt3.nvim"
]
]]
        local config = require("rocks.config.internal")
        local fh = assert(io.open(config.config_path, "w"), "Could not open rocks.toml for writing")
        fh:write(config_content)
        fh:close()
        local plugin_config_content = [[
vim.g.foo_nvim_loaded = true
]]
        fh = assert(
            io.open(vim.fs.joinpath(tempdir, "lua", "plugins", "foo.lua"), "w"),
            "Could not open plugin config file for writing"
        )
        fh:write(plugin_config_content)
        fh:close()
        local bundle_config_content = [[
vim.g.baz_bundle_loaded = true
]]
        fh = assert(
            io.open(vim.fs.joinpath(tempdir, "lua", "plugins", "baz.lua"), "w"),
            "Could not open bundle config file for writing"
        )
        fh:write(bundle_config_content)
        fh:close()
        local bad_plugin_config_content = [[
vim.g.bad_nvim_loaded = true
error("This should fail gracefully")
]]
        fh = assert(
            io.open(vim.fs.joinpath(tempdir, "lua", "plugins", "bad.lua"), "w"),
            "Could not open bad plugin config file for writing"
        )
        fh:write(bad_plugin_config_content)
        fh:close()
        local bad_bundle_config_content = [[
vim.g.bad_bundle_loaded = true
error("This should fail gracefully")
]]
        fh = assert(
            io.open(vim.fs.joinpath(tempdir, "lua", "plugins", "bad_bundle.lua"), "w"),
            "Could not open bad bundle config file for writing"
        )
        fh:write(bad_bundle_config_content)
        fh:close()
        local opt_bundle_config_content = [[
vim.g.opt_bundle_loaded = true
]]
        fh = assert(
            io.open(vim.fs.joinpath(tempdir, "lua", "plugins", "opt_bundle.lua"), "w"),
            "Could not open bad bundle config file for writing"
        )
        fh:write(opt_bundle_config_content)
        fh:close()
        vim.opt.runtimepath:append(tempdir)
        api.configure("foo.nvim")
        assert.True(vim.g.foo_nvim_loaded)
        assert.is_nil(vim.g.baz_bundle_loaded)
        require("lux-config.internal").setup()
        assert.True(vim.g.baz_bundle_loaded)
        assert.True(vim.g.bad_bundle_loaded)
        api.configure("bad.nvim")
        assert.True(vim.g.foo_nvim_loaded)
        assert.is_nil(vim.g.opt_bundle_loaded)
        local bundle_items
        api.configure("opt1.nvim", {
            load_bundle_pre = function(items)
                bundle_items = items
            end,
        })
        assert.True(vim.g.opt_bundle_loaded)
        assert.same({
            "opt1.nvim",
            "opt2.nvim",
            "opt3.nvim",
        }, bundle_items)
    end)
end)
