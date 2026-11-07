extends Panel

@onready var item: TextureRect = $Item

var item_id: int = 0   # the item's id in the database (0 = no id)

var normal_style: StyleBox
var active_style: StyleBoxTexture

func _ready():
	# Let the Slot itself receive the mouse, not the picture inside it
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# All slots join one group so we can find them together
	add_to_group("slots")

	# Remember the normal look, and prepare the glowing "active" look
	normal_style = get_theme_stylebox("panel")
	active_style = StyleBoxTexture.new()
	active_style.texture = preload("res://UI/Inventory/Inventory_Slot_Active.png")

# ---------- Content of the slot ----------

func is_empty() -> bool:
	return item.texture == null

func put_item(new_id: int, new_texture: Texture2D):
	item_id = new_id
	item.texture = new_texture

func clear_item():
	item_id = 0
	item.texture = null

# ---------- Active slot ----------

# Click on a slot to make it the active one
func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		set_active()

# This slot becomes active, all the others go back to normal
func set_active():
	for slot in get_tree().get_nodes_in_group("slots"):
		slot.set_highlight(slot == self)

func set_highlight(on: bool):
	if on:
		add_theme_stylebox_override("panel", active_style)
	else:
		add_theme_stylebox_override("panel", normal_style)

# ---------- Drag and drop ----------

# Godot calls this when you press and drag on this slot
func _get_drag_data(_at_position):
	if is_empty():
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

	return {"from_slot": self, "item_id": item_id, "texture": item.texture}

# Godot calls this on the slot under the mouse: can the item be dropped here?
func _can_drop_data(_at_position, data):
	return typeof(data) == TYPE_DICTIONARY and data.has("from_slot")

# Godot calls this when you release the mouse over this slot
func _drop_data(_at_position, data):
	var from_slot = data["from_slot"]
	if from_slot == self:
		return

	# Swap: if this slot is empty, the item simply moves here
	var my_id = item_id
	var my_texture = item.texture
	put_item(data["item_id"], data["texture"])
	from_slot.put_item(my_id, my_texture)

	# The slot you dropped on becomes the active one
	set_active()

# Restore the item's look when any drag ends (dropped or cancelled)
func _notification(what):
	if what == NOTIFICATION_DRAG_END:
		item.modulate.a = 1.0
