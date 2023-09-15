@tool
extends EditorPlugin

const CONTROL_PANEL = preload("res://addons/godohmygod/control_panel.tscn")
const GSCLIENT = preload("res://addons/godohmygod/gsclient.gd")

var _control_panel: OMGControlPanel
var _gsclient: GSClient
var _character_count: int = 0


func _enter_tree() -> void:
	var editor: EditorInterface = get_editor_interface()
	var script_editor: ScriptEditor = editor.get_script_editor()
	script_editor.editor_script_changed.connect(_editor_script_changed)
	
	_gsclient = GSCLIENT.new()
	add_child(_gsclient)

	_control_panel = CONTROL_PANEL.instantiate()
	_control_panel.gsclient = _gsclient
	add_control_to_dock(DOCK_SLOT_RIGHT_BL, _control_panel)


func _exit_tree() -> void:
	if _gsclient and _gsclient.is_client_connected():
		_gsclient.stop()


func _editor_script_changed(script) -> void:
	var editor: EditorInterface = get_editor_interface()
	var script_editor: ScriptEditor = editor.get_script_editor()
	_connect_editors(script_editor)


func _connect_editors(parent: Node) -> void:
	for child in parent.get_children():
		if child.get_child_count():
			_connect_editors(child)
		if child is TextEdit:
			if child.gui_input.is_connected(_on_gui_input):
				child.gui_input.disconnect(_on_gui_input)
			child.gui_input.connect(_on_gui_input)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if not event.pressed or not _control_panel or not _gsclient.is_client_connected():
			return
		_character_count += 1
		if _character_count < _control_panel.get_interval():
			return
		_character_count = 0
		var duration = _control_panel.get_duration()
		if duration == 0:
			return
		var device = _control_panel.get_selected_device()
		var action = _control_panel.get_selected_action()
		if not device or not action:
			return
		var intensity = _control_panel.get_varied_intensity()
		match action.feature_command:
			GSMessage.MESSAGE_TYPE_SCALAR_CMD:
				_gsclient.send_scalar(device.device_index, action.feature_index, action.actuator_type, intensity)
				await get_tree().create_timer(duration).timeout
				_gsclient.stop_device(device.device_index)
			GSMessage.MESSAGE_TYPE_ROTATE_CMD:
				_gsclient.send_rotate(device.device_index, action.feature_index, true, intensity)
				await get_tree().create_timer(duration).timeout
				_gsclient.stop_device(device.device_index)
			GSMessage.MESSAGE_TYPE_LINEAR_CMD:
				await _gsclient.send_linear(device.device_index, action.feature_index, duration, intensity)
