extends Node

var current_case_data: LevelCaseData = null

func load_case_data(data: LevelCaseData) -> void:
	if data == null:
		push_warning("LevelDataManager: ได้รับ case_data เป็น null")
	current_case_data = data
