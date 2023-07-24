extends ColorRect

## Each var that gets send should be [function_name, value]
## List of possible commands which can be send:
## change_color_background (Color)
## change_color_text (Color)
## change_script (String)


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


func _ready() -> void:
	start_server()


func start_server() -> void:
	# Initialize server
	$Script.visible = false
	server = TCPServer.new()
	server.listen(port)
	$NoConnection.visible = true
	%IPLabel.text = "IP: %s" % IP.get_local_addresses()[0]


func _process(_delta: float) -> void:
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
			self.call(data[0], data[1])
			if data[0] == "change_alignment":
				change_script()


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
