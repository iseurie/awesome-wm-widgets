local awful = require("awful")
local beautiful = require("beautiful")
local naughty = require("naughty")
local wibox = require("wibox")
local timer = require("gears.timer")

local HOME = os.getenv("HOME")

local PWR_DIR = "/sys/class/power_supply/"

local textbox = wibox.widget {
	id = "txt",
	font = "Play 5",
	widget = wibox.widget.textbox
}

local textbox_mirrored = wibox.container.mirror(textbox)
local textbox_mirrored_wbg = wibox.container.background(textbox_mirrored)

local batteryarc = wibox.container.mirror(wibox.widget {
	textbox_mirrored_wbg,
    max_value = 1,
    rounded_edge = true,
    thickness = 1.5,
    start_angle = 4.71238898, -- 2pi*3/4
    forced_height = 17,
    forced_width = 17,
    bg = "#ffffff11",
    paddings = 2,
    widget = wibox.container.arcchart,
    set_value = function(self, value)
        self.value = value
    end,

	battery_state = {
		index = 0,
		status = "",
		charge = 0,
	},

	init = function (self, index)
		self.update_bat_state(index)
	end,

	read_bat_prop = function(self, prop)
		local index = self.battery_state.index
		local bat_path = PWR_DIR.."BAT"..index
		local f, err = io.open(bat_path.."/"..prop, "r")
		if err then
			naughty.notify({ preset = naughty.config.presets.critical,
							 title = "Cannot read battery "..index.." "..prop,
							 text = "error: "..err })
			return nil
		end
		ret = f:read("*all")
		f:close()
		return ret
	end,

	update_bat_state = function(self)
		local charge_now = tonumber(self.read_bat_prop(self, "charge_now")) or 0
		local charge_full = tonumber(self.read_bat_prop(self, "charge_full")) or 0
		self.battery_state.status = self.read_bat_prop(self, "status") or "..."
		self.battery_state.charge = charge_now / charge_full * 100
		self.repaint(self)
	end,

	repaint = function(self)
		self.set_value(self, self.battery_state.charge / 100)
		textbox.text = self.battery_state.charge
		if status == 'Charging' then
			textbox_mirrored_wbg.bg = beautiful.widget_green
			textbox_mirrored_wbg.fg = beautiful.widget_black
		else
			textbox_mirrored_wbg.bg = beautiful.widget_transparent
			textbox_mirrored_wbg.fg = beautiful.widget_main_color
		end

		if self.battery_state.charge <= 15 then
            self.colors = { beautiful.widget_red }
            if self.battery_state.status ~= 'Charging' then
                show_battery_warning()
            end
        elseif self.battery_state.charge > 15 and self.battery_state.charge < 40 then
            self.colors = { beautiful.widget_yellow }
        else
            self.colors = { beautiful.widget_main_color }
        end
	end
}, { horizontal = true }).widget

-- mirror the widget, so that chart value increases clockwise
batteryarc_widget = batteryarc

timer {
	timeout = 5,
	autostart = true,
	callback = batteryarc.update_bat_state(batteryarc)
}

-- Popup with battery info
-- One way of creating a pop-up notification - naughty.notify
local notification
function show_battery_status()
    awful.spawn.easy_async([[bash -c 'acpi']],
        function(stdout, _, _, _)
            notification = naughty.notify {
                text = stdout,
                title = "Battery status",
                timeout = 5,
                hover_timeout = 0.5,
                width = 200,
            }
        end)
end

batteryarc:connect_signal("mouse::enter", function() show_battery_status() end)
batteryarc:connect_signal("mouse::leave", function() naughty.destroy(notification) end)

-- Alternative to naughty.notify - tooltip. You can compare both and choose the preferred one

--battery_popup = awful.tooltip({objects = {battery_widget}})

-- To use colors from beautiful theme put
-- following lines in rc.lua before require("battery"):
-- beautiful.tooltip_fg = beautiful.fg_normal
-- beautiful.tooltip_bg = beautiful.bg_normal

--[[ Show warning notification ]]
function show_battery_warning()
    naughty.notify {
        icon = HOME .. "/.config/awesome/nichosi.png",
        icon_size = 100,
        text = "Houston, we have a problem",
        title = "Battery is dying",
        timeout = 5,
        hover_timeout = 0.5,
        position = "bottom_right",
        bg = "#F06060",
        fg = "#EEE9EF",
        width = 300,
    }
end
