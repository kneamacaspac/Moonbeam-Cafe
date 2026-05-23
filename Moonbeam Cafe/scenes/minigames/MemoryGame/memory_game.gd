# scripts/MemoryGame.gd
extends CanvasLayer

# ── Constants ─────────────────────────────────────────────────────────────────
const MAX_ROUNDS     = 10
const FLASH_DURATION = 0.5
const FLASH_GAP      = 0.2
const INPUT_TIME     = 5.0   # seconds player has to input per round

const COLORS = ["Red", "Green", "Blue", "Yellow"]
const COLOR_MAP = {
	"Red":    Color(1.0, 0.3, 0.3),
	"Green":  Color(0.3, 1.0, 0.3),
	"Blue":   Color(0.3, 0.5, 1.0),
	"Yellow": Color(1.0, 1.0, 0.3),
}
const DIM_COLOR = Color(0.3, 0.3, 0.3)

# ── State ─────────────────────────────────────────────────────────────────────
var sequence:       Array = []
var player_input:   Array = []
var current_round:  int   = 0
var gold_earned:    int   = 0
var is_showing:     bool  = false
var time_left:      float = 0.0
var timer_running:  bool  = false

# ── Node References ───────────────────────────────────────────────────────────
@onready var round_label   = $PanelContainer/VBoxContainer/RoundLabel
@onready var status_label  = $PanelContainer/VBoxContainer/StatusLabel
@onready var timer_label   = $PanelContainer/VBoxContainer/TimerLabel
@onready var gold_label    = $PanelContainer/VBoxContainer/GoldEarnedLabel
@onready var close_btn     = $PanelContainer/VBoxContainer/CloseButton
@onready var slime_grid    = $PanelContainer/VBoxContainer/SlimeGrid

var color_buttons: Dictionary = {}

# ── Setup ─────────────────────────────────────────────────────────────────────
func _ready() -> void:
	add_to_group("memory_game")
	visible      = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	close_btn.pressed.connect(_on_give_up)

	for color in COLORS:
		var btn = slime_grid.get_node(color + "Button")
		color_buttons[color] = btn
		btn.pressed.connect(func(): _on_color_pressed(color))

	_dim_all_buttons()

func open_game() -> void:
	visible       = true
	sequence      = []
	player_input  = []
	current_round = 0
	gold_earned   = 0
	is_showing    = false
	timer_running = false
	timer_label.text = ""
	get_tree().paused = true
	process_mode      = Node.PROCESS_MODE_ALWAYS
	_update_labels()
	_dim_all_buttons()
	await get_tree().create_timer(0.8).timeout
	_next_round()

# ── Timer ─────────────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if not timer_running:
		return

	time_left -= delta
	# Show the countdown with one decimal place
	timer_label.text = "Time: " + str(snappedf(time_left, 0.1)) + "s"

	# Change color to warn player when time is low
	if time_left <= 2.0:
		timer_label.modulate = Color(1, 0.3, 0.3)   # red when urgent
	else:
		timer_label.modulate = Color(1, 1, 1)        # white normally

	if time_left <= 0.0:
		timer_running = false
		timer_label.text = ""
		_time_ran_out()

func _start_timer() -> void:
	time_left     = INPUT_TIME + (sequence.size() * 0.5)  # more time for longer sequences
	timer_running = true

func _stop_timer() -> void:
	timer_running    = false
	timer_label.text = ""
	timer_label.modulate = Color(1, 1, 1)   # reset color

func _time_ran_out() -> void:
	_enable_buttons(false)
	status_label.text = "Time's up!"
	await get_tree().create_timer(0.8).timeout
	_wrong_answer()

# ── Round Logic ───────────────────────────────────────────────────────────────
func _next_round() -> void:
	current_round += 1
	player_input   = []

	if current_round > MAX_ROUNDS:
		_win_game()
		return

	sequence.append(COLORS[randi() % COLORS.size()])
	_update_labels()
	status_label.text = "Watch carefully..."
	timer_label.text  = ""

	await get_tree().create_timer(0.8).timeout
	await _show_sequence()

	# Player's turn — start the countdown
	status_label.text = "Your turn! (" + str(sequence.size()) + " colors)"
	_enable_buttons(true)
	_start_timer()

