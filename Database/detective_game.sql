-- =====================================================================
-- The Calendar Case: database for the detective game
-- SQLite. Part A = game content (does not change while playing)
--         Part B = save data (changes while playing)
-- =====================================================================
PRAGMA foreign_keys = ON;

-- ---------------------------------------------------------------------
-- PART A: GAME CONTENT
-- ---------------------------------------------------------------------

-- 1) Everyone in the story
CREATE TABLE characters (
    character_id  INTEGER PRIMARY KEY,
    name          TEXT NOT NULL UNIQUE,
    role          TEXT NOT NULL,
    description   TEXT,
    is_culprit    INTEGER NOT NULL DEFAULT 0 CHECK (is_culprit IN (0, 1))
);

-- 2) Every place the player can visit
CREATE TABLE scenes (
    scene_id        INTEGER PRIMARY KEY,
    name            TEXT NOT NULL UNIQUE,
    chapter         INTEGER NOT NULL,            -- 0 = available in every chapter
    description     TEXT,
    background_file TEXT NOT NULL,
    uv_layer_file   TEXT                         -- NULL = no blacklight layer
);

-- 3) Things the player can pick up (they go into the inventory slots)
CREATE TABLE items (
    item_id      INTEGER PRIMARY KEY,
    name         TEXT NOT NULL UNIQUE,
    description  TEXT,
    icon_file    TEXT NOT NULL,
    found_in_scene_id INTEGER NOT NULL REFERENCES scenes(scene_id)
);

-- 4) Cards on the evidence board: items, blacklight marks and statements
CREATE TABLE clues (
    clue_id      INTEGER PRIMARY KEY,
    name         TEXT NOT NULL UNIQUE,
    description  TEXT NOT NULL,
    clue_type    TEXT NOT NULL CHECK (clue_type IN ('item', 'blacklight', 'statement')),
    item_id      INTEGER REFERENCES items(item_id),    -- only for clue_type = 'item'
    scene_id     INTEGER NOT NULL REFERENCES scenes(scene_id),
    character_id INTEGER REFERENCES characters(character_id)  -- who said it (statements)
);

-- 5) The puzzles on the evidence board
CREATE TABLE deductions (
    deduction_id     INTEGER PRIMARY KEY,
    name             TEXT NOT NULL UNIQUE,
    conclusion       TEXT NOT NULL,              -- what the player learns when solved
    unlocks_scene_id INTEGER REFERENCES scenes(scene_id),
    is_final         INTEGER NOT NULL DEFAULT 0 CHECK (is_final IN (0, 1))
);

-- 6) Which clues must be connected to solve each deduction
--    (one deduction needs several clues, one clue can be used in more deductions)
CREATE TABLE deduction_clues (
    deduction_id INTEGER NOT NULL REFERENCES deductions(deduction_id),
    clue_id      INTEGER NOT NULL REFERENCES clues(clue_id),
    PRIMARY KEY (deduction_id, clue_id)
);

-- 7) What characters say
CREATE TABLE dialogue (
    dialogue_id    INTEGER PRIMARY KEY,
    character_id   INTEGER NOT NULL REFERENCES characters(character_id),
    scene_id       INTEGER NOT NULL REFERENCES scenes(scene_id),
    line_order     INTEGER NOT NULL,             -- order inside the conversation
    text           TEXT NOT NULL,
    required_item_id INTEGER REFERENCES items(item_id),   -- NULL = always said
    gives_clue_id    INTEGER REFERENCES clues(clue_id),   -- clue received after this line
    UNIQUE (character_id, scene_id, line_order)
);

-- ---------------------------------------------------------------------
-- PART B: SAVE DATA
-- ---------------------------------------------------------------------

-- 8) One row per save file
CREATE TABLE saves (
    save_id          INTEGER PRIMARY KEY,
    player_name      TEXT NOT NULL,
    current_scene_id INTEGER NOT NULL REFERENCES scenes(scene_id),
    current_chapter  INTEGER NOT NULL DEFAULT 1,
    active_slot      INTEGER,                    -- which inventory slot is highlighted
    created_at       TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at       TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 9) What is in each inventory slot (saves the order after dragging items)
