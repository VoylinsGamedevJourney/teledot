extends ColorRect


func change_color_background(new_color: Color) -> void:
	self.self_modulate = new_color
func change_color_text(new_color: Color) -> void:
	%Script.self_modulate = new_color
