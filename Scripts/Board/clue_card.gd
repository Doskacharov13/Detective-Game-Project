extends TextureRect
# One clue card on the evidence board. The board creates these in code.

signal card_clicked(card)
signal card_moved

const CARD_TEXTURE = preload("res://art/ui/clue_card.svg")
const PIN_TEXTURE = preload("res://art/ui/pin.svg")
const CARD_SIZE = Vector2(240, 168)

var clue_id: int = 0
var clue_name: String = ""

var dragging = false
var drag_offset = Vector2.ZERO
var press_position = Vector2.ZERO
var moved_too_far = false

func setup(id: int, title: String, description: String):
	clue_id = id
	clue_name = title

	texture = CARD_TEXTURE
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_SCALE
	size = CARD_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	tooltip_text = description   # hover over the card to read the description

	# The name of the clue
	var label = Label.new()
	label.text = title
	label.position = Vector2(18, 34)
	label.size = Vector2(204, 90)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(0.15, 0.1, 0.05))
	add_child(label)

	# The red pin at the top
	var pin = TextureRect.new()
	pin.texture = PIN_TEXTURE
	pin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pin.stretch_mode = TextureRect.STRETCH_SCALE
	pin.size = Vector2(44, 44)
	pin.position = Vector2(CARD_SIZE.x / 2.0 - 22, -16)
	pin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pin)

# The selected card is highlighted in yellow
func set_selected(on: bool):
	modulate = Color(1.0, 1.0, 0.6) if on else Color(1, 1, 1)

# Press = maybe a click. Press and move = drag the card.
func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = true
			moved_too_far = false
			press_position = get_global_mouse_position()
			drag_offset = press_position - global_position
			get_parent().move_child(self, -1)   # bring this card to the front
		else:
			if dragging and not moved_too_far:
				card_clicked.emit(self)
			dragging = false
	elif event is InputEventMouseMotion and dragging:
		var mouse = get_global_mouse_position()
		if mouse.distance_to(press_position) > 6:
			moved_too_far = true
		if moved_too_far:
			var limit = get_viewport_rect().size
			var new_pos = mouse - drag_offset
			new_pos.x = clampf(new_pos.x, 0.0, limit.x - size.x)
			new_pos.y = clampf(new_pos.y, 100.0, limit.y - size.y)
			global_position = new_pos
			card_moved.emit()
