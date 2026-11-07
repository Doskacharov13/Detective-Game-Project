extends CanvasLayer
# The evidence board. Everything is built in code, so the scene only needs this one node.

const ClueCardScript = preload("res://Scripts/Board/clue_card.gd")
const CARD_SIZE = Vector2(240, 168)

var root: Control
var strings: Node2D
var cards_holder: Control
var message_label: Label
var solved_label: Label
var solved_panel: ColorRect
var close_button: Button

var cards = {}            # clue_id -> card
var connections = []      # each one: {"a": card, "b": card, "line": Line2D}
var selected_card = null
var deductions = []       # filled from the database

func _ready():
	layer = 10            # above everything else
	_build_ui()
	visible = false

# ---------- Building the screen ----------

func _build_ui():
	root = Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var background = TextureRect.new()
	background.texture = load("res://art/ui/evidence_board_background.svg")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.mouse_filter = Control.MOUSE_FILTER_STOP   # stops clicks reaching the scene below
	root.add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		# A dark box behind the list of solved deductions, so it is easy to read
	solved_panel = ColorRect.new()
	solved_panel.color = Color(0, 0, 0, 0.45)
	solved_panel.position = Vector2(70, 590)
	solved_panel.size = Vector2(1200, 430)
	solved_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(solved_panel)

	strings = Node2D.new()
	root.add_child(strings)

	cards_holder = Control.new()
	cards_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(cards_holder)

	message_label = _make_label(Vector2(260, 50), Vector2(1400, 70), 34, HORIZONTAL_ALIGNMENT_CENTER)
	solved_label = _make_label(Vector2(95, 605), Vector2(1150, 400), 28, HORIZONTAL_ALIGNMENT_LEFT)

	close_button = Button.new()
	close_button.text = "Close"
	close_button.position = Vector2(1720, 50)
	close_button.size = Vector2(150, 64)
	close_button.add_theme_font_size_override("font_size", 28)
	close_button.pressed.connect(close)
	root.add_child(close_button)

func _make_label(pos: Vector2, label_size: Vector2, font_size: int, align) -> Label:
	var label = Label.new()
	label.position = pos
	label.size = label_size
	label.horizontal_alignment = align
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 10)
	root.add_child(label)
	return label

# ---------- Opening and closing ----------

func open():
	_load_deductions()
	_refresh_cards()
	_update_solved_list()
	_clear_selection()
	message_label.text = "Click one card, then another one, to connect them."
	visible = true

func close():
	_clear_selection()
	visible = false

func _input(event):
	if not visible:
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			close()
		elif event.keycode == KEY_T:
			# TESTING ONLY: gives you all 12 clue cards
			for id in range(1, 13):
				GameDB.add_clue(GameDB.current_save_id, id)
			_refresh_cards()
			message_label.text = "Test: all clues added."

# ---------- Cards ----------

func _load_deductions():
	deductions = GameDB.get_deductions()
	for d in deductions:
		d["clue_ids"] = GameDB.get_deduction_clue_ids(int(d["deduction_id"]))

# Makes a card for every clue the player has found (and doesn't have a card yet)
func _refresh_cards():
	var found = GameDB.get_found_clues(GameDB.current_save_id)
	var index = cards.size()
	for clue in found:
		var id = int(clue["clue_id"])
		if cards.has(id):
			continue
		var card = TextureRect.new()
		card.set_script(ClueCardScript)
		cards_holder.add_child(card)
		card.setup(id, clue["name"], clue["description"])
		card.position = Vector2(120 + (index % 6) * 280, 150 + floori(index / 6.0) * 230)
		card.card_clicked.connect(_on_card_clicked)
		card.card_moved.connect(_update_strings)
		cards[id] = card
		index += 1

func _clear_selection():
	if selected_card != null:
		selected_card.set_selected(false)
	selected_card = null

# ---------- Connecting cards ----------

func _on_card_clicked(card):
	# First click: select the card
	if selected_card == null:
		selected_card = card
		card.set_selected(true)
		message_label.text = "Selected: " + card.clue_name + ". Now click another card."
		return

	# Click the same card again: cancel
	if selected_card == card:
		_clear_selection()
		message_label.text = "Cancelled."
		return

	# Second click: try to connect the two cards
	var first = selected_card
	_clear_selection()
	_try_connect(first, card)

