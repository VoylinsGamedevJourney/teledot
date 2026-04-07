# TeleDot
A Teleprompter solution made with Godot. This standalone app is all you need for your teleprompting needs.

## Features
- **Standalone teleprompter:** Easily edit, format, and scroll through your scripts;
- **Bluetooth controller support:** Control playback, speed, and scroll using any Bluetooth media remote or keyboard;
- **NeoVim integration:** Seamlessly send scripts directly from your code editor;

## How use TeleDot?
TeleDot is a standalone application. Simply create a new script inside the app, configure your settings (scroll speed, font size, margin, mirroring), and start the teleprompter!

### Bluetooth Controller Controls
You can control the teleprompter using a connected Bluetooth keyboard/remote:
- **Play/Pause:** `Space` or `Play/Pause button`
- **Speed Up:** `Right arrow` or `Next track`
- **Speed Down:** `Left arrow` or `Previous track`
- **Scroll Up/Down:** `Up/Down arrows`
- **Exit Prompter:** `Escape`, `Backspace`, or `Back Button`

### Send with NeoVim
```lua
vim.api.nvim_create_user_command("Teledot", function()
	local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t")
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local text = filename .. "\n" .. table.concat(lines, "\n")

	local client = vim.loop.new_tcp()
	client:connect("127.0.0.1", 4242, function(err)
		if err then
			vim.schedule(function()
				vim.notify("Teledot: connect failed — " .. err, vim.log.levels.ERROR)
			end)
			return
		end

		client:write(text, function(write_err)
			if write_err then
				vim.schedule(function()
					vim.notify("Teledot: write failed — " .. write_err, vim.log.levels.ERROR)
				end)
			end
			client:shutdown()
			client:close()
		end)
	end)
end, {})

vim.keymap.set("n", "<leader>t", ":Teledot<CR>")
```

## Support this project
[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/R6R4M1UM6)
[Patreon page](https://patreon.com/voylin)
