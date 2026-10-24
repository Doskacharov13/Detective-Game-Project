extends TextureRect

@onready var scrollContainer: ScrollContainer = $ScrollContainer
const SlotClass = preload("res://Scripts/UI/slot.gd")
var temp_item_texture = null
var current_slot = null
var next_slot = null

 

func _on_left_arrow_pressed() -> void:
	var value = scrollContainer.scroll_horizontal
	scrollContainer.scroll_horizontal = value - 210

func _on_right_arrow_pressed() -> void:
	var value = scrollContainer.scroll_horizontal
	scrollContainer.scroll_horizontal = value + 210
