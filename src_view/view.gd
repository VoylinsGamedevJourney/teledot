extends ColorRect

const no_connection_text = "[b]No Connection[/b]\nIP: %s\n Port: %s"
const port := 55757

var connected := false
var show_ip := false

var ip := IP.get_local_addresses() # [0] = public (IPv4), [2] = local


func _ready() -> void:
	# Startup server
	pass


func _process(delta: float) -> void:
	pass


func change_color_background(new_color: Color = Color8(0,0,0)) -> void:
	self.self_modulate = new_color
func change_color_text(new_color: Color = Color8(255,255,255)) -> void:
	%Script.self_modulate = new_color


func change_script(text: String) -> void:
	%Script.text = text


func _on_switch_ip_button_pressed() -> void:
	if show_ip:
		find_child("SwitchIPButton1").text = "Show IP"
		find_child("SwitchIPButton2").text = "Show IP"
		%ConnectionInfo.text = no_connection_text % ip[0]
		show_ip = false
	else:
		find_child("SwitchIPButton1").text = "Hide IP"
		find_child("SwitchIPButton2").text = "Hide IP"
		%ConnectionInfo.text = no_connection_text % ip[2]
		show_ip = true
