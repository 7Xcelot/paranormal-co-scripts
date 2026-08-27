extends EneAno
class_name EneAnoBuff

var blocks_hunter_report: bool = false

func _enter_stage_3() -> void:
	blocks_hunter_report = true
	# stays here indefinitely — no timer set, base _process() does nothing in STAGE_3

func _try_report_stage_3() -> bool:
	blocks_hunter_report = false
	_return_to_pool()
	return true
