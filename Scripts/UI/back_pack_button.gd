extends Button

var open_texture = preload("res://UI/Inventory/BackPackOpen.png")
var closed_texture = preload("res://UI/Inventory/BackPackClosed.png")

# The inventory panel is a sibling of this button in the scene tree
@onready var inventory_container = get_node("../InventoryContainer")

var is_open = false

func _ready():
	set_button_icon(closed_texture)
	toggle_mode = false
	pressed.connect(_on_pressed)

func _on_pressed():
	is_open = !is_open
	inventory_container.visible = is_open

	if is_open:
		set_button_icon(open_texture)
	else:
		set_button_icon(closed_texture)
