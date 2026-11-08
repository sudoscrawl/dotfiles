local config = require("config")


hl.bind(config.modifier .. " + Q", hl.dsp.window.close()) -- close window

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
hl.bind(config.modifier .. " + M", hl.dsp.exec_cmd(config.apps.power_btn))
hl.bind(config.modifier .. " + L", hl.dsp.exec_cmd(config.apps.lock_screen))


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


-- BRIGHTNESS
hl.bind(config.modifier .. " + F9",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 2%+"),                  { locked = true, repeating = true })
hl.bind(config.modifier .. " + F8",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 2%-"),                  { locked = true, repeating = true })
hl.bind(config.modifier .. " + XF86AudioRaiseVolume", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 1%+"), { locked = true, repeating = true})
hl.bind(config.modifier .. " + XF86AudioLowerVolume", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 1%-"), {locked = true, repeating = true})


-- AUDIO CONTROLS
hl.bind(config.modifier .. " + F6", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 1%+"), { locked = true, repeating = true })
hl.bind(config.modifier .. " + F5", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 1%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true})
hl.bind(config.modifier .. " + XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),  {locked = true})
-- pause, previous and next from earphones
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), {locked=true})
hl.bind(config.modifier .. " + SHIFT + XF86AudioRaiseVolume", hl.dsp.exec_cmd("playerctl next"), { locked = true})
hl.bind(config.modifier .. " + SHIFT + XF86AudioLowerVolume", hl.dsp.exec_cmd("playerctl previous"), { locked = true})
-- pause, previous and next from keyboard
hl.bind(config.modifier .. " + GRAVE", hl.dsp.exec_cmd("playerctl play-pause"), {locked = true})
hl.bind(config.modifier .. " + F2", hl.dsp.exec_cmd("playerctl previous"), {locked=true})
hl.bind(config.modifier .. " + F3", hl.dsp.exec_cmd("playerctl next"), {locked=true})


-- SCREENSHOTS
hl.bind(config.modifier .. " + F12", hl.dsp.exec_cmd("hyprshot -m region -o ~/Pictures/Screenshots")) -- custom region
hl.bind(config.modifier .. " + SHIFT + F12", hl.dsp.exec_cmd("hyprshot -m window -o ~/Pictures/Screenshots")) -- select window
hl.bind(config.modifier .. " + CTRL + F12", hl.dsp.exec_cmd("hyprshot -m output -o ~/Pictures/Screenshots")) -- entire screen



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
end, {repeating = true})

hl.bind(config.modifier .. " + CTRL + down", function ()
    resize_window(0, 20)
end, {repeating=true})

hl.bind(config.modifier .. " + CTRL + up", function ()
    resize_window(0, -20)
end, {repeating=true})

hl.bind(config.modifier .. " + CTRL + right", function ()
    resize_window(20, 0)
end, {repeating=true})
