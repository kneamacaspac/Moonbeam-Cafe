# scripts/OrderMenu.gd
extends CanvasLayer

signal item_prepared(item_id: String)

@onready var menu_grid = $PanelContainer/VBoxContainer/MenuGrid
@onready var close_btn = $PanelContainer/VBoxContainer/CloseButton

func _ready() -> void:
	add_to_group("order_menu")  
	visible = false

func open_for_slime(_slime: Node) -> void:
	visible = true
	# Clear old buttons
	for child in menu_grid.get_children():
		child.queue_free()
	# Create a button for each active menu item
	for item_id in GameManager.active_menu:
		var btn = Button.new()
		btn.text = item_id   # replace with item name from database later
		btn.pressed.connect(func(): _prepare_item(item_id))
		menu_grid.add_child(btn)

func _prepare_item(item_id: String) -> void:
	emit_signal("item_prepared", item_id)
	visible = false

func _on_close_button_pressed() -> void:
	visible = false
