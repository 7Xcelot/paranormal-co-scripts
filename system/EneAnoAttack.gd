extends EneAno
class_name EneAnoAttack

@export var game_over_threat: GameOverThreat  # assign in scene, or instantiate here

func _enter_stage_3() -> void:
	game_over_threat.target_id = "mission_point"  # or wherever it should attack
	game_over_threat.threat_resolved.connect(_on_threat_resolved, CONNECT_ONE_SHOT)
	game_over_threat.threat_expired.connect(_on_threat_expired, CONNECT_ONE_SHOT)
	game_over_threat.start()

func _try_report_stage_3() -> bool:
	return game_over_threat.try_report()  # delegates to GameOverThreat's own state check

func _on_threat_resolved(_threat) -> void:
	_return_to_pool()

func _on_threat_expired(_threat) -> void:
	pass # GameOverManager (not yet written) should listen to game_over_threat.threat_expired directly
