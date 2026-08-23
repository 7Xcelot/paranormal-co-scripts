extends Node
class_name LevelConfig
# แนบกับ node ใน LevelControllers ของแต่ละ Level scene

@export var level_id: int = 1
@export var ene_ano_whitelist: Array[String] = []
@export var ene_ano_capacity: int = 3

func _ready():
	SpawnManager.load_level_config(level_id, ene_ano_whitelist, ene_ano_capacity)
	GlobalTimeManager.reset_timer()
	ReportManager.reset_progress()
	GlobalTimeManager.start_timer()
