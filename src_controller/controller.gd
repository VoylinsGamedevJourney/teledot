extends ColorRect

# TODO: Add shortcuts to switch between Script view and preview view
# TODO: Make scripts saving/deleting/loading work
# TODO: Save settings and load+set everything on startup
# TODO: On connection send everything


const NET_STATUS := "Status: [i]%s[/i]"

const PORT := 55757
var client: StreamPeerTCP
var status = -1

var screensaver_img: Texture


func _ready() -> void:
	$Screensaver.visible = false


func _process(_delta: float) -> void:
	if client == null: return
	client.poll()
	# Checking status
	if client.get_status() != status:
		status = client.get_status()
		match status:
			client.STATUS_NONE: 
				%NetworkStatusLabel.text = NET_STATUS % "[color=grey]no connection[/color]"
			client.STATUS_ERROR: 
				%NetworkStatusLabel.text = NET_STATUS % "[color=red]Error[/color]"
			client.STATUS_CONNECTING: 
				%NetworkStatusLabel.text = NET_STATUS % "[color=orange]connecting ...[/color]"
			client.STATUS_CONNECTED: 
				%NetworkStatusLabel.text = NET_STATUS % "[color=grey]connected[/color]"
				# TODO: Send all data once
				send_command("change_script", %ScriptTextEdit.text)
				send_command("change_alignment", %AlignmentOptionButton.selected) 
				send_command("change_mirror", %MirrorOptionButton.selected == 1)
				send_command("change_color_text", %FontColorPicker.color)
				send_command("change_color_background", %FontColorPicker.color)
				send_command("change_margin", %MarginSpinBox.value)
				send_command("change_scroll_speed", %ScrollSpeedSpinBox.value)
				# Send font size
				# Send scroll speed


func send_command(key:String, value) -> void:
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
		client = StreamPeerTCP.new()
		client.connect_to_host(%IPLineEdit.text, int(%PortLineEdit.text.strip_edges()))
		status = client.STATUS_NONE
	else:
		# Stop connection
		%ConnectionButton.text = "Start connection"
		client = null
		%NetworkStatusLabel.text = NET_STATUS % "[color=grey]no connection[/color]"


func _on_alignment_option_item_selected(index: int) -> void:
	send_command("change_alignment", index)


func _on_mirror_option_button_item_selected(index: int) -> void:
	send_command("change_mirror", index == 1)


func _on_font_color_picker_changed(color: Color) -> void:
	send_command("change_color_text", color)


func _on_background_color_picker_changed(color: Color) -> void:
	send_command("change_color_background", color)


func _on_margin_spin_box_value_changed(value: float) -> void:
	send_command("change_margin", value)


# TODO: Screensaver
func _on_screen_saver_button_pressed() -> void:
	# TODO: When pressed, go fullscreen
	# TODO: Display screensaver
	# TODO: when pressed again or esc pressed, exit screensaver mode
	pass


func _on_scroll_speed_spin_box_value_changed(value: float) -> void:
	send_command("change_scroll_speed", value)
	pass # Replace with function body.
