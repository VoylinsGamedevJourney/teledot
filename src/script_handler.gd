extends Node


signal scripts_updated


const PATH: String = "user://scripts"


var scripts: Array[PackedStringArray] = [] ## [[Title, Text], ...]



func _ready() -> void:
	if FileAccess.file_exists(PATH):
		var file: FileAccess = FileAccess.open(PATH, FileAccess.READ)
		scripts = file.get_var()
		scripts_updated.emit()


func on_script_received(text: String) -> void:
	var title: String = text.get_slice('\n', 0)
	add_script([title, text.lstrip(title).strip_edges()])


func add_script(script: PackedStringArray) -> void:
	if script[1].is_empty():
		return
	if script[0].is_empty():
		script[0] = "New script"
	scripts.push_front(script)
	scripts_updated.emit()


func update_script(old_script: PackedStringArray, new_script: PackedStringArray) -> void:
	if new_script[1].is_empty():
		return delete_script(old_script[0])
	var index: int = scripts.find_custom(_find_script.bind(old_script[0]))
	scripts[index] = new_script


func delete_script(title: String) -> void:
	var index: int = scripts.find_custom(_find_script.bind(title))
	scripts.remove_at(index)
	scripts_updated.emit()


func _find_script(script: PackedStringArray, title: String) -> bool:
	return script[0] == title
