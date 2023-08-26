extends ColorRect

## TeleDot controller's job is to connect to the TeleDot view and
## send all necesarry data. This data includes commands and settings.
##
## Full list of possible commands and settings data which can
## be send, can be found within the main script of TeleView.


enum LANGUAGE {ENGLISH, JAPANESE, FRENCH, CHINESE_TAIWAN}

# Paths:
const SETTINGS_FILE := "user://settings"

# Connection variables:
const port := 55757
var client: StreamPeerTCP
var status = client.STATUS_NONE
var listener : PacketPeerUDP


func _ready() -> void:
	version_check_request()
	# Hiding the screensaver incase it was visible when building.
	$Screensaver.visible = false
	load_settings()
	set_connection_text()
	
	# Server finder
	listener = PacketPeerUDP.new()
	var ok = listener.bind(port)
	
	if ok == OK:
		print("bound to: " + str(port))
	else:
		print("failed to bind to: " + str(port))


func version_check_request() -> void:
	const version_url := "https://raw.githubusercontent.com/voylin/TeleDot/master/src_controller/version.json"
	var http_request := HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(self.version_check)
	var error = http_request.request(version_url)
	if error != OK: print_debug("Could not get version json")


func version_check(_result, response_code, _headers, body) -> void:
	var result: String = body.get_string_from_utf8()
	if response_code == 404 or result.length() < 5: 
		print("Received version file info invalid")
		return
	var json = JSON.new()
	json.parse(result)
	var current_version: Dictionary = json.data
	var file := FileAccess.open("res://version.json", FileAccess.READ)
	json.parse(file.get_as_text())
	var local_version: Dictionary = json.data
	var update_available := false
	if current_version.latest_stable.major > local_version.latest_stable.major:
		update_available = true
	elif current_version.latest_stable.minor > local_version.latest_stable.minor:
		update_available = true
	elif current_version.latest_stable.patch > local_version.latest_stable.patch:
		update_available = true
	%UpdateAvailableLabel.visible = update_available


func _process(_delta: float) -> void:
	if get_viewport().gui_get_focus_owner() == null:
		if Input.is_action_just_released("play_pause"):
			get_viewport().gui_release_focus()
			send_command("command_play_pause", null)
		if Input.is_action_pressed("move_down"):
			send_command("command_move_down", null)
		if Input.is_action_pressed("move_up"):
			send_command("command_move_up", null)
		if Input.is_action_pressed("jump_beginning"):
			send_command("command_jump_beginning", null)
		if Input.is_action_pressed("jump_end"):
			send_command("command_jump_end", null)
		if Input.is_action_just_pressed("page_up"):
			send_command("command_page_up", null)
		if Input.is_action_just_pressed("page_down"):
			send_command("command_page_down", null)

	# Do not go further when no connection has been made yet.
	if client != null:
		# Checking connection status with TeleDot View
		client.poll()
		var current_status := client.get_status()
		if current_status != status:
			if status == client.STATUS_CONNECTED:
				_on_connection_button_pressed()
			status = current_status
			connection_changed()
	# Auto grabs and IP and connects if enabled
	elif listener.is_bound() && listener.get_available_packet_count() > 0:
		listener.get_packet() 
		%IPLineEdit.text = str(listener.get_packet_ip())
		%PortLineEdit.text = str(listener.get_packet_port())
		
		if %AutoConnectButton.button_pressed:
			_on_connection_button_pressed()
		#Closes the listener after getting the relevant information to avoid manually entered IPS from being overwritten
		listener.close()


func _input(event: InputEvent) -> void:
	# Switching tab commands:
	if event.is_action_pressed("switch_tab_script"):  %ScriptPanel.current_tab = 0
	if event.is_action_pressed("switch_tab_preview"): %ScriptPanel.current_tab = 1
	if event.is_action_pressed("switch_tab_double"):  %ScriptPanel.current_tab = 2
	
	# Shortcut commands
	if event.is_action_pressed("show_screensaver"):
		get_viewport().gui_release_focus()
		if $Screensaver.visible:
			get_window().mode = Window.MODE_WINDOWED
		else:
			get_window().mode = Window.MODE_FULLSCREEN
		$Screensaver.visible = !$Screensaver.visible
	
	if event.is_action_pressed("release_focus"):
		get_viewport().gui_release_focus()
		if get_node("Screensaver").visible:
			get_window().mode = Window.MODE_WINDOWED
			get_node("Screensaver").visible = false
	
	if event.is_action_pressed("decrease_speed"):
		%ScrollSpeedSpinBox.value -= 1
	if event.is_action_pressed("increase_speed"):
		%ScrollSpeedSpinBox.value += 1


