extends Control
class_name CameraLayoutPanel

@export var camera_manager: CameraManager
@export var selected_modulate: Color = Color(1.0, 0.85, 0.2)
@export var normal_modulate: Color = Color(1, 1, 1)
@export var alert_border_color: Color = Color(1, 0, 0)
@export var alert_border_width: int = 4
@export var alert_blink_interval: float = 0.4
@export var line_color: Color = Color(1, 1, 1, 0.4)
@export var button_size: Vector2 = Vector2(48, 32)

var buttons: Dictionary = {}
var _connections: Dictionary = {}     # { cam_id: Array[String] } — เก็บไว้ใช้ตอน _draw()
var _alert_ids: Dictionary = {}
var _alert_stylebox: StyleBoxFlat
var _blink_timer: float = 0.0
var _blink_on: bool = false

func _ready():
	if camera_manager == null:
		push_warning("CameraLayoutPanel: ยังไม่ได้ผูก camera_manager")
		return

	await get_tree().process_frame   # รอให้ทุก _ready() ใน tree รันจบก่อน

	var level_config := get_tree().get_first_node_in_group("level_config")
	if level_config == null or level_config.camera_map_layout == null:
		push_warning("CameraLayoutPanel: หา LevelConfig หรือ camera_map_layout ไม่เจอ")
		return

	_build_from_layout(level_config.camera_map_layout)

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

## สร้างปุ่มจริงจากข้อมูล .tres — เรียกครั้งเดียวตอน _ready()
func _build_from_layout(layout: CameraMapLayout) -> void:
	print("🔍 CameraMapLayout nodes count = ", layout.nodes.size())
	for node_data in layout.nodes:
		print("  → cam_id=", node_data.cam_id, " pos=", node_data.grid_position)
		var btn := Button.new()
		btn.text = "Cam" + node_data.cam_id
		btn.position = node_data.grid_position
		btn.size = button_size
		add_child(btn)
		buttons[node_data.cam_id] = btn
		_connections[node_data.cam_id] = node_data.connections
		btn.pressed.connect(_on_camera_button_pressed.bind(node_data.cam_id))
	queue_redraw()

## วาดเส้นเชื่อมระหว่างปุ่ม ตาม connections ที่กำหนดไว้ใน .tres
func _draw() -> void:
	for cam_id in _connections.keys():
		if not buttons.has(cam_id):
			continue
		var from_center: Vector2 = buttons[cam_id].position + button_size / 2.0
		for target_id in _connections[cam_id]:
			if not buttons.has(target_id):
				push_warning("CameraLayoutPanel: connections ของ '%s' ชี้ไป '%s' ที่ไม่มีอยู่จริง" % [cam_id, target_id])
				continue
			var to_center: Vector2 = buttons[target_id].position + button_size / 2.0
			draw_line(from_center, to_center, line_color, 2.0)

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

func start_alert(target_id: String) -> void:
	if camera_manager.visibility_config == null:
		push_warning("CameraLayoutPanel: visibility_config ยังไม่ได้ผูกใน CameraManager")
		return
	var cams: Array[String] = camera_manager.visibility_config.get_cameras_that_see(target_id)
	if cams.is_empty():
		push_warning("CameraLayoutPanel: ไม่มีกล้องไหนเห็น target_id '%s' เลยใน visibility_map" % target_id)
	for cam_id in cams:
		if not buttons.has(cam_id):
			push_warning("CameraLayoutPanel: เจอ cam_id '%s' ใน visibility_map แต่ไม่มีปุ่มนี้ใน buttons dict" % cam_id)
		_alert_ids[cam_id] = true
	_blink_timer = 0.0
	_blink_on = true
	for id in _alert_ids.keys():
		_apply_alert_visual(id, true)
	set_process(true)

func stop_alert(target_id: String) -> void:
	if camera_manager.visibility_config == null:
		return
	for cam_id in camera_manager.visibility_config.get_cameras_that_see(target_id):
		_alert_ids.erase(cam_id)
		_apply_alert_visual(cam_id, false)

func _apply_alert_visual(cam_id: String, on: bool) -> void:
	var btn: Button = buttons.get(cam_id)
	if btn == null:
		return
	if on:
		btn.add_theme_stylebox_override("normal", _alert_stylebox)
	else:
		btn.remove_theme_stylebox_override("normal")

func _on_camera_button_pressed(cam_id: String) -> void:
	camera_manager.switch_to_camera_by_id(cam_id)

func _on_camera_switched(cam_id: String, _cam: Camera3D) -> void:
	_highlight_button(cam_id)

func _highlight_button(cam_id: String) -> void:
	for id in buttons.keys():
		buttons[id].modulate = selected_modulate if id == cam_id else normal_modulate
