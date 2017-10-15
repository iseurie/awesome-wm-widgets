local awful = require("awful")
local beautiful = require("beautiful")
local wibox = require("wibox")
local timer = require("gears.timer")

volumearc = wibox.widget {
    max_value = 1,
    thickness = 1,
    start_angle = 4.71238898, -- 2pi*3/4
    forced_height = 17,
    forced_width = 17,
    bg = "#ffffff11",
    paddings = 2,
    widget = wibox.container.arcchart,
	audio_state = { volume = 0, mute = 0 },
    set_value = function(self, value)
        self.value = value
    end,

	init = function(self)
		self.fetch_audio_state(self)
		self.repaint(self)
	end,

	update_audio_volume = function(self, delta)
		local cmd = string.format("amixer -D pulse sset Master %d%%",
								  math.abs(delta))..((delta > 0) and '+' or '-')
		self.audio_state.volume = self.audio_state.volume + delta
		awful.spawn(cmd)
		self.repaint(self)
	end,

	toggle_audio_mute = function(self)
		awful.spawn("amixer -D pulse sset Master toggle")
		self.audio_state.mute = not self.audio_state.mute
		self.repaint(self)
	end,

	repaint = function(self)
		if self.audio_state.mute then
			self.colors = { beautiful.widget_red }
		else
			self.colors = { beautiful.widget_main_color }
		end
		self.set_value(self, self.audio_state.volume / 100)
	end,

	fetch_audio_state = function(self)
		awful.spawn.easy_async("amixer -D pulse sget Master", function(stdout, stderr, exitreason, exitcode)
			local volume = string.match(stdout, "(%d?%d?%d)%%")
			self.audio_state.volume = tonumber(string.format("% 3d", volume))
			self.audio_state.mute = string.match(stdout, "%[(o%D%D?)%]") == "off"
			self.repaint(self)
		end)
	end,
}

volumearc_widget = wibox.container.mirror(volumearc, { horizontal = true })

volumearc:connect_signal("button::press", function(_, _, _, button)
    if (button == 4) then awful.spawn(INC_VOLUME_CMD, false)
    elseif (button == 5) then awful.spawn(DEC_VOLUME_CMD, false)
    elseif (button == 1) then awful.spawn(TOG_VOLUME_CMD, false)
    end
	volumearc.repaint(volumearc)
	end
)

timer {
	timeout = 3,
	autostart = true,
	callback = volumearc.fetch_audio_state(volumearc)
}
