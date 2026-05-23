extends CharacterBody2D

const SPEED = 120.0
var held_item: String = ""
var last_direction: String = "down"  # ← track last direction for idle

@onready var sprite     = $AnimatedSprite2D
@onready var held_icon  = $HeldItemIcon

func _ready() -> void:
	add_to_group("witch")       # ← so slimes can find the witch
	held_icon.visible = false   # ← hide at start

func _physics_process(_delta: float) -> void:
	var direction = Vector2.ZERO
	if Input.is_action_pressed("ui_right"): direction.x += 1
	if Input.is_action_pressed("ui_left"):  direction.x -= 1
	if Input.is_action_pressed("ui_down"):  direction.y += 1
	if Input.is_action_pressed("ui_up"):    direction.y -= 1

	if direction != Vector2.ZERO:
		direction = direction.normalized()
	velocity = direction * SPEED
	move_and_slide()
	_update_animation(direction)

func _update_animation(dir: Vector2) -> void:
	if dir == Vector2.ZERO:
		sprite.play("idle_" + last_direction)  # ← uses last direction
		return
	if abs(dir.x) > abs(dir.y):
		if dir.x > 0:
			sprite.play("walk_right")
			last_direction = "right"           # ← update last direction
		else:
			sprite.play("walk_left")
			last_direction = "left"
	else:
		if dir.y > 0:
			sprite.play("walk_down")
			last_direction = "down"
		else:
			sprite.play("walk_up")
			last_direction = "up"

func pick_up_item(item_id: String) -> void:
	held_item = item_id
	# Look up the item and load its icon texture
	var item = GameManager.find_item(item_id)
	if item.has("icon_path"):
		held_icon.texture = load(item["icon_path"])
	held_icon.visible = true

func deliver_to_slime(slime) -> void:
	if held_item == "":
		return
	slime.serve(held_item)
	held_item = ""
	held_icon.visible = false
