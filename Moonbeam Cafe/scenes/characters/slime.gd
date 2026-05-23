# scripts/Slime.gd
extends CharacterBody2D

enum State { ENTERING, FINDING_SEAT, WAITING, SERVED, LEAVING }
var state: State = State.ENTERING
var target_seat: Node2D = null
var order_id: String = ""
var patience: float = 100.0
var patience_rate: float = 5.0

@onready var nav_agent   = $NavigationAgent2D
@onready var patience_bar = $PatienceBar
@onready var order_icon  = $SpeechBubble/OrderIcon
@onready var sprite      = $AnimatedSprite2D

const SPEED = 60.0

func _ready() -> void:
	add_to_group("slimes")          # ← was missing entirely
	patience_bar.min_value = 0.0
	patience_bar.max_value = 100.0
	patience_bar.value     = 100.0
	$SpeechBubble.visible = false
	sprite.play("idle")
	_enter_cafe()                   # ← only called once now

# ─── Movement ────────────────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	match state:
		State.FINDING_SEAT:
			_move_to_target(delta)
		State.WAITING:
			_drain_patience(delta)
			_play_idle_animation()

func _move_to_target(_delta: float) -> void:
	if nav_agent.is_navigation_finished():
		state = State.WAITING
		_play_idle_animation()
		_place_order()
		return
	var next_pos = nav_agent.get_next_path_position()
	var dir = (next_pos - global_position).normalized()
	velocity = dir * SPEED
	move_and_slide()
	_play_walk_animation(dir)

# ─── Animation ───────────────────────────────────────────────────────────────

func _play_walk_animation(dir: Vector2) -> void:
	sprite.play("walk")
	if dir.x != 0:
		sprite.flip_h = dir.x < 0

func _play_idle_animation() -> void:
	if sprite.animation != "idle":
		sprite.play("idle")

# ─── Ordering & Patience ─────────────────────────────────────────────────────

func _enter_cafe() -> void:
	var all_seats = get_tree().get_nodes_in_group("seats")
	var free_seat: Node2D = null
	for seat in all_seats:
		if not seat.occupied:
			free_seat = seat
			break
	if free_seat == null:
		queue_free()
		return
	target_seat = free_seat
	free_seat.occupied = true
	state = State.FINDING_SEAT
	nav_agent.target_position = free_seat.global_position

func _place_order() -> void:
	var menu = GameManager.active_menu
	if menu.is_empty():
		print("ERROR: active_menu is empty!")
		return
	order_id = menu[randi() % menu.size()]
	print("Slime ordered: ", order_id)
	$SpeechBubble.visible = true

func _drain_patience(delta: float) -> void:
	patience -= patience_rate * delta
	patience_bar.value = patience
	if patience <= 0:
		_leave_disappointed()

# ─── Leaving ─────────────────────────────────────────────────────────────────

func _leave_disappointed() -> void:
	state = State.LEAVING
	$SpeechBubble.visible = false
	if target_seat:
		target_seat.occupied = false
	sprite.play("sad")
	await get_tree().create_timer(1.0).timeout
	queue_free()

func serve(item_id: String) -> void:
	if item_id == order_id:
		state = State.SERVED
		$SpeechBubble.visible = false
		if target_seat:
			target_seat.occupied = false
		var tip_bonus = int((patience / 100.0) * 10)
		GameManager.add_gold(20 + tip_bonus)
		sprite.play("happy")
		await get_tree().create_timer(2).timeout
		queue_free()

# ─── Click Detection ─────────────────────────────────────────────────────────

func _input_event(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton and event.pressed:
		var witch = get_tree().get_first_node_in_group("witch")
		if witch == null:
			print("ERROR: witch not found in group!")
			return
		if witch.held_item != "":
			witch.deliver_to_slime(self)
		elif state == State.WAITING:
			var order_menu = get_tree().get_first_node_in_group("order_menu")
			if order_menu:
				order_menu.open_for_slime(self)
				order_menu.item_prepared.connect(
					func(item_id): witch.pick_up_item(item_id), CONNECT_ONE_SHOT
				)
			else:
				print("ERROR: order_menu not found in group!")
