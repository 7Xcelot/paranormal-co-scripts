extends Node
class_name EneAnoSpawner

@export var library_scene: PackedScene
@export var spawn_parent_path: NodePath

@export_group("Krasue Path (Prototype)")
@export var krasue_stage1: Node3D
@export var krasue_stage2: Node3D
@export var krasue_stage3: Node3D

@export_group("Intruder Path (Prototype)")
@export var intruder_stage1: Node3D
@export var intruder_stage2: Node3D
@export var intruder_stage3: Node3D

var _library: Node

func _ready() -> void:
	if library_scene == null:
		push_error("EneAnoSpawner: ยังไม่ได้ตั้งค่า library_scene")
		return
	_library = library_scene.instantiate()

func spawn_entity(entity_key: String, initial_point: Node3D) -> EneAno:
	if _library == null:
		push_error("EneAnoSpawner: library ยังไม่พร้อม")
		return null

	var template := _library.get_node_or_null(entity_key)
	if template == null or not template is EneAno:
		push_warning("EneAnoSpawner: entity_key ไม่ถูกต้อง: %s" % entity_key)
		return null

	var instance := template.duplicate() as EneAno
	var parent: Node = get_node(spawn_parent_path) if spawn_parent_path != NodePath() else get_parent()
	parent.add_child(instance)

	_assign_node_points(instance, entity_key)

	if initial_point != null:
		instance.global_position = initial_point.global_position

	return instance

## ผูก NodePoint ของแต่ละ Stage ให้ instance ตามชื่อ entity_key
## ชั่วคราวสำหรับ Prototype เท่านั้น — ต้องออกแบบใหม่ให้ scale ได้ตอนมีศัตรูครบ 6+ ตัวจริง
func _assign_node_points(instance: EneAno, entity_key: String) -> void:
	match entity_key:
		"Buff/The_Krasue":
			instance.node_point_stage_1 = krasue_stage1
			instance.node_point_stage_2 = krasue_stage2
			instance.node_point_stage_3 = krasue_stage3
		"Attack/The_Intruder":
			instance.node_point_stage_1 = intruder_stage1
			instance.node_point_stage_2 = intruder_stage2
			instance.node_point_stage_3 = intruder_stage3
		_:
			push_warning("EneAnoSpawner: ไม่มี NodePoint mapping สำหรับ '%s'" % entity_key)
