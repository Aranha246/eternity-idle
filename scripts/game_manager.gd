extends Node

signal currency_changed(tier_index: int, new_amount: float)
signal tier_unlocked(tier_index: int)
signal quest_progress_updated(current_time: float, total_time: float)
signal quest_completed(reward_amount: float)
signal quest_started(quest_type: String)

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

const QUEST_TYPES: Dictionary = {
	"retrieval": {
		"id": "retrieval",
		"name": "Retrieval Quest",
		"description": "Scout the outskirts to recover lost supplies.",
		"duration": 5.0,
		"reward_tier": 0,
		"reward_amount": 15.0,
	},
	"hunting": {
		"id": "hunting",
		"name": "Hunting Quest",
		"description": "Hunt wild beasts threatening the perimeter.",
		"duration": 12.0,
		"reward_tier": 0,
		"reward_amount": 50.0,
	},
	"dungeon": {
		"id": "dungeon",
		"name": "Dungeon Delve",
		"description": "Delve into ancient crypts for precious treasure.",
		"duration": 25.0,
		"reward_tier": 1,
		"reward_amount": 1.0,
	},
}

## Maps currency index (0 to 10) to the current float balance.
var currencies: Dictionary = {}
## Maps currency index to whether its UI row is visible.
var unlocked_tiers: Dictionary = {}

## Active quest state
var is_quest_active: bool = false
var quest_timer: float = 0.0
var quest_duration: float = 0.0
var current_quest_type: String = ""

## Stats tracking
var total_coins_earned_by_tier: Dictionary = {}
var quests_completed_count: int = 0
var time_played: float = 0.0
var sfx_volume: float = 1.0
var music_volume: float = 1.0
var ui_scale: float = 1.0


func _ready() -> void:
	_initialize_currencies()


func _process(delta: float) -> void:
	time_played += delta
	if is_quest_active:
		tick_quest(delta)


func _initialize_currencies() -> void:
	for tier_index in TIER_COUNT:
		currencies[tier_index] = 0.0
		total_coins_earned_by_tier[tier_index] = 0.0
		# Copper Coin is available from the start; every other tier is locked.
		unlocked_tiers[tier_index] = tier_index == 0


func get_currency_name(tier_index: int) -> String:
	if not _is_valid_tier(tier_index):
		return ""
	return CURRENCY_NAMES[tier_index]


func get_balance(tier_index: int) -> float:
	if not _is_valid_tier(tier_index):
		return 0.0
	return float(currencies.get(tier_index, 0.0))


func is_tier_unlocked(tier_index: int) -> bool:
	if not _is_valid_tier(tier_index):
		return false
	return bool(unlocked_tiers.get(tier_index, false))


func can_convert(from_tier: int) -> bool:
	if not _is_valid_tier(from_tier):
		return false
	if not is_tier_unlocked(from_tier):
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
	total_coins_earned_by_tier[tier_index] = total_coins_earned_by_tier.get(tier_index, 0.0) + amount
	if not is_tier_unlocked(tier_index):
		_unlock_tier(tier_index)
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
	if not is_tier_unlocked(from_tier):
		return false
	if get_balance(from_tier) < CONVERSION_RATE:
		return false
	if not spend_currency(from_tier, CONVERSION_RATE):
		return false
	add_currency(next_tier, 1.0)
	_unlock_tier(next_tier)
	return true


func _unlock_tier(tier_index: int) -> void:
	if not _is_valid_tier(tier_index):
		return
	if is_tier_unlocked(tier_index):
		return
	unlocked_tiers[tier_index] = true
	tier_unlocked.emit(tier_index)


func _is_valid_tier(tier_index: int) -> bool:
	return tier_index >= 0 and tier_index < TIER_COUNT


# ---------------------------------------------------------
# Quest System Methods
# ---------------------------------------------------------

func get_quest_definition(quest_type: String) -> Dictionary:
	var lower_key := quest_type.strip_edges().to_lower()
	if QUEST_TYPES.has(lower_key):
		return QUEST_TYPES[lower_key]
	for key in QUEST_TYPES:
		var q: Dictionary = QUEST_TYPES[key]
		if q.get("name", "").to_lower() == lower_key or q.get("id", "").to_lower() == lower_key:
			return q
	return {}


func start_quest(quest_type: String) -> bool:
	if is_quest_active:
		return false
	var quest_info := get_quest_definition(quest_type)
	if quest_info.is_empty():
		push_warning("start_quest: Unknown quest type '%s'" % quest_type)
		return false
	is_quest_active = true
	current_quest_type = str(quest_info.get("id", quest_type))
	quest_duration = float(quest_info.get("duration", 5.0))
	quest_timer = 0.0
	quest_started.emit(current_quest_type)
	quest_progress_updated.emit(quest_timer, quest_duration)
	return true


func tick_quest(delta: float) -> void:
	if not is_quest_active:
		return
	quest_timer += delta
	if quest_timer >= quest_duration:
		quest_timer = quest_duration
		quest_progress_updated.emit(quest_timer, quest_duration)
		complete_quest()
	else:
		quest_progress_updated.emit(quest_timer, quest_duration)


func complete_quest() -> void:
	if not is_quest_active:
		return
	var quest_info := get_quest_definition(current_quest_type)
	var reward_amount: float = float(quest_info.get("reward_amount", 10.0))
	var reward_tier: int = int(quest_info.get("reward_tier", 0))

	is_quest_active = false
	current_quest_type = ""
	quest_timer = 0.0
	quest_duration = 0.0
	quests_completed_count += 1

	add_currency(reward_tier, reward_amount)
	quest_completed.emit(reward_amount)


func cancel_quest() -> void:
	if not is_quest_active:
		return
	is_quest_active = false
	current_quest_type = ""
	quest_timer = 0.0
	quest_duration = 0.0
	quest_progress_updated.emit(0.0, 0.0)


func get_quest_progress_ratio() -> float:
	if quest_duration <= 0.0:
		return 0.0
	return clampf(quest_timer / quest_duration, 0.0, 1.0)
