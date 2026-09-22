extends Node

const REPORT_HOLD_DURATION: float = 2.4
const REPORT_COOLDOWN: float = 1.5
const MOVE_CANCEL_THRESHOLD_PX: float = 10.4
const RAY_LENGTH: float = 1000.0
const CLICK_THRESHOLD: float = 0.1

var reporting_enabled: bool = false
var is_holding: bool = false
var hold_time: float = 0.0
var anchor_pos: Vector2 = Vector2.ZERO
var action_cooldown: float = 0.0

func _ready() -> void:
	pass  # Input.mouse_mode ค่อยตั้งตอนมี custom cursor แล้ว

func set_reporting_enabled(enabled: bool) -> void:
	reporting_enabled = enabled
	print("🔴 reporting_enabled = ", enabled)
	Crosshair.set_bar_enabled(enabled)
	if not enabled:
		_reset_hold()

func _process(delta: float) -> void:
	if not reporting_enabled:
		return
	if action_cooldown > 0.0:
		action_cooldown -= delta
		_reset_hold()
	else:
		_update_hold(delta)

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

	if hold_time > CLICK_THRESHOLD:
		Crosshair.set_bar_enabled(true)
		Crosshair.set_progress(hold_time / REPORT_HOLD_DURATION)

	if hold_time >= REPORT_HOLD_DURATION:
		_attempt_report(camera_display)
		action_cooldown = REPORT_COOLDOWN
		_reset_hold()

func _attempt_report(camera_display: Control) -> void:
	if EncounterManager.active_encounter != null and EncounterManager.active_encounter.state == Encounter.State.ACTIVE:
		EncounterManager.active_encounter.try_report()
		return
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
	Crosshair.set_bar_enabled(false)
