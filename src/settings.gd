extends Node


const PATH: String = "user://settings.cfg"


var font_size: int = 50
var scroll_speed: int = 4
var prompt_width: int = 65 ## Percentage of the screen.
var mirror: bool = true
var font_color: Color = Color.WHITE_SMOKE
var background_color: Color = Color.BLACK



func _ready() -> void:
	load_settings()


func load_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(PATH) == OK:
		font_size = config.get_value("settings", "font_size", font_size)
		scroll_speed = config.get_value("settings", "scroll_speed", scroll_speed)
		prompt_width = config.get_value("settings", "prompt_width", prompt_width)
		mirror = config.get_value("settings", "mirror", mirror)
		font_color = config.get_value("settings", "font_color", font_color)
		background_color = config.get_value("settings", "background_color", background_color)


func save_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("settings", "font_size", font_size)
	config.set_value("settings", "scroll_speed", scroll_speed)
	config.set_value("settings", "prompt_width", prompt_width)
	config.set_value("settings", "mirror", mirror)
	config.set_value("settings", "font_color", font_color)
	config.set_value("settings", "background_color", background_color)
	var _err: int = config.save(PATH)
