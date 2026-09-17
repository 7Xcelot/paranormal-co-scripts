extends Control
class_name CameraLayoutPanel

@export var camera_manager: CameraManager
@export var selected_modulate: Color = Color(1.0, 0.85, 0.2)
@export var normal_modulate: Color = Color(1, 1, 1)
@export var alert_border_color: Color = Color(1, 0, 0)
@export var alert_border_width: int = 4
@export var alert_blink_interval: float = 0.4   # วิ ต่อการสลับ on/off หนึ่งครั้ง

var buttons: Dictionary = {}
var _alert_ids: Dictionary = {}       # { cam_id: true } — ปุ่มที่กำลังกระพริบอยู่
var _alert_stylebox: StyleBoxFlat
var _blink_timer: float = 0.0
var _blink_on: bool = false

func _ready():
	if camera_manager == null:
		push_warning("CameraLayoutPanel: ยังไม่ได้ผูก camera_manager")
		return

	for child in get_children():
		if child is Button:
			var cam_id = _extract_id(child.name)
			buttons[cam_id] = child
			child.pressed.connect(_on_camera_button_pressed.bind(cam_id))

	camera_manager.camera_switched.connect(_on_camera_switched)
	camera_manager.alert_started.connect(start_alert)
	camera_manager.alert_stopped.connect(stop_alert)

	if camera_manager.current_camera_id != "":
		_highlight_button(camera_manager.current_camera_id)

	_alert_stylebox = StyleBoxFlat.new()
	_alert_stylebox.bg_color = Color(0, 0, 0, 0)
	_alert_stylebox.set_border_width_all(alert_border_width)
	_alert_stylebox.border_color = alert_border_color
	set_process(false)

func _process(delta: float) -> void:
	if _alert_ids.is_empty():
		set_process(false)
		return
	_blink_timer += delta
	if _blink_timer >= alert_blink_interval:
		_blink_timer = 0.0
		_blink_on = not _blink_on
		for id in _alert_ids.keys():
			_apply_alert_visual(id, _blink_on)

## เรียกอัตโนมัติจาก camera_manager.alert_started — ไม่ต้องเรียกเองจากที่อื่น
func start_alert(target_id: String) -> void:
	if camera_manager.visibility_config == null:
		push_warning("CameraLayoutPanel: visibility_config ยังไม่ได้ผูกใน CameraManager")
		return
	var cams: Array[String] = camera_manager.visibility_config.get_cameras_that_see(target_id)
	if cams.is_empty():
		push_warning("CameraLayoutPanel: ไม่มีกล้องไหนเห็น target_id '%s' เลยใน visibility_map (พิมพ์ผิด/ลืมเพิ่ม entry?)" % target_id)
	for cam_id in cams:
		if not buttons.has(cam_id):
			push_warning("CameraLayoutPanel: เจอ cam_id '%s' ใน visibility_map แต่ไม่มีปุ่มนี้ใน buttons dict" % cam_id)
		_alert_ids[cam_id] = true
	_blink_timer = 0.0
	_blink_on = true
	for id in _alert_ids.keys():
		_apply_alert_visual(id, true)
	set_process(true)
	print("CameraLayoutPanel: start_alert ok — alert_ids = %s" % _alert_ids.keys())

func stop_alert(target_id: String) -> void:
	if camera_manager.visibility_config == null:
		return
	for cam_id in camera_manager.visibility_config.get_cameras_that_see(target_id):
		_alert_ids.erase(cam_id)
		_apply_alert_visual(cam_id, false)
	print("CameraLayoutPanel: stop_alert ok — alert_ids เหลือ = %s" % _alert_ids.keys())

func _apply_alert_visual(cam_id: String, on: bool) -> void:
	var btn: Button = buttons.get(cam_id)
	if btn == null:
		return
	if on:
		btn.add_theme_stylebox_override("normal", _alert_stylebox)
	else:
		btn.remove_theme_stylebox_override("normal")

func _extract_id(node_name: String) -> String:
	var regex = RegEx.new()
	regex.compile("\\d+$")
	var result = regex.search(node_name)
	return result.get_string() if result else node_name

func _on_camera_button_pressed(cam_id: String) -> void:
	camera_manager.switch_to_camera_by_id(cam_id)

func _on_camera_switched(cam_id: String, _cam: Camera3D) -> void:
	_highlight_button(cam_id)

func _highlight_button(cam_id: String) -> void:
	for id in buttons.keys():
		buttons[id].modulate = selected_modulate if id == cam_id else normal_modulate
