extends Node
# Autoload: "EneAnoSpawnManager" (แยกจาก ObjAnoSpawnManager แล้ว)

## Check -> Selective -> Time&Cooldown state machine ตาม GDD (Entity_Type_Anomaly.md)

signal ene_ano_spawned(instance: EneAno)
signal ene_ano_returned(entity_name: String)

enum SpawnStage { SLEEPING, CHECK, SELECTIVE, TIME_AND_COOLDOWN }

const WAKE_TIME: float = 120.0

@export var spawner: EneAnoSpawner            # ตัวที่เขียนไว้ก่อนหน้า
@export var node_points: Array[Node3D] = []   # NodePoint ที่ใช้สุ่ม/กำหนดตำแหน่ง spawn เริ่มต้น

var level_id: int = 0
var ene_ano_whitelist: Array[String] = []     # entity_key เช่น "Attack/The_Intruder"
var ene_ano_capacity: int = 0

var active_ene_ano_ids: Array[String] = []    # entity_key ที่ active อยู่ตอนนี้ (กันเลือกซ้ำ)
var _active_instances: Dictionary = {}        # entity_key -> EneAno instance

var _stage: SpawnStage = SpawnStage.SLEEPING
var _has_woken: bool = false
var _cooldown_timer: float = 0.0
var _spawn_delay_timer: float = 0.0
var _pending_key: String = ""

func load_level_config(new_level_id: int, whitelist: Array[String], new_capacity: int) -> void:
	level_id = new_level_id
	ene_ano_whitelist = whitelist.duplicate()
	ene_ano_capacity = new_capacity
	active_ene_ano_ids.clear()
	_active_instances.clear()
	_stage = SpawnStage.SLEEPING
	_has_woken = false
	set_process(true)  # แก้: เดิมเป็น false แล้วไม่มีใครเปิดกลับมาเลย ทำให้ _process() ไม่ทำงานเลยทั้งเกม
	print("EneAnoSpawnManager: Level Load %d (whitelist: %s, capacity: %d)" % [level_id, ene_ano_whitelist, ene_ano_capacity])

func _process(delta: float) -> void:
	if not _has_woken:
		if GlobalTimeManager.elapsed_time >= WAKE_TIME:
			_has_woken = true
			_enter_stage(SpawnStage.CHECK)
		return

	match _stage:
		SpawnStage.TIME_AND_COOLDOWN:
			if _pending_key != "":
				_spawn_delay_timer -= delta
				if _spawn_delay_timer <= 0.0:
					_do_spawn(_pending_key)
					_pending_key = ""
					_cooldown_timer = _get_cooldown_duration()
			else:
				_cooldown_timer -= delta
				if _cooldown_timer <= 0.0:
					_enter_stage(SpawnStage.CHECK)

func _enter_stage(new_stage: SpawnStage) -> void:
	_stage = new_stage
	match new_stage:
		SpawnStage.CHECK:
			_run_check_stage()
		SpawnStage.SELECTIVE:
			_run_selective_stage()
		SpawnStage.TIME_AND_COOLDOWN:
			pass  # _process() จัดการต่อเอง
		SpawnStage.SLEEPING:
			pass

func _run_check_stage() -> void:
	if active_ene_ano_ids.size() >= ene_ano_capacity:
		_stage = SpawnStage.SLEEPING  # รอ _on_instance_returned ปลุกใหม่ ไม่ busy-loop
		return
	_enter_stage(SpawnStage.SELECTIVE)

func _run_selective_stage() -> void:
	var eligible: Array[String] = ene_ano_whitelist.filter(
		func(key): return key not in active_ene_ano_ids
	)
	if eligible.is_empty():
		_stage = SpawnStage.SLEEPING  # ไม่มีตัวว่างเหลือใน whitelist
		return
	_pending_key = eligible.pick_random()
	active_ene_ano_ids.append(_pending_key)  # จองไว้ตั้งแต่ตอนนี้ กัน Selective รอบถัดไปเลือกซ้ำ
	_spawn_delay_timer = randf_range(10.0, 20.0)
	_enter_stage(SpawnStage.TIME_AND_COOLDOWN)

func _get_cooldown_duration() -> float:
	match GlobalTimeManager.current_phase:
		3:
			return 40.0
		5:
			return 30.0
		_:
			return 40.0  # fallback — GDD ระบุแค่ Phase 3 และ 5 ชัดเจน

func _do_spawn(entity_key: String) -> void:
	if spawner == null:
		push_error("EneAnoSpawnManager: spawner ยังไม่ได้ตั้งค่า")
		return
	var node_point: Node3D = node_points.pick_random() if not node_points.is_empty() else null
	var instance := spawner.spawn_entity(entity_key, node_point)
	if instance == null:
		# spawn ไม่สำเร็จ (เช่น entity_key ผิด) — คืน reservation แล้วลองใหม่รอบหน้า
		active_ene_ano_ids.erase(entity_key)
		return
	_active_instances[entity_key] = instance
	instance.returned_to_pool.connect(_on_instance_returned.bind(entity_key))
	instance.activate()
	ene_ano_spawned.emit(instance)
	# เพิ่มใหม่ — log สไตล์เดียวกับ ObjAno เพื่อ debug ว่าระบบทำงานอยู่
	print("[Sec %d] EneAno Spawn: %s | Active %d/%d" % [
		GlobalTimeManager.get_current_second(),
		entity_key,
		active_ene_ano_ids.size(),
		ene_ano_capacity
	])

func _on_instance_returned(entity_key: String) -> void:
	var instance: EneAno = _active_instances.get(entity_key)
	if instance:
		instance.queue_free()
	_active_instances.erase(entity_key)
	active_ene_ano_ids.erase(entity_key)
	ene_ano_returned.emit(entity_key)
	if _stage == SpawnStage.SLEEPING and _has_woken:
		_enter_stage(SpawnStage.CHECK)  # slot ว่างแล้ว เช็คใหม่ทันที

func reset() -> void:
	for instance in _active_instances.values():
		instance.queue_free()
	_active_instances.clear()
	active_ene_ano_ids.clear()
	_stage = SpawnStage.SLEEPING
	_has_woken = false
	set_process(false)
