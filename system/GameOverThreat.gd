extends Node
class_name GameOverThreat

## Reusable threat pattern shared by The Hunter and Ene.Ano (A.):
## NOTIFY -> COUNTING_DOWN -> (paused when player reaches target_location) ->
## PAUSED_FOR_REPORT -> REPORTED (resolved) or EXPIRED (game over)

signal threat_expired(threat: GameOverThreat)
signal threat_resolved(threat: GameOverThreat)
signal state_changed(threat: GameOverThreat, new_state: State)

enum State { INACTIVE, NOTIFY, COUNTING_DOWN, PAUSED_FOR_REPORT, RESOLVED, EXPIRED }

@export var target_location: Node3D          # Mission Point or PlayerPoint
@export var countdown_duration: float = 40.0 # 40.0 for Ene.Ano (A.), 20.0 for Hunter
@export var report_window_duration: float = 6.0
@export var report_hold_multiplier: float = 1.5
@export var target_scene_id: StringName # how close player must be to target_location to pause


var state: State = State.INACTIVE
var _time_left: float = 0.0
var player_ref: Node3D = null  # assign externally (e.g. via group lookup) before starting

func _ready() -> void:
	set_process(false)

func start() -> void:
	if state != State.INACTIVE:
		push_warning("GameOverThreat.start() called while already active")
		return
	_change_state(State.NOTIFY)
	# Caller (EneAnoAttack / Hunter) is expected to connect to state_changed
	# and fire the actual notification UI when it sees NOTIFY.
	_change_state(State.COUNTING_DOWN)
	_time_left = countdown_duration
	set_process(true)

func _process(delta: float) -> void:
	match state:
		State.COUNTING_DOWN:
			_time_left -= delta
			if _player_at_target():
				_change_state(State.PAUSED_FOR_REPORT)
				_time_left = report_window_duration
			elif _time_left <= 0.0:
				_expire()
		State.PAUSED_FOR_REPORT:
			_time_left -= delta
			if not _player_at_target():
				# Player left before reporting: resume the countdown from where it paused
				_change_state(State.COUNTING_DOWN)
				# NOTE: decide whether report_window time lost should just be discarded
				# (current behavior) or carried back into countdown; left as-is for now.
			elif _time_left <= 0.0:
				_expire()

func _player_at_target() -> bool:
	var cam_manager := _get_camera_manager()
	if cam_manager == null or cam_manager.active_camera == null:
		return false
	return cam_manager.active_camera.scene_id == target_scene_id
	
func _get_camera_manager() -> Node:
	var group := get_tree().get_first_node_in_group("camera_manager")
	return group

## Call this from ReportController/whatever calls try_report() on this threavat's target
func try_report() -> bool:
	if state != State.PAUSED_FOR_REPORT:
		return false
	_change_state(State.RESOLVED)
	set_process(false)
	threat_resolved.emit(self)
	return true

## Duck-typed hook for ReportController's per-target hold duration
func get_report_hold_duration() -> float:
	return 2.4 * report_hold_multiplier if state == State.PAUSED_FOR_REPORT else 2.4

func _expire() -> void:
	_change_state(State.EXPIRED)
	set_process(false)
	threat_expired.emit(self)

func _change_state(new_state: State) -> void:
	state = new_state
	state_changed.emit(self, new_state)
