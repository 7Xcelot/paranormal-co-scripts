extends Node
# Autoload: "DebugTools" (เดิมชื่อ DebugTimeControl — ต้องไปเปลี่ยนชื่อใน
# Project Settings > Autoload ด้วย มิฉะนั้น global ยังเป็น DebugTimeControl อยู่)
# ทำงานเฉพาะ debug build เท่านั้น — export build จริงปิดตัวเองอัตโนมัติ

var _enabled: bool = false

# --- [Log] state ---
var _time_log_enabled: bool = false
var _last_logged_tick: int = -1

# --- [EneAno] state ---
var _eneano_log_enabled: bool = false

# --- [GameOverThreat] state --- alway toggle
var _watched_threats: Dictionary = {} # threat -> enemy_label
var _last_threat_tick: Dictionary = {} # threat -> last logged 5s tick

# --- [Alert] state ---
var _cam_manager_connected: bool = false

func _ready() -> void:
	_enabled = OS.is_debug_build()
	if not _enabled:
		return
	EneAnoSpawnManager.ene_ano_spawned.connect(_on_ene_ano_spawned)
	EneAnoSpawnManager.ene_ano_returned.connect(_on_ene_ano_returned)
	print("DebugTools: เปิดใช้งาน (debug build เท่านั้น) — กด F1 เพื่อดูปุ่มทั้งหมด")

func _unhandled_key_input(event: InputEvent) -> void:
	if not _enabled or not event is InputEventKey or not event.pressed:
		return
	match event.keycode:
		KEY_F1:
			_print_help()
		# --- [Time] ---
		KEY_F5:
			_time_set_speed(1.0)
		KEY_F6:
			_time_set_speed(2.0)
		KEY_F7:
			_time_set_speed(5.0)
		KEY_F9:
			_time_jump_next_phase()
		KEY_F12:
			_time_toggle_pause()
		# --- [Log] ---
		KEY_F2:
			_log_toggle_global_time()
		# --- [EneAno] ---
		KEY_F3:
			_eneano_toggle_log()
		KEY_F4:
			_eneano_dump_active()

func _process(_delta: float) -> void:
	if not _enabled:
		return
	if _time_log_enabled:
		_log_check_tick()
	for threat in _watched_threats.keys():
		if threat.state == GameOverThreat.State.COUNTING_DOWN or threat.state == GameOverThreat.State.PAUSED_FOR_REPORT:
			_threat_tick_check(threat)
	if not _cam_manager_connected:
		_try_connect_camera_manager()

func _try_connect_camera_manager() -> void:
	var cam_manager = get_tree().get_first_node_in_group("camera_manager")
	if cam_manager == null:
		return
	cam_manager.alert_started.connect(func(id): print("DebugTools[Alert]: STARTED  target=%s" % id))
	cam_manager.alert_stopped.connect(func(id): print("DebugTools[Alert]: STOPPED  target=%s" % id))
	_cam_manager_connected = true
	print("DebugTools[Alert]: เจอ CameraManager แล้ว ต่อ log สำเร็จ")

# ============================================================
# [Time] — ควบคุมความเร็ว/เวลาเกม
# ============================================================
func _time_set_speed(scale: float) -> void:
	Engine.time_scale = scale
	print("DebugTools[Time]: speed = %.0fx" % scale)

func _time_toggle_pause() -> void:
	if Engine.time_scale > 0.0:
		Engine.time_scale = 0.0
		print("DebugTools[Time]: paused")
	else:
		Engine.time_scale = 1.0
		print("DebugTools[Time]: resumed (1x)")

## กระโดด elapsed_time ไปที่ threshold ของ Phase ถัดไปทันที
func _time_jump_next_phase() -> void:
	var thresholds: Array = GlobalTimeManager.PHASE_THRESHOLDS.values()
	thresholds.sort()
	for t in thresholds:
		if t > GlobalTimeManager.elapsed_time:
			GlobalTimeManager.elapsed_time = t
			print("DebugTools[Time]: jump elapsed_time -> %.0fs" % t)
			return
	print("DebugTools[Time]: อยู่ Phase สุดท้ายแล้ว ไม่มีที่ให้กระโดดต่อ")

# ============================================================
# [Log] — toggle print เวลาทุก 10 วิ
# ============================================================
func _log_toggle_global_time() -> void:
	_time_log_enabled = not _time_log_enabled
	_last_logged_tick = -1
	print("DebugTools[Log]: GlobalTime tick log = %s" % ("ON" if _time_log_enabled else "OFF"))

func _log_check_tick() -> void:
	var tick: int = int(GlobalTimeManager.elapsed_time / 10.0)
	if tick != _last_logged_tick:
		_last_logged_tick = tick
		print("DebugTools[Log]: elapsed = %.0fs | phase = %s" % [
			GlobalTimeManager.elapsed_time, GlobalTimeManager.current_phase
		])

