extends Area2D
# A clickable spot in a scene. Put a CollisionShape2D (rectangle) inside it.

signal clicked(hotspot)

@export var hotspot_name: String = "Hotspot"
@export_multiline var message: String = ""   # text shown when clicked (empty = automatic text)
@export var item_id: int = 0                 # the item's id in the database (0 = not an item)
@export var only_in_blacklight: bool = false # only exists while the blacklight is on
@export var hide_in_blacklight: bool = false # only exists while the blacklight is off
@export var show_outline: bool = true        # turn this off when the final art is in

var hovering = false

func _ready():
	input_pickable = true
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	if only_in_blacklight:
		set_active(false)

# Turns the hotspot on or off (invisible and not clickable when off)
func set_active(on: bool):
	visible = on
	input_pickable = on
	$CollisionShape2D.set_deferred("disabled", not on)
	if not on:
		hovering = false
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	queue_redraw()

func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(self)

func _on_mouse_entered():
	hovering = true
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	queue_redraw()

func _on_mouse_exited():
	hovering = false
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	queue_redraw()

# Draws a yellow box so you can see where the hotspot is
func _draw():
	if not show_outline:
		return
	var shape = $CollisionShape2D.shape as RectangleShape2D
	var rect = Rect2(-shape.size / 2, shape.size)
	var alpha = 0.45 if hovering else 0.18
	draw_rect(rect, Color(1, 0.9, 0.4, alpha), true)
	draw_rect(rect, Color(1, 0.9, 0.4, 0.9), false, 2.0)
