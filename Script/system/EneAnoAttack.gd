extends Area3D
class_name EneAnoA

signal stage_changed(instance: Node3D, new_stage: int)
signal returned_to_pool(instance: Node3D)

enum Stage { INACTIVE, STAGE_1, STAGE_2, STAGE_3, COOLDOWN }

@export var animation_player: AnimationPlayer
@export var enemy_name: String = ""
@export var stage_1_duration: float = 40.0
@export var stage_2_duration: float = 35.0
@export var cooldown_duration: float = 30.0
@export var node_point_stage_1: Node3D
@export var node_point_stage_2: Node3D
@export var node_point_stage_3: Node3D

@export_group("Stage 3 Threat")
@export var target_id: String = ""
@export var countdown_duration: float = 40.0
@export var report_window_duration: float = 6.0
@export var report_hold_multiplier: float = 1.5

var _original_collision_layer: int = 0
var stage: Stage = Stage.INACTIVE
var _timer: float = 0.0
var _threat: GameOverThreat

func _ready() -> void:
	_original_collision_layer = collision_layer
	_enter_stage(Stage.STAGE_1)
	set_process(true)

func activate() -> void:
	_enter_stage(Stage.STAGE_1)
	set_process(true)

func _process(delta: float) -> void:
	if not GlobalTimeManager.is_running:
		return
	match stage:
		Stage.STAGE_1:
			_timer -= delta
			if _timer <= 0.0:
				_enter_stage(Stage.STAGE_2)
		Stage.STAGE_2:
			_timer -= delta
			if _timer <= 0.0:
				_enter_stage(Stage.STAGE_3)
		Stage.COOLDOWN:
			_timer -= delta
			if _timer <= 0.0:
				_return_to_pool()
		Stage.STAGE_3:
			pass

func _enter_stage(new_stage: Stage) -> void:
	stage = new_stage
	match new_stage:
		Stage.STAGE_1:
			_teleport_to(node_point_stage_1)
			visible = true
			collision_layer = _original_collision_layer
			_timer = stage_1_duration
		Stage.STAGE_2:
			_teleport_to(node_point_stage_2)
			_timer = stage_2_duration
		Stage.STAGE_3:
			_teleport_to(node_point_stage_3)
			_start_threat()
		Stage.COOLDOWN:
			visible = false
			collision_layer = 0
			_timer = cooldown_duration
	_play_stage_animation(new_stage)
	stage_changed.emit(self, new_stage)

func _teleport_to(point: Node3D) -> void:
	if point:
		global_position = point.global_position

func _start_threat() -> void:
	_threat = GameOverThreat.new()
	_threat.target_id = target_id
	_threat.countdown_duration = countdown_duration
	_threat.report_window_duration = report_window_duration
	_threat.report_hold_multiplier = report_hold_multiplier
	add_child(_threat)
	_threat.threat_resolved.connect(_on_threat_resolved)
	_threat.threat_expired.connect(_on_threat_expired)
	_threat.start()

func _on_threat_resolved(_t) -> void:
	ReportManager.report("ene_ano_a", enemy_name)
	_return_to_pool()

func _on_threat_expired(_t) -> void:
	GameOverManager.trigger_game_over()

func try_report() -> bool:
	match stage:
		Stage.STAGE_1, Stage.STAGE_2:
			ReportManager.report("ene_ano_a", enemy_name)
			_enter_stage(Stage.COOLDOWN)
			return true
		Stage.STAGE_3:
			return _threat.try_report() if _threat else false
		_:
			return false

func get_threat() -> GameOverThreat:
	return _threat

func get_report_hold_duration() -> float:
	return _threat.get_report_hold_duration() if _threat else 2.4

func _return_to_pool() -> void:
	if _threat:
		_threat.queue_free()
		_threat = null
	set_process(false)
	stage = Stage.INACTIVE
	returned_to_pool.emit(self)

func _play_stage_animation(new_stage: Stage) -> void:
	if animation_player == null:
		return
	var clip_name := "stage_%d" % [new_stage] if new_stage in [Stage.STAGE_1, Stage.STAGE_2, Stage.STAGE_3] else  ""
	if clip_name != "" and animation_player.has_animation(clip_name):
		animation_player.play(clip_name)
