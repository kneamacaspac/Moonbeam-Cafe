# scripts/FurnitureItem.gd
extends StaticBody2D

var furniture_id: String = "01"

func setup(item_id: String, texture: Texture2D) -> void:
	furniture_id = item_id
	$Sprite2D.texture = texture