# ============================================================
# [EneAno] — ตรวจ Spawn จริงว่าใช้ Marker ตัวไหน (ไล่บั๊ก Marker1/Marker3)
# ============================================================
func _eneano_toggle_log() -> void:
	_eneano_log_enabled = not _eneano_log_enabled
	print("DebugTools[EneAno]: spawn log = %s" % ("ON" if _eneano_log_enabled else "OFF"))

func _on_ene_ano_spawned(instance) -> void:
	if _eneano_log_enabled:
		_print_instance_markers(instance, "SPAWNED")
	if instance.has_signal("stage_changed"):
		instance.stage_changed.connect(_on_instance_stage_changed)

func _on_instance_stage_changed(instance, new_stage: int) -> void:
	if _eneano_log_enabled:
		var enemy_label: String = instance.enemy_name if "enemy_name" in instance else "?"
		print("DebugTools[EneAno]: STAGE_CHANGED[%s] -> %s  pos=%s  t=%.0fs" % [
			enemy_label, new_stage, instance.global_position, GlobalTimeManager.elapsed_time
		])

	# --- [GameOverThreat] ทำงานตลอด ไม่ขึ้นกับ _eneano_log_enabled ---
	if new_stage == 3 and "target_id" in instance:
		if instance.has_method("get_threat"):
			var threat: GameOverThreat = instance.get_threat()
			if threat == null:
				print("DebugTools[GameOverThreat]: WARNING | เข้า Stage 3 แล้วแต่ get_threat() คืนค่าเป็น null")
				return
			var t_label: String = instance.enemy_name if "enemy_name" in instance else "?"
			_watched_threats[threat] = t_label
			threat.state_changed.connect(_on_threat_state_changed)
			_print_threat_state(threat, threat.state, "START")
		else:
			print("DebugTools[GameOverThreat]: WARNING | Attack instance ไม่มี get_threat() เลย")

func _on_threat_state_changed(threat: GameOverThreat, new_stage: int) -> void:
	_print_threat_state(threat, new_stage, "CHANGED")
	if new_stage == GameOverThreat.State.RESOLVED or new_stage == GameOverThreat.State.EXPIRED:
		_watched_threats.erase(threat)

func _print_threat_state(threat: GameOverThreat, state: int, tag: String) -> void:
	const  STATE_NAMES = ["INACTIVE", "NOTIFY", "COUNTING_DOWN", "PAUSED_FOR_REPORT", "RESOLVED", "EXPIRED"]
	var label: String = _watched_threats.get(threat, "?")
	print("DebugTools[GameOverThreat][%s] %s: state=%s cooldown_left=%.1fs target=%s t=%.0fs" % [
		label, tag, STATE_NAMES[state], threat.get_countdown_time_left(), threat.target_id,
		GlobalTimeManager.elapsed_time
	])

func _threat_tick_check(threat: GameOverThreat) -> void:
	var tick: int = int(threat.get_countdown_time_left() / 5.0)
	if _last_threat_tick.get(threat, -1) != tick:
		_last_threat_tick[threat] = tick
		_print_threat_state(threat, threat.state, "TICK")

func _on_ene_ano_returned(entity_key: String) -> void:
	if _eneano_log_enabled:
		print("DebugTools[EneAno]: RETURNED  key=%s" % entity_key)

## กด F4 เมื่อไหร่ก็ได้ — dump instance ที่ Active อยู่ตอนนี้ พร้อมชื่อ Marker ที่ผูกไว้จริง
func _eneano_dump_active() -> void:
	var instances: Dictionary = EneAnoSpawnManager.get_active_instances()
	if instances.is_empty():
		print("DebugTools[EneAno]: ไม่มี instance active อยู่ตอนนี้")
		return
	print("DebugTools[EneAno]: active = %d" % instances.size())
	for key in instances.keys():
		_print_instance_markers(instances[key], "ACTIVE(%s)" % key)

func _print_instance_markers(instance, label: String) -> void:
	var s1: String = instance.node_point_stage_1.name if instance.node_point_stage_1 else "(none)"
	var s2: String = instance.node_point_stage_2.name if instance.node_point_stage_2 else "(none)"
	var s3: String = instance.node_point_stage_3.name if instance.node_point_stage_3 else "(none)"
	print("DebugTools[EneAno]: %s  pos=%s  stage=%s  s1=%s  s2=%s  s3=%s" % [
		label, instance.global_position, instance.stage, s1, s2, s3
	])

# ============================================================
# [Alert]
# ============================================================


# ============================================================
# [Help]
# ============================================================
func _print_help() -> void:
	print("""
	--- DebugTools ---
	[Time]
	  F5  speed x1        F9  jump to next Phase
	  F6  speed x2        F12 pause / resume
	  F7  speed x5
	[Log]
	  F2  toggle GlobalTime tick log (ทุก 10 วิ)
	[EneAno]
	  F3  toggle spawn/return log (auto print ตอน spawn/return)
	  F4  dump active instances + marker ที่ผูกไว้จริงตอนนี้ (เรียกได้ทุกเมื่อ)
	""")
