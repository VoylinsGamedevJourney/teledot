extends ColorRect

# TODO: Add shortcuts to switch between Script view and preview view
# TODO: Make scripts saving/deleting/loading work


const SETTINGS_FILE := "user://settings"

const PORT := 55757
var client: StreamPeerTCP
var status = -1

var screensaver_img: Texture


func _ready() -> void:
	load_settings()
	$Screensaver.visible = false


func _process(_delta: float) -> void:
	if client == null: return
	client.poll()
	# Checking status
	if client.get_status() != status:
		status = client.get_status()
		connection_changed()


func connection_changed() -> void:
	set_connection_text()
	
	# Sending all necesarry data to view
	if status == client.STATUS_CONNECTED: 
		send_command("change_script", %ScriptTextEdit.text)
		var settings := FileAccess.open(SETTINGS_FILE, FileAccess.READ)
		var settings_data: Dictionary = settings.get_var()
		settings.close()
		for setting in settings_data:
			send_command("change_%s" % setting, settings_data[setting])


func set_connection_text(_status: int = status) -> void:
	var text: PackedStringArray
	match _status:
		client.STATUS_NONE:       text = ["gray", "no connection"]
		client.STATUS_ERROR:      text = ["red", "error"]
		client.STATUS_CONNECTING: text = ["purple", "connecting"]
		client.STATUS_CONNECTED:  text = ["green", "connected"]
	%NetworkStatusLabel.text = "Status: [i][color=%s]%s[/color][/i]" % text


func send_command(key:String, value) -> void:
	if client == null: return
	if client.get_status() == 2: client.put_var([key,value])


func _on_script_panel_tab_changed(_tab: int) -> void:
	%ScriptPreview.text = %ScriptTextEdit.text
	%ScriptPreview.get_parent().scroll_horizontal = %ScriptTextEdit.get_parent().scroll_horizontal
	%ScriptPreview.get_parent().scroll_vertical = %ScriptTextEdit.get_parent().scroll_vertical


func _on_script_text_edit_changed() -> void:
	send_command("change_script", %ScriptTextEdit.text)


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


func save_setting(key: String, value) -> void:
	var settings_file := FileAccess.open(SETTINGS_FILE, FileAccess.READ)
	var settings_data: Dictionary = settings_file.get_var()
	settings_file.close()
	settings_data[key] = value
	settings_file = FileAccess.open(SETTINGS_FILE, FileAccess.WRITE)
	settings_file.store_var(settings_data)


func load_settings() -> void:
	if !FileAccess.file_exists(SETTINGS_FILE):
		var default_file := FileAccess.open(SETTINGS_FILE,FileAccess.WRITE)
		default_file.store_var({
			"color_background": %FontColorPicker.color,
			"scroll_speed": %ScrollSpeedSpinBox.value,
			"color_text": %FontColorPicker.color,
			"alignment": %AlignmentOptionButton.selected,
			"font_size": %FontSizeSpinBox.value,
			"mirror": %MirrorOptionButton.selected,
			"margin": %MarginSpinBox.value,
			})
		return
	var settings_file := FileAccess.open(SETTINGS_FILE, FileAccess.READ)
	var settings_data: Dictionary = settings_file.get_var()
	for setting in settings_data:
		match setting:
			"alignment": 
				%AlignmentOptionButton.selected = settings_data[setting]
			"mirror": 
				%MirrorOptionButton.selected = settings_data[setting]
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
			_: printerr("Could not find setting: %s" % setting)


# TODO: Screensaver
func _on_screen_saver_button_pressed() -> void:
	# TODO: When pressed, go fullscreen
	# TODO: Display screensaver
	# TODO: when pressed again or esc pressed, exit screensaver mode
	pass
