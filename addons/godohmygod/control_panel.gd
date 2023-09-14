@tool
extends Control
class_name OMGControlPanel

const CONFIG_FILE = "user://godohmygod.cfg"
const CONNECT_TEXT = "Connect to Intiface Central"

var gsclient: GSClient


var _config: ConfigFile = ConfigFile.new()
var _connecting: bool = false

@onready var _server: TextEdit = %Server
@onready var _port: SpinBox = %Port
@onready var _connect: Button = %Connect
@onready var _device_list: OptionButton = %Device
@onready var _action_list: OptionButton = %Action
@onready var _retrieve_devices: Button = %RetrieveDevices
@onready var _interval: SpinBox = %Interval
@onready var _intensity: SpinBox = %Intensity
@onready var _variance: SpinBox = %Variance
@onready var _duration: SpinBox = %Duration


func _ready() -> void:
	_load_config()
	if gsclient:
		gsclient.client_connection_changed.connect(_on_client_connection_changed)
		gsclient.client_device_list_received.connect(_on_client_device_list_received)


func _exit_tree() -> void:
	_save_config()


func get_server() -> String:
	return _server.text


func get_port() -> int:
	return int(_port.value)


func get_selected_device() -> GSDevice:
	if _device_list.selected == -1:
		return null
	return _device_list.get_item_metadata(_device_list.selected) as GSDevice


func get_selected_action() -> GSFeature:
	if _action_list.selected == -1:
		return null
	return _action_list.get_item_metadata(_action_list.selected) as GSFeature


func get_interval() -> int:
	return int(_interval.value)


func get_intensity() -> float:
	return _intensity.value


func get_variance() -> float:
	return _variance.value


func get_duration() -> float:
	return _duration.value


func get_varied_intensity() -> float:
	var variance = randf_range(-get_variance(), get_variance())
	var intensity = get_intensity() + variance
	return min(1.0, max(0.1, intensity))


func _on_connect_pressed() -> void:
	if _connecting or not _validate_connect():
		return
	if gsclient.is_client_connected():
		gsclient.stop()
		return
	_connect.text = "Connecting..."
	_connect.disabled = true
	_connecting = true
	gsclient.start(get_server(), get_port())
	await gsclient.client_connection_changed
	_connecting = false
	if not gsclient.is_client_connected():
		OS.alert("Unable to connect to Intiface Central. Check your server and port settings.")
		_connect.text = CONNECT_TEXT
		_connect.disabled = false
		return
	gsclient.request_device_list()


func _validate_connect() -> bool:
	return get_server() and get_server() != "" and get_port() != 0


func _load_config() -> void:
	var res = _config.load(CONFIG_FILE)
	if res != OK:
		_set_defaults()
		return
	_server.text = _config.get_value("settings", "server", "localhost")
	_port.value = int(_config.get_value("settings", "port", "12345"))
	_interval.value = int(_config.get_value("settings", "interval", "1"))
	_intensity.value = float(_config.get_value("settings", "intensity", "0.5"))
	_variance.value = float(_config.get_value("settings", "variance", "0.5"))
	_duration.value = float(_config.get_value("settings", "duration", "0.5"))


func _save_config() -> void:
	_config.set_value("settings", "server", get_server())
	_config.set_value("settings", "port", get_port())
	_config.set_value("settings", "interval", get_interval())
	_config.set_value("settings", "intensity", get_intensity())
	_config.set_value("settings", "variance", get_variance())
	_config.set_value("settings", "duration", get_duration())
	_config.save(CONFIG_FILE)


func _set_defaults() -> void:
	_server.text = "localhost"
	_port.value = 12345
	_interval.value = 1
	_intensity.value = 0.5
	_variance.value = 0.5
	_duration.value = 1.0


func _populate_device_list(devices: Array):
	_device_list.clear()
	devices.sort_custom(func(a, b): return a.device_index < b.device_index)
	for device in devices:
		_add_device(device)


func _add_device(device: GSDevice):
	_device_list.add_item(device.get_display_name())
	var idx = _device_list.item_count - 1
	_device_list.set_item_metadata(idx, device)
	device.set_meta("device_list_idx", idx)


func _remove_device(device: GSDevice):
	if device.has_meta("device_list_idx"):
		var idx = device.get_meta("device_list_idx")
		if idx < _device_list.item_count:
			_action_list.clear()
		_device_list.remove_item(idx)


func _populate_action_list(actions: Array):
	_action_list.clear()
	actions.sort_custom(func(a, b): return a.feature_index < b.feature_index)
	for action in actions:
		_add_action(action)
	_action_list.disabled = false


func _add_action(feature: GSFeature):
	if feature.feature_command not in [ 
		GSMessage.MESSAGE_TYPE_SCALAR_CMD, 
		GSMessage.MESSAGE_TYPE_ROTATE_CMD, 
		GSMessage.MESSAGE_TYPE_LINEAR_CMD ]:
		return
	_action_list.add_item(feature.get_display_name())
	var idx = _device_list.item_count - 1
	_action_list.set_item_metadata(idx, feature)
	feature.set_meta("action_list_idx", idx)


func _on_retrieve_devices_pressed() -> void:
	_device_list.clear()
	_action_list.clear()
	gsclient.request_device_list()


func _on_device_item_selected(index: int) -> void:
	_get_actions(index)


func _on_client_connection_changed(connected: bool) -> void:
	if connected:
		_connect.text = "Disconnect"
		_connect.disabled = false
		_device_list.disabled = false
		_retrieve_devices.disabled = false
	else:
		_connect.text = CONNECT_TEXT
		_connect.disabled = false
		_device_list.disabled = true
		_action_list.disabled = true
		_retrieve_devices.disabled = true
	_device_list.clear()
	_action_list.clear()


func _on_client_scan_finished():
	_populate_device_list(gsclient.get_devices())
	_get_actions(0)


func _get_actions(idx: int) -> void:
	if _device_list.item_count > 0:
		_device_list.selected = idx
		var device = _device_list.get_item_metadata(_device_list.selected) as GSDevice
		if device:
			_populate_action_list(device.features)


func _on_client_device_list_received(devices: Array):
	_populate_device_list(devices)
	_get_actions(0)


func _on_client_device_added(device: GSDevice):
	_add_device(device)


func _on_client_device_removed(device: GSDevice):
	_remove_device(device)
