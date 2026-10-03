extends Node

signal report_registered(report_type: String, entity_id: String)

const VALID_TYPES := ["obj_ano", "ene_ano_a", "ene_ano_b", "hunter_s", "hunter_h"]

var report_counts: Dictionary = {
	"obj_ano": 0,
	"ene_ano_a": 0,
	"ene_ano_b": 0,
	"hunter_s": 0,
	"hunter_h": 0,
}

func report(report_type: String, entity_id: String) -> void:
	if report_type not in VALID_TYPES:
		push_warning("ReportManager: ไม่รู้จัก report_type '%s' (ต้องเป็นหนึ่งใน %s)" % [report_type, VALID_TYPES])
		return
	report_counts[report_type] += 1
	report_registered.emit(report_type, entity_id)
	print("Report: [%s] %s" % [report_type, entity_id])

func get_count(report_type: String) -> int:
	return report_counts.get(report_type, 0)

func get_total_reports() -> int:
	var sum := 0
	for count in report_counts.values():
		sum += count
	return sum

func reset_progress() -> void:
	for key in report_counts.keys():
		report_counts[key] = 0