CREATE TABLE save_inventory (
    save_id    INTEGER NOT NULL REFERENCES saves(save_id) ON DELETE CASCADE,
    slot_index INTEGER NOT NULL CHECK (slot_index BETWEEN 1 AND 6),
    item_id    INTEGER REFERENCES items(item_id),   -- NULL = empty slot
    PRIMARY KEY (save_id, slot_index)
);

-- 10) Clue cards the player has found
CREATE TABLE save_clues (
    save_id  INTEGER NOT NULL REFERENCES saves(save_id) ON DELETE CASCADE,
    clue_id  INTEGER NOT NULL REFERENCES clues(clue_id),
    found_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (save_id, clue_id)
);

-- 11) Deductions the player has solved
CREATE TABLE save_deductions (
    save_id      INTEGER NOT NULL REFERENCES saves(save_id) ON DELETE CASCADE,
    deduction_id INTEGER NOT NULL REFERENCES deductions(deduction_id),
    solved_at    TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (save_id, deduction_id)
);

-- =====================================================================
-- DATA
-- =====================================================================

INSERT INTO characters (character_id, name, role, description, is_culprit) VALUES
 (1, 'Elias Crowe',      'Detective (player)', 'Calm and patient. Carries a blacklight in his coat.', 0),
 (2, 'Ruth Calloway',    'Police captain',     'Runs the precinct and gives you the case files.', 0),
 (3, 'Daniel Hargrove',  'District attorney',  'Honest and tired. Wants to put Lucian Vance in prison.', 0),
 (4, 'Quentin Marsh',    'Prisoner / almanac writer', 'Understands calendars and patterns. Only helps if you bring real clues.', 0),
 (5, 'Adrian Vance',     'Crime boss''s son',  'Quiet and polite. The first killer.', 1),
 (6, 'Helena Hargrove',  'DA''s wife',         'Becomes the second killer. The twist of the story.', 1);

INSERT INTO scenes (scene_id, name, chapter, description, background_file, uv_layer_file) VALUES
 (1, 'Precinct Office',       0, 'The hub. Case board and the map to other places.', 'res://art/backgrounds/precinct_office.svg', NULL),
 (2, 'Harbor Warehouse',      1, 'Halloween. A man has been shot.',                   'res://art/backgrounds/harbor_warehouse.svg', 'res://art/blacklight/harbor_warehouse_uv.svg'),
 (3, 'Prison Visiting Room',  2, 'Thanksgiving. Professor Marsh waits at the table.', 'res://art/backgrounds/prison_visiting_room.svg', 'res://art/blacklight/prison_visiting_room_uv.svg'),
 (4, 'Vance Mansion Study',   3, 'Christmas. The desk drawer is locked.',             'res://art/backgrounds/vance_mansion_study.svg', 'res://art/blacklight/vance_mansion_study_uv.svg'),
 (5, 'Hargrove Apartment',    4, 'New Year''s Eve. Helena is nervous.',               'res://art/backgrounds/hargrove_apartment.svg', 'res://art/blacklight/hargrove_apartment_uv.svg');

INSERT INTO items (item_id, name, description, icon_file, found_in_scene_id) VALUES
 (1, 'Old Storage Key',      'A key stamped with a crest. Opens the desk drawer in the Vance study.', 'res://UI/Inventory/OldStorageKey.png', 2),
 (2, 'Shell Casing',         'A small .22 casing. The killer used the same gun every time.',       'res://art/items/shell_casing.svg', 2),
 (3, 'Warehouse Photograph', 'A photo of the crime scene with the body outline.',                   'res://art/items/warehouse_photograph.svg', 2),
 (4, 'Almanac Page',         'A calendar page with four holidays circled in red.',                   'res://art/items/almanac_page.svg', 3),
 (5, 'Ledger Page',          'Looks like ordinary accounts, but hides something under UV light.',    'res://art/items/ledger_page.svg', 4),
 (6, 'Black Leather Glove',  'Found behind the kitchen door. Powder residue glows under UV light.',  'res://art/items/black_leather_glove.svg', 5);

