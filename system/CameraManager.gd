extends Node
class_name CameraManager

@export var pan_speed: float = 2.0
@export var smooth_factor: float = 10.0
@export var pan_limit_degrees: float = 20.0

signal camera_switched(camera_id: String, camera: Camera3D)

var pan_limit: float
var cameras: Array[Camera3D] = []
var camera_lookup: Dictionary = {}      # { "1": Camera3D, "2": Camera3D, "3": Camera3D }
var base_rotations: Dictionary = {}
var target_rotations: Dictionary = {}
var current_camera_id: String = ""


func _ready():
	pan_limit = deg_to_rad(pan_limit_degrees)

	for child in get_children():
		if child is Camera3D:
			cameras.append(child)
			base_rotations[child] = child.rotation.y
			target_rotations[child] = child.rotation.y
			child.current = false

			# ดึงเฉพาะตัวเลขท้ายชื่อ เช่น "Camera1" -> "1" (รองรับทั้ง Camera1, Cam1, CAM_1 ฯลฯ)
			var cam_id = _extract_id(child.name)
			camera_lookup[cam_id] = child

	if cameras.size() > 0:
		switch_to_camera_by_id(camera_lookup.keys()[0])
	else:
		push_warning("CameraManager: ไม่พบ Camera3D ในฉากนี้เลย")


func _extract_id(node_name: String) -> String:
	var regex = RegEx.new()
	regex.compile("\\d+$") # จับตัวเลขท้ายสตริง
	var result = regex.search(node_name)
	return result.get_string() if result else node_name


func _process(delta):
	if cameras.is_empty() or not camera_lookup.has(current_camera_id):
		return

	var active_cam = camera_lookup[current_camera_id]

	var pan_direction = 0.0
	if Input.is_action_pressed("pan_left"):
		pan_direction = 1.0
	elif Input.is_action_pressed("pan_right"):
		pan_direction = -1.0

	if pan_direction != 0.0:
		var base_y = base_rotations[active_cam]
		target_rotations[active_cam] = clamp(
			target_rotations[active_cam] + pan_direction * pan_speed * delta,
			base_y - pan_limit,
			base_y + pan_limit
		)

	var current_target = target_rotations[active_cam]
	active_cam.rotation.y = lerp(
		active_cam.rotation.y,
		current_target,
		1.0 - exp(-smooth_factor * delta)
	)


func switch_to_camera_by_id(cam_id: String) -> void:
	if not camera_lookup.has(cam_id):
		push_warning("CameraManager: Camera Not Found '%s'" % cam_id)
		return

	if camera_lookup.has(current_camera_id):
		camera_lookup[current_camera_id].current = false

	current_camera_id = cam_id
	var new_cam = camera_lookup[cam_id]
	target_rotations[new_cam] = base_rotations[new_cam]
	new_cam.rotation.y = base_rotations[new_cam]
	new_cam.current = true
	camera_switched.emit(cam_id, new_cam)


func get_current_camera() -> Camera3D:
	return camera_lookup.get(current_camera_id, null)


func get_all_camera_ids() -> Array:
	return camera_lookup.keys()
