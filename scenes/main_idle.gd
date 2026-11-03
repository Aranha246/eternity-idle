extends Control

const MENU_SCENE := "res://scenes/main_menu.tscn"
const SETTINGS_SCENE := preload("res://scenes/settings_menu.tscn")

@onready var _rows_container: VBoxContainer = %CurrenciesContainer
@onready var _village: TextureRect = $Root/RightContentArea/VillagePanel/VillageMargin/Village
@onready var _menu_overlay: ColorRect = $MenuOverlay
@onready var _hint_label: Label = $Root/RightContentArea/VillagePanel/VillageMargin/Village/HintLabel
@onready var _stats_vbox: VBoxContainer = %StatsVBox
@onready var _hero_sprite: TextureRect = %VillageHeroSprite

var _balance_labels: Dictionary = {}
var _convert_buttons: Dictionary = {}
var _rows: Dictionary = {}
var _stat_labels: Dictionary = {}
var _settings_instance: Control


func _ready() -> void:
	_menu_overlay.visible = false
	_build_currency_rows()
	_initialize_stats_display()
	
	GameManager.currency_changed.connect(_on_currency_changed)
	GameManager.tier_unlocked.connect(_on_tier_unlocked)
	GameManager.quest_completed.connect(_on_quest_completed)
	GameManager.quest_started.connect(_on_quest_started)
	
	# Settings button in ESC menu (logic to be added)
	if has_node("%SettingsButton"):
		%SettingsButton.pressed.connect(_on_settings_pressed)

	_refresh_all_rows()
	_update_stats_display()


func _process(_delta: float) -> void:
	# Update time played stat occasionally or every frame if we want precision
	_update_stat_label("time_played", "Time Played: %s" % _format_time(GameManager.time_played))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_toggle_menu()
		get_viewport().set_input_as_handled()


func _on_quest_started(_quest_type: String) -> void:
	_pulse_hero()


func _on_quest_completed(_reward_amount: float) -> void:
	_pulse_village()
	_update_stats_display()


func _pulse_village() -> void:
	var tween := create_tween()
	tween.tween_property(_village, "modulate", Color(1.12, 1.08, 0.92, 1), 0.05)
	tween.tween_property(_village, "modulate", Color.WHITE, 0.12)


func _pulse_hero() -> void:
	var tween := create_tween()
	tween.tween_property(_hero_sprite, "scale", Vector2(1.1, 1.1), 0.1)
	tween.tween_property(_hero_sprite, "scale", Vector2(1.0, 1.0), 0.1)


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


func _initialize_stats_display() -> void:
	for child in _stats_vbox.get_children():
		child.queue_free()
	
	_add_stat_label("quests_completed", "Quests Completed: 0")
	_add_stat_label("time_played", "Time Played: 0s")
	
	for tier_index in GameManager.TIER_COUNT:
		if tier_index < 3: # Just show first few tiers for now to keep it clean, or all?
			_add_stat_label("total_tier_%d" % tier_index, "Total %s: 0" % GameManager.get_currency_name(tier_index))


func _add_stat_label(id: String, initial_text: String) -> void:
	var label := Label.new()
	label.text = initial_text
	label.add_theme_font_size_override("font_size", 14)
	_stats_vbox.add_child(label)
	_stat_labels[id] = label


func _update_stat_label(id: String, text: String) -> void:
	if _stat_labels.has(id):
		_stat_labels[id].text = text


func _update_stats_display() -> void:
	_update_stat_label("quests_completed", "Quests Completed: %d" % GameManager.quests_completed_count)
	
	for tier_index in GameManager.TIER_COUNT:
		var id: String = "total_tier_%d" % tier_index
		if _stat_labels.has(id):
			var total: float = float(GameManager.total_coins_earned_by_tier.get(tier_index, 0.0))
			_update_stat_label(id, "Total %s: %s" % [GameManager.get_currency_name(tier_index), _format_amount(total)])


func _on_convert_pressed(from_tier: int) -> void:
	GameManager.convert_to_next_tier(from_tier)


func _on_currency_changed(tier_index: int, new_amount: float) -> void:
	_update_balance_label(tier_index, new_amount)
	_update_convert_button(tier_index)
	if tier_index > 0:
		_update_convert_button(tier_index - 1)
	_update_stats_display()


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


func _format_time(seconds: float) -> String:
	var hrs := int(seconds / 3600.0)
	var mins := int(fmod(seconds, 3600.0) / 60.0)
	var secs := int(fmod(seconds, 60.0))
	if hrs > 0:
		return "%dh %dm %ds" % [hrs, mins, secs]
	elif mins > 0:
		return "%dm %ds" % [mins, secs]
	return "%ds" % secs


func _on_menu_button_pressed() -> void:
	_open_menu()


func _on_resume_pressed() -> void:
	_close_menu()


func _on_settings_pressed() -> void:
	if _settings_instance == null:
		_settings_instance = SETTINGS_SCENE.instantiate()
		add_child(_settings_instance)
	_settings_instance.show()


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
