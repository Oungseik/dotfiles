local wezterm = require("wezterm")

local config = wezterm.config_builder()

config.color_scheme = "Catppuccin Macchiato"

config.enable_tab_bar = false
config.enable_wayland = true

config.font = wezterm.font("JetBrainsMono NF", { weight = "Regular", stretch = "Normal" })
config.font_size = 12.5
config.front_end = "WebGpu"

config.window_background_opacity = 0.95

config.window_padding = {
	left = 1,
	right = 1,
	top = 1,
	bottom = 1,
}

return config
