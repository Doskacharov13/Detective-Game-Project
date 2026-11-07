extends Node
# This script is an "Autoload": Godot loads it once when the game starts,
# and every other script can use it by its name:  GameDB.get_item(1)

const DB_SOURCE = "res://Database/detective_game.db"  # the file inside your project
const DB_COPY = "user://detective_game.db"            # the copy the game really uses

# While you are building the game: true = start with a fresh copy every time
# (so changes you make in DB Browser show up). Set to false when saving matters.
const RESET_COPY_ON_START = true

var db: SQLite
var current_save_id: int = 1   # which save we are playing (1 = the test save)

func _ready():
	# A finished game cannot write inside res://, so we work on a copy in user://
	if RESET_COPY_ON_START or not FileAccess.file_exists(DB_COPY):
		DirAccess.copy_absolute(DB_SOURCE, DB_COPY)

	db = SQLite.new()
	db.path = DB_COPY
	db.foreign_keys = true
	if not db.open_db():
		push_error("Could not open the database")
		return

	# While building: every run starts with no clues found and nothing solved
	if RESET_COPY_ON_START:
		start_new_game()

	print("Database opened. Items found: ", get_all_items().size())

# ---------- Reading game content ----------

func get_all_items() -> Array:
	db.query("SELECT * FROM items;")
	return db.query_result

func get_item(item_id: int) -> Dictionary:
	db.query_with_bindings("SELECT * FROM items WHERE item_id = ?;", [item_id])
	if db.query_result.is_empty():
		return {}
	return db.query_result[0]

func get_dialogue(character_id: int, scene_id: int) -> Array:
	db.query_with_bindings(
		"SELECT * FROM dialogue WHERE character_id = ? AND scene_id = ? ORDER BY line_order;",
		[character_id, scene_id])
	return db.query_result

# All deductions (the puzzles of the evidence board)
func get_deductions() -> Array:
	db.query("SELECT * FROM deductions ORDER BY deduction_id;")
	return db.query_result

# The ids of the clues needed for one deduction, for example [1, 2]
func get_deduction_clue_ids(deduction_id: int) -> Array:
	db.query_with_bindings("SELECT clue_id FROM deduction_clues WHERE deduction_id = ?;", [deduction_id])
	var rows = db.query_result
	var ids = []
	for row in rows:
		ids.append(int(row["clue_id"]))
	return ids

# ---------- Reading and writing the save ----------

func start_new_game() -> void:
	db.query_with_bindings("DELETE FROM save_clues WHERE save_id = ?;", [current_save_id])
	db.query_with_bindings("DELETE FROM save_deductions WHERE save_id = ?;", [current_save_id])

func get_inventory(save_id: int) -> Array:
	db.query_with_bindings(
		"SELECT si.slot_index, si.item_id, i.name, i.icon_file " +
		"FROM save_inventory si LEFT JOIN items i ON i.item_id = si.item_id " +
		"WHERE si.save_id = ? ORDER BY si.slot_index;", [save_id])
	return db.query_result

func set_slot_item(save_id: int, slot_index: int, item_id) -> void:
	db.query_with_bindings(
		"UPDATE save_inventory SET item_id = ? WHERE save_id = ? AND slot_index = ?;",
		[item_id, save_id, slot_index])

# --- clues ---

func add_clue(save_id: int, clue_id: int) -> void:
	db.query_with_bindings(
		"INSERT OR IGNORE INTO save_clues (save_id, clue_id) VALUES (?, ?);", [save_id, clue_id])

# When the player picks up an item, the matching clue card is found too
func add_clue_for_item(save_id: int, item_id: int) -> void:
	db.query_with_bindings("SELECT clue_id FROM clues WHERE item_id = ?;", [item_id])
	var rows = db.query_result
	for row in rows:
		add_clue(save_id, int(row["clue_id"]))

func has_clue(save_id: int, clue_id: int) -> bool:
	db.query_with_bindings(
		"SELECT 1 FROM save_clues WHERE save_id = ? AND clue_id = ?;", [save_id, clue_id])
	return not db.query_result.is_empty()

# The clues the player has found (name, description ...)
func get_found_clues(save_id: int) -> Array:
	db.query_with_bindings(
		"SELECT c.* FROM save_clues sc JOIN clues c ON c.clue_id = sc.clue_id " +
		"WHERE sc.save_id = ? ORDER BY sc.found_at, c.clue_id;", [save_id])
	return db.query_result

# --- deductions ---

func mark_deduction_solved(save_id: int, deduction_id: int) -> void:
	db.query_with_bindings(
		"INSERT OR IGNORE INTO save_deductions (save_id, deduction_id) VALUES (?, ?);",
		[save_id, deduction_id])

func is_deduction_solved(save_id: int, deduction_id: int) -> bool:
	db.query_with_bindings(
		"SELECT 1 FROM save_deductions WHERE save_id = ? AND deduction_id = ?;",
		[save_id, deduction_id])
	return not db.query_result.is_empty()

# The conclusions of the solved deductions, as a list of texts
func get_solved_conclusions(save_id: int) -> Array:
	db.query_with_bindings(
		"SELECT d.conclusion FROM save_deductions sd JOIN deductions d ON d.deduction_id = sd.deduction_id " +
		"WHERE sd.save_id = ? ORDER BY d.deduction_id;", [save_id])
	var rows = db.query_result
	var texts = []
	for row in rows:
		texts.append(row["conclusion"])
	return texts

func _exit_tree():
	if db:
		db.close_db()
