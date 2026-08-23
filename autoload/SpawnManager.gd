extends Node
# Autoload: ตั้งชื่อ "SpawnManager"

const OBJ_ANO_MAX_CAPACITY: int = 6  # คงที่ทุก Level ตามเอกสาร

signal obj_ano_sleep_changed(is_sleeping: bool)
signal ene_ano_pool_updated()

var level_id: int = 0
var ene_ano_whitelist: Array[String] = []
var ene_ano_capacity: int = 0

var active_obj_ano_count: int = 0
var active_ene_ano_ids: Array[String] = []  # ชื่อเอนทิตี้ที่ active อยู่ตอนนี้ กันเลือกซ้ำ


func load_level_config(new_level_id: int, whitelist: Array[String], new_ene_ano_capacity: int) -> void:
	level_id = new_level_id
	ene_ano_whitelist = whitelist.duplicate()
	ene_ano_capacity = new_ene_ano_capacity
	active_obj_ano_count = 0
	active_ene_ano_ids.clear()
	print("SpawnManager: โหลด Level %d (Ene.Ano whitelist: %s, capacity: %d)" % [level_id, ene_ano_whitelist, ene_ano_capacity])


# ---------- Obj.Ano ----------

func can_spawn_obj_ano() -> bool:
	return active_obj_ano_count < OBJ_ANO_MAX_CAPACITY


func register_obj_ano_spawned() -> void:
	active_obj_ano_count += 1
	if active_obj_ano_count >= OBJ_ANO_MAX_CAPACITY:
		obj_ano_sleep_changed.emit(true)


func register_obj_ano_reported() -> void:
	var was_full := active_obj_ano_count >= OBJ_ANO_MAX_CAPACITY
	active_obj_ano_count = max(0, active_obj_ano_count - 1)
	if was_full and active_obj_ano_count < OBJ_ANO_MAX_CAPACITY:
		obj_ano_sleep_changed.emit(false)  # ปลุกระบบ Obj.Ano กลับมาทำงาน


# ---------- Ene.Ano ----------

func request_ene_ano_spawn() -> String:
	# คืนชื่อ entity ที่เลือกได้ หรือ "" ถ้า spawn ไม่ได้ (เต็ม capacity หรือ whitelist ว่าง)
	if active_ene_ano_ids.size() >= ene_ano_capacity:
		return ""

	var available: Array = ene_ano_whitelist.filter(func(id): return id not in active_ene_ano_ids)
	if available.is_empty():
		return "" # ผู้เรียกต้อง sleep เองเมื่อได้ค่านี้กลับไป

	var chosen: String = available[randi() % available.size()]
	active_ene_ano_ids.append(chosen)
	ene_ano_pool_updated.emit()
	return chosen


func register_ene_ano_despawned(entity_name: String) -> void:
	active_ene_ano_ids.erase(entity_name)
	ene_ano_pool_updated.emit()


func get_active_ene_ano_count() -> int:
	return active_ene_ano_ids.size()


func reset() -> void:
	active_obj_ano_count = 0
	active_ene_ano_ids.clear()
