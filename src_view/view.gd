extends ColorRect

## Each var that gets send should be [function_name, value]
## List of possible commands which can be send:
## change_color_background (Color)
## change_color_text (Color)
## change_script (String)
##
## Commands:
## command_play_pause
## command_move_up
## command_move_down


# TODO: Set margin feature
# TODO: Set mirroring feature
# TODO: Set alignment



const port := 55757

var connected := false
var server: TCPServer
var connection : StreamPeerTCP
var client_status: int = -1

var base_script: String
var formatted_script: String
var alignment: int = 1

var scroll_speed: int = 2
var play: bool = false


func _ready() -> void:
	start_server()


func start_server() -> void:
	$NoConnection.visible = true
	
	# Initialize server
	$Script.visible = false
	server = TCPServer.new()
	server.listen(port)
	$NoConnection.visible = true
	%IPLabel.text = "IP: %s" % IP.get_local_addresses()[0]


func _process(delta: float) -> void:
	if play: %ScriptScroll.scroll_vertical += 2* delta
	if server.is_connection_available(): 
		connection = server.take_connection()
	if connection != null:
		connection.poll()
		if client_status != connection.get_status():
			client_status = connection.get_status()
			$Script.visible = true
		if client_status != connection.STATUS_CONNECTED:
			connection = null
			start_server()
			client_status = -1
			return
		if connection.get_available_bytes() == null:
			var data: Array = connection.get_var()
			if data.size() == 2:
				self.call(data[0], data[1])
				if data[0] == "change_alignment":
					change_script()
			else: self.call(data[0])


func change_color_background(new_color: Color = Color8(0,0,0)) -> void:
	self.self_modulate = new_color
func change_color_text(new_color: Color = Color8(255,255,255)) -> void:
	%Script.self_modulate = new_color
func change_script(text: String = base_script) -> void:
	base_script = text
	change_alignment()
	%Script.text = text
func change_alignment(new_align: int = alignment) -> void:
	alignment = new_align
	match alignment:
		0: # Left
			formatted_script = "[left]%s[/left]" % base_script
		1: # Center
			formatted_script = "[center]%s[/center]" % base_script
		2: # Right
			formatted_script = "[right]%s[/right]" % base_script
func change_mirror(mirror: bool) -> void:
	$Script.flip_h = mirror
func change_margin(margin: int) -> void:
	%ScriptMargin.add_theme_constant_override("margin_left", margin)
	%ScriptMargin.add_theme_constant_override("margin_right", margin)
func change_scroll_speed(speed: int) -> void:
	scroll_speed = speed
func change_font_size(value: int) -> void:
	%ScriptBox.add_theme_font_size_override("normal_font_size", value)
	%ScriptBox.add_theme_font_size_override("bold_font_size", value)
	%ScriptBox.add_theme_font_size_override("italics_font_size", value)
	%ScriptBox.add_theme_font_size_override("bold_italics_font_size", value)
	%ScriptBox.add_theme_font_size_override("mono_font_size", value)


func command_play_pause() -> void:
	play = !play
func command_move_up() -> void:
	%ScrollScript.scroll_vertical -= 1
func command_move_down() -> void:
	%ScrollScript.scroll_vertical += 1
