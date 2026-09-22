extends Area3D
class_name Hunter

signal stage_changed(instance: Node3D, new_stage: int)

enum Stage { DESPAWNED, SPAWNING, DESPAWNING, HUNT_STAGE_1, HUNT_STAGE_2, HUNT_STAGE_3, HUNT_STAGE_4, COOLDOWN }
enum Phase { STARING, HUNTING }

const WAKE_TIME: float = 210.0   # GlobalTime Phase 3 — ตาม GDD

@export var hunter_path: HunterPath

@export_group("Staring Phase")
@export var staring_spawn_delay_min: float = 0.0
@export var staring_spawn_delay_max: float = 30.0
@export var staring_despawn_duration_min: float = 60.0
@export var staring_despawn_duration_max: float = 80.0
@export var cooldown_duration: float = 45.0

@export_group("Hunting Phase")
@export var hunting_stage_1_duration: float = 20.0
@export var hunting_stage_2_duration: float = 15.0
@export var hunting_stage_3_duration: float = 12.0
@export var hunting_countdown_duration: float = 20.0
@export var hunting_report_window_duration: float = 6.0
@export var hunting_report_hold_multiplier: float = 1.5
@export var hunting_target_id: String = ""   # ต้องตรงกับ key ใน LevelVisibilityConfig (เหมือน EneAnoAttack)

var stage: Stage = Stage.DESPAWNED
var phase: Phase = Phase.STARING

var _original_collision_layer: int = 0
var _has_woken: bool = false
var _timer: float = 0.0
var _pending_hunting: bool = false
var _current_hunting_path: Array[Marker3D] = []
var _threat: GameOverThreat

func _ready() -> void:
	_original_collision_layer = collision_layer
	visible = false
	collision_layer = 0
	EneAnoSpawnManager.any_stage2_reached.connect(_on_enemy_stage2_reached)
	set_process(true)

func _on_enemy_stage2_reached() -> void:
	if phase == Phase.STARING:
		_pending_hunting = true

func _process(delta: float) -> void:
	if not GlobalTimeManager.is_running:
		return
	if not _has_woken:
		if GlobalTimeManager.elapsed_time >= WAKE_TIME:
			_has_woken = true
			_enter_stage(Stage.SPAWNING)
		return

	match stage:
		Stage.SPAWNING:
			_timer -= delta
			if _timer <= 0.0:
				_enter_stage(Stage.DESPAWNING)
		Stage.DESPAWNING:
			_timer -= delta
			if _timer <= 0.0:
				if _pending_hunting:
					_enter_stage(Stage.COOLDOWN)
				else:
					_enter_stage(Stage.SPAWNING)
		Stage.HUNT_STAGE_1:
			_timer -= delta
			if _timer <= 0.0:
				_enter_stage(Stage.HUNT_STAGE_2)
		Stage.HUNT_STAGE_2:
			_timer -= delta
			if _timer <= 0.0:
				_enter_stage(Stage.HUNT_STAGE_3)
		Stage.HUNT_STAGE_3:
			_timer -= delta
			if _timer <= 0.0:
				_enter_stage(Stage.HUNT_STAGE_4)
		Stage.COOLDOWN:
			_timer -= delta
			if _timer <= 0.0:
				_exit_cooldown()
		Stage.HUNT_STAGE_4:
			pass   # จัดการผ่าน _threat ทั้งหมด

func _exit_cooldown() -> void:
	var should_hunt :=  _pending_hunting and phase == Phase.STARING
	_pending_hunting = false
	if should_hunt:
		phase = Phase.HUNTING
		_current_hunting_path = hunter_path.get_random_hunting_path()
		_enter_stage(Stage.HUNT_STAGE_1)
	else :
		phase = Phase.STARING
		_enter_stage(Stage.SPAWNING)

func _enter_stage(new_stage: Stage) -> void:
	stage = new_stage
	match new_stage:
		Stage.SPAWNING:
			visible = false
			collision_layer = 0
			_timer = randf_range(staring_spawn_delay_min, staring_spawn_delay_max)
		Stage.DESPAWNING:
			_teleport_to(hunter_path.staring_points.pick_random())
			visible = true
			collision_layer = _original_collision_layer
			_timer = randf_range(staring_despawn_duration_min, staring_despawn_duration_max)
		Stage.HUNT_STAGE_1:
			_teleport_to(_current_hunting_path[0])
			visible = true
			collision_layer = _original_collision_layer
			_timer = hunting_stage_1_duration
		Stage.HUNT_STAGE_2:
			_teleport_to(_current_hunting_path[1])
			_timer = hunting_stage_2_duration
		Stage.HUNT_STAGE_3:
			_teleport_to(_current_hunting_path[2])
			_timer = hunting_stage_3_duration
		Stage.HUNT_STAGE_4:
			_teleport_to(hunter_path.hunting_final_point)
			_start_threat()
		Stage.COOLDOWN:
			visible = false
			collision_layer = 0
			_timer = _cooldown_duration_for_phase(GlobalTimeManager.current_phase)
	stage_changed.emit(self, new_stage)

func _teleport_to(point: Node3D) -> void:
	if point:
		global_position = point.global_position

func _start_threat() -> void:
	_threat = GameOverThreat.new()
	_threat.target_id = hunting_target_id
	_threat.countdown_duration = hunting_countdown_duration
	_threat.report_window_duration = hunting_report_window_duration
	_threat.report_hold_multiplier = hunting_report_hold_multiplier
	add_child(_threat)
	_threat.threat_resolved.connect(_on_threat_resolved)
	_threat.threat_expired.connect(_on_threat_expired)
	_threat.start()

func _on_threat_resolved(_t) -> void:
	ReportManager.report("hunter_h", "Hunter")
	if _threat:
		_threat.queue_free()
		_threat = null
	_enter_stage(Stage.COOLDOWN)

func _on_threat_expired(_t) -> void:
	GameOverManager.trigger_game_over()

## Duck-typed hook — เรียกจาก ReportController ตอน raycast โดน
func try_report() -> bool:
	if _if_blocked_by_buff():
		return false
	
	match stage:
		Stage.DESPAWNING, Stage.HUNT_STAGE_1, Stage.HUNT_STAGE_2, Stage.HUNT_STAGE_3:
			var report_type := "hunter_h" if phase == Phase.HUNTING else "hunter_s"
			ReportManager.report(report_type, "Hunter")
			_enter_stage(Stage.COOLDOWN)
			return true
		Stage.HUNT_STAGE_4:
			return _threat.try_report() if _threat else false
		_:
			return false

func _if_blocked_by_buff() -> bool:
	for instance in EneAnoSpawnManager.get_active_instances().values():
		if "blocks_hunter_report" in instance and instance.blocks_hunter_report:
			return true
	return false

func get_threat() -> GameOverThreat:
	return _threat

func get_report_hold_duration() -> float:
	return _threat.get_report_hold_duration() if _threat else 2.4

func _cooldown_duration_for_phase(global_phase: int) -> float:
	match global_phase:
		5: return 31.5
		_: return cooldown_duration
