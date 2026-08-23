extends Area3D
class_name ObjAno

signal state_changed(new_state: State)
signal anomaly_triggered(entity_id: String)
signal anomaly_reverted(entity_id: String)

enum State { WAITING, SPAWNING, HOLDING, ANOMALY, COOLDOWN }

@export var entity_id: String = ""
@export var score_value: int = 10
@export var normal_visual: NodePath
@export var anomaly_visual: NodePath

var current_state: State = State.WAITING
var _timer: float = 0.0
var _timer_duration: float = 0.0

func _ready() -> void:
	if entity_id == "":
		entity_id = name
	anomaly_triggered.connect(_on_self_anomaly_triggered)
	anomaly_reverted.connect(_on_self_anomaly_reverted)
	input_ray_pickable = true
	input_event.connect(_on_input_event)
	_enter_waiting()

func _process(delta: float) -> void:
	if not GlobalTimeManager.is_running:
		return
	if current_state == State.HOLDING:
		return
	_timer += delta
	if _timer >= _timer_duration:
		_on_timer_finished()

func _on_input_event(_camera: Node, event: InputEvent, _pos: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("Click A1 แล้ว, current_state = ", current_state)
		if try_report():
			print("Report สำเร็จ: %s" % entity_id)

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

func _try_enter_anomaly() -> void:
	if SpawnManager.can_spawn_obj_ano():
		_enter_anomaly()
	else:
		current_state = State.HOLDING
		state_changed.emit(current_state)
		if not SpawnManager.obj_ano_sleep_changed.is_connected(_on_sleep_changed):
			SpawnManager.obj_ano_sleep_changed.connect(_on_sleep_changed)
	print("Anomaly เข้าแล้ว")

func _on_sleep_changed(sleeping: bool) -> void:
	if current_state == State.HOLDING and not sleeping:
		if SpawnManager.can_spawn_obj_ano():
			SpawnManager.obj_ano_sleep_changed.disconnect(_on_sleep_changed)
			_enter_anomaly()
		# ถ้ายังเต็มอยู่ (ตัวอื่นแย่ง slot ไปก่อน) ก็ค้าง HOLDING ต่อ ไม่ disconnect เผื่อรอบหน้า

func _enter_anomaly() -> void:
	SpawnManager.register_obj_ano_spawned()
	current_state = State.ANOMALY
	_timer = 0.0
	_timer_duration = 15.0
	state_changed.emit(current_state)
	anomaly_triggered.emit(entity_id)

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
		State.ANOMALY:
			_enter_cooldown(false)
		State.COOLDOWN:
			_enter_waiting()

func try_report() -> bool:
	if current_state == State.ANOMALY:
		_enter_cooldown(true)
		return true
	return false

func _on_self_anomaly_triggered(_id: String) -> void:
	if normal_visual != NodePath():
		get_node(normal_visual).visible = false
	if anomaly_visual != NodePath():
		get_node(anomaly_visual).visible = true

func _on_self_anomaly_reverted(_id: String) -> void:
	if normal_visual != NodePath():
		get_node(normal_visual).visible = true
	if anomaly_visual != NodePath():
		get_node(anomaly_visual).visible = false
