extends ColorRect

const port := 55757

var connected := false
var server: TCPServer
var connection : StreamPeerTCP


func _ready() -> void:
	$NoConnection.visible = true
	$Script.visible = false
	%IPLabel.text = "IP: %s" % IP.get_local_addresses()[0]
	
	# Initialize server
	server = TCPServer.new()
	server.listen(port)


func _process(_delta: float) -> void:
	if server.is_connection_available():
		connection = server.take_connection()
	if connection != null and connection.get_available_bytes() >= 0:
		_data_receiver(connection.get_string())


func _data_receiver(data:String) -> void:
	print(data)



func change_color_background(new_color: Color = Color8(0,0,0)) -> void:
	self.self_modulate = new_color
func change_color_text(new_color: Color = Color8(255,255,255)) -> void:
	%Script.self_modulate = new_color


func change_script(text: String) -> void:
	%Script.text = text
