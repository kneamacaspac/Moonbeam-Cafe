# scripts/CafeRoom.gd
extends Node2D

func _ready() -> void:
	# Debug checks
	var hud = get_node_or_null("HUD")
	print("HUD found: ", hud)
	
	var order_menu = get_tree().get_first_node_in_group("order_menu")
	print("OrderMenu found: ", order_menu)
	
	var witch = get_tree().get_first_node_in_group("witch")
	print("Witch found: ", witch)
	
	var seats = get_tree().get_nodes_in_group("seats")
	print("Seats found: ", seats.size())
	
	print("Active menu: ", GameManager.active_menu)
	
	await get_tree().create_timer(3.0).timeout
	var slimes = get_tree().get_nodes_in_group("slimes")
	print("Slimes in scene: ", slimes.size())
