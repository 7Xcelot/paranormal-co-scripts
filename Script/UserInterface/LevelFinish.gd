extends Control
class_name LevelFinish

const DEFAULT_MISSION_STATUS := "Successfully Compleated as Contracted"

@onready var wage_value_label: Label = $PageSummary/Panel/Point
@onready var main_menu_button: Button = $PageSummary/Panel/HBoxContainer/MainMenuButton
@onready var store_button: Button = $PageSummary/Panel/HBoxContainer/StoreButton

# ต้อง verify node path จริงตอนต่อ scene — ชื่อด้านล่างเป็นการเดาตามภาพ concept
@onready var case_summary_label: Label = $PageSummary/Panel/CaseSummaryReport
@onready var operational_summary_label: RichTextLabel = $PageSummary/Panel/RichTextLabel

func _ready() -> void:
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	store_button.pressed.connect(_on_store_pressed)

func focus_defalut() -> void:
	main_menu_button.grab_focus()

func show_summary() -> void:
	wage_value_label.text = str(PointManager.total_score)

	var data := LevelDataManager.current_case_data
	if data == null:
		push_warning("LevelFinish: LevelDataManager.current_case_data ยังไม่ถูก set")
		return

	case_summary_label.text = "Case Summary Report: Case No. %s\nMission: Status: %s" % [data.report_id, DEFAULT_MISSION_STATUS]
	operational_summary_label.text = data.operational_summary

func _on_store_pressed() -> void:
	push_warning("LevelFinish: PageStore ยังไม่ implement")

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	SceneManager._show_game_ui()
