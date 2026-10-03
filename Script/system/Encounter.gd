extends Node3D
class_name Encounter

signal resolved
signal state_changed(new_state: int)

enum State { INACTIVE, WAITING, ACTIVE, RESOLVED, EXPIRED, DESPAWNED }

@export var cam_id: String = ""
@export var animation_player: AnimationPlayer
@export var jumpscare_clip: String = "jumpscare"
@export var waiting_duration: float = 40.0        # รอผู้เล่นมาเจอ ก่อน Despawn เอง
@export var countdown_duration: float = 15.0      # เวลา Report หลัง Active แล้ว (placeholder)
@export var blackout_duration: float = 100.0

var consumed: bool = false
var state: State = State.INACTIVE
var _timer: float = 0.0

func _ready() -> void:
	visible = false
	set_process(false)
	EncounterManager.register(self)

func _get_camera_manager() -> CameraManager:
	return get_tree().get_first_node_in_group("camera_manager") as CameraManager

func trigger() -> void:
	consumed = true
	_set_state(State.WAITING)
	visible = true
	_timer = waiting_duration
	set_process(true)
	var cam_manager := _get_camera_manager()
	if cam_manager:
		cam_manager.camera_switched.connect(_on_camera_switched)

func _process(delta: float) -> void:
	match state:
		State.WAITING:
			_timer -= delta
			if _timer <= 0.0:
				_despawn()
		State.ACTIVE:
			_timer -= delta
			if _timer <= 0.0:
				_expire()

func _on_camera_switched(id: String, _cam: Camera3D) -> void:
	if state == State.WAITING and id == cam_id:
		_activate()

func _activate() -> void:
	_set_state(State.ACTIVE)
	_timer = countdown_duration
	var cam_manager := _get_camera_manager()
	if cam_manager:
		cam_manager.camera_switched.disconnect(_on_camera_switched)
		cam_manager.lock_to(cam_id)
	if animation_player and animation_player.has_animation(jumpscare_clip):
		animation_player.play(jumpscare_clip)

func _despawn() -> void:
	_set_state(State.DESPAWNED)
	set_process(false)
	visible = false
	var cam_manager := _get_camera_manager()
	if cam_manager and cam_manager.camera_switched.is_connected(_on_camera_switched):
		cam_manager.camera_switched.disconnect(_on_camera_switched)
	EncounterManager._on_encounter_resolved()

func _expire() -> void:
	_set_state(State.EXPIRED)
	set_process(false)
	visible = false
	var cam_manager := _get_camera_manager()
	if cam_manager:
		cam_manager.unlock()
		cam_manager.blackout_camera(cam_id, blackout_duration)
	resolved.emit()
	EncounterManager._on_encounter_resolved()

## เรียกจาก ReportController ตรงๆ (ไม่ผ่าน raycast)
func try_report() -> bool:
	if state != State.ACTIVE:
		return false
	_set_state(State.RESOLVED)
	set_process(false)
	visible = false
	var cam_manager := _get_camera_manager()
	if cam_manager:
		cam_manager.unlock()
	resolved.emit()
	EncounterManager._on_encounter_resolved()
	return true

func _set_state(new_state: State) -> void:
	state = new_state
	state_changed.emit(new_state)
