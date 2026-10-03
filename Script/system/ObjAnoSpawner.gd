extends Node
class_name ObjAnoSpawner

@export var library_scene: PackedScene
@export var spawn_parent_path: NodePath   # เช่น path ไปยัง node "Entities"

func _ready() -> void:
	if library_scene == null:
		push_error("ObjAnoSpawner: ยังไม่ได้ตั้งค่า library_scene ใน Inspector")
		return

	var library := library_scene.instantiate()
	var parent: Node = get_node(spawn_parent_path) if spawn_parent_path != NodePath() else get_parent()
	var markers := get_tree().get_nodes_in_group("obj_ano_markers")

	var spawned_count := 0
	for marker in markers:
		if not marker is ObjAnoMarker:
			continue
		var template := library.get_node_or_null(marker.anomaly_key)
		if template == null:
			push_warning("ObjAnoSpawner: ไม่พบ anomaly_key '%s' สำหรับ marker '%s'" % [marker.anomaly_key, marker.name])
			continue

		var instance := template.duplicate()
		parent.add_child(instance)
		instance.global_transform = marker.global_transform
		instance.entity_id = marker.entity_id_override if marker.entity_id_override != "" else marker.name
		marker.queue_free()
		spawned_count += 1

	library.free()
	print("ObjAnoSpawner: แทนที่ marker สำเร็จ %d จุด" % spawned_count)
