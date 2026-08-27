extends Node3D
class_name EneAno

## Base state machine shared by all Buff/Attack Ene.Ano enemies.
## Subclasses (EneAnoBuff, EneAnoAttack) override _enter_stage_3().

signal stage_changed(ene_ano: EneAno, new_stage: Stage)
signal returned_to_pool(ene_ano: EneAno)

enum Stage { INACTIVE, STAGE_1, STAGE_2, STAGE_3, COOLDOWN }

@export var enemy_name: String                    # e.g. "The Krasue"
@export var stage_1_duration: float = 40.0         # time unreported before -> Stage 2
@export var stage_2_duration: float = 35.0         # time unreported before -> Stage 3
@export var cooldown_duration: float = 30.0        # after Stage 1/2 report, before returning
@export var node_point_stage_1: Node3D
@export var node_point_stage_2: Node3D
@export var node_point_stage_3: Node3D             # may be null for enemies w/o a distinct stage-3 point

var stage: Stage = Stage.INACTIVE
var _timer: float = 0.0

func _ready() -> void:
	set_process(false)

## Called by the spawn manager once this instance is chosen and placed.
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
			pass # subclasses manage their own stage-3 process via _enter_stage_3 hooks/signals

func _enter_stage(new_stage: Stage) -> void:
	stage = new_stage
	match new_stage:
		Stage.STAGE_1:
			_teleport_to(node_point_stage_1)
			_timer = stage_1_duration
		Stage.STAGE_2:
			_teleport_to(node_point_stage_2)
			_timer = stage_2_duration
		Stage.STAGE_3:
			_teleport_to(node_point_stage_3)
			_enter_stage_3()  # virtual, subclass-defined
		Stage.COOLDOWN:
			_timer = cooldown_duration
	stage_changed.emit(self, new_stage)

## Virtual — overridden by EneAnoBuff / EneAnoAttack
func _enter_stage_3() -> void:
	push_error("EneAno._enter_stage_3() not overridden by subclass")

func _teleport_to(point: Node3D) -> void:
	if point:
		global_position = point.global_position

## Duck-typed hook called by ReportController
func try_report() -> bool:
	match stage:
		Stage.STAGE_1, Stage.STAGE_2:
			set_process(true)
			_enter_stage(Stage.COOLDOWN)
			return true
		Stage.STAGE_3:
			return _try_report_stage_3()  # virtual, subclass-defined
		_:
			return false

## Virtual — overridden by subclasses for stage-3-specific report handling
func _try_report_stage_3() -> bool:
	_return_to_pool()
	return true

func _return_to_pool() -> void:
	set_process(false)
	stage = Stage.INACTIVE
	returned_to_pool.emit(self)
