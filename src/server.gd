extends Node


var server: TCPServer = TCPServer.new()
var clients: Array[StreamPeerTCP] = []



func _ready() -> void:
	if server.listen(4242):
		printerr("Server: Failed to start server")


func _process(_delta: float) -> void:
	if server.is_connection_available():
		clients.append(server.take_connection())
	for client: StreamPeerTCP in clients:
		var status: int = client.get_status()
		if status not in [StreamPeerTCP.STATUS_CONNECTED, StreamPeerTCP.STATUS_CONNECTING]:
			clients.erase(client)
		if client.get_available_bytes() > 0:
			var data: String = client.get_utf8_string(client.get_available_bytes())
			ScriptHandler.on_script_received(data)
