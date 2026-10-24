extends Panel

@onready var item: TextureRect = $Item

func _ready():
	# Let the Slot itself receive the mouse, not the picture inside it
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE

func pickFromSlot():
	item.texture = null

func putIntoSlot(new_texture):
	item.texture = new_texture

# Godot calls this when you press and drag on this slot
func _get_drag_data(_at_position):
	if item.texture == null:
		return null # empty slot, nothing to drag

	# Small picture that follows the mouse while dragging
	var preview = TextureRect.new()
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE # IMPORTANT: otherwise it blocks the drop
	preview.texture = item.texture
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.size = Vector2(100, 100)
	preview.position = -preview.size / 2 # centered on the mouse
	var holder = Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(preview)
	set_drag_preview(holder)

	# Fade the item in its original slot while dragging
	item.modulate.a = 0.3

	return {"from_slot": self, "texture": item.texture}

# Godot calls this on the slot under the mouse: can the item be dropped here?
func _can_drop_data(_at_position, data):
	return typeof(data) == TYPE_DICTIONARY and data.has("from_slot")

# Godot calls this when you release the mouse over this slot
func _drop_data(_at_position, data):
	var from_slot = data["from_slot"]
	if from_slot == self:
		return

	# Swap: if this slot is empty, the item simply moves here
	var my_texture = item.texture
	putIntoSlot(data["texture"])
	from_slot.putIntoSlot(my_texture)

# Restore the item's look when any drag ends (dropped or cancelled)
func _notification(what):
	if what == NOTIFICATION_DRAG_END:
		item.modulate.a = 1.0
#da
