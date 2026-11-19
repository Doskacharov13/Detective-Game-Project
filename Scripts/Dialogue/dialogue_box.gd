extends CanvasLayer
# The dialogue box. It is an Autoload named DialogueBox and builds itself in code.
# Use it from a scene:  DialogueBox.start(character_id, scene_id)

signal item_given(item_id)   # a line of the conversation gave the player an item
signal finished              # the conversation is over

var root: Control
var name_label: Label
var text_label: Label
var hint_label: Label

var lines = []          # the lines of the current conversation
var index = 0
var typing = false
var active = false
var tween: Tween

func _ready():
	layer = 20            # above the evidence board
	_build_ui()
	visible = false

# ---------- Building the box ----------

func _build_ui():
	root = Control.new()
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP   # blocks clicks on the scene while people talk
	root.gui_input.connect(_on_gui_input)

	var panel = ColorRect.new()
	panel.color = Color(0.05, 0.04, 0.03, 0.88)
	panel.position = Vector2(160, 770)
	panel.size = Vector2(1600, 270)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(panel)

	var gold_line = ColorRect.new()
	gold_line.color = Color(0.79, 0.64, 0.29)
	gold_line.position = Vector2(160, 770)
	gold_line.size = Vector2(1600, 4)
	gold_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(gold_line)

	name_label = _make_label(Vector2(200, 790), Vector2(1500, 50), 36, Color(0.95, 0.78, 0.25))
	text_label = _make_label(Vector2(200, 850), Vector2(1520, 140), 32, Color.WHITE)
	hint_label = _make_label(Vector2(1260, 995), Vector2(480, 36), 24, Color(0.7, 0.7, 0.7))
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

func _make_label(pos: Vector2, label_size: Vector2, font_size: int, color: Color) -> Label:
	var label = Label.new()
	label.position = pos
	label.size = label_size
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	root.add_child(label)
	return label

# ---------- Starting a conversation ----------

func start(character_id: int, scene_id: int):
	if active:
		return

	var character = GameDB.get_character(character_id)
	var rows = GameDB.get_dialogue(character_id, scene_id)

	lines = []
	for row in rows:
		# A line that needs an item is only said if the player already found that item
		if row["required_item_id"] != null:
			if not GameDB.has_picked_up(GameDB.current_save_id, int(row["required_item_id"])):
				continue
		lines.append(row)

	if lines.is_empty():
		lines = [{"text": "...", "gives_clue_id": null, "gives_item_id": null}]

	name_label.text = character.get("name", "???")
	index = 0
	active = true
	visible = true
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	_show_line()

# ---------- Showing lines ----------

func _show_line():
	var line = lines[index]
	_apply_rewards(line)

	text_label.text = line["text"]
	text_label.visible_ratio = 0.0
	typing = true
	if tween:
		tween.kill()
	tween = create_tween()
	var duration = max(0.3, line["text"].length() * 0.02)
	tween.tween_property(text_label, "visible_ratio", 1.0, duration)
	tween.tween_callback(_typing_done)

	if index < lines.size() - 1:
		hint_label.text = "Click to continue"
	else:
		hint_label.text = "Click to close"

func _typing_done():
	typing = false

# A line can give a clue or an item
func _apply_rewards(line):
	if line.get("gives_clue_id") != null:
		GameDB.add_clue(GameDB.current_save_id, int(line["gives_clue_id"]))
	if line.get("gives_item_id") != null:
		var item_id = int(line["gives_item_id"])
		if not GameDB.has_picked_up(GameDB.current_save_id, item_id):
			item_given.emit(item_id)

# ---------- Moving on ----------

func _advance():
	# While the text is still appearing, a click shows the whole line
	if typing:
		if tween:
			tween.kill()
		text_label.visible_ratio = 1.0
		typing = false
		return

	index += 1
	if index >= lines.size():
		_close()
	else:
		_show_line()

func _close():
	active = false
	visible = false
	finished.emit()

func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_advance()

func _input(event):
	if not active:
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			_advance()
			get_viewport().set_input_as_handled()
