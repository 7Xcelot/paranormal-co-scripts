extends Control
class_name NoSignalCam

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
	var camera_manager := get_tree().get_first_node_in_group("camera_manager")
	var camera_display := get_tree().get_first_node_in_group("camera_display")
	if camera_manager == null or camera_display == null:
		return

	global_position = camera_display.global_position
	size = camera_display.size

	var current_id: String = camera_manager.current_camera_id   # แก้ตรงนี้
	visible = camera_manager.is_camera_blacked_out(current_id)
