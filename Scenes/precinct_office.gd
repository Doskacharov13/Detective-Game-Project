extends Node2D

# The two looks of the office: normal, and with the blacklight on
const DAY = preload("res://art/backgrounds/precinct_day.png")
const BLACKLIGHT_VIEW = preload("res://art/backgrounds/precinct_night_no_lamps.png")

@onready var background: Sprite2D = $Background
@onready var uv_layer: Sprite2D = $UVLayer
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
	message_label.text = "Precinct Office. Your desk."

func _on_blacklight_pressed():
	blacklight_on = not blacklight_on
	_update_blacklight()
	message_label.text = "The blacklight is on." if blacklight_on else "The blacklight is off."

func _update_blacklight():
	background.texture = BLACKLIGHT_VIEW if blacklight_on else DAY
	uv_layer.visible = blacklight_on
	for hotspot in $Hotspots.get_children():
		if hotspot.only_in_blacklight:
			hotspot.set_active(blacklight_on)
		elif hotspot.hide_in_blacklight:
			hotspot.set_active(not blacklight_on)

func _on_hotspot_clicked(hotspot):
	# Hotspots that hold an item: put it in the inventory
	if hotspot.pickup and hotspot.item_id > 0:
		_pick_up(hotspot)
		return

	message_label.text = hotspot.message

func _pick_up(hotspot):
	if inventory.add_item(hotspot.item_id):
		var item = GameDB.get_item(hotspot.item_id)
		# The matching clue card is now on the evidence board
		GameDB.add_clue_for_item(GameDB.current_save_id, hotspot.item_id)
		message_label.text = "Picked up: " + item["name"] + ". A new card is on the evidence board."
		hotspot.queue_free()   # the hotspot (and its picture) disappears from the scene
	else:
		message_label.text = "Your inventory is full."
