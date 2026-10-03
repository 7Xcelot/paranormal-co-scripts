extends Node
signal game_over

func trigger_game_over() -> void:
	if get_tree().paused:
		return #กัน trigger ซ้ำถ้าหากมีหลาย threat expire พร้อมกัน
	get_tree().paused = true
	game_over.emit()
	print("GameOverManager: GameOver")
	
func retry() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
