extends Node
class_name GameOverThreat

## Reusable threat pattern shared by The Hunter and Ene.Ano (A.):
## NOTIFY -> COUNTING_DOWN -> (paused when player's camera can see target_id) ->
## PAUSED_FOR_REPORT -> REPORTED (resolved) or EXPIRED (game over)
## Reusable threat pattern ที่ใช้ร่วมกันระหว่าง The Hunter และ Ene.Ano (A.):
## NOTIFY -> COUNTING_DOWN -> (pause เมื่อกล้องผู้เล่นเห็น target_id) ->
## PAUSED_FOR_REPORT -> RESOLVED (report ทัน) หรือ EXPIRED (game over)

signal threat_expired(threat: GameOverThreat)
signal threat_resolved(threat: GameOverThreat)
signal state_changed(threat: GameOverThreat, new_state: State)

enum State { INACTIVE, NOTIFY, COUNTING_DOWN, PAUSED_FOR_REPORT, RESOLVED, EXPIRED }

@export var target_id: String                 # เช่น "mission_point" — ต้องตรงกับ key ใน LevelVisibilityConfig
@export var countdown_duration: float = 40.0  # 40.0 สำหรับ Ene.Ano (A.), 20.0 สำหรับ Hunter
@export var report_window_duration: float = 6.0
@export var report_hold_multiplier: float = 1.5

var state: State = State.INACTIVE

## แยกเวลา 2 ช่วงออกจากกันเด็ดขาด — เดิมใช้ตัวแปรเดียวปนกัน (บั๊กหลัก)
var _countdown_time_left: float = 0.0   # เวลาที่เหลือของ GameOverCountdown จริง ไม่ถูกแตะระหว่าง PAUSED_FOR_REPORT
var _report_time_left: float = 0.0      # เวลาที่เหลือของหน้าต่าง Report (6 วิ) เท่านั้น

func _ready() -> void:
	set_process(false)

func start() -> void:
	if state != State.INACTIVE:
		push_warning("GameOverThreat.start() called while already active")
		return
	_change_state(State.NOTIFY)
	_set_alert(true)
	# Caller (EneAnoAttack / Hunter) ควร connect state_changed แล้วเช็ค NOTIFY เพื่อยิง UI แจ้งเตือน
	_change_state(State.COUNTING_DOWN)
	_countdown_time_left = countdown_duration
	set_process(true)

func _process(delta: float) -> void:
	match state:
		State.COUNTING_DOWN:
			_countdown_time_left -= delta
			if _player_at_target():
				_change_state(State.PAUSED_FOR_REPORT)
				_report_time_left = report_window_duration
			elif _countdown_time_left <= 0.0:
				_expire()
		State.PAUSED_FOR_REPORT:
			_report_time_left -= delta
			if not _player_at_target():
				# กลับไปนับ GameOverCountdown ต่อจากที่ค้างไว้จริง — _countdown_time_left ไม่ถูกแตะระหว่างนี้เลย
				_change_state(State.COUNTING_DOWN)
			elif _report_time_left <= 0.0:
				_expire()

func _player_at_target() -> bool:
	var cam_manager := _get_camera_manager()
	if cam_manager == null or cam_manager.visibility_config == null:
		return false
	return cam_manager.visibility_config.can_see(cam_manager.current_camera_id, target_id)

func _get_camera_manager() -> CameraManager:
	return get_tree().get_first_node_in_group("camera_manager") as CameraManager

## เรียกจาก ReportController ตอน raycast โดน target นี้
func try_report() -> bool:
	if state != State.PAUSED_FOR_REPORT:
		return false
	_change_state(State.RESOLVED)
	set_process(false)
	_set_alert(false)
	threat_resolved.emit(self)
	return true

## Duck-typed hook — ReportController ใช้รู้ว่าต้อง hold นานเท่าไหร่
func get_report_hold_duration() -> float:
	return 2.4 * report_hold_multiplier if state == State.PAUSED_FOR_REPORT else 2.4

## เวลาที่เหลือจริงของ GameOverCountdown — เผื่อ UI/Debug อยากโชว์ ไม่ต้องสนใจว่าตอนนี้อยู่ state ไหน
func get_countdown_time_left() -> float:
	return _countdown_time_left

func _expire() -> void:
	_change_state(State.EXPIRED)
	set_process(false)
	_set_alert(false)
	threat_expired.emit(self)

func _change_state(new_state: State) -> void:
	state = new_state
	state_changed.emit(self, new_state)

func _set_alert(active: bool) -> void:
	var cam_manager := _get_camera_manager()
	if cam_manager == null:
		return
	if active:
		cam_manager.alert_started.emit(target_id)
	else:
		cam_manager.alert_stopped.emit(target_id)
