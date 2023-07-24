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


func _ready() -> void:
	start_server()


func start_server() -> void:
	# Initialize server
	server = TCPServer.new()
	server.listen(port)
	$NoConnection.visible = true
	$Script.visible = false
	%IPLabel.text = "IP: %s" % IP.get_local_addresses()[0]


func _process(_delta: float) -> void:
	if server.is_connection_available(): 
		connection = server.take_connection()
	if connection != null:
		connection.poll()
		if client_status != connection.get_status():
			client_status = connection.get_status()
		if client_status != connection.STATUS_CONNECTED:
			connection = null
			start_server()
			client_status = -1
			return
		if connection.get_available_bytes() == null:
			print(connection.get_var())
#			var data: Array = connection.get_var()
#			self.call(data[0], data[1])3


func change_color_background(new_color: Color = Color8(0,0,0)) -> void:
	self.self_modulate = new_color
func change_color_text(new_color: Color = Color8(255,255,255)) -> void:
	%Script.self_modulate = new_color
func change_script(text: String) -> void:
	%Script.text = text
