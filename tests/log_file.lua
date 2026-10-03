-- Run from the mod directory: lua tests/log_file.lua
local levels = {"none", "error", "warning", "action", "info", "verbose", "trace"}
for _, configuration in ipairs({
    {engine = "info", expected = 5},
    {engine = "verbose", override = "warning", expected = 3},
    {engine = "info", override = "inherit", expected = 5},
    {engine = "info", override = "off", expected = 0},
    {engine = "", expected = 0},
}) do
    local forwarded, delegated = {}, {}
    minetest = {
        settings = {get = function(_, name)
            if name == "mtui.log_level" then return configuration.override end
            return configuration.engine
        end},
        log = function(...)
            delegated[#delegated + 1] = {...}
            return "native-result"
        end,
    }
    mtui = {send_command = function(command)
        forwarded[#forwarded + 1] = command
    end}
    dofile("log_file.lua")
    for _, level in ipairs(levels) do
        assert(minetest.log(level, level) == "native-result")
    end
    assert(#forwarded == configuration.expected)
    for index, command in ipairs(forwarded) do
        assert(command.data.message == levels[index])
    end
    assert(minetest.log("single argument") == "native-result")
    assert(#delegated == #levels + 1 and #delegated[#delegated] == 1)
end
print("PASS: severity filtering before queueing, native calls preserved")
