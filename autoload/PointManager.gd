extends Node

const  POINT_TABLE := {
	"obj_ano": 100,
	"ene_ano_a": 1500,
	"ene_ano_b": 1200,
	"hunter_s": 1200,
	"hunter_h": 1800,
}

var total_score: int = 0

signal  score_changed(new_score: int)

func _ready() -> void:
	ReportManager.report_registered.connect(_on_report_registered)

func _on_report_registered(report_type: String, _entity_id: String) -> void:
	var points: int = POINT_TABLE.get(report_type, 0)
	if points == 0:
		push_warning("PointManager: ไม่รู้จัก report_type '%s' ใน  POINT_TABLE" % report_type)
		return
	total_score += points
	score_changed.emit(total_score)

func reset() -> void:
	total_score = 0
	score_changed.emit(total_score)
