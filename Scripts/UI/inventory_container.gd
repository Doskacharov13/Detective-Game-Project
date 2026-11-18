extends TextureRect

@onready var scrollContainer: ScrollContainer = $ScrollContainer
@onready var slots_box: HBoxContainer = $ScrollContainer/HBoxContainer

var loading = false   # true while the slots are being filled from the database

func _ready():
	_load_from_db()
	# Every time an item moves, save the inventory
	for slot in slots_box.get_children():
		slot.changed.connect(_save_to_db)

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

# Fills the slots with what the save contains (so the items stay when the scene changes)
func _load_from_db():
	loading = true
	var slots = slots_box.get_children()
	var rows = GameDB.get_inventory(GameDB.current_save_id)
	for row in rows:
		var index = int(row["slot_index"]) - 1
		if index < 0 or index >= slots.size():
			continue
		if row["item_id"] == null:
			slots[index].clear_item()
		else:
			var item = GameDB.get_item(int(row["item_id"]))
			if item.is_empty():
				slots[index].clear_item()
			else:
				slots[index].put_item(int(row["item_id"]), load(item["icon_file"]))
	loading = false

# Writes the 6 slots to the database
func _save_to_db():
	if loading:
		return
	var slots = slots_box.get_children()
	for i in slots.size():
		var slot = slots[i]
		var id = null
		if not slot.is_empty() and slot.item_id > 0:
			id = slot.item_id
		GameDB.set_slot_item(GameDB.current_save_id, i + 1, id)
