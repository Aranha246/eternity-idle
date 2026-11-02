extends Control

const MINE_AMOUNT: float = 1.0
const MENU_SCENE := "res://scenes/main_menu.tscn"

@onready var _rows_container: VBoxContainer = $Root/CurrencyPanel/Margin/CurrencyVBox/ScrollContainer/VBoxContainer
@onready var _village: TextureRect = $Root/VillageArea/VillageFrame/Village
@onready var _menu_overlay: ColorRect = $MenuOverlay
@onready var _hint_label: Label = $Root/VillageArea/HintLabel

var _balance_labels: Dictionary = {}
var _convert_buttons: Dictionary = {}
var _rows: Dictionary = {}


func _ready() -> void:
	_menu_overlay.visible = false
	_build_currency_rows()
	GameManager.currency_changed.connect(_on_currency_changed)
	GameManager.tier_unlocked.connect(_on_tier_unlocked)
	_village.gui_input.connect(_on_village_gui_input)
	_refresh_all_rows()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_toggle_menu()
		get_viewport().set_input_as_handled()


func _on_village_gui_input(event: InputEvent) -> void:
	if _menu_overlay.visible:
		return
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
			GameManager.add_currency(0, MINE_AMOUNT)
			_pulse_village()


func _pulse_village() -> void:
	var tween := create_tween()
	tween.tween_property(_village, "modulate", Color(1.12, 1.08, 0.92, 1), 0.05)
	tween.tween_property(_village, "modulate", Color.WHITE, 0.12)


func _build_currency_rows() -> void:
	for child in _rows_container.get_children():
		child.queue_free()
	_balance_labels.clear()
	_convert_buttons.clear()
	_rows.clear()

	for tier_index in GameManager.TIER_COUNT:
		var row := _create_currency_row(tier_index)
		_rows_container.add_child(row)
		_rows[tier_index] = row
		row.visible = GameManager.is_tier_unlocked(tier_index)


func _create_currency_row(tier_index: int) -> Control:
	var row := HBoxContainer.new()
	row.name = "Tier%dRow" % tier_index
	row.add_theme_constant_override("separation", 8)

	var label := Label.new()
	label.name = "BalanceLabel"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.text = _format_balance_text(tier_index)
	row.add_child(label)
	_balance_labels[tier_index] = label

	if tier_index < GameManager.TIER_COUNT - 1:
		var convert_button := Button.new()
		convert_button.name = "ConvertButton"
		convert_button.text = "Convert 100"
		convert_button.tooltip_text = "Exchange 100 into 1 of the next currency"
		convert_button.pressed.connect(_on_convert_pressed.bind(tier_index))
		row.add_child(convert_button)
		_convert_buttons[tier_index] = convert_button
		_update_convert_button(tier_index)

	return row


func _on_convert_pressed(from_tier: int) -> void:
	GameManager.convert_to_next_tier(from_tier)


func _on_currency_changed(tier_index: int, new_amount: float) -> void:
	_update_balance_label(tier_index, new_amount)
	_update_convert_button(tier_index)
	if tier_index > 0:
		_update_convert_button(tier_index - 1)


func _on_tier_unlocked(tier_index: int) -> void:
	var row := _rows.get(tier_index) as Control
	if row != null:
		row.visible = true
	_update_convert_button(tier_index)
	if tier_index > 0:
		_update_convert_button(tier_index - 1)


func _refresh_all_rows() -> void:
	for tier_index in GameManager.TIER_COUNT:
		var row := _rows.get(tier_index) as Control
		if row != null:
			row.visible = GameManager.is_tier_unlocked(tier_index)
		_update_balance_label(tier_index, GameManager.get_balance(tier_index))
		_update_convert_button(tier_index)


func _update_balance_label(tier_index: int, amount: float) -> void:
	var label := _balance_labels.get(tier_index) as Label
	if label == null:
		return
	label.text = "%s: %s" % [GameManager.get_currency_name(tier_index), _format_amount(amount)]


func _update_convert_button(tier_index: int) -> void:
	var button := _convert_buttons.get(tier_index) as Button
	if button == null:
		return
	button.disabled = not GameManager.can_convert(tier_index)


func _format_balance_text(tier_index: int) -> String:
	return "%s: %s" % [
		GameManager.get_currency_name(tier_index),
		_format_amount(GameManager.get_balance(tier_index)),
	]


func _format_amount(amount: float) -> String:
	if is_equal_approx(amount, round(amount)):
		return str(int(round(amount)))
	return "%.2f" % amount


func _on_menu_button_pressed() -> void:
	_open_menu()


func _on_resume_pressed() -> void:
	_close_menu()


func _on_main_menu_pressed() -> void:
	get_tree().change_scene_to_file(MENU_SCENE)


func _on_quit_pressed() -> void:
	get_tree().quit()


func _toggle_menu() -> void:
	if _menu_overlay.visible:
		_close_menu()
	else:
		_open_menu()


func _open_menu() -> void:
	_menu_overlay.visible = true
	_hint_label.visible = false


func _close_menu() -> void:
	_menu_overlay.visible = false
	_hint_label.visible = true