func _show_sequence() -> void:
	is_showing = true
	_enable_buttons(false)
	_stop_timer()   # no timer while showing

	for color in sequence:
		_flash_button(color)
		await get_tree().create_timer(FLASH_DURATION).timeout
		_dim_all_buttons()
		await get_tree().create_timer(FLASH_GAP).timeout

	is_showing = false

func _flash_button(color: String) -> void:
	_dim_all_buttons()
	if color_buttons.has(color):
		color_buttons[color].modulate = COLOR_MAP[color]

func _dim_all_buttons() -> void:
	for color in COLORS:
		if color_buttons.has(color):
			color_buttons[color].modulate = DIM_COLOR

func _enable_buttons(enabled: bool) -> void:
	for color in COLORS:
		if color_buttons.has(color):
			color_buttons[color].disabled = not enabled

# ── Player Input ──────────────────────────────────────────────────────────────
func _on_color_pressed(color: String) -> void:
	if is_showing:
		return

	# Brief flash feedback
	color_buttons[color].modulate = COLOR_MAP[color]
	await get_tree().create_timer(0.15).timeout
	color_buttons[color].modulate = DIM_COLOR

	player_input.append(color)
	var index = player_input.size() - 1

	if player_input[index] != sequence[index]:
		_stop_timer()
		await _wrong_answer()
		return

	# Correct so far
	if player_input.size() == sequence.size():
		_stop_timer()
		await _round_complete()

func _round_complete() -> void:
	_enable_buttons(false)
	var round_gold = current_round * 5
	gold_earned   += round_gold
	_update_labels()
	status_label.text = "Correct! +" + str(round_gold) + "g"
	await get_tree().create_timer(1.2).timeout

	if current_round >= MAX_ROUNDS:
		_win_game()
	else:
		_next_round()

# ── Wrong Answer — shows sequence again before ending ─────────────────────────
func _wrong_answer() -> void:
	_enable_buttons(false)
	_stop_timer()

	# Flash all red to signal mistake
	for color in COLORS:
		color_buttons[color].modulate = Color(1, 0.2, 0.2)
	status_label.text = "Wrong! Watch the correct sequence..."
	await get_tree().create_timer(1.2).timeout

	# Replay the correct sequence slowly so player can see what they missed
	_dim_all_buttons()
	await get_tree().create_timer(0.5).timeout
	for color in sequence:
		color_buttons[color].modulate = COLOR_MAP[color]
		await get_tree().create_timer(0.7).timeout   # slightly slower so it's clear
		_dim_all_buttons()
		await get_tree().create_timer(0.3).timeout

	# Now show game over
	status_label.text = "Game over! You reached round " + str(current_round) + "."
	timer_label.text  = ""
	await get_tree().create_timer(2.0).timeout
	_end_game()

func _win_game() -> void:
	_stop_timer()
	gold_earned   += 50
	_update_labels()
	status_label.text = "Perfect! +" + str(gold_earned) + "g total!"
	timer_label.text  = ""
	await get_tree().create_timer(2.0).timeout
	_end_game()

func _on_give_up() -> void:
	_stop_timer()
	status_label.text = "Better luck next time!"
	await get_tree().create_timer(0.8).timeout
	_end_game()

# ── Cleanup ───────────────────────────────────────────────────────────────────
func _end_game() -> void:
	if gold_earned > 0:
		GameManager.add_gold(gold_earned)
		print("Memory game ended. Gold earned: ", gold_earned)
	visible           = false
	get_tree().paused = false

func _update_labels() -> void:
	round_label.text = "Round " + str(current_round) + " / " + str(MAX_ROUNDS)
	gold_label.text  = "Gold earned: " + str(gold_earned)
