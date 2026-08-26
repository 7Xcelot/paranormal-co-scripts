extends Area3D
class_name ObjAno

signal state_changed(new_state: State)
signal anomaly_triggered(entity_id: String)
signal anomaly_reverted(entity_id: String)

enum State { QUEUED, WAITING, SPAWNING, HOLDING, ANOMALY, COOLDOWN }

## ประเภทของ Anomaly — เลือกได้จาก dropdown ใน Inspector
enum AnomalyType { DISAPPEAR, SHIFT, TEXTURE_SWAP, TOGGLE }

@export var anomaly_type: AnomalyType = AnomalyType.DISAPPEAR
@export var entity_id: String = ""
@export var score_value: int = 10
@export var normal_visual: NodePath
@export var anomaly_visual: NodePath
@export var normal_material: Material
@export var anomaly_material: Material

var current_state: State = State.QUEUED
var _timer: float = 0.0
var _timer_duration: float = 0.0

func _ready() -> void:
	if entity_id == "":
		entity_id = name
	anomaly_triggered.connect(_on_self_anomaly_triggered)
	anomaly_reverted.connect(_on_self_anomaly_reverted)
	_set_visual_state(true)
	# input_ray_pickable = true
	# input_event.connect(_on_input_event)
	SpawnManager.waiting_turn_granted.connect(_on_waiting_turn_granted)
	SpawnManager.request_waiting_turn(self)

func _on_waiting_turn_granted(entity: Node) -> void:
	if entity == self:
		_enter_waiting()

func _process(delta: float) -> void:
	if not GlobalTimeManager.is_running:
		return
	if current_state == State.QUEUED or current_state == State.HOLDING or current_state == State.ANOMALY:
		return
	_timer += delta
	if _timer >= _timer_duration:
		_on_timer_finished()

#func _on_input_event(_camera: Node, event: InputEvent, _pos: Vector3, _normal: Vector3, _shape_idx: int) -> void:
#	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
#		if try_report():
#			print("Report สำเร็จ: %s" % entity_id)

func _enter_waiting() -> void:
	current_state = State.WAITING
	_timer = 0.0
	_timer_duration = randf_range(10.0, 15.0)
	state_changed.emit(current_state)

func _enter_spawning() -> void:
	current_state = State.SPAWNING
	_timer = 0.0
	_timer_duration = randf_range(2.0, 10.0)
	state_changed.emit(current_state)
	SpawnManager.release_waiting_turn(self)

func _try_enter_anomaly() -> void:
	if SpawnManager.can_spawn_obj_ano():
		_enter_anomaly()
	else:
		current_state = State.HOLDING
		state_changed.emit(current_state)
		if not SpawnManager.obj_ano_sleep_changed.is_connected(_on_sleep_changed):
			SpawnManager.obj_ano_sleep_changed.connect(_on_sleep_changed)

func _on_sleep_changed(sleeping: bool) -> void:
	if current_state == State.HOLDING and not sleeping:
		if SpawnManager.can_spawn_obj_ano():
			SpawnManager.obj_ano_sleep_changed.disconnect(_on_sleep_changed)
			_enter_anomaly()

func _enter_anomaly() -> void:
	SpawnManager.register_obj_ano_spawned()
	current_state = State.ANOMALY
	state_changed.emit(current_state)
	anomaly_triggered.emit(entity_id)
	print("[Sec %d] Anomaly Spawn: %s | Slot %d/%d" % [
		GlobalTimeManager.get_current_second(),
		entity_id,
		SpawnManager.OBJ_ANO_MAX_CAPACITY - SpawnManager.active_obj_ano_count,
		SpawnManager.OBJ_ANO_MAX_CAPACITY
	])

func _enter_cooldown(reported: bool) -> void:
	if reported:
		SpawnManager.register_obj_ano_reported()
		ReportManager.report("obj_ano", entity_id, score_value)
	anomaly_reverted.emit(entity_id)
	current_state = State.COOLDOWN
	_timer = 0.0
	_timer_duration = _cooldown_duration_for_phase(GlobalTimeManager.current_phase)
	state_changed.emit(current_state)

func _cooldown_duration_for_phase(phase: int) -> float:
	match phase:
		1: return 12.0
		2: return 30.0
		3: return 45.0
		5: return 33.0
		_: return 12.0

func _on_timer_finished() -> void:
	match current_state:
		State.WAITING:
			_enter_spawning()
		State.SPAWNING:
			_try_enter_anomaly()
		State.COOLDOWN:
			current_state = State.QUEUED
			SpawnManager.request_waiting_turn(self)

func try_report() -> bool:
	if current_state == State.ANOMALY:
		_enter_cooldown(true)
		return true
	return false

## ---- ส่วนควบคุม visual แยกตามประเภท ----

func _on_self_anomaly_triggered(_id: String) -> void:
	match anomaly_type:
		AnomalyType.DISAPPEAR:
			_trigger_disappear()
		AnomalyType.SHIFT:
			_trigger_shift()
		AnomalyType.TEXTURE_SWAP:
			_trigger_texture_swap()
		AnomalyType.TOGGLE:
			_trigger_toggle()

func _on_self_anomaly_reverted(_id: String) -> void:
	if anomaly_type == AnomalyType.TEXTURE_SWAP:
		if normal_visual != NodePath():
			var mesh_node := get_node(normal_visual)
			if mesh_node is MeshInstance3D and normal_material != null:
				mesh_node.set_surface_override_material(0, normal_material)
	else:
		_set_visual_state(true)

func _trigger_disappear() -> void:
	_set_visual_state(false)

func _trigger_shift() -> void:
	_set_visual_state(false)

func _trigger_texture_swap() -> void:
	if normal_visual != NodePath():
		var mesh_node := get_node(normal_visual)
		if mesh_node is MeshInstance3D and anomaly_material != null:
			mesh_node.set_surface_override_material(0, anomaly_material)

func _trigger_toggle() -> void:
	_set_visual_state(false)

func _set_visual_state(show_normal: bool) -> void:
	if normal_visual != NodePath():
		get_node(normal_visual).visible = show_normal
	if anomaly_visual != NodePath():
		get_node(anomaly_visual).visible = not show_normal
