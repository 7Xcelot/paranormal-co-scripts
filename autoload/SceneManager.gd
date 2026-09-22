extends Node

var current_ui: Node = null

func _show_game_ui() -> void:
	_swap_ui(preload("res://Assets/Scenes/GameUI.tscn"))

func _show_ingame_ui() -> void:
	_swap_ui(preload("res://Assets/Scenes/InGameUI.tscn"))

func _swap_ui(scene: PackedScene) -> void:
	if current_ui:
		current_ui.queue_free()
	current_ui = scene.instantiate()
	get_tree().root.add_child(current_ui)
