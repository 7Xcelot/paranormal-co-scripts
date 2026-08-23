extends Node
# Autoload: ตั้งชื่อ "ReportManager"

signal report_registered(report_type: String, entity_id: String, score_awarded: int)
signal score_changed(new_score: int)

const VALID_TYPES := ["obj_ano", "ene_ano", "hunter", "encounter"]

var total_score: int = 0
var report_counts: Dictionary = {
	"obj_ano": 0,
	"ene_ano": 0,
	"hunter": 0,
	"encounter": 0,
}


func report(report_type: String, entity_id: String, score_awarded: int = 0) -> void:
	if report_type not in VALID_TYPES:
		push_warning("ReportManager: ไม่รู้จัก report_type '%s' (ต้องเป็นหนึ่งใน %s)" % [report_type, VALID_TYPES])
		return

	report_counts[report_type] += 1
	total_score += score_awarded

	report_registered.emit(report_type, entity_id, score_awarded)
	if score_awarded != 0:
		score_changed.emit(total_score)

	print("Report: [%s] %s (+%d คะแนน, รวม: %d)" % [report_type, entity_id, score_awarded, total_score])


func get_count(report_type: String) -> int:
	return report_counts.get(report_type, 0)


func get_total_reports() -> int:
	var sum := 0
	for count in report_counts.values():
		sum += count
	return sum


func reset_progress() -> void:
	total_score = 0
	for key in report_counts.keys():
		report_counts[key] = 0
