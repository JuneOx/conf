--------------------------------
-- Author: Gregor Best        --
-- Copyright 2009 Gregor Best --
--------------------------------

local setmetatable = setmetatable
local tonumber = tonumber
local io = {
    popen = io.popen
}
local string = {
    match  = string.match,
    find   = string.find,
    format = string.format
}
local capi = {
    widget = widget,
}
local awful = require("awful")

module("obvious.volume_alsa")

local cardid  = 0
local channel = "Master"

widget = capi.widget({
    type  = "textbox",
    name  = "tb_volume",
    align = "right"
})

function get_data()
    local rv = { }
    local fd = io.popen("amixer -c " .. cardid .. " -- sget " .. channel)
    if not fd then return end
    local status = fd:read("*all")
    fd:close()

    rv.volume = tonumber(string.match(status, "(%d?%d?%d)%%"))
    if not rv.volume then return end

    status = string.match(status, "%[(o[^%]]*)%]")
    if string.find(status, "on", 1, true) then
        rv.mute = false
    else
        rv.mute = true
    end

    return rv
end

local function update()
    local status = get_data()

    local color = "#900000"
    if not status.mute then
        color = "#009000"
    end
    widget.text = "<span color=\"" .. color .. "\">☊</span> " .. string.format("%03d%%", status.volume)
end

function raise(v)
    v = v or 1
    awful.util.spawn("amixer -q -c " .. cardid .. " sset " .. channel .. " " .. v .. "+", false)
    update()
end

function lower(v)
    v = v or 1
    awful.util.spawn("amixer -q -c " .. cardid .. " sset " .. channel .. " " .. v .. "-", false)
    update()
end

function mute()
    awful.util.spawn("amixer -c " .. cardid .. " sset " .. channel .. " toggle > /dev/null", false)
    update()
end

function setcardid(id)
    cardid = id
end

function setchannel(c)
    channel = c
end

widget:buttons(awful.util.table.join(
    awful.button({ }, 4, function () raise() end),
    awful.button({ }, 5, function () lower() end),
    awful.button({ }, 1, function () mute() end)
))

update()
awful.hooks.timer.register(10, update)

setmetatable(_M, { __call = function () return widget end })
