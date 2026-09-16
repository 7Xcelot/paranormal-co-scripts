extends Area3D
class_name EneAnoB

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

var _original_collision_layer: int = 0
var stage: Stage = Stage.INACTIVE
var blocks_hunter_report: bool = false
var _timer: float = 0.0

func _ready() -> void:
	_original_collision_layer = collision_layer
	set_process(false)

func activate() -> void:
	_enter_stage(Stage.STAGE_1)
	set_process(true)

func _process(delta: float) -> void:
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
			blocks_hunter_report = true
		Stage.COOLDOWN:
			_timer = cooldown_duration
			visible = false
			collision_layer = 0
	_play_stage_animation(new_stage)
	stage_changed.emit(self, new_stage)

func _teleport_to(point: Node3D) -> void:
	if point:
		global_position = point.global_position
		
## Duck-typed hook — เรียกจาก ReportController ตอน raycast โดน
func try_report() -> bool:
	match stage:
		Stage.STAGE_1, Stage.STAGE_2:
			_enter_stage(Stage.COOLDOWN)
			return true
		Stage.STAGE_3:
			blocks_hunter_report = false
			_return_to_pool()
			return true
		_:
			return false
			
func get_report_hold_duration() -> float:
	return 2.4
	
func _return_to_pool() -> void:
	set_process(false)
	stage = Stage.INACTIVE
	returned_to_pool.emit(self)
	
func _play_stage_animation(new_stage: Stage) -> void:
	if animation_player == null:
		return
	var clip_name := "stage_%d" % [new_stage] if new_stage in [Stage.STAGE_1, Stage.STAGE_2, Stage.STAGE_3] else  ""
	if clip_name != "" and animation_player.has_animation(clip_name):
		animation_player.play(clip_name)
