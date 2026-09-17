extends Control

@onready var crt_r_effect = $"../../../../CRTFlicker"

@onready var case1_header = $Case_List_Scroll/Accordion_VBox/Case1_Container/Case1_Header
@onready var case1_detail = $Case_List_Scroll/Accordion_VBox/Case1_Container/Case1_Detail_VBox
@onready var case1_enter_btn = $Case_List_Scroll/Accordion_VBox/Case1_Container/Case1_Detail_VBox/Action_HBox/Enter_Button

@onready var case2_header = $Case_List_Scroll/Accordion_VBox/Case2_Container/Case2_Header
@onready var case2_detail = $Case_List_Scroll/Accordion_VBox/Case2_Container/Case2_Detail_VBox
@onready var case2_enter_btn = $Case_List_Scroll/Accordion_VBox/Case2_Container/Case2_Detail_VBox/Action_HBox/Enter_Button

var current_open_detail: VBoxContainer = null

func _ready() -> void:
	case1_header.pressed.connect(_on_case_header_pressed.bind(case1_detail, case1_enter_btn))
	case2_header.pressed.connect(_on_case_header_pressed.bind(case2_detail, case2_enter_btn))

func _on_case_header_pressed(target_detail: VBoxContainer, target_enter_btn: Button):
	play_crt_r_flicker()
	if current_open_detail == target_detail:
		target_enter_btn.grab_focus()
		return
	if current_open_detail != null:
		current_open_detail.visible = false
	target_detail.visible = true
	current_open_detail = target_detail
	target_enter_btn.grab_focus()

func play_crt_r_flicker():
	crt_r_effect.visible = true
	await get_tree().create_timer(0.05).timeout
	crt_r_effect.visible = false

func _input(event):
	if not visible:
		return
	if event.is_action_pressed("ui_down") and current_open_detail != null:
		if case1_enter_btn.has_focus():
			case2_header.grab_focus()
			get_viewport().set_input_as_handled()
