extends Control
class_name InGameUserInterface

@onready var info_readout_1: Label = $MarginContainer/MarginContainer/VBoxContainer/InfoReadout1
@onready var info_readout_2: Label = $MarginContainer/MarginContainer/VBoxContainer/InfoReadout2
@onready var info_readout_3: Label = $MarginContainer/MarginContainer/VBoxContainer/InfoReadout3

var _camera_manager: CameraManager = null

func _ready() -> void:
	_set_static_readouts()

	GlobalTimeManager.hour_changed.connect(_on_hour_changed)
	_update_time_readout()

	_camera_manager = get_tree().get_first_node_in_group("camera_manager") as CameraManager
	if _camera_manager == null:
		push_warning("InGameUserInterface: หา CameraManager (group 'camera_manager') ไม่เจอ")
		info_readout_2.text = "Camera: --"
		return
	_camera_manager.camera_switched.connect(_on_camera_switched)

	if _camera_manager.current_camera_id != "":
		_update_camera_readout_from_id(_camera_manager.current_camera_id)
	else:
		info_readout_2.text = "Camera: --"

func _set_static_readouts() -> void:
	var data := LevelDataManager.current_case_data
	if data == null:
		push_warning("InGameUserInterface: LevelDataManager.current_case_data ยังไม่ถูก set")
		info_readout_1.text = ""
		return
	# InfoReadout1 ประกอบจาก case_date_label + เวลา (ส่วนเวลาอัปเดตแยกใน _update_time_readout)
	_update_time_readout()

func _on_hour_changed(_new_hour: int) -> void:
	_update_time_readout()

func _update_time_readout() -> void:
	var data := LevelDataManager.current_case_data
	if data == null:
		return
	info_readout_1.text = "%s: %s" % [data.case_date_label, GlobalTimeManager.get_clock_display()]

func _on_camera_switched(camera_id: String, _camera: Camera3D) -> void:
	_update_camera_readout_from_id(camera_id)

func _update_camera_readout_from_id(camera_id: String) -> void:
	if camera_id.is_valid_int():
		info_readout_2.text = "Camera: %d" % int(camera_id)
	else:
		info_readout_2.text = "Camera: %s" % camera_id
