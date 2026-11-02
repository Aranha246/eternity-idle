extends Control

const MINE_AMOUNT: float = 1.0

@onready var _rows_container: VBoxContainer = $ScrollContainer/VBoxContainer

var _balance_labels: Dictionary = {}
var _convert_buttons: Dictionary = {}


func _ready() -> void:
	_build_currency_rows()
	GameManager.currency_changed.connect(_on_currency_changed)
	_refresh_all_rows()


func _build_currency_rows() -> void:
	for child in _rows_container.get_children():
		child.queue_free()
	_balance_labels.clear()
	_convert_buttons.clear()

	for tier_index in GameManager.TIER_COUNT:
		_rows_container.add_child(_create_currency_row(tier_index))


func _create_currency_row(tier_index: int) -> Control:
	var row := HBoxContainer.new()
	row.name = "Tier%dRow" % tier_index
	row.add_theme_constant_override("separation", 12)

	var label := Label.new()
	label.name = "BalanceLabel"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.text = _format_balance_text(tier_index)
	row.add_child(label)
	_balance_labels[tier_index] = label

	var mine_button := Button.new()
	mine_button.name = "MineButton"
	mine_button.text = "Mine / Earn"
	mine_button.disabled = tier_index != 0
	mine_button.pressed.connect(_on_mine_pressed.bind(tier_index))
	row.add_child(mine_button)

	var convert_button := Button.new()
	convert_button.name = "ConvertButton"
	convert_button.text = "Convert (100 -> 1 Next Tier)"
	convert_button.pressed.connect(_on_convert_pressed.bind(tier_index))
	row.add_child(convert_button)
	_convert_buttons[tier_index] = convert_button

	_update_convert_button(tier_index)
	return row


func _on_mine_pressed(tier_index: int) -> void:
	if tier_index != 0:
		return
	GameManager.add_currency(0, MINE_AMOUNT)


func _on_convert_pressed(from_tier: int) -> void:
	GameManager.convert_to_next_tier(from_tier)


func _on_currency_changed(tier_index: int, new_amount: float) -> void:
	_update_balance_label(tier_index, new_amount)
	_update_convert_button(tier_index)
	if tier_index > 0:
		_update_convert_button(tier_index - 1)


func _refresh_all_rows() -> void:
	for tier_index in GameManager.TIER_COUNT:
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
