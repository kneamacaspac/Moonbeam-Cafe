# scripts/MathGame.gd
extends CanvasLayer

const TOTAL_QUESTIONS = 5

var current_answer:    int    = 0
var gold_per_correct:  int    = 0
var questions_remaining: int  = 0
var _current_difficulty: String = ""

@onready var difficulty_picker = $PanelContainer/VBoxContainer/DifficultyPicker
@onready var quiz_panel        = $PanelContainer/VBoxContainer/QuizPanel
@onready var progress_label    = $PanelContainer/VBoxContainer/QuizPanel/ProgressLabel
@onready var question_label    = $PanelContainer/VBoxContainer/QuizPanel/QuestionLabel
@onready var answer_input      = $PanelContainer/VBoxContainer/QuizPanel/AnswerInput
@onready var submit_btn        = $PanelContainer/VBoxContainer/QuizPanel/SubmitButton
@onready var result_label      = $PanelContainer/VBoxContainer/QuizPanel/ResultLabel
@onready var close_btn         = $PanelContainer/VBoxContainer/CloseButton

@onready var easy_btn   = $PanelContainer/VBoxContainer/DifficultyPicker/EasyButton
@onready var medium_btn = $PanelContainer/VBoxContainer/DifficultyPicker/MediumButton
@onready var hard_btn   = $PanelContainer/VBoxContainer/DifficultyPicker/HardButton

func _ready() -> void:
	add_to_group("math_game")
	visible      = false
	process_mode = Node.PROCESS_MODE_ALWAYS

	easy_btn.pressed.connect(func():   _start_game("Easy"))
	medium_btn.pressed.connect(func(): _start_game("Medium"))
	hard_btn.pressed.connect(func():   _start_game("Hard"))
	submit_btn.pressed.connect(_on_submit_pressed)
	close_btn.pressed.connect(_on_close_pressed)

# ── Entry Points ──────────────────────────────────────────────────────────────
func open_difficulty_picker() -> void:
	visible = true
	get_tree().paused    = true
	difficulty_picker.visible = true
	quiz_panel.visible        = false
	result_label.text         = ""

func _start_game(difficulty: String) -> void:
	_current_difficulty   = difficulty
	questions_remaining   = TOTAL_QUESTIONS
	difficulty_picker.visible = false
	quiz_panel.visible        = true
	match difficulty:
		"Easy":   gold_per_correct = 10
		"Medium": gold_per_correct = 25
		"Hard":   gold_per_correct = 50
	_next_question()

# ── Question Generation ───────────────────────────────────────────────────────
func _next_question() -> void:
	if questions_remaining <= 0:
		_end_game()
		return

	result_label.text  = ""
	answer_input.text  = ""
	answer_input.grab_focus()   # auto-focus input so player can type immediately

	var q_number = TOTAL_QUESTIONS - questions_remaining + 1
	progress_label.text = "Question " + str(q_number) + " / " + str(TOTAL_QUESTIONS)
	questions_remaining -= 1

	var a: int
	var b: int
	var c: int

	match _current_difficulty:
		"Easy":
			a = randi_range(1, 20)
			b = randi_range(1, 20)
			current_answer      = a + b
			question_label.text = str(a) + " + " + str(b) + " = ?"
		"Medium":
			a = randi_range(2, 12)
			b = randi_range(2, 12)
			current_answer      = a * b
			question_label.text = str(a) + " × " + str(b) + " = ?"
		"Hard":
			a = randi_range(5, 20)
			b = randi_range(2, 10)
			c = randi_range(1, 30)
			current_answer      = a * b - c
			question_label.text = "(" + str(a) + " × " + str(b) + ") − " + str(c) + " = ?"

# ── Answering ─────────────────────────────────────────────────────────────────
func _on_submit_pressed() -> void:
	var player_answer = answer_input.text.strip_edges()
	if player_answer == "":
		return   # don't count empty submissions

	if int(player_answer) == current_answer:
		result_label.text = "✅ Correct! +" + str(gold_per_correct) + "g"
		GameManager.add_gold(gold_per_correct)
	else:
		result_label.text = "❌ Wrong. Answer was " + str(current_answer)

	# Wait briefly so player can read the result, then show next question
	await get_tree().create_timer(1.2).timeout
	_next_question()

func _input(event: InputEvent) -> void:
	# Allow pressing Enter to submit instead of clicking the button
	if not visible: return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ENTER:
		_on_submit_pressed()

# ── End Game ──────────────────────────────────────────────────────────────────
func _end_game() -> void:
	result_label.text = "Quiz complete! Well done!"
	await get_tree().create_timer(1.5).timeout
	visible = false
	get_tree().paused = false
	print("Math quiz ended.")

func _on_close_pressed() -> void:
	visible = false
	get_tree().paused = false