func connection_changed() -> void:
	set_connection_text()
	
	# Sending all necesarry data to view
	if status == client.STATUS_CONNECTED: 
		send_command("change_script", %ScriptTextEdit.text)
		var settings := FileAccess.open(SETTINGS_FILE, FileAccess.READ)
		var settings_data: Dictionary = settings.get_var()
		settings.close()
		for setting in settings_data:
			if setting in ["language", "ip"]: continue
			send_command("change_%s" % setting, settings_data[setting])


func set_connection_text(_status: int = status) -> void:
	var text: Array = [tr("NETWORK_STATUS")]
	match _status:
		client.STATUS_NONE:       text.append_array(["gray", tr("NETWORK_STATUS_NO_CONNECTION")])
		client.STATUS_ERROR:      text.append_array(["red", tr("NETWORK_STATUS_ERROR")])
		client.STATUS_CONNECTING: text.append_array(["purple", tr("NETWORK_STATUS_CONNECTING")])
		client.STATUS_CONNECTED:  text.append_array(["green", tr("NETWORK_STATUS_CONNECTING")])
		_: text = ["red", _status]
	%NetworkStatusLabel.text = "%s [i][color=%s]%s[/color][/i]" % text


func send_command(key:String, value) -> void:
	if client == null: return
	if client.get_status() == 2: client.put_var([key,value])


func _on_connection_button_pressed() -> void:
	if client == null:
		# Start connection
		%ConnectionButton.text = "Stop connection"
		status = client.STATUS_NONE
		client = StreamPeerTCP.new()
		client.connect_to_host(%IPLineEdit.text, int(%PortLineEdit.text.strip_edges()))
	else:
		# Stop connection
		%ConnectionButton.text = "Start connection"
		client = null
		set_connection_text(client.STATUS_NONE)
	get_viewport().gui_release_focus()


func _on_alignment_option_item_selected(index: int) -> void:
	save_setting("alignment", index)
	send_command("change_alignment", index)
func _on_mirror_option_button_item_selected(index: int) -> void:
	save_setting("mirror", index)
	send_command("change_mirror", index == 1)
func _on_font_color_picker_changed(_color: Color) -> void:
	save_setting("color_text", _color)
	send_command("change_color_text", _color)
func _on_background_color_picker_changed(_color: Color) -> void:
	save_setting("color_background", _color)
	send_command("change_color_background", _color)
func _on_margin_spin_box_value_changed(value: float) -> void:
	save_setting("margin", value)
	send_command("change_margin", value)
func _on_scroll_speed_spin_box_value_changed(value: float) -> void:
	save_setting("scroll_speed", value)
	send_command("change_scroll_speed", value)
func _on_font_size_spin_box_value_changed(value: float) -> void:
	save_setting("font_size", value)
	send_command("change_font_size", value)
func _on_language_option_button_item_selected(value: int) -> void:
	save_setting("language", value)
	set_language(value)
func _on_auto_connect_button_toggled(button_pressed):
	save_setting("auto_connect", button_pressed)


func set_language(value:int) -> void:
	match value:
		LANGUAGE.ENGLISH:
			TranslationServer.set_locale("en")
		LANGUAGE.JAPANESE:
			TranslationServer.set_locale("ja")
		LANGUAGE.FRENCH:
			TranslationServer.set_locale("fr")
		LANGUAGE.CHINESE_TAIWAN:
			TranslationServer.set_locale("zh_TW")
	# Set tab translations correctI was thinking for the auto connect maybe having 
	%ScriptPanel.get_child(0).name = "%s (ctrl+1)" % tr("TAB_SCRIPT")
	%ScriptPanel.get_child(1).name = "%s (ctrl+2)" % tr("TAB_PREVIEW")
	%ScriptPanel.get_child(2).name = "%s (ctrl+3)" % tr("TAB_SIDE_BY_SIDE")


func save_setting(key: String, value) -> void:
	var settings_file := FileAccess.open(SETTINGS_FILE, FileAccess.READ)
	var settings_data: Dictionary = settings_file.get_var()
	settings_file.close()
	settings_data[key] = value
	settings_file = FileAccess.open(SETTINGS_FILE, FileAccess.WRITE)
	settings_file.store_var(settings_data)


