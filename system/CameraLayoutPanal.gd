extends Control
class_name CameraLayoutPanel

@export var camera_manager: CameraManager
@export var selected_modulate: Color = Color(1.0, 0.85, 0.2) # สีไฮไลต์ปุ่มที่กำลังดูอยู่
@export var normal_modulate: Color = Color(1, 1, 1)

var buttons: Dictionary = {} # { "1": Button, "2": Button, "3": Button }


func _ready():
	if camera_manager == null:
		push_warning("CameraLayoutPanel: ยังไม่ได้ผูก camera_manager")
		return

	# สแกนหาปุ่มลูกที่มีอยู่แล้วใน scene (Cam1, Cam2, Cam3 ฯลฯ) แทนการสร้างใหม่
	for child in get_children():
		if child is Button:
			var cam_id = _extract_id(child.name)
			buttons[cam_id] = child
			child.pressed.connect(_on_camera_button_pressed.bind(cam_id))

	camera_manager.camera_switched.connect(_on_camera_switched)

	# ไฮไลต์ปุ่มเริ่มต้นให้ตรงกับกล้องที่ active อยู่ตอนเริ่มเกม
	if camera_manager.current_camera_id != "":
		_highlight_button(camera_manager.current_camera_id)


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
