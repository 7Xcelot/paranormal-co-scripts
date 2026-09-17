extends Control

@onready var main_menu = $MainMargin/OutlinePanel/MenuStack/MainMenu
@onready var level_selection = $MainMargin/OutlinePanel/MenuStack/LevelSelective
@onready var option_menu = $MainMargin/OutlinePanel/MenuStack/Option

@onready var first_main_btn = $MainMargin/OutlinePanel/MenuStack/MainMenu/Menu_VBox/Start_Button
@onready var first_level_btn = $MainMargin/OutlinePanel/MenuStack/LevelSelective/Case_List_Scroll/Accordion_VBox/Case1_Container/Case1_Header

func _ready() -> void:
	switch_to_menu(main_menu, first_main_btn)
	first_main_btn.pressed.connect(_on_start_button_pressed)

func switch_to_menu(target_menu: Control, focus_button: Button = null):
	main_menu.visible = false
	level_selection.visible = false
	option_menu.visible = false
	target_menu.visible = true
	if focus_button:
		focus_button.grab_focus()

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		if level_selection.visible or option_menu.visible:
			switch_to_menu(main_menu, first_main_btn)
			get_viewport().set_input_as_handled()

func _on_start_button_pressed():
	switch_to_menu(level_selection, first_level_btn)
