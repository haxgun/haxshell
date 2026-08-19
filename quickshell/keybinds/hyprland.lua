-- Installed to ~/.config/hypr/naton/keybinds.lua and included from hyprland.lua via: require("naton.keybinds")
local mainMod = "SUPER"
local natonctl = "$HOME/.config/quickshell/natonctl"

hl.bind(mainMod .. " + SPACE",      hl.dsp.exec_cmd(natonctl .. " ipc drawer toggle"))
hl.bind(mainMod .. " + comma",      hl.dsp.exec_cmd(natonctl .. " ipc settings toggle"))
hl.bind(mainMod .. " + V",          hl.dsp.exec_cmd(natonctl .. " ipc clipboard toggle"))
hl.bind(mainMod .. " + N",          hl.dsp.exec_cmd(natonctl .. " ipc notifications toggle"))
hl.bind(mainMod .. " + X",          hl.dsp.exec_cmd(natonctl .. " ipc power toggle"))
hl.bind(mainMod .. " + C",          hl.dsp.exec_cmd(natonctl .. " ipc control-center toggle"))
hl.bind(mainMod .. " + T",          hl.dsp.exec_cmd(natonctl .. " ipc calendar toggle"))
hl.bind(mainMod .. " + M",          hl.dsp.exec_cmd(natonctl .. " ipc media toggle"))
hl.bind(mainMod .. " + W",          hl.dsp.exec_cmd(natonctl .. " ipc wifi toggle"))
hl.bind(mainMod .. " + B",          hl.dsp.exec_cmd(natonctl .. " ipc bluetooth toggle"))
hl.bind(mainMod .. " + L",          hl.dsp.exec_cmd(natonctl .. " ipc brightness toggle"))
hl.bind(mainMod .. " + K",          hl.dsp.exec_cmd(natonctl .. " ipc keyboard toggle"))
hl.bind(mainMod .. " + I",          hl.dsp.exec_cmd(natonctl .. " ipc system toggle"))
hl.bind(mainMod .. " + SHIFT + Q",  hl.dsp.exec_cmd(natonctl .. " ipc shell reload"))