func _try_connect(a, b):
	if _are_connected(a, b):
		message_label.text = "These two cards are already connected."
		return

	if _belong_together(a.clue_id, b.clue_id):
		_add_string(a, b, Color(0.95, 0.78, 0.25))   # gold string stays
		message_label.text = "These clues fit together!"
		_check_deductions()
	else:
		_flash_wrong_string(a, b)                    # red string fades away
		message_label.text = "These two clues don't seem to be connected."

func _are_connected(a, b) -> bool:
	for c in connections:
		if (c["a"] == a and c["b"] == b) or (c["a"] == b and c["b"] == a):
			return true
	return false

# Two clues fit together if one deduction needs both of them
func _belong_together(id_a: int, id_b: int) -> bool:
	for d in deductions:
		if int(d["is_final"]) == 1:
			continue
		if id_a in d["clue_ids"] and id_b in d["clue_ids"]:
			return true
	return false

func _pin_position(card) -> Vector2:
	return strings.to_local(card.global_position + Vector2(CARD_SIZE.x / 2.0, 6.0))

func _add_string(a, b, color: Color):
	var line = Line2D.new()
	line.width = 6
	line.default_color = color
	line.points = PackedVector2Array([_pin_position(a), _pin_position(b)])
	strings.add_child(line)
	connections.append({"a": a, "b": b, "line": line})

func _flash_wrong_string(a, b):
	var line = Line2D.new()
	line.width = 6
	line.default_color = Color(0.9, 0.15, 0.15)
	line.points = PackedVector2Array([_pin_position(a), _pin_position(b)])
	strings.add_child(line)
	var tween = create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.9)
	tween.tween_callback(line.queue_free)

# Moves the strings when a card is dragged
func _update_strings():
	for c in connections:
		c["line"].points = PackedVector2Array([_pin_position(c["a"]), _pin_position(c["b"])])

# ---------- Solving deductions ----------

func _check_deductions():
	var save_id = GameDB.current_save_id
	for d in deductions:
		if int(d["is_final"]) == 1:
			continue
		var id = int(d["deduction_id"])
		if GameDB.is_deduction_solved(save_id, id):
			continue
		if _all_connected(d["clue_ids"]):
			GameDB.mark_deduction_solved(save_id, id)
			message_label.text = "Deduction solved: " + d["conclusion"]

	_check_final_deduction()
	_update_solved_list()

# The final deduction is solved when all the others are solved
func _check_final_deduction():
	var save_id = GameDB.current_save_id
	for d in deductions:
		if int(d["is_final"]) == 0 and not GameDB.is_deduction_solved(save_id, int(d["deduction_id"])):
			return
	for d in deductions:
		if int(d["is_final"]) == 1 and not GameDB.is_deduction_solved(save_id, int(d["deduction_id"])):
			GameDB.mark_deduction_solved(save_id, int(d["deduction_id"]))
			message_label.text = "CASE SOLVED! " + d["conclusion"]

# True if all the clues are linked together by gold strings
func _all_connected(clue_ids: Array) -> bool:
	if clue_ids.is_empty():
		return false
	for id in clue_ids:
		if not cards.has(id):
			return false

	var visited = {}
	var queue = [cards[clue_ids[0]]]
	visited[cards[clue_ids[0]]] = true
	while not queue.is_empty():
		var current = queue.pop_front()
		for c in connections:
			var other = null
			if c["a"] == current:
				other = c["b"]
			elif c["b"] == current:
				other = c["a"]
			if other != null and not visited.has(other):
				visited[other] = true
				queue.append(other)

	for id in clue_ids:
		if not visited.has(cards[id]):
			return false
	return true

func _update_solved_list():
	var conclusions = GameDB.get_solved_conclusions(GameDB.current_save_id)
	solved_panel.visible = not conclusions.is_empty()
	if conclusions.is_empty():
		solved_label.text = ""
		return
	solved_label.text = "Solved:\n- " + "\n- ".join(conclusions)
