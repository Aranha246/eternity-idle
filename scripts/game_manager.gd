extends Node

signal currency_changed(tier_index: int, new_amount: float)

const CURRENCY_NAMES: PackedStringArray = [
	"Copper Coin",
	"Silver Coin",
	"Gold Coin",
	"Platinum Coin",
	"Ruby",
	"Diamond",
	"Arcane Shard",
	"Astral Token",
	"Void Essence",
	"Dragon Scale",
	"Eternity Core",
]

const TIER_COUNT: int = 11
const CONVERSION_RATE: float = 100.0

## Maps currency index (0 to 10) to the current float balance.
var currencies: Dictionary = {}


func _ready() -> void:
	_initialize_currencies()


func _initialize_currencies() -> void:
	for tier_index in TIER_COUNT:
		# Every tier, including Copper Coin (tier 0), starts at 0.0.
		currencies[tier_index] = 0.0


func get_currency_name(tier_index: int) -> String:
	if not _is_valid_tier(tier_index):
		return ""
	return CURRENCY_NAMES[tier_index]


func get_balance(tier_index: int) -> float:
	if not _is_valid_tier(tier_index):
		return 0.0
	return float(currencies.get(tier_index, 0.0))


func can_convert(from_tier: int) -> bool:
	if not _is_valid_tier(from_tier):
		return false
	if not _is_valid_tier(from_tier + 1):
		return false
	return get_balance(from_tier) >= CONVERSION_RATE


func add_currency(tier_index: int, amount: float) -> void:
	if not _is_valid_tier(tier_index):
		push_warning("add_currency: invalid tier_index %s" % tier_index)
		return
	if amount == 0.0:
		return
	currencies[tier_index] = get_balance(tier_index) + amount
	currency_changed.emit(tier_index, currencies[tier_index])


func spend_currency(tier_index: int, amount: float) -> bool:
	if not _is_valid_tier(tier_index):
		push_warning("spend_currency: invalid tier_index %s" % tier_index)
		return false
	if amount < 0.0:
		return false
	if get_balance(tier_index) < amount:
		return false
	currencies[tier_index] = get_balance(tier_index) - amount
	currency_changed.emit(tier_index, currencies[tier_index])
	return true


func convert_to_next_tier(from_tier: int) -> bool:
	var next_tier := from_tier + 1
	if not _is_valid_tier(from_tier) or not _is_valid_tier(next_tier):
		return false
	if get_balance(from_tier) < CONVERSION_RATE:
		return false
	if not spend_currency(from_tier, CONVERSION_RATE):
		return false
	add_currency(next_tier, 1.0)
	return true


func _is_valid_tier(tier_index: int) -> bool:
	return tier_index >= 0 and tier_index < TIER_COUNT
