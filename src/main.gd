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
@export_group("Teleprompter")
@export var teleprompter_bg: ColorRect
@export var teleprompter_margin: MarginContainer
@export var teleprompter_scroll: ScrollContainer
@export var teleprompter_label: RichTextLabel


var save_script: Callable
var is_playing: bool = false
var current_scroll: float = 0.0
var active_scroll_speed: float = 0.0
var teleprompter_active: bool = false
var is_dragging: bool = false
var touch_start_pos: Vector2



func _ready() -> void:
	get_tree().quit_on_go_back = false
	self.current_tab = SCREENS.START
	var _err: int = ScriptHandler.scripts_updated.connect(_update_scripts)
	_update_scripts()
	_disable_ui_interaction(teleprompter_bg)
	_disable_ui_interaction(teleprompter_margin)


func _disable_ui_interaction(node: Node) -> void:
	if node is Control:
		var control_node: Control = node
		control_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		control_node.focus_mode = Control.FOCUS_NONE
	for child: Node in node.get_children(true):
		_disable_ui_interaction(child)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if current_tab == SCREENS.TELEPROMPT:
			close_teleprompter()
		elif current_tab != SCREENS.START:
			_on_cancel_pressed()
		else:
			get_tree().quit()


func _input(event: InputEvent) -> void:
	if teleprompter_active:
		if event.is_action_pressed("teleprompt_play_pause"):
			is_playing = not is_playing
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("teleprompt_back"):
			close_teleprompter()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("teleprompt_speed_up"):
			active_scroll_speed += 1.0
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("teleprompt_speed_down"):
			active_scroll_speed = max(1.0, active_scroll_speed - 1.0)
			get_viewport().set_input_as_handled()
		elif event.is_action("teleprompt_up") or event.is_action("teleprompt_down"):
			get_viewport().set_input_as_handled()

		if event is InputEventScreenTouch:
			var touch_event: InputEventScreenTouch = event
			if touch_event.pressed:
				is_dragging = false
				touch_start_pos = touch_event.position
			else:
				if not is_dragging and touch_start_pos.distance_to(touch_event.position) < 20:
					is_playing = not is_playing
				is_dragging = false
			get_viewport().set_input_as_handled()

		elif event is InputEventScreenDrag:
			var screen_drag_event: InputEventScreenDrag = event
			is_dragging = true
			current_scroll -= screen_drag_event.relative.y
			get_viewport().set_input_as_handled()
	else: # !teleprompter_active
		if event.is_action_pressed("teleprompt_play_pause"):
			# TODO: Open the selected script.
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("teleprompt_up"):
			# TODO: Set the focussed button to the previous button in the list, or to the full bottom when on top.
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("teleprompt_down"):
			# TODO: Set the focussed button to the next button in the list, or to the full top when on top.
			get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not teleprompter_active:
		return

	if Input.is_action_pressed("teleprompt_up"):
		current_scroll = max(0.0, current_scroll - 500.0 * delta)
	if Input.is_action_pressed("teleprompt_down"):
		current_scroll += 500.0 * delta

	if is_playing and not is_dragging:
		current_scroll += active_scroll_speed * 20.0 * delta

	teleprompter_scroll.scroll_vertical = int(current_scroll)
	if teleprompter_scroll.scroll_vertical != int(current_scroll):
		current_scroll = float(teleprompter_scroll.scroll_vertical)


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

		scripts_vbox.add_child(hbox)


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
	Settings.save_settings()
	self.current_tab = SCREENS.START


func edit_script(script: PackedStringArray) -> void:
	text_edit_title.text = script[0]
	text_edit_script.text = script[1]
	self.current_tab = SCREENS.EDIT_SCRIPT

	if script[0].is_empty() and script[1].is_empty():
		save_script = _add_script
	else:
		save_script = _update_script.bind(script)


func _add_script() -> void:
	var new_script: PackedStringArray = [text_edit_title.text, text_edit_script.text]
	ScriptHandler.add_script(new_script)


func _update_script(old_script: PackedStringArray) -> void:
	var new_script: PackedStringArray = [text_edit_title.text, text_edit_script.text]
	ScriptHandler.update_script(old_script, new_script)


func open_teleprompter(script: PackedStringArray) -> void:
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_LANDSCAPE)
	self.current_tab = SCREENS.TELEPROMPT

	teleprompter_bg.color = Settings.background_color
	teleprompter_label.add_theme_color_override("default_color", Settings.font_color)
	teleprompter_label.add_theme_font_size_override("normal_font_size", Settings.font_size)
	teleprompter_label.add_theme_font_size_override("bold_font_size", Settings.font_size)
	teleprompter_label.add_theme_font_size_override("italics_font_size", Settings.font_size)
	teleprompter_label.text = "[center]" + script[1] + "[/center]"

	teleprompter_active = true
	is_playing = false
	current_scroll = 0.0
	teleprompter_scroll.scroll_vertical = 0
	active_scroll_speed = float(Settings.scroll_speed)

	await get_tree().process_frame
	await get_tree().process_frame

	var screen_width: float = get_viewport_rect().size.x
	var margin_px: int = int((screen_width * (100 - Settings.prompt_width) / 100.0) / 2.0)
	teleprompter_margin.add_theme_constant_override("margin_left", margin_px)
	teleprompter_margin.add_theme_constant_override("margin_right", margin_px)

	if Settings.mirror:
		teleprompter_margin.scale.x = -1
		teleprompter_margin.pivot_offset.x = screen_width / 2.0
	else:
		teleprompter_margin.scale.x = 1
		teleprompter_margin.pivot_offset.x = screen_width / 2.0


func close_teleprompter() -> void:
	teleprompter_active = false
	is_playing = false
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_PORTRAIT)
	self.current_tab = SCREENS.START


func _on_background_color_picker_button_color_changed(color: Color) -> void:
	example_panel.self_modulate = color


func _on_font_size_h_slider_value_changed(value: float) -> void:
	example_label.add_theme_font_size_override("font_size", int(value))


func _on_font_color_picker_button_color_changed(color: Color) -> void:
	example_label.add_theme_color_override("font_color", color)
