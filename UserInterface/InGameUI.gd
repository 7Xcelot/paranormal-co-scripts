extends CanvasLayer
class_name InGameUI

enum State { GAMEPLAY, PAUSED, GAMEOVER, LEVEL_FINISH }
var state: State = State.GAMEPLAY

@onready var crosshair_bar: Control = $HUDLayer/IngameHUD/CrosshairBar
@onready var info_readout1: Label = $HUDLayer/IngameHUD/InfoReadout1
@onready var info_readout2: Label = $HUDLayer/IngameHUD/InfoReadout2
@onready var info_readout3: Label = $HUDLayer/IngameHUD/InfoReadout3
@onready var cam_offline: Control = $HUDLayer/NoSignalCam

@onready var flicker_rect: ColorRect = $TransitionLayer/FlickerRect
@onready var blur_rect: ColorRect = $TransitionLayer/BlurRect

@onready var pause_window: Control = $ModalLayer/PauseWindow
@onready var game_over_ui: Control = $ModalLayer/GameOverUI
@onready var level_finish: Control = $ModalLayer/LevelFinish
@onready var page_summary: Control = $ModalLayer/LevelFinish/PageSummary
@onready var page_store: Control = $ModalLayer/LevelFinish/PageStore

var _backed_out_cam_id: String = ""
var _level_config: Node = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	flicker_rect.visible = false
	blur_rect.visible = false
	pause_window.visible = false
	game_over_ui.visible = false
	level_finish.visible = false
	cam_offline.visible = false
	
	GameOverManager.game_over.connect(_on_game_over)
	_level_config = get_tree().get_first_node_in_group("level_config")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action("ui_cancel") and state in [State.GAMEPLAY, State.PAUSE]:
		_toggle_pause()

func _process(delta: float) -> void:
	_update_info_readout()
	_update_cam_offline()

# ============================================================
# Info Readout
# ============================================================
func _update_info_readout() -> void:
	if _level_config == null:
		return
	var cam_manager := get_tree().get_first_node_in_group("camera_manager")
	var cam_id: String = cam_manager.current_camera_id if cam_manager else "?"
	info_readout1.text = "%s: %s" % [_level_config.case_date_label, GlobalTimeManager.get_clock_display()]
	info_readout2.text = "Camera: %s" % cam_id
	info_readout3.text = "CaseNo.%s" % _level_config.case_no

# ============================================================
# CamOffline
# ============================================================
func _update_cam_offline() -> void:
	var cam_manager := get_tree().get_first_node_in_group("camera_manager")
	if cam_manager == null:
		return
	var current_id: String = cam_manager.current_camera_id
	var blacked: bool = cam_manager.is_camera_blacked_out(current_id)
	
	if blacked and _blacked_out_cam_id != current_id:
		_backed_out_cam_id = current_id
		cam_offline.visible = true
	elif  not blacked:
		_blacked_out_cam_id = ""
		cam_offline.visible = false

# ============================================================
# Transition Effects
# ============================================================
func flicker() -> void:
	flicker_rect.visible = true
	await get_tree().process_frame
	flicker_rect.visible = false

# ============================================================
# Modal 
# ============================================================
func _close_all_modals() -> void:
	pause_window.visible = false
	game_over_ui.visible = false
	level_finish.visible = false

func _toggle_pause() -> void:
	if state == State.PAUSED:
		state = State.GAMEPLAY
		pause_window.visible = false
		blur_rect.visible = false
		get_tree().paused = false
	else:
		state = State.PAUSED
		_close_all_modals()
		pause_window.visible = true
		blur_rect.visible = true
		get_tree().paused = true

func _show_gameOver() -> void:
	state = State.GAMEOVER
	_close_all_modals()
	flicker()
	game_over_ui.visible = true
	get_tree().paused = true

func _show_levelFinish() -> void:
	state = State.LEVEL_FINISH
	_close_all_modals()
	flicker()
	level_finish.visible = true
	page_summary.visible = true
	page_store.visible = false
	get_tree().paused = true

func _on_game_over() -> void:
	_show_gameOver()
