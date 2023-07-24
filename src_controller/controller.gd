extends ColorRect

const port := 55757
var client: StreamPeerTCP
var status = -1


func _ready() -> void:
	client = StreamPeerTCP.new()
	client.connect_to_host("192.0.0.1", port)


func _process(delta: float) -> void:
	client.poll()
	if client.get_status() != status:
		status = client.get_status()
	if client.get_status() == 2:
		client.put_string("hello")