INSERT INTO clues (clue_id, name, description, clue_type, item_id, scene_id, character_id) VALUES
 (1,  'Shell Casing',          'A .22 casing left at the warehouse.',                         'item',       2,    2, NULL),
 (2,  'Warehouse Photograph',  'The shooter stood at the side door.',                         'item',       3,    2, NULL),
 (3,  'Old Storage Key',       'Stamped with the Vance family crest.',                        'item',       1,    2, NULL),
 (4,  'Chemical Trail',        'A glowing trail on the floor that leads to the side door.',  'blacklight', NULL, 2, NULL),
 (5,  'Almanac Page',          'Holidays circled in red: the killer follows a calendar.',     'item',       4,    3, NULL),
 (6,  'Hidden Date',           'A date in the margin, visible only under UV light.',          'blacklight', NULL, 3, NULL),
 (7,  'Marsh''s Warning',      'The killer is two people, not one.',                          'statement',  NULL, 3, 4),
 (8,  'Ledger Page',           'Normal accounts in daylight.',                                'item',       5,    4, NULL),
 (9,  'Hidden Victim List',    'Under UV light: a list of victims in Adrian''s handwriting.', 'blacklight', NULL, 4, NULL),
 (10, 'Black Leather Glove',   'A glove from the Hargrove kitchen.',                          'item',       6,    5, NULL),
 (11, 'Powder Glow',           'Gunpowder residue on the glove, visible under UV light.',     'blacklight', NULL, 5, NULL),
 (12, 'Helena''s Alibi',       'Helena says she was home all night, but she was nervous.',    'statement',  NULL, 5, 6);

INSERT INTO deductions (deduction_id, name, conclusion, unlocks_scene_id, is_final) VALUES
 (1, 'One gun',            'The same gun was used in the killings.',           3, 0),
 (2, 'Two killers',        'Two killers follow a holiday list.',               4, 0),
 (3, 'Adrian began it',    'Adrian Vance began the killings.',                 5, 0),
 (4, 'Helena continued',   'Helena Hargrove continued the killings.',          1, 0),
 (5, 'Case solved',        'All the conclusions fit: the case is solved.',     NULL, 1);

INSERT INTO deduction_clues (deduction_id, clue_id) VALUES
 (1, 1), (1, 2),
 (2, 5), (2, 7),
 (3, 3), (3, 8), (3, 9),
 (4, 10), (4, 11), (4, 12);
-- (Deduction 5 has no clues: it needs deductions 1 to 4 to be solved.)

INSERT INTO dialogue (dialogue_id, character_id, scene_id, line_order, text, required_item_id, gives_clue_id) VALUES
 (1, 2, 1, 1, 'Another man dead on a holiday, Crowe. Same small gun as the others.', NULL, NULL),
 (2, 2, 1, 2, 'Start at the harbor warehouse. Take your blacklight.', NULL, NULL),
 (3, 4, 3, 1, 'You came to see me? Then show me something worth my time.', NULL, NULL),
 (4, 4, 3, 2, 'That casing... yes. I know this pattern. Look at the calendar.', 2, 5),
 (5, 4, 3, 3, 'Be careful, detective. The killer is two people, not one.', 2, 7),
 (6, 5, 4, 1, 'My father is not here. Is there something I can help you with?', NULL, NULL),
 (7, 6, 5, 1, 'Daniel is at the office. I was home all night. Alone.', NULL, 12),
 (8, 3, 1, 1, 'Whatever you find, Crowe, I need proof. Names are not enough in court.', NULL, NULL);

-- A sample save so you can test your queries
INSERT INTO saves (save_id, player_name, current_scene_id, current_chapter, active_slot) VALUES
 (1, 'Test Player', 2, 1, 1);
INSERT INTO save_inventory (save_id, slot_index, item_id) VALUES
 (1, 1, 1), (1, 2, 2), (1, 3, NULL), (1, 4, NULL), (1, 5, NULL), (1, 6, NULL);
INSERT INTO save_clues (save_id, clue_id) VALUES (1, 1), (1, 3);
INSERT INTO save_deductions (save_id, deduction_id) VALUES (1, 1);
