extends TabContainer


enum SCREENS { START, EDIT_SCRIPT, SETTINGS, TELEPROMPT }


@export var scripts_vbox: VBoxContainer
@export_group("Edit Script")
@export var text_edit_title: LineEdit
@export var text_edit_script: TextEdit
@export_group("Settings")
@export var slider_font_size: HSlider
@export var slider_scroll_speed: HSlider
@export var slider_prompt_width: HSlider
@export var mirror: CheckButton
@export var color_picker_font: ColorPickerButton
@export var color_picker_background: ColorPickerButton
@export_subgroup("Example")
@export var example_panel: PanelContainer
@export var example_label: Label


var save_script: Callable



func _ready() -> void:
	self.current_tab = SCREENS.START
	_update_scripts()


func _update_scripts() -> void:
	for child: HBoxContainer in scripts_vbox.get_children():
		scripts_vbox.remove_child(child)
		child.queue_free()

	for script: PackedStringArray in ScriptHandler.scripts:
		var hbox: HBoxContainer = HBoxContainer.new()
		var button_delete: TextureButton = TextureButton.new()
		var button_script: Button = Button.new()
		var button_edit: TextureButton = TextureButton.new()
		hbox.add_child(button_delete)
		hbox.add_child(button_script)
		hbox.add_child(button_edit)

		button_delete.texture_normal = load("uid://dvjebqos5r0hn")
		if button_delete.pressed.connect(ScriptHandler.delete_script.bind(script[0])):
			printerr("Main: Couldn't connect delete button!")

		button_script.text = script[0]
		button_script.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if button_script.pressed.connect(open_teleprompter.bind(script)):
			printerr("Main: Couldn't connect script button!")

		button_edit.texture_normal = load("uid://d075rip0f06lo")
		if button_edit.pressed.connect(edit_script.bind(script)):
			printerr("Main: Couldn't connect edit button!")


func _on_settings_button_pressed() -> void:
	slider_font_size.value = Settings.font_size
	slider_scroll_speed.value = Settings.scroll_speed
	slider_prompt_width.value = Settings.prompt_width
	mirror.button_pressed = Settings.mirror
	color_picker_font.color = Settings.font_color
	color_picker_background.color = Settings.background_color
	example_panel.self_modulate = Settings.background_color
	example_label.add_theme_color_override("font_color", Settings.font_color)
	example_label.add_theme_font_size_override("font_size", Settings.font_size)
	self.current_tab = SCREENS.SETTINGS


func _on_add_script_button_pressed() -> void:
	edit_script(["", ""])


func _on_cancel_pressed() -> void:
	self.current_tab = SCREENS.START


func _on_save_pressed() -> void:
	save_script.call()
	self.current_tab = SCREENS.START


func _on_save_settings_pressed() -> void:
	Settings.font_size = int(slider_font_size.value)
	Settings.scroll_speed = int(slider_scroll_speed.value)
	Settings.prompt_width = int(slider_prompt_width.value)
	Settings.mirror = mirror.button_pressed
	Settings.font_color = color_picker_font.color
	Settings.background_color = color_picker_background.color
	self.current_tab = SCREENS.START


func edit_script(script: PackedStringArray) -> void:
	if script[0] == "New script" and script[1].is_empty():
		save_script = ScriptHandler.add_script.bind(script)
	else:
		save_script = _update_script.bind(script)


func _update_script(old_script: PackedStringArray) -> void:
	var new_script: PackedStringArray = [text_edit_title.text, text_edit_script.text]
	ScriptHandler.update_script(old_script, new_script)


func open_teleprompter(script: PackedStringArray) -> void:
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_LANDSCAPE)
	self.current_tab = SCREENS.TELEPROMPT


func close_teleprompter(script: PackedStringArray) -> void:
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_PORTRAIT)
	self.current_tab = SCREENS.START


func _on_background_color_picker_button_color_changed(color: Color) -> void:
	example_panel.self_modulate = color


func _on_font_size_h_slider_value_changed(value: float) -> void:
	example_label.add_theme_font_size_override("font_size", int(value))


func _on_font_color_picker_button_color_changed(color: Color) -> void:
	example_label.add_theme_color_override("font_color", color)
