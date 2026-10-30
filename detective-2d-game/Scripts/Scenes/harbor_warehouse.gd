extends Node2D

@onready var message_label: Label = $UI/MessageLabel

func _ready():
	# Listen to every hotspot in the scene
	for hotspot in $Hotspots.get_children():
		hotspot.clicked.connect(_on_hotspot_clicked)
	message_label.text = "Harbor Warehouse. Halloween night."

func _on_hotspot_clicked(hotspot):
	var text = "You look at the " + hotspot.hotspot_name + "."

	# If the hotspot is an item, read its name and description from the database
	if hotspot.item_id > 0 and has_node("/root/GameDB"):
		var item = GameDB.get_item(hotspot.item_id)
		if not item.is_empty():
			text = item["name"] + ": " + item["description"]

	message_label.text = text
	print(text)
