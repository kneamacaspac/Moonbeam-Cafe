# scripts/HUD.gd
extends CanvasLayer

# ── Node References ───────────────────────────────────────────────────────────
# All @onready vars must be declared BEFORE _ready() uses them
@onready var gold_label      = $GoldLabel
@onready var shop_btn        = $ShopButton
@onready var deco_btn        = $DecoButton
@onready var minigame_btn    = $MiniGameButton

# ── Ready ─────────────────────────────────────────────────────────────────────
func _ready() -> void:
	# Gold display
	GameManager.gold_changed.connect(_on_gold_changed)
	gold_label.text = "Gold: " + str(GameManager.gold)

	# Button connections — all in one place
	shop_btn.pressed.connect(_on_shop_button_pressed)
	deco_btn.pressed.connect(_on_deco_button_pressed)
	minigame_btn.pressed.connect(_on_minigame_button_pressed)

# ── Signal Handlers ───────────────────────────────────────────────────────────
func _on_gold_changed(new_amount: int) -> void:
	gold_label.text = "Gold: " + str(new_amount)

func _on_shop_button_pressed() -> void:
	var shop = get_tree().get_first_node_in_group("shop_menu")
	if shop:
		shop.visible = true

func _on_deco_button_pressed() -> void:
	var deco = get_tree().get_first_node_in_group("deco_mode")
	if deco:
		deco.enter_deco_mode()

func _on_minigame_button_pressed() -> void:
	var selector = get_tree().get_first_node_in_group("mini_game_selector")
	if selector:
		selector.open()
