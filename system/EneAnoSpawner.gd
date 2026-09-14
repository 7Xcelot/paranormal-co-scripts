extends Node
class_name EneAnoSpawner

## รับผิดชอบ instantiate EneAno entity (Attack/Buff) จาก library
## และผูก NodePoint (Stage 1/2/3) ให้ตาม EneAnoPath ที่วางไว้ใน Level scene

@export var library_scene: PackedScene
@export var spawn_parent_path: NodePath
@export var path_container_path: NodePath   # ลาก node ที่รวม EneAnoPath ทุกตัวของ Level นี้

var _library: Node
var _paths: Dictionary = {}   # entity_key -> EneAnoPath

func _ready() -> void:
	if library_scene == null:
		push_error("EneAnoSpawner: ยังไม่ได้ตั้งค่า library_scene")
		return
	_library = library_scene.instantiate()
	_collect_paths()

func _collect_paths() -> void:
	if path_container_path == NodePath():
		push_error("EneAnoSpawner: ยังไม่ได้ตั้งค่า path_container_path")
		return
	var container := get_node_or_null(path_container_path)
	if container == null:
		push_error("EneAnoSpawner: หา path_container ไม่เจอ ('%s')" % path_container_path)
		return
	for child in container.get_children():
		if child is EneAnoPath:
			if child.entity_key == "":
				push_error("EneAnoSpawner: EneAnoPath '%s' ยังไม่ได้ตั้ง entity_key" % child.name)
				continue
			if _paths.has(child.entity_key):
				push_error("EneAnoSpawner: entity_key '%s' ซ้ำกันที่ node '%s' — ใช้ตัวแรกที่เจอ ('%s') เท่านั้น" % [
					child.entity_key, child.name, _paths[child.entity_key].name
				])
				continue
			_paths[child.entity_key] = child

## คืนค่า instance แบบ dynamic (ไม่มี base class ร่วมระหว่าง Attack/Buff แล้ว)
## ต้อง duck-type เช็ค has_method("activate") แทนการ type-cast
func spawn_entity(entity_key: String, initial_point: Node3D):
	if _library == null:
		push_error("EneAnoSpawner: library ยังไม่พร้อม")
		return null

	var template := _library.get_node_or_null(entity_key)
	if template == null or not template.has_method("activate"):
		push_warning("EneAnoSpawner: entity_key ไม่ถูกต้องหรือไม่ใช่ EneAno entity: %s" % entity_key)
		return null

	var instance := template.duplicate()
	var parent: Node = get_node(spawn_parent_path) if spawn_parent_path != NodePath() else get_parent()
	parent.add_child(instance)

	_assign_node_points(instance, entity_key)

	if initial_point != null:
		instance.global_position = initial_point.global_position

	return instance

## ผูก NodePoint ของแต่ละ Stage ให้ instance ตาม EneAnoPath ที่ match entity_key
## แทนที่ match statement เดิม — เพิ่ม Enemy/Level ใหม่ = วาง EneAnoPath ใน Scene ไม่ต้องแก้โค้ด
func _assign_node_points(instance, entity_key: String) -> void:
	var path: EneAnoPath = _paths.get(entity_key)
	if path == null:
		push_warning("EneAnoSpawner: ไม่มี EneAnoPath สำหรับ '%s' ใน Level นี้" % entity_key)
		return
	instance.node_point_stage_1 = path.stage_1
	instance.node_point_stage_2 = path.stage_2
	instance.node_point_stage_3 = path.stage_3
