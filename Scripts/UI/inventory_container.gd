extends TextureRect

@onready var scrollContainer: ScrollContainer = $ScrollContainer
@onready var slots_box: HBoxContainer = $ScrollContainer/HBoxContainer

func _on_left_arrow_pressed() -> void:
	var value = scrollContainer.scroll_horizontal
	scrollContainer.scroll_horizontal = value - 210

func _on_right_arrow_pressed() -> void:
	var value = scrollContainer.scroll_horizontal
	scrollContainer.scroll_horizontal = value + 210

# Puts an item into the first empty slot.
# Returns true if it worked, false if the inventory is full.
func add_item(item_id: int) -> bool:
	var item = GameDB.get_item(item_id)
	if item.is_empty():
		push_error("Item " + str(item_id) + " is not in the database")
		return false

	for slot in slots_box.get_children():
		if slot.is_empty():
			slot.put_item(item_id, load(item["icon_file"]))
			return true

	return false
