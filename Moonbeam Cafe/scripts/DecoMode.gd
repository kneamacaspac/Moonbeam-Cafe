# scripts/DecoMode.gd
extends CanvasLayer

var held_furniture: String = ""
var placed_furniture: Array = []
var preview_node: Node2D = null   # the ghost sprite following the mouse

@onready var grid_overlay    = $GridOverlay
@onready var inventory_panel = $InventoryPanel
@onready var exit_btn        = $CloseButton

func _ready() -> void:
	add_to_group("deco_mode")
	visible = false
	exit_btn.pressed.connect(exit_deco_mode)

func enter_deco_mode() -> void:
	visible = true
	grid_overlay.visible = true
	_refresh_inventory()

func exit_deco_mode() -> void:
	visible = false
	held_furniture = ""
	grid_overlay.visible = false
	_clear_preview()
	var nav = get_tree().get_first_node_in_group("nav_region")
	if nav:
		nav.bake_navigation_polygon()

# ── Inventory Panel ──────────────────────────────────────────────────────────
func _refresh_inventory() -> void:
	for child in inventory_panel.get_children():
		child.queue_free()
	for item_id in GameManager.purchased_items:
		var item = GameManager.find_item(item_id)
		if item.is_empty():
			continue
		if item["type"] == "furniture":
			_add_inventory_button(item)

func _add_inventory_button(item: Dictionary) -> void:
	var btn = Button.new()
	btn.text = item["name"]
	btn.custom_minimum_size = Vector2(80, 40)
	btn.pressed.connect(func(): _select_furniture(item["id"]))
	inventory_panel.add_child(btn)

func _select_furniture(item_id: String) -> void:
	held_furniture = item_id
	print("Selected: ", item_id)
	_clear_preview()
	_create_preview(item_id)   # spawn ghost sprite that follows mouse

# ── Preview (Ghost Sprite) ───────────────────────────────────────────────────
func _create_preview(item_id: String) -> void:
	var item = GameManager.find_item(item_id)
	if item.is_empty():
		return
	var scene_path = item.get("scene_path", "")
	if scene_path == "":
		return
	var packed = load(scene_path)
	if packed == null:
		return

	preview_node = packed.instantiate()
	# Make it semi-transparent so it looks like a ghost/preview
	preview_node.modulate = Color(1, 1, 1, 0.5)
	# Disable its collision so it doesn't interfere with the world
	for child in preview_node.get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			child.disabled = true
	get_tree().current_scene.add_child(preview_node)

func _clear_preview() -> void:
	if preview_node != null:
		preview_node.queue_free()
		preview_node = null

func _update_preview(world_pos: Vector2) -> void:
	if preview_node == null:
		return
	var snapped = (world_pos / 32).floor() * 32
	preview_node.position = snapped + Vector2(16, 16)

# ── Input ────────────────────────────────────────────────────────────────────
func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	var camera = get_viewport().get_camera_2d()
	var world_pos: Vector2
	if camera:
		world_pos = camera.get_global_mouse_position()
	else:
		world_pos = get_viewport().get_mouse_position()

	# Mouse moved — update preview position
	if event is InputEventMouseMotion:
		_update_preview(world_pos)
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if held_furniture != "":
			# Place the held furniture
			_place_furniture(held_furniture, world_pos)
		else:
			# Check if player clicked an already-placed furniture to pick it up
			_try_pick_up(world_pos)

# ── Placing ──────────────────────────────────────────────────────────────────
func _place_furniture(item_id: String, pos: Vector2) -> void:
	# ✅ Stock check FIRST, before doing anything
	var stock = GameManager.furniture_stock.get(item_id, 0)
	if stock <= 0:
		return  # nothing in stock, stop here

	# Snap to 32x32 grid — renamed to avoid built-in conflict
	var snap_pos = (pos / 32).floor() * 32

	# Deduct stock
	GameManager.furniture_stock[item_id] -= 1

	# Place it
	placed_furniture.append({"id": item_id, "pos": snap_pos})
	_spawn_furniture_sprite(item_id, snap_pos)
	_clear_preview()
	held_furniture = ""
	

func _spawn_furniture_sprite(item_id: String, pos: Vector2) -> void:
	var item = GameManager.find_item(item_id)
	if item.is_empty():
		push_error("DecoMode: item not found: " + item_id)
		return
	var scene_path = item.get("scene_path", "")
	if scene_path == "":
		push_error("DecoMode: no scene_path for item: " + item_id)
		return
	var packed = load(scene_path)
	if packed == null:
		push_error("DecoMode: could not load scene: " + scene_path)
		return

	var furniture_node = packed.instantiate()
	furniture_node.position = pos + Vector2(16, 16)
	furniture_node.add_to_group("placed_furniture")   # ← tag it so we can find it
	furniture_node.set_meta("item_id", item_id)       # ← store what item this is
	get_tree().current_scene.add_child(furniture_node)
	print("Placed ", item_id, " at ", furniture_node.position)

# ── Pick Up Placed Furniture ─────────────────────────────────────────────────
func _try_pick_up(world_pos: Vector2) -> void:
	# Find all placed furniture nodes and check if click is within 32px of one
	var furniture_nodes = get_tree().get_nodes_in_group("placed_furniture")
	for node in furniture_nodes:
		if node.position.distance_to(world_pos) < 32.0:
			# Pick it back up
			var item_id = node.get_meta("item_id", "")
			if item_id == "":
				continue
			# Remove from placed list
			placed_furniture = placed_furniture.filter(
				func(entry): return not (entry["id"] == item_id and entry["pos"].distance_to(node.position) < 2.0)
			)
			node.queue_free()
			# Re-select it so player can place it again
			_select_furniture(item_id)
			print("Picked up: ", item_id)
			return
