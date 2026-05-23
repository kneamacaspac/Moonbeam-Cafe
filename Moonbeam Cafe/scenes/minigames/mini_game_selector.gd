# scripts/MiniGameSelector.gd
extends CanvasLayer

@onready var match_btn  = $PanelContainer/VBoxContainer/MemoryButton
@onready var math_btn   = $PanelContainer/VBoxContainer/MathButton
@onready var close_btn  = $PanelContainer/VBoxContainer/CloseButton


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	match_btn.pressed.connect(_on_match_pressed)
	math_btn.pressed.connect(_on_math_pressed)
	close_btn.pressed.connect(func(): visible = false)

func open() -> void:
	visible = true

func _on_match_pressed() -> void:
	visible = false
	var game = get_tree().get_first_node_in_group("memory_game")
	if game:
		game.open_game()

func _on_math_pressed() -> void:
	visible = false
	# Show difficulty picker before opening math game
	var game = get_tree().get_first_node_in_group("math_game")
	if game:
		game.open_difficulty_picker()
		
