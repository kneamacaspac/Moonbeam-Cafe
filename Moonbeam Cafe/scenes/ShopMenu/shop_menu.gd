# scripts/ShopMenu.gd
extends CanvasLayer

func _ready() -> void:
	add_to_group("shop_menu")   
	visible = false
	_populate_tabs()
	close_btn.pressed.connect(func(): visible = false)


func _populate_tabs() -> void:
	for item in GameManager.item_database:
		var card = _make_item_card(item)
		match item["type"]:
			"furniture": $PanelContainer/TabContainer/Furniture.add_child(card)
			"pastry":    $PanelContainer/TabContainer/Pastries.add_child(card)
			"drink":     $PanelContainer/TabContainer/Drinks.add_child(card)

func _make_item_card(item: Dictionary) -> Control:
	var vbox = VBoxContainer.new()
	var label = Label.new()
	label.text = item["name"] + "  —  " + str(item["price"]) + "g"
	var btn = Button.new()
	btn.text = "Buy"
	btn.pressed.connect(func(): _buy_item(item))
	vbox.add_child(label)
	vbox.add_child(btn)
	return vbox

func _buy_item(item: Dictionary) -> void:
	if item["id"] in GameManager.purchased_items:
		return  # already owned
	if GameManager.spend_gold(item["price"]):
		GameManager.purchased_items.append(item["id"])
		if item["type"] in ["pastry", "drink"]:
			GameManager.active_menu.append(item["id"])
		# TODO: add to furniture inventory if furniture
		
@onready var close_btn = $CloseButton
