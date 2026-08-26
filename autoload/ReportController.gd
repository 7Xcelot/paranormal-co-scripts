extends Node

const DEFAULT_HOLD_DURATION: float = 2.4
const RAY_LENGTH: float = 1000.0

var current_target: Node = null
var hold_time: float = 0.0
var is_holding: bool = false
var overlay: Control

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(overlay)
	overlay.draw.connect(_on_overlay_draw)

func _process(delta: float) -> void:
	_update_target()
	_update_hold(delta)
	overlay.queue_redraw()
#	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
#		print("Mouse held | target = ", current_target, " | is_holding = ", is_holding)

func _update_target() -> void:
	var target := _get_target_under_mouse()
	if target != current_target:
		current_target = target
		_reset_hold()

func _update_hold(delta: float) -> void:
	if current_target == null:
		_reset_hold()
		return
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_reset_hold()
		return
	is_holding = true
	hold_time += delta
	var duration := _get_hold_duration(current_target)
	if hold_time >= duration:
		var target_ref := current_target
		_reset_hold()
		if is_instance_valid(target_ref) and target_ref.has_method("try_report"):
			target_ref.try_report()

func _reset_hold() -> void:
	is_holding = false
	hold_time = 0.0

func _get_hold_duration(target: Node) -> float:
	if target.has_method("get_report_hold_duration"):
		return target.get_report_hold_duration()
	return DEFAULT_HOLD_DURATION

func _get_target_under_mouse() -> Node:
	var camera_display := get_tree().get_first_node_in_group("camera_display")
	var camera_manager := get_tree().get_first_node_in_group("camera_manager")
	if camera_display == null or camera_manager == null:
		return null

	var cam: Camera3D = camera_manager.get_current_camera()
	if cam == null:
		return null

	var local_pos: Vector2 = camera_display.get_local_mouse_position()
	if local_pos.x < 0 or local_pos.y < 0 or local_pos.x > camera_display.size.x or local_pos.y > camera_display.size.y:
		return null   # เมาส์อยู่นอกกรอบภาพกล้อง ไม่นับ

	var camera_viewport: Viewport = camera_manager.get_viewport()
	var scale_factor: Vector2 = Vector2(camera_viewport.size) / camera_display.size
	var viewport_pos: Vector2 = local_pos * scale_factor

	var from: Vector3 = cam.project_ray_origin(viewport_pos)
	var to: Vector3 = from + cam.project_ray_normal(viewport_pos) * RAY_LENGTH

	var space_state := cam.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true
	var result := space_state.intersect_ray(query)

	if result.is_empty():
		return null
	var collider: Node = result.get("collider")
	if collider and collider.has_method("try_report"):
		return collider
	return null

func _on_overlay_draw() -> void:
	var pos: Vector2 = overlay.get_local_mouse_position()
	var arm: float = 8.0
	var color := Color.WHITE

	# วาดกากบาท "+"
	overlay.draw_line(pos + Vector2(-arm, 0), pos + Vector2(arm, 0), color, 2.0)
	overlay.draw_line(pos + Vector2(0, -arm), pos + Vector2(0, arm), color, 2.0)

	if is_holding:
		var duration := _get_hold_duration(current_target)
		var progress: float = clamp(hold_time / duration, 0.0, 1.0)
		var bar_width: float = 24.0
		var bar_height: float = 3.0
		var bar_pos := pos + Vector2(-bar_width / 2.0, arm + 6.0)
		overlay.draw_rect(Rect2(bar_pos, Vector2(bar_width, bar_height)), Color(1, 1, 1, 0.3))
		overlay.draw_rect(Rect2(bar_pos, Vector2(bar_width * progress, bar_height)), color)
