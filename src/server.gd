extends Node


var server: TCPServer = TCPServer.new()
var clients: Array[StreamPeerTCP] = []
var client_buffers: Dictionary[StreamPeerTCP, String] = {}
var udp_server: UDPServer = UDPServer.new()



func _ready() -> void:
	if server.listen(4242): printerr("Server: Failed to start TCP server")
	if udp_server.listen(4243): printerr("Server: Failed to start UDP server")


func _process(_delta: float) -> void:
	var _err: int = udp_server.poll()
	if udp_server.is_connection_available():
		var peer: PacketPeerUDP = udp_server.take_connection()
		var packet: String = peer.get_packet().get_string_from_utf8()
		if packet == "TELEDOT_DISCOVER":
			_err = peer.put_packet("TELEDOT_ACK".to_utf8_buffer())

	if server.is_connection_available():
		var peer: StreamPeerTCP = server.take_connection()
		clients.append(peer)
		client_buffers[peer] = ""

	for i: int in range(clients.size() - 1, -1, -1):
		var client: StreamPeerTCP = clients[i]
		_err = client.poll()
		if client.get_available_bytes() > 0:
			client_buffers[client] += client.get_utf8_string(client.get_available_bytes())

		var status: int = client.get_status()
		if status not in [StreamPeerTCP.STATUS_CONNECTED, StreamPeerTCP.STATUS_CONNECTING]:
			if client_buffers[client].length() > 0:
				ScriptHandler.on_script_received(client_buffers[client])
			_err = client_buffers.erase(client)
			clients.remove_at(i)
