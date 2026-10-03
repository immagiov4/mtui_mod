local old_log = minetest.log
local log_levels = {none = 0, error = 1, warning = 2, action = 3, info = 4, verbose = 5, trace = 6}
-- Filtering must happen before the HTTP queue; the engine filters only its own outputs.
local configured_level = minetest.settings:get("mtui.log_level") or "inherit"
if configured_level == "inherit" then
    configured_level = minetest.settings:get("debug_log_level") or "action"
end
local maximum_level = (configured_level == "" or configured_level == "off") and -1
    or log_levels[configured_level]
assert(maximum_level, "Invalid MTUI log level: " .. configured_level)
local logfile_level_mapping = {
    ["none"] = "logfile",
    ["error"] = "logfile-error",
    ["warning"] = "logfile-warning",
    ["action"] = "logfile-action",
    ["info"] = "logfile-info",
    ["verbose"] = "logfile-verbose",
    ["trace"] = "logfile-trace",
}

function minetest.log(level, msg)
    if type(level) == "string" and type(msg) == "string"
            and (log_levels[level] or log_levels.none) <= maximum_level then
        -- TODO: parse out online player-names, mod-prefix, position(s?)
        local event = logfile_level_mapping[level]
        if not event then
            event = "logfile"
        end

        mtui.send_command({
            type = "log",
            data = {
                category = "minetest",
                event = event,
                message = msg
            }
        })
    end

    if not msg then
        -- call with a single parameter only (the engine checks param-count, not var-type)
        return old_log(level)
    else
        return old_log(level, msg)
    end
end
