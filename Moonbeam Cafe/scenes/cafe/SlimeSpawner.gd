# scripts/SlimeSpawner.gd
extends Node2D

@export var slime_scene: PackedScene
@export var spawn_position: Vector2 = Vector2(100, 50)

@export var min_spawn_time: float = 5.0   # ← adjust these two
@export var max_spawn_time: float = 15.0  # ← in the Inspector

func _ready() -> void:
	$Timer.wait_time = _random_wait_time()
	$Timer.autostart = true
	$Timer.timeout.connect(_on_timer_timeout)

func _on_timer_timeout() -> void:
	_spawn_slime()
	$Timer.wait_time = _random_wait_time()  # pick a new random duration
	$Timer.start()                           # restart with the new duration

func _spawn_slime() -> void:
	if slime_scene == null:
		push_error("SlimeSpawner: slime_scene is not assigned!")
		return
	var slime = slime_scene.instantiate()
	get_parent().add_child(slime)
	slime.global_position = spawn_position

func _random_wait_time() -> float:
	return randf_range(min_spawn_time, max_spawn_time)
