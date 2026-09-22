extends Control
class_name LevelFinish

@onready var wage_value_label: Label = $PageSummary/Panel/Point
@onready var main_menu_button: Button = $PageSummary/Panel/HBoxContainer/MainMenuButton
@onready var store_button: Button = $PageSummary/Panel/HBoxContainer/StoreButton

func _ready() -> void:
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	store_button.pressed.connect(_on_store_pressed)

func focus_defalut() -> void:
	main_menu_button.grab_focus()

func show_summary() -> void:
	wage_value_label.text = str(PointManager.total_score)

func _on_store_pressed() -> void:
	push_warning("LevelFinish: PageStore ยังไม่ implement")

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	SceneManager._show_game_ui()
