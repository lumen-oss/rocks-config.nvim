local rocks_config = require("lux-config.internal")

local tempdir = vim.fn.tempname()
vim.system({ "rm", "-r", tempdir }):wait()
vim.system({ "mkdir", "-p", tempdir .. "/lua/plugins" }):wait()
vim.system({ "mkdir", "-p", tempdir .. "/lua/bla" }):wait()
vim.opt.runtimepath:append(tempdir)

describe("setup", function()
    it("Loads configs", function()
        stub(vim.fn, "stdpath", function(_)
            return tempdir
        end)
        local config_content = [[
[dependencies]
"foo.nvim" = "1.0.0"
"bar.nvim" = "1.0.0"
"bat.nvim" = { version = "1.0.0", config = "plugins.fledermaus" }
"bla.nvim" = { version = "1.0.0", config = { bla = true } }
]]
        local fh = assert(io.open(vim.fs.joinpath(tempdir, "lux.toml"), "w"), "Could not open lux.toml for writing")
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

        rocks_config.configure_all()
        assert.True(vim.g.foo_nvim_loaded)
        assert.True(vim.g.bar_nvim_loaded)
        assert.True(vim.g.bat_nvim_loaded)
        assert.same(vim.g.bla_opts, { bla = true })
    end)
end)
