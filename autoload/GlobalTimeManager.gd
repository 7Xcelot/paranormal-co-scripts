extends Node
# Autoload: ตั้งชื่อ "GlobalTimeManager"

const LEVEL_DURATION: float = 885.0

# Phase หลัก (ใช้คำนวณ cooldown ของ Obj.Ano / Ene.Ano / Hunter)
# ไม่มี Phase 4 ในนี้ เพราะ Phase 4 เป็นแค่หน้าต่างเหตุการณ์พิเศษที่ทับซ้อนกับ Phase 3/5 (ดูด้านล่าง)
const PHASE_THRESHOLDS := {
	1: 30.0,
	2: 120.0,
	3: 210.0,
	5: 730.0,
}

# หน้าต่าง The Encounter (Phase 4 ตามเอกสาร) — แยกต่างหากเพราะทับซ้อนกับ Phase 3 ท้ายและ Phase 5 ต้น
const ENCOUNTER_WINDOW_START: float = 550.0
const ENCOUNTER_WINDOW_END: float = 740.0

# ตาราง Hour สำหรับ UI นาฬิกา (11PM - 5AM)
const HOUR_TABLE := [
	{"hour": 1, "start": 0.0,   "end": 135.0},
	{"hour": 2, "start": 135.0, "end": 275.0},
	{"hour": 3, "start": 275.0, "end": 420.0},
	{"hour": 4, "start": 420.0, "end": 570.0},
	{"hour": 5, "start": 570.0, "end": 725.0},
	{"hour": 6, "start": 725.0, "end": 885.0},
]

signal second_tick(current_second: int)
signal phase_changed(new_phase: int)
signal hour_changed(new_hour: int)
signal encounter_window_started()
signal encounter_window_ended()
signal level_time_ended()

var elapsed_time: float = 0.0
var is_running: bool = false

var current_phase: int = 0   # 0 = ยังไม่เข้า Phase ไหนเลย (ช่วง 0-30 วิแรก)
var current_hour: int = 1
var is_encounter_window_active: bool = false

var _last_whole_second: int = -1


func _process(delta: float) -> void:
	if not is_running:
		return

	elapsed_time += delta

	if elapsed_time >= LEVEL_DURATION:
		elapsed_time = LEVEL_DURATION
		is_running = false
		level_time_ended.emit()
		return

	_check_second_tick()
	_check_phase()
	_check_hour()
	_check_encounter_window()


func _check_second_tick() -> void:
	var whole_second := int(elapsed_time)
	if whole_second != _last_whole_second:
		_last_whole_second = whole_second
		second_tick.emit(whole_second)


func _check_phase() -> void:
	var new_phase := current_phase
	for phase_num in PHASE_THRESHOLDS.keys():
		if elapsed_time >= PHASE_THRESHOLDS[phase_num]:
			new_phase = phase_num

	if new_phase != current_phase:
		current_phase = new_phase
		phase_changed.emit(current_phase)


func _check_hour() -> void:
	for entry in HOUR_TABLE:
		if elapsed_time >= entry["start"] and elapsed_time < entry["end"]:
			if entry["hour"] != current_hour:
				current_hour = entry["hour"]
				hour_changed.emit(current_hour)
			return


func _check_encounter_window() -> void:
	var should_be_active: bool = elapsed_time >= ENCOUNTER_WINDOW_START and elapsed_time < ENCOUNTER_WINDOW_END

	if should_be_active and not is_encounter_window_active:
		is_encounter_window_active = true
		encounter_window_started.emit()
	elif not should_be_active and is_encounter_window_active:
		is_encounter_window_active = false
		encounter_window_ended.emit()


func start_timer() -> void:
	is_running = true


func pause_timer() -> void:
	is_running = false


func reset_timer() -> void:
	elapsed_time = 0.0
	is_running = false
	current_phase = 0
	current_hour = 1
	is_encounter_window_active = false
	_last_whole_second = -1


func get_current_second() -> int:
	return int(elapsed_time)
