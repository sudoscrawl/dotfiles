local config = require("config")


hl.bind(config.modifier .. " + Q", hl.dsp.window.close())

hl.bind(config.modifier .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(config.modifier .. " + F", hl.dsp.window.fullscreen({ action = "toggle" }))

-- FOCUS
hl.bind(config.modifier .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(config.modifier .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(config.modifier .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(config.modifier .. " + down", hl.dsp.focus({ direction = "down" }))


-- APPLICATIONS
hl.bind(config.modifier .. " + T", hl.dsp.exec_cmd(config.apps.terminal))
hl.bind(config.modifier .. " + B", hl.dsp.exec_cmd(config.apps.browser))
hl.bind(config.modifier .. " + E", hl.dsp.exec_cmd(config.apps.file_manager))
hl.bind(config.modifier .. " + R", hl.dsp.exec_cmd(config.apps.launcher))


-- WORKSPACES
for i = 1, 10 do
    local key = i % 10

    hl.bind(
        config.modifier .. " + " .. key, 
        hl.dsp.focus({ workspace = i })
    )

    hl.bind(
        config.modifier .. " + SHIFT + " .. key,
        hl.dsp.window.move({ workspace = i })
    
    )
end

-- SPECIAL KEYS
hl.bind(config.modifier .. " + F6", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind(config.modifier .. " + F5", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind(config.modifier .. " + F9",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind(config.modifier .. " + F8",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })


-- SCREENSHOTS
hl.bind(config.modifier .. " + PRINT", hl.dsp.exec_cmd("hyprshot -m region -o ~/Pictures/Screenshots"))
hl.bind(config.modifier .. " + SHIFT + PRINT", hl.dsp.exec_cmd("hyprshot -m window -o ~/Pictures/Screenshots"))
hl.bind(config.modifier .. " + CTRL + PRINT", hl.dsp.exec_cmd("hyprshot -m output -o ~/Pictures/Screenshots")) 



-- RESIZE

local function resize_window(dw, dh)
    hl.dispatch(hl.dsp.window.resize({
        x = dw,
        y = dh,
        relative = true,
    }))
end

hl.bind(config.modifier .. " + CTRL + left", function ()
    resize_window(-20, 0)
end)

hl.bind(config.modifier .. " + CTRL + down", function ()
    resize_window(0, 20)
end)

hl.bind(config.modifier .. " + CTRL + up", function ()
    resize_window(0, -20)
end)

hl.bind(config.modifier .. " + CTRL + right", function ()
    resize_window(20, 0)
end)


-- LOCK
hl.bind(config.modifier .. " + l", hl.dsp.exec_cmd(config.apps.lock_screen))

