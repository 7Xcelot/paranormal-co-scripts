extends Node
class_name EneAnoSpawner

## Duplicates a template node from EntityLib.tscn and places it at a NodePoint.
## Unlike ObjAnoSpawner (one-shot at _ready, then frees the library), Ene.Ano
## spawns/despawns repeatedly all game long, so the library instance is kept alive.

@export var library_scene: PackedScene   # EntityLib.tscn
@export var spawn_parent_path: NodePath  # e.g. path to an "Entities" node

var _library: Node

func _ready() -> void:
	if library_scene == null:
		push_error("EneAnoSpawner: ยังไม่ได้ตั้งค่า library_scene ใน Inspector")
		return
	_library = library_scene.instantiate()
	# หมายเหตุ: ไม่ add_child(_library) เข้า scene tree เพราะเป็นแค่ที่เก็บ template
	# ไว้ duplicate ออกมาเท่านั้น ไม่ต้องการให้มันแสดงผล/ประมวลผลอะไรเอง

## เรียกจาก EneAnoSpawnManager ตอน Selective Stage เลือก entity_key ได้แล้ว
## entity_key เช่น "Attack/The_Intruder" หรือ "Attack_Special/The_Intruder_ReBalance"
func spawn_entity(entity_key: String, node_point: Node3D) -> EneAno:
	if _library == null:
		push_error("EneAnoSpawner: library ยังไม่พร้อม (library_scene ไม่ได้ตั้งค่า หรือ _ready() ยังไม่รัน)")
		return null

	var template := _library.get_node_or_null(entity_key)
	if template == null:
		push_warning("EneAnoSpawner: ไม่พบ entity_key '%s' ใน library" % entity_key)
		return null
	if not template is EneAno:
		push_warning("EneAnoSpawner: node ที่ entity_key '%s' ชี้ไป ไม่ใช่ EneAno" % entity_key)
		return null

	var instance := template.duplicate() as EneAno
	var parent: Node = get_node(spawn_parent_path) if spawn_parent_path != NodePath() else get_parent()
	parent.add_child(instance)

	if node_point != null:
		instance.global_position = node_point.global_position

	return instance

## เผื่อ EneAnoSpawnManager อยากเช็คว่า entity_key นี้มีอยู่จริงไหมก่อนจะ commit การสุ่ม
func has_entity(entity_key: String) -> bool:
	return _library != null and _library.get_node_or_null(entity_key) != null
