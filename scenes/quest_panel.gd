extends MarginContainer

@onready var hero_avatar: TextureRect = %HeroAvatar
@onready var hero_name_label: Label = %HeroNameLabel
@onready var hero_status_label: Label = %HeroStatusLabel

@onready var active_quest_label: Label = %QuestTitleLabel
@onready var timer_label: Label = %TimerLabel
@onready var progress_bar: ProgressBar = %QuestProgressBar
@onready var status_message_label: Label = %StatusMessageLabel

@onready var retrieval_button: Button = %RetrievalButton
@onready var hunting_button: Button = %HuntingButton
@onready var dungeon_button: Button = %DungeonButton


func _ready() -> void:
	GameManager.quest_progress_updated.connect(_on_quest_progress_updated)
	GameManager.quest_completed.connect(_on_quest_completed)
	GameManager.quest_started.connect(_on_quest_started)

	retrieval_button.pressed.connect(_on_start_quest_pressed.bind("retrieval"))
	hunting_button.pressed.connect(_on_start_quest_pressed.bind("hunting"))
	dungeon_button.pressed.connect(_on_start_quest_pressed.bind("dungeon"))

	_update_ui_state()


func _on_start_quest_pressed(quest_type: String) -> void:
	if GameManager.start_quest(quest_type):
		status_message_label.text = "Embarking on %s..." % _get_quest_name(quest_type)
		_update_ui_state()


func _on_quest_started(quest_type: String) -> void:
	status_message_label.text = "Quest started: %s" % _get_quest_name(quest_type)
	_update_ui_state()


func _on_quest_progress_updated(current_time: float, total_time: float) -> void:
	if total_time > 0.0:
		progress_bar.max_value = total_time
		progress_bar.value = current_time
		timer_label.text = "Time: %.1fs / %.1fs" % [current_time, total_time]
	else:
		progress_bar.max_value = 1.0
		progress_bar.value = 0.0
		timer_label.text = "Time: 0.0s / 0.0s"
	_update_ui_state()


func _on_quest_completed(reward_amount: float) -> void:
	status_message_label.text = "Quest Complete! Received +%s coins!" % _format_amount(reward_amount)
	_update_ui_state()


func _update_ui_state() -> void:
	var is_active := GameManager.is_quest_active
	retrieval_button.disabled = is_active
	hunting_button.disabled = is_active
	dungeon_button.disabled = is_active

	if is_active:
		var q_info := GameManager.get_quest_definition(GameManager.current_quest_type)
		var quest_name: String = str(q_info.get("name", GameManager.current_quest_type.capitalize()))
		hero_status_label.text = "Status: On Quest (%s)" % quest_name
		active_quest_label.text = "Active Quest: %s" % quest_name
	else:
		hero_status_label.text = "Status: Idle (Ready)"
		active_quest_label.text = "No Active Quest"
		if not GameManager.is_quest_active:
			progress_bar.value = 0.0
			timer_label.text = "Ready for adventure"


func _get_quest_name(quest_type: String) -> String:
	var info := GameManager.get_quest_definition(quest_type)
	return str(info.get("name", quest_type.capitalize()))


func _format_amount(amount: float) -> String:
	if is_equal_approx(amount, round(amount)):
		return str(int(round(amount)))
	return "%.2f" % amount
