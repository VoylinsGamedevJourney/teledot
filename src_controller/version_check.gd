class_name VersionCheck extends Node


var update_label: RichTextLabel


func _init(control: Control, _update_label: RichTextLabel) -> void:
	update_label = _update_label
	const version_url := "https://raw.githubusercontent.com/voylin/TeleDot/master/src_controller/version.json"
	var http_request := HTTPRequest.new()
	control.add_child(http_request)
	http_request.request_completed.connect(self._check)
	var error = http_request.request(version_url)
	if error != OK:
		print_debug("Could not get version json")


func _check(_result, response_code, _headers, body) -> void:
	var result: String = body.get_string_from_utf8()
	if response_code == 404 or result.length() < 5: 
		print("Received version file info invalid")
		return
	var json = JSON.new()
	json.parse(result)
	var current_version: Dictionary = json.data
	var file := FileAccess.open("res://version.json", FileAccess.READ)
	json.parse(file.get_as_text())
	var local_version: Dictionary = json.data
	var update_available := false
	if current_version.latest_stable.major > local_version.latest_stable.major:
		update_available = true
	elif current_version.latest_stable.minor > local_version.latest_stable.minor:
		update_available = true
	elif current_version.latest_stable.patch > local_version.latest_stable.patch:
		update_available = true
	update_label.visible = update_available
