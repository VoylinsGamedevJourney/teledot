# TeleDot
A Teleprompter solution made with Godot. Use it as a stand-alone app on your phone, or use your phone with your pc as the controller!

## How use TeleDot?

You have a view application and a controller application. Have the view on your phone or extra monitor, open the application and that is it. It will display the ip and port to connect to the view. Next up open the controller application, configure your settings and shortcuts, add your script to the script box and that's it. The script box works with BBCode and is also displayed using BBCode.

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

## Translations
TeleDot controller has been translated to following languages by following people:

- English: Voylin;
- Japanese: Voylin;
- French: Slander;
- Chinese: Aappaapp.

## Support this project
[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/R6R4M1UM6)
[Patreon page](https://patreon.com/voylin)
