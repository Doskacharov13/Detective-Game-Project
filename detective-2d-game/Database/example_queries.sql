-- Example queries: copy one at a time into DB Browser ("Execute SQL" tab)

-- 1) All items and the scene where each one is found
SELECT items.name AS item, scenes.name AS scene
FROM items JOIN scenes ON scenes.scene_id = items.found_in_scene_id;

-- 2) Which clues are needed for each deduction
SELECT d.name AS deduction, c.name AS clue
FROM deduction_clues dc
JOIN deductions d ON d.deduction_id = dc.deduction_id
JOIN clues c      ON c.clue_id = dc.clue_id
ORDER BY d.deduction_id;

-- 3) What the test player carries in each slot (empty slots show NULL)
SELECT si.slot_index, items.name AS item
FROM save_inventory si LEFT JOIN items ON items.item_id = si.item_id
WHERE si.save_id = 1 ORDER BY si.slot_index;

-- 4) Move the item from slot 1 to slot 3 (what dragging does in the game)
UPDATE save_inventory SET item_id = NULL WHERE save_id = 1 AND slot_index = 1;
UPDATE save_inventory SET item_id = 1    WHERE save_id = 1 AND slot_index = 3;

-- 5) Has the player found every clue for deduction 3?
SELECT d.name,
       COUNT(dc.clue_id)  AS clues_needed,
       COUNT(sc.clue_id)  AS clues_found
FROM deductions d
JOIN deduction_clues dc ON dc.deduction_id = d.deduction_id
LEFT JOIN save_clues sc ON sc.clue_id = dc.clue_id AND sc.save_id = 1
WHERE d.deduction_id = 3;

-- 6) All blacklight clues and where they are
SELECT clues.name, scenes.name AS scene
FROM clues JOIN scenes ON scenes.scene_id = clues.scene_id
WHERE clue_type = 'blacklight';
