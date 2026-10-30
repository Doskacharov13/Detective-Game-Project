extends Node2D

# The two looks of the office: normal, and with the blacklight on
const DAY = preload("res://art/backgrounds/precinct_day.png")
const BLACKLIGHT_VIEW = preload("res://art/backgrounds/precinct_night_no_lamps.png")

@onready var background: Sprite2D = $Background
@onready var uv_layer: Sprite2D = $UVLayer
@onready var message_label: Label = $UI/MessageLabel
@onready var blacklight_button: TextureButton = $UI/BlacklightButton

var blacklight_on = false

func _ready():
	for hotspot in $Hotspots.get_children():
		hotspot.clicked.connect(_on_hotspot_clicked)
	blacklight_button.pressed.connect(_on_blacklight_pressed)
	_update_blacklight()
	message_label.text = "Precinct Office. Your desk."

func _on_blacklight_pressed():
	blacklight_on = not blacklight_on
	_update_blacklight()
	message_label.text = "The blacklight is on." if blacklight_on else "The blacklight is off."

# Swaps the picture and turns the right hotspots on and off
func _update_blacklight():
	background.texture = BLACKLIGHT_VIEW if blacklight_on else DAY
	uv_layer.visible = blacklight_on
	for hotspot in $Hotspots.get_children():
		if hotspot.only_in_blacklight:
			hotspot.set_active(blacklight_on)
		elif hotspot.hide_in_blacklight:
			hotspot.set_active(not blacklight_on)

func _on_hotspot_clicked(hotspot):
	var text = "You look at the " + hotspot.hotspot_name + "."

	if hotspot.message != "":
		text = hotspot.message
	elif hotspot.item_id > 0 and has_node("/root/GameDB"):
		var item = GameDB.get_item(hotspot.item_id)
		if not item.is_empty():
			text = item["name"] + ": " + item["description"]

	message_label.text = text
	print(text)
