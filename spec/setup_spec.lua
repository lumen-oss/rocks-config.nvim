local rocks_config = require("lux-config.internal")

local tempdir = vim.fn.tempname()
vim.system({ "rm", "-r", tempdir }):wait()
vim.system({ "mkdir", "-p", tempdir .. "/lua/plugins" }):wait()
vim.system({ "mkdir", "-p", tempdir .. "/lua/bla" }):wait()
vim.g.rocks_nvim = {
    rocks_path = tempdir,
    config_path = vim.fs.joinpath(tempdir, "rocks.toml"),
}
vim.opt.rtp:append(tempdir)

describe("setup", function()
    it("Loads configs", function()
        local config_content = [[
[plugins]
"foo.nvim" = "1.0.0"
"bar.nvim" = "1.0.0"
"bat.nvim" = { version = "1.0.0", config = "plugins.fledermaus" }

[plugins."bla.nvim"]
version = "1.0.0"

[plugins."bla.nvim".config]
bla = true
]]
        local config = require("rocks.config.internal")
        local fh = assert(io.open(config.config_path, "w"), "Could not open rocks.toml for writing")
        fh:write(config_content)
        fh:close()

        local foo_config_content = [[
vim.g.foo_nvim_loaded = true
]]
        fh = assert(
            io.open(vim.fs.joinpath(tempdir, "lua", "plugins", "foo.lua"), "w"),
            "Could not open config file for writing"
        )
        fh:write(foo_config_content)
        fh:close()
        local bar_config_content = [[
vim.g.bar_nvim_loaded = true
]]
        fh = assert(
            io.open(vim.fs.joinpath(tempdir, "lua", "plugins", "bar-nvim.lua"), "w"),
            "Could not open config file for writing"
        )
        fh:write(bar_config_content)
        fh:close()

        local bat_config_content = [[
vim.g.bat_nvim_loaded = true
]]
        fh = assert(
            io.open(vim.fs.joinpath(tempdir, "lua", "plugins", "fledermaus.lua"), "w"),
            "Could not open config file for writing"
        )
        fh:write(bat_config_content)
        fh:close()

        local bla_module_content = [[
local M = {}
  M.setup = function(opts)
    vim.g.bla_opts = opts
  end
return M
]]
        fh = assert(
            io.open(vim.fs.joinpath(tempdir, "lua", "bla", "init.lua"), "w"),
            "Could not open mock plugin module for writing"
        )
        fh:write(bla_module_content)
        fh:close()
        assert.same("function", type(require("bla").setup))

        vim.opt.runtimepath:append(tempdir)
        rocks_config.setup()
        assert.True(vim.g.foo_nvim_loaded)
        assert.True(vim.g.bar_nvim_loaded)
        assert.True(vim.g.bat_nvim_loaded)
        assert.same(vim.g.bla_opts, { bla = true })
    end)
end)
