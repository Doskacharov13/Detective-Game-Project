extends Node2D

@onready var message_label: Label = $UI/MessageLabel

func _ready():
	for hotspot in $Hotspots.get_children():
		hotspot.clicked.connect(_on_hotspot_clicked)
	message_label.text = "Precinct Office. Your desk."

func _on_hotspot_clicked(hotspot):
	message_label.text = hotspot.message
