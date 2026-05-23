# scripts/GameManager.gd
extends Node

# Gold (currency)
var gold: int = 100
var active_menu: Array = []
var purchased_furniture: Array = []
var purchased_pastries: Array = []
var purchased_drinks: Array = []
var placed_furniture: Array = []
var furniture_stock: Dictionary = {}  # { "chair": 2, "wooden_countertop": 0, ... }

func _ready() -> void:
	load_game()
	if active_menu.is_empty():
		active_menu = ["star_cookie", "donut"]
		print("Active menu set to: ", active_menu)  

# Each item: { id, name, type, price, icon_path }
# type: "pastry", "drink", or "furniture"
var item_database: Array = [
	{ "id": "apple_pie",  "name": "Apple Pie",   "type": "pastry",    "price": 30, "icon_path": "res://Moonbeam Cafe/assets/foods/06_apple_pie_dish.png"  },
	{ "id": "cheesecake",    "name": "Cheesecake",     "type": "pastry",    "price": 50,  "icon_path": "res://Moonbeam Cafe/assets/foods/23_cheesecake_dish.png" },
	{ "id": "cocktail",   "name": "Cocktail",    "type": "drink",     "price": 40, "icon_path": "res://Moonbeam Cafe/assets/drinks/cocktail.png" },
	{ "id": "sunrise_cocktail",   "name": "Sunrise Cocktail",    "type": "drink",     "price": 60, "icon_path": "res://Moonbeam Cafe/assets/drinks/sunrise_cocktail.png"  },
	{ "id": "ocean_cocktail",  "name": "Ocean Cocktail",   "type": "drink", "price": 65, "icon_path": "res://Moonbeam Cafe/assets/drinks/ocean_cocktail.png" },
	{ "id": "wooden_countertop",   "name": "Wooden Countertop",    "type": "furniture", "price": 80, "scene_path": "res://Moonbeam Cafe/scenes/furniture/wooden_countertop.tscn" },
	{ "id": "chair",   "name": "Chair",    "type": "furniture", "price": 30, "scene_path": "res://Moonbeam Cafe/scenes/furniture/chair.tscn"  },
	{"id": "star_cookie",  "name": "Star Cookie",   "type": "pastry",    "price": 30, "icon_path": "res://Moonbeam Cafe/assets/foods/29_cookies_dish.png" },
	{"id": "donut",  "name": "Donut",   "type": "pastry",    "price": 30, "icon_path": "res://Moonbeam Cafe/assets/foods/35_donut_dish.png" },
]

# Track what the player has bought
var purchased_items: Array = []   # array of item IDs


# Signal fires whenever gold changes — UI listens to this
signal gold_changed(new_amount: int)

func add_gold(amount: int) -> void:
	gold += amount
	emit_signal("gold_changed", gold)
	save_game()  # auto-save on every gold change

func spend_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		emit_signal("gold_changed", gold)
		save_game()
		return true
	return false  # not enough gold

# Stubs — we'll fill these in Phase 7
func save_game() -> void:
	pass

func load_game() -> void:
	pass
	
	
func find_item(item_id: String) -> Dictionary:
	for item in item_database:
		if item["id"] == item_id:
			return item
	return {}   # ← this line must be OUTSIDE the for loop, at the base indent level
