extends Node
# This script is an "Autoload": Godot loads it once when the game starts,
# and every other script can use it by its name:  GameDB.get_item(1)

const DB_SOURCE = "res://Database/detective_game.db"  # the file inside your project
const DB_COPY = "user://detective_game.db"            # the copy the game really uses

# While you are building the game: true = start with a fresh copy every time
# (so changes you make in DB Browser show up). Set to false when saving matters.
const RESET_COPY_ON_START = true

var db: SQLite

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

# ---------- Reading and writing the save ----------

# Returns 6 rows: slot_index, item_id, name, icon_file (item_id is null for an empty slot)
func get_inventory(save_id: int) -> Array:
	db.query_with_bindings(
		"SELECT si.slot_index, si.item_id, i.name, i.icon_file " +
		"FROM save_inventory si LEFT JOIN items i ON i.item_id = si.item_id " +
		"WHERE si.save_id = ? ORDER BY si.slot_index;", [save_id])
	return db.query_result

# item_id = null means "empty this slot"
func set_slot_item(save_id: int, slot_index: int, item_id) -> void:
	db.query_with_bindings(
		"UPDATE save_inventory SET item_id = ? WHERE save_id = ? AND slot_index = ?;",
		[item_id, save_id, slot_index])

func add_clue(save_id: int, clue_id: int) -> void:
	db.query_with_bindings(
		"INSERT OR IGNORE INTO save_clues (save_id, clue_id) VALUES (?, ?);", [save_id, clue_id])

func has_clue(save_id: int, clue_id: int) -> bool:
	db.query_with_bindings(
		"SELECT 1 FROM save_clues WHERE save_id = ? AND clue_id = ?;", [save_id, clue_id])
	return not db.query_result.is_empty()

func _exit_tree():
	if db:
		db.close_db()
