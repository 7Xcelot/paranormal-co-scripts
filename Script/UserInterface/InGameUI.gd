extends CanvasLayer
class_name InGameUI

enum State { GAMEPLAY, PAUSED, GAME_OVER, LEVEL_FINISH }
var state: State = State.GAMEPLAY

@onready var pause_ui: Control = $ModalLayer/PauseUI
@onready var game_over_ui: Control = $ModalLayer/GameOverUI
@onready var level_finish: Control = $ModalLayer/LevelFinish
@onready var page_summary: Control = $ModalLayer/LevelFinish/PageSummary
@onready var flicker_rect: ColorRect = $TransitionLayer/FlickerRect
@onready var blur_rect: Control = $TransitionLayer/BlurRect
@onready var blur_pass_h: ColorRect = $TransitionLayer/BlurRect/BlurPassH
@onready var blur_pass_v: ColorRect = $TransitionLayer/BlurRect/BlurPassV
@onready var in_game_userinterface: Control = $InGameUserInterface

func  _ready() -> void:
	add_to_group("ingame_ui")
	process_mode = Node.PROCESS_MODE_ALWAYS
	_close_all_modals()
	flicker_rect.visible = false
	blur_rect.visible = false
	blur_pass_h.material = _build_blur_pass_material(true)
	blur_pass_v.material = _build_blur_pass_material(false)
	GameOverManager.game_over.connect(_on_game_over)
	_set_state(State.GAMEPLAY)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and state in [State.GAMEPLAY, State.PAUSED]:
		toggle_pause()

# ============================================================
# Centralized state entry — จุดเดียวที่ตัดสินใจว่า report ได้ไหม
# ============================================================

func _set_state(new_state: State) -> void:
	state = new_state
	ReportController.set_reporting_enabled(new_state == State.GAMEPLAY)
	_update_camera_layout_visibility(new_state == State.GAMEPLAY)

func _update_camera_layout_visibility(_show: bool) -> void:
	var canvas := get_tree().get_first_node_in_group("camera_layout_canvas")
	if canvas:
		canvas.visible = _show

func _close_all_modals() -> void:
	pause_ui.visible = false
	game_over_ui.visible = false
	level_finish.visible = false

func toggle_pause() -> void:
	if state == State.PAUSED:
		_set_state(State.GAMEPLAY)
		pause_ui.visible = false
		blur_rect.visible = false
		in_game_userinterface.visible = true
		get_tree().paused = false
	else:
		_close_all_modals()
		_set_state(State.PAUSED)
		pause_ui.visible = true
		pause_ui.focus_default()
		blur_rect.visible = true
		in_game_userinterface.visible = false
		get_tree().paused = true

func show_game_over() -> void:
	_close_all_modals()
	_set_state(State.GAME_OVER)
	flicker()
	game_over_ui.visible = true
	get_tree().paused = true

func show_level_finish() -> void:
	_close_all_modals()
	_set_state(State.LEVEL_FINISH)
	flicker()
	level_finish.visible = true
	page_summary.visible = true
	get_tree().paused = true

func flicker() -> void:
	flicker_rect.visible = true
	await get_tree().process_frame
	flicker_rect.visible = false

func _on_game_over() -> void:
	show_game_over()

func _build_blur_pass_material(is_horizontal: bool) -> ShaderMaterial:
	var shader := Shader.new()
	var direction := "vec2(1.0, 0.0)" if is_horizontal else "vec2(0.0, 1.0)"
	shader.code = """
shader_type canvas_item;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear;
uniform float blur_size : hint_range(0.0, 20.0) = 6.0;

void fragment() {
	vec2 dir = %s;
	vec4 sum = vec4(0.0);
	float total = 0.0;
	for (int i = -8; i <= 8; i++) {
		float weight = exp(-float(i * i) / (2.0 * 3.0 * 3.0));
		vec2 offset = dir * float(i) * blur_size * SCREEN_PIXEL_SIZE;
		vec2 uv = clamp(SCREEN_UV + offset, vec2(0.0), vec2(1.0));
		sum += texture(SCREEN_TEXTURE, uv) * weight;
		total += weight;
	}
	COLOR = sum / total;
}
""" % direction
	var mat := ShaderMaterial.new()
	mat.shader = shader
	return mat
