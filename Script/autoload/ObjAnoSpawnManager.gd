extends Node

const OBJ_ANO_MAX_CAPACITY: int = 6  # คงที่ทุก Level ตามเอกสาร

signal obj_ano_sleep_changed(is_sleeping: bool)
signal waiting_turn_granted(entity: Node)

var level_id: int = 0
var active_obj_ano_count: int = 0

var _waiting_queue: Array = []
var _current_waiter: Node = null

func load_level_config(new_level_id: int) -> void:
	level_id = new_level_id
	active_obj_ano_count = 0
	print("ObjAnoSpawnManager: Level Load %d" % level_id)

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

# ---------- Obj.Ano Queue ----------

func request_waiting_turn(entity: Node) -> void:
	if _current_waiter == null:
		_current_waiter = entity
		waiting_turn_granted.emit(entity)
	else:
		_waiting_queue.append(entity)

func release_waiting_turn(entity: Node) -> void:
	if _current_waiter != entity:
		return
	_current_waiter = null
	if _waiting_queue.size() > 0:
		var next_entity: Node = _waiting_queue.pop_front()
		_current_waiter = next_entity
		waiting_turn_granted.emit(next_entity)
