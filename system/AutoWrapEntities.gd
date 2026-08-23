@tool
extends EditorScript

# ระบุตรงนี้ว่าเอนทิตี้ตัวไหนเป็น humanoid (capsule) ตัวไหนประหลาด (convex ตาม mesh จริง)
const HUMANOID_ENTITIES := ["E1", "E2"]
const ANOMALOUS_ENTITIES := ["E3", "E4"]

const ANOMALY_SCRIPT_PATH := "res://Assets/Script/system/AnomalyEntity.gd"


func _run():
	var scene_root = get_editor_interface().get_edited_scene_root()
	if scene_root == null:
		push_error("AutoWrapEntities: ไม่มี scene เปิดอยู่ในตอนนี้")
		return

	var entities_node = scene_root.get_node_or_null("Entities")
	if entities_node == null:
		push_error("AutoWrapEntities: ไม่พบ node ชื่อ 'Entities' ใน scene")
		return

	# ต้อง .duplicate() รายชื่อลูกก่อน เพราะเราจะแก้โครงสร้าง tree ระหว่างวนลูป
	var targets: Array = entities_node.get_children().duplicate()

	for child in targets:
		if child is MeshInstance3D:
			_wrap_with_area3d(entities_node, child, scene_root)

	print("AutoWrapEntities: เสร็จสิ้น กรุณาเซฟ scene ด้วย Ctrl+S")


func _wrap_with_area3d(parent: Node, mesh_instance: MeshInstance3D, scene_root: Node) -> void:
	var entity_name := mesh_instance.name as String
	var original_idx := mesh_instance.get_index()
	var original_transform := mesh_instance.transform

	# 1. สร้าง Area3D มาแทนที่ตำแหน่งเดิมของ mesh ใน tree
	var area := Area3D.new()
	area.name = entity_name

	parent.remove_child(mesh_instance)
	parent.add_child(area)
	area.owner = scene_root
	parent.move_child(area, original_idx)

	# 2. ย้าย transform เดิมไปไว้ที่ Area3D แล้วรีเซ็ต mesh ให้เป็น local identity
	area.transform = original_transform
	mesh_instance.transform = Transform3D.IDENTITY
	area.add_child(mesh_instance)
	mesh_instance.owner = scene_root

	# 3. สร้าง CollisionShape3D ตามประเภทเอนทิตี้
	var collision_shape := CollisionShape3D.new()
	collision_shape.name = "CollisionShape3D"
	var aabb: AABB = mesh_instance.get_aabb()

	if entity_name in HUMANOID_ENTITIES:
		var capsule := CapsuleShape3D.new()
		capsule.height = aabb.size.y
		capsule.radius = max(aabb.size.x, aabb.size.z) * 0.5
		collision_shape.shape = capsule
		collision_shape.position = aabb.get_center()

	elif entity_name in ANOMALOUS_ENTITIES:
		var mesh: Mesh = mesh_instance.mesh
		if mesh:
			collision_shape.shape = mesh.create_convex_shape()
		else:
			push_warning("AutoWrapEntities: %s ไม่มี Mesh, ใช้ BoxShape3D แทน" % entity_name)
			var box := BoxShape3D.new()
			box.size = aabb.size
			collision_shape.shape = box
			collision_shape.position = aabb.get_center()

	else:
		# default: BoxShape3D สำหรับเอนทิตี้ที่ไม่ได้ระบุประเภท
		var box := BoxShape3D.new()
		box.size = aabb.size
		collision_shape.shape = box
		collision_shape.position = aabb.get_center()

	area.add_child(collision_shape)
	collision_shape.owner = scene_root

	# 4. แนบสคริปต์ AnomalyEntity.gd และตั้ง entity_id
	var anomaly_script = load(ANOMALY_SCRIPT_PATH)
	if anomaly_script:
		area.set_script(anomaly_script)
		area.set("entity_id", entity_name)
	else:
		push_warning("AutoWrapEntities: หาสคริปต์ที่ %s ไม่เจอ" % ANOMALY_SCRIPT_PATH)

	print("Wrapped %s -> %s" % [entity_name, collision_shape.shape.get_class()])
