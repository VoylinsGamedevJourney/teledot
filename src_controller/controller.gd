extends ColorRect

# TODO: Add shortcuts to switch between Script view and preview view
# TODO: Make scripts saving/deleting/loading work
# TODO: Save settings and load+set everything on startup
# TODO: On connection send everything


const NET_STATUS := "Status: [i]%s[/i]"

const PORT := 55757
var client: StreamPeerTCP
var status = -1


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
				# Send text color
				# Send background color
				# Send margin
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
