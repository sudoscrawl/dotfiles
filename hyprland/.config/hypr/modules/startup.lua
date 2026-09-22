local config = require("config")

hl.on("hyprland.start", function()
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("swaync")
    hl.exec_cmd("quickshell -c newbar")
    hl.exec_cmd("hypridle")
end)
