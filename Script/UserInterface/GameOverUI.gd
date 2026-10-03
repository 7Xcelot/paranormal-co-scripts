extends Control
class_name GameOverUI

@onready var retry_button = $Panel/MarginContainer/VBoxContainer/RetryButton
@onready var main_menu_button = $Panel/MarginContainer/VBoxContainer/MainMenuButton
@onready var exit_button = $Panel/MarginContainer/VBoxContainer/ExitButton

func _ready() -> void:
	retry_button.pressed.connect(_on_retry_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

func focus_default() -> void:
	retry_button.grab_focus()

func _on_retry_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	SceneManager._show_game_ui()

func _on_exit_pressed() -> void:
	get_tree().quit()