func load_settings() -> void:
	var settings_data: Dictionary = get_settings()
	for setting in settings_data:
		match setting:
			"alignment":
				%AlignmentOptionButton.select(settings_data[setting])
			"mirror":
				%MirrorOptionButton.select(settings_data[setting])
			"color_text":
				%FontColorPicker.color = settings_data[setting]
			"color_background":
				%FontColorPicker.color = settings_data[setting]
			"margin":
				%MarginSpinBox.value = settings_data[setting]
			"scroll_speed":
				%ScrollSpeedSpinBox.value = settings_data[setting]
			"font_size":
				%FontSizeSpinBox.value = settings_data[setting]
			"language":
				%LanguageOptionButton.select(settings_data[setting])
				set_language(settings_data[setting])
			"ip":
				%IPLineEdit.text = settings_data[setting]
			"auto_connect":
				%AutoConnectButton.button_pressed = settings_data[setting]
			_:
				printerr("Could not find setting: %s" % setting)


func get_settings() -> Dictionary:
	var settings: Dictionary
	if !FileAccess.file_exists(SETTINGS_FILE):
		# Default Settings
		settings = {
			"color_background": %BackgroundColorPicker.color,
			"scroll_speed": %ScrollSpeedSpinBox.value,
			"color_text": %FontColorPicker.color,
			"alignment": %AlignmentOptionButton.selected,
			"font_size": %FontSizeSpinBox.value,
			"mirror": %MirrorOptionButton.selected,
			"margin": %MarginSpinBox.value,
			"language": %LanguageOptionButton.selected,
			"ip": get_default_ip(),
			"auto_connect": %AutoConnectButton.button_pressed,
		}
		FileAccess.open(SETTINGS_FILE, FileAccess.WRITE).store_var(settings)

		# Possible TODO for later, Godot automatically selects your
		# system language, we could use this info to save the system
		# locale directly without having English as the default.
		set_language(%LanguageOptionButton.selected)
	else:
		settings = FileAccess.open(SETTINGS_FILE, FileAccess.READ).get_var()
	return settings


func get_default_ip() -> String:
	for x in IP.get_local_addresses():
		if x.count(".") == 3 and !x.begins_with("127"):
			return x
		else:
			continue
		break
	return "127.0.0.1"


func _on_script_tab_text_changed() -> void:
	%sbsTextEdit.text = %ScriptTextEdit.text
	%sbsPreview.text = %ScriptTextEdit.text
	%ScriptPreview.text = %ScriptTextEdit.text
	%ScriptPreview.get_parent().scroll_horizontal = %ScriptTextEdit.get_parent().scroll_horizontal
	%ScriptPreview.get_parent().scroll_vertical = %ScriptTextEdit.get_parent().scroll_vertical
	send_command("change_script", %ScriptTextEdit.text)


func _on_sbs_tab_text_changed() -> void:
	%ScriptTextEdit.text = %sbsTextEdit.text
	%sbsPreview.text = %sbsTextEdit.text
	%ScriptPreview.get_parent().scroll_horizontal = %ScriptTextEdit.get_parent().scroll_horizontal
	%ScriptPreview.get_parent().scroll_vertical = %ScriptTextEdit.get_parent().scroll_vertical
	send_command("change_script", %ScriptTextEdit.text)


func _on_screen_saver_button_pressed() -> void:
	var file_explorer := FileDialog.new()
	file_explorer.title = "Select Screensaver"
	file_explorer.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_explorer.size = Vector2i(600,600)
	file_explorer.access = FileDialog.ACCESS_FILESYSTEM
	add_child(file_explorer)
	file_explorer.file_selected.connect(change_screensaver)
	file_explorer.popup_centered()


func change_screensaver(path: String) -> void:
	var tex := ImageTexture.new()
	var image := Image.load_from_file(path)
	tex.set_image(image)
	$Screensaver/ScreensaverTexture.texture = tex


func _on_remove_focus_button_pressed(_e:int = 0) -> void:
	get_viewport().gui_release_focus()


func _on_ip_line_edit_text_submitted(_new_text: String) -> void:
	_on_connection_button_pressed()
	get_viewport().gui_release_focus()
# Explanation of why this is commented is bellow
#	%PortLineEdit.grab_focus()
#	%PortLineEdit.caret_column = %PortLineEdit.text.length()


func _on_ip_line_edit_text_changed(new_text: String) -> void:
	save_setting("ip", new_text)


# Port is being hidden for now as there is no way of changing the port
# in view anyway. Maybe we could check if the port is actually open
# on TeleDot View and make it choose a different port, but that's
# probably for a later moment if this were to become an issue.
func _on_port_line_edit_text_submitted(_new_text: String) -> void:
	_on_connection_button_pressed()
	get_viewport().gui_release_focus()


func _on_update_available_label_meta_clicked(meta) -> void:
	OS.shell_open(meta)


func _on_reset_ip_pressed() -> void:
	save_setting("ip", get_default_ip())
	load_settings()

func _exit_tree():
	if listener.is_bound():
		listener.close()
