extends Node
class_name LevelConfig

# แนบกับ node ใน LevelControllers ของแต่ละ Level scene
# รวม LevelSession.gd เข้ามาแล้ว (เดิมมีแค่ GlobalTimeManager.start_timer() ซ้ำซ้อนกับที่นี่)

@export var level_id: int = 1
@export var ene_ano_whitelist: Array[String] = []
@export var ene_ano_capacity: int = 3

## เพิ่มใหม่ — ตัว EneAnoSpawnManager (autoload) เป็น script-only autoload
## ไม่มี .tscn ของตัวเอง จึงไม่มีที่เก็บ reference กลับไปยัง node ในฉากได้เอง
## ต้อง inject เข้าไปตรงนี้ตอน Level _ready() แทน
@export var ene_ano_spawner_path: NodePath          # ลาก node "EneObjSpawner" มาใส่
@export var ene_ano_node_points: Array[Node3D] = []  # ลาก NodePoint ที่จะใช้ (เผื่อไว้ก่อน — ดูหมายเหตุด้านล่าง)

func _ready() -> void:
	_wire_ene_ano_spawner()

	ObjAnoSpawnManager.load_level_config(level_id)
	EneAnoSpawnManager.load_level_config(level_id, ene_ano_whitelist, ene_ano_capacity)
	GlobalTimeManager.reset_timer()
	ReportManager.reset_progress()
	GlobalTimeManager.start_timer()

func _wire_ene_ano_spawner() -> void:
	if ene_ano_spawner_path == NodePath():
		push_error("LevelConfig: ยังไม่ได้ตั้งค่า ene_ano_spawner_path ใน Inspector")
		return

	var spawner_node := get_node_or_null(ene_ano_spawner_path)
	if spawner_node == null or not spawner_node is EneAnoSpawner:
		push_error("LevelConfig: ene_ano_spawner_path ('%s') หา EneAnoSpawner ไม่เจอ" % ene_ano_spawner_path)
		return

	EneAnoSpawnManager.spawner = spawner_node as EneAnoSpawner
	EneAnoSpawnManager.node_points = ene_ano_node_points
