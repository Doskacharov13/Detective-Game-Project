extends Node2D

# The two looks of the warehouse: normal, and with the blacklight on
const LIGHT = preload("res://art/backgrounds/warehouse_light.png")
const DARK = preload("res://art/backgrounds/warehouse_dark.png")

@onready var background: Sprite2D = $Background
@onready var uv_layers: Node2D = $UVLayers
@onready var message_label: Label = $UI/MessageLabel
@onready var blacklight_button: TextureButton = $UI/BlacklightButton
@onready var board_button: TextureButton = $UI/BoardButton
@onready var board = $EvidenceBoard
@onready var inventory = $UI/Inventory/InventoryContainer

var blacklight_on = false

func _ready():
	for hotspot in $Hotspots.get_children():
		hotspot.clicked.connect(_on_hotspot_clicked)
	blacklight_button.pressed.connect(_on_blacklight_pressed)
	board_button.pressed.connect(board.open)
	_update_blacklight()
	message_label.text = "Harbor Warehouse. Halloween night."

func _on_blacklight_pressed():
	blacklight_on = not blacklight_on
	_update_blacklight()
	message_label.text = "The blacklight is on." if blacklight_on else "The blacklight is off."

# Swaps the picture, shows the glowing layers and turns the right hotspots on and off
func _update_blacklight():
	background.texture = DARK if blacklight_on else LIGHT
	uv_layers.visible = blacklight_on
	for hotspot in $Hotspots.get_children():
		if hotspot.only_in_blacklight:
			hotspot.set_active(blacklight_on)
		elif hotspot.hide_in_blacklight:
			hotspot.set_active(not blacklight_on)

func _on_hotspot_clicked(hotspot):
	# An item: put it in the inventory
	if hotspot.pickup and hotspot.item_id > 0:
		_pick_up(hotspot)
		return

	# A clue (like the chemical trail): it goes on the evidence board
	if hotspot.clue_id > 0:
		GameDB.add_clue(GameDB.current_save_id, hotspot.clue_id)
		if hotspot.message != "":
			message_label.text = hotspot.message
		else:
			message_label.text = "You found a new clue. It is on the evidence board."
		return

	message_label.text = hotspot.message

func _pick_up(hotspot):
	if inventory.add_item(hotspot.item_id):
		var item = GameDB.get_item(hotspot.item_id)
		# The matching clue card is now on the evidence board
		GameDB.add_clue_for_item(GameDB.current_save_id, hotspot.item_id)
		message_label.text = "Picked up: " + item["name"] + ". A new card is on the evidence board."

		# The picture of the item disappears from the scene too
		if not hotspot.linked_node.is_empty():
			var picture = hotspot.get_node_or_null(hotspot.linked_node)
			if picture:
				picture.queue_free()

		hotspot.queue_free()
	else:
		message_label.text = "Your inventory is full."
