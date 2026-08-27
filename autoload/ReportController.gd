extends Node

const REPORT_HOLD_DURATION: float = 2.4
const REPORT_COOLDOWN: float = 1.5
const MOVE_CANCEL_THRESHOLD_PX: float = 10.4
const RAY_LENGTH: float = 1000.0
const BAR_FADE_DURATION: float = 1.0

var is_holding: bool = false
var hold_time: float = 0.0
var anchor_pos: Vector2 = Vector2.ZERO
var action_cooldown: float = 0.0

var _bar_alpha: float = 0.0
var _bar_frozen_progress: float = 0.0
var _bar_frozen_pos: Vector2 = Vector2.ZERO

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
	if action_cooldown > 0.0:
		action_cooldown -= delta
		_reset_hold()
	else:
		_update_hold(delta)

	_update_bar_fade(delta)
	overlay.queue_redraw()

func _update_hold(delta: float) -> void:
	var camera_display := get_tree().get_first_node_in_group("camera_display")
	if camera_display == null:
		_reset_hold()
		return

	var local_pos: Vector2 = camera_display.get_local_mouse_position()
	var inside_display: bool = (
		local_pos.x >= 0 and local_pos.y >= 0
		and local_pos.x <= camera_display.size.x and local_pos.y <= camera_display.size.y
	)
	var mouse_down: bool = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

	if not is_holding:
		if mouse_down and inside_display:
			is_holding = true
			hold_time = 0.0
			anchor_pos = local_pos
		return

	if not mouse_down or not inside_display:
		_reset_hold()
		return
	if local_pos.distance_to(anchor_pos) > MOVE_CANCEL_THRESHOLD_PX:
		_reset_hold()
		return

	hold_time += delta
	if hold_time >= REPORT_HOLD_DURATION:
		_attempt_report(camera_display)
		action_cooldown = REPORT_COOLDOWN
		_reset_hold()

func _attempt_report(camera_display: Control) -> void:
	var camera_manager := get_tree().get_first_node_in_group("camera_manager")
	if camera_manager == null:
		return
	var cam: Camera3D = camera_manager.get_current_camera()
	if cam == null:
		return

	var camera_viewport: Viewport = camera_manager.get_viewport()
	var scale_factor: Vector2 = Vector2(camera_viewport.size) / camera_display.size
	var viewport_pos: Vector2 = anchor_pos * scale_factor

	var from: Vector3 = cam.project_ray_origin(viewport_pos)
	var to: Vector3 = from + cam.project_ray_normal(viewport_pos) * RAY_LENGTH

	var space_state := cam.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true
	var result := space_state.intersect_ray(query)

	if result.is_empty():
		return
	var collider: Node = result.get("collider")
	if collider and collider.has_method("try_report"):
		collider.try_report()

func _reset_hold() -> void:
	is_holding = false
	hold_time = 0.0

func _update_bar_fade(delta: float) -> void:
	if is_holding:
		_bar_alpha = 0.2
		_bar_frozen_progress = hold_time / REPORT_HOLD_DURATION
	elif _bar_alpha > 0.0:
		_bar_alpha = max(0.0, _bar_alpha - delta / BAR_FADE_DURATION)

func _on_overlay_draw() -> void:
	var pos: Vector2 = overlay.get_local_mouse_position()
	var arm: float = 8.0
	overlay.draw_line(pos + Vector2(-arm, 0), pos + Vector2(arm, 0), Color.WHITE, 2.0)
	overlay.draw_line(pos + Vector2(0, -arm), pos + Vector2(0, arm), Color.WHITE, 2.0)

	if _bar_alpha <= 0.0:
		return
	var bar_width: float = 24.0
	var bar_height: float = 3.0
	var origin := pos + Vector2(-bar_width / 2.0, arm + 6.0)
	overlay.draw_rect(Rect2(origin, Vector2(bar_width, bar_height)), Color(1, 1, 1, 0.3 * _bar_alpha))
	overlay.draw_rect(Rect2(origin, Vector2(bar_width * _bar_frozen_progress, bar_height)), Color(1, 1, 1, _bar_alpha))
