extends Control

@onready var resume_button: Button = $MarginContainer/ButtonList/ResumeButton
@onready var restart_button: Button = $MarginContainer/ButtonList/RestartButton
@onready var quit_button: Button = $MarginContainer/ButtonList/QuitButton

func _ready() -> void:
	resume_button.pressed.connect(_on_resume_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func focus_default() -> void:
	resume_button.grab_focus()

func _on_resume_pressed() -> void:
	var hud: InGameUI = get_tree().get_first_node_in_group("ingame_ui")
	if hud:
		hud.toggle_pause()

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit_pressed() -> void:
	SceneManager.show_game_ui()
