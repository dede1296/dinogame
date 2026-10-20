extends Node
## Local save (user://, i.e. the app's private storage on Android, IndexedDB on the Web), in SLOTS
## slots (save_1.json … save_3.json). Every save — the autosave and every Save.save_game() of the game —
## goes to the ACTIVE slot (`slot`, `path`): the one last loaded, created, or chosen in game
## (Paramètres, ui/save_slots.gd); it is remembered in save_meta.json for « Continuer ».
## The save from before the slots (save.json) becomes slot 1 the first time the title screen opens
## (migrate): copied, checked, then kept as save.json.migre — never deleted.
## Written to a temporary file then renamed, so a crash mid-write never corrupts the save. A slot
## overwritten or deleted (always after a confirmation) is kept as save_N.json.ancienne.
## Saves automatically when the app goes to the background and every AUTOSAVE_S seconds.

signal saved

## The single save from before the slots: migrated to slot 1, never written again.
const PATH := "user://save.json"
## Where the player's own slots live.
const PLAYER_DIR := "user://"
const VERSION := 1
const AUTOSAVE_S := 30.0
const SLOTS := 3
const SLOT_FILE := "save_%d.json"
const META_FILE := "save_meta.json"
const LEGACY_FILE := "save.json"
const LEGACY_KEPT := ".migre"
const OLD_COPY := ".ancienne"
## What slot_summary says of a slot.
const EMPTY := "vide"
const READY := "occupe"
const UNREADABLE := "illisible"

## Set by the world while a game is running; nothing is saved from the title screen.
var enabled := false
## Called before writing, so the world can store Chloé's position in Game.
var before_save: Callable
## The folder of the slots and of save_meta.json: the player's (PLAYER_DIR), or a folder of the test
## and demo tools (see `path`).
var dir := PLAYER_DIR
## The active slot, 1 to SLOTS.
var slot := 1
## Where the game is saved: the active slot's file. The test and demo tools (tools/capture.gd, tests/)
## set a file of their own: the slots then live in a folder beside it ("<file>_slots"), never over the
## player's game; set back to a slot's file, that slot (and its folder) is active again.
var path := "":
	set(value):
		path = value
		var n := slot_of_file(value)
		if n > 0:
			dir = value.get_base_dir()
			slot = n
		elif value != "":
			dir = value.get_basename() + "_slots"

var _timer := 0.0


## Once per game version, in the installed game: the slots are copied to user://sauvegardes_avant_<old version>/
## before the new version touches them (a game updated by reinstalling keeps its saves, and a copy of them).
func backup_for_update() -> void:
	var seen_file := PLAYER_DIR + "version_vue.txt"
	var now := str(ProjectSettings.get_setting("application/config/version", ""))
	var before := FileAccess.get_file_as_string(seen_file).strip_edges() if FileAccess.file_exists(seen_file) else ""
	if before == now:
		return
	if before != "":
		var folder := PLAYER_DIR + "sauvegardes_avant_" + before
		DirAccess.make_dir_recursive_absolute(folder)
		for file in DirAccess.get_files_at(PLAYER_DIR):
			if file.begins_with("save") and (file.ends_with(".json") or file.ends_with(LEGACY_KEPT) or file.ends_with(OLD_COPY)):
				DirAccess.copy_absolute(PLAYER_DIR + file, folder + "/" + file)
	var out := FileAccess.open(seen_file, FileAccess.WRITE)
	if out:
		out.store_string(now)


func _init() -> void:
	if not OS.has_feature("editor"):   # (the installed game only: not the editor, not the tests)
		backup_for_update()
	path = path_for(slot)
	var remembered := remembered_slot()
	if remembered > 0:
		path = path_for(remembered)


func _process(delta: float) -> void:
	if not enabled:
		return
	_timer += delta
	if _timer >= AUTOSAVE_S:
		save_game()


func _notification(what: int) -> void:
	# Android: the app goes to the background (home button, call…) or is closed.
	if what in [NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_APPLICATION_FOCUS_OUT]:
		if enabled:
			save_game()


# ------------------------------------------------------------------ the game being played

## A game to continue: at least one slot holds something (or the tool's own file, see `path`).
func has_save() -> bool:
	if FileAccess.file_exists(path):
		return true
	for n in range(1, SLOTS + 1):
		if FileAccess.file_exists(path_for(n)):
			return true
	return false


## Writes the game into the active slot.
func save_game() -> bool:
	_timer = 0.0
	if before_save.is_valid():
		before_save.call()
	var data := {"version": VERSION, "saved_at": int(Time.get_unix_time_from_system()), "summary": _summary(),
		"game": Game.to_dict()}
	if not _write(path, JSON.stringify(data)):
		return false
	saved.emit()
	return true


## Loads the save into Game. Returns false (and leaves Game untouched) if it is missing or unreadable.
func load_game() -> bool:
	if not FileAccess.file_exists(path):
		return false
	var text := FileAccess.get_file_as_string(path)
	var data: Variant = JSON.parse_string(text)
	if not data is Dictionary or not data.get("game") is Dictionary:
		push_error("Sauvegarde illisible : %s" % path)
		return false
	if _number(data.get("version"), 0.0) > VERSION:
		push_error("Sauvegarde d'une version plus récente du jeu")
		return false
	Game.from_dict(data["game"])
	return true


# ------------------------------------------------------------------ the slots

## The slot a file is (save_2.json: 2), 0 for any other file.
func slot_of_file(file: String) -> int:
	for n in range(1, SLOTS + 1):
		if file.get_file() == SLOT_FILE % n:
			return n
	return 0


func path_for(n: int) -> String:
	return dir.path_join(SLOT_FILE % n)


## Loads slot `n` and makes it the active one (remembered for « Continuer »). False, and nothing
## changed, when it is empty or unreadable.
func load_slot(n: int) -> bool:
	if not _valid(n) or slot_summary(n)["state"] != READY:
		return false
	var before := path
	path = path_for(n)
	if not load_game():
		path = before
		return false
	_remember(n)
	return true


## The slot « Continuer » loads: the last one used if it can be read, else the most recently saved one
## that can; 0 when there is none.
func continue_slot() -> int:
	var remembered := remembered_slot()
	if remembered > 0 and slot_summary(remembered)["state"] == READY:
		return remembered
	var best := 0
	var best_at := -1
	for n in range(1, SLOTS + 1):
		var summary := slot_summary(n)
		if summary["state"] == READY and int(summary["saved_at"]) > best_at:
			best = n
			best_at = int(summary["saved_at"])
	return best


## A new game (Game.new_game() just done) in slot `n`, saved there at once, the active slot from now
## on. Refused (false) when the slot holds a game, unless `confirmed` (the player said « Écraser »).
func start_new_game(n: int, confirmed := false) -> bool:
	if not _valid(n) or not _may_overwrite(n, confirmed):
		return false
	_keep_old(n)
	path = path_for(n)
	_remember(n)
	return save_game()


## A Nouvelle partie+ (Game.new_game_plus, docs/post-game-plan.md § 4) from the finished game of slot `from`,
## created in slot `to`, saved there at once, the active slot from now on. Slot `from` is never touched (nor
## chosen as `to`). Refused (false, nothing changed) when `from` is not a finished game, when `to` is `from`,
## or when `to` holds a game unless `confirmed` (the player said « Écraser »: its game is put aside).
func start_new_game_plus(from: int, to: int, confirmed := false) -> bool:
	if not _valid(from) or not _valid(to) or from == to or not _may_overwrite(to, confirmed):
		return false
	if slot_summary(from).get("finished", false) != true or not Game.new_game_plus(game_of(from)):
		return false
	return start_new_game(to, true)


## The game saved in slot `n` (its Game.to_dict()), read without loading it; {} when empty or unreadable.
func game_of(n: int) -> Dictionary:
	if not _valid(n) or slot_summary(n)["state"] != READY:
		return {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path_for(n)))
	return data["game"] if data is Dictionary and data.get("game") is Dictionary else {}


## In game: from now on, everything saves in slot `n`; the game being played is copied there at once.
## Refused (false) when the slot holds another game, unless `confirmed`.
func switch_slot(n: int, confirmed := false) -> bool:
	if not _valid(n):
		return false
	if n == slot and path == path_for(n):
		return save_game()
	if not _may_overwrite(n, confirmed):
		return false
	_keep_old(n)
	var before := path
	path = path_for(n)
	if not save_game():
		path = before
		return false
	_remember(n)
	return true


## Deletes the game of slot `n` (kept aside as save_N.json.ancienne). Only `confirmed`; never the slot
## the running game saves in.
func delete_slot(n: int, confirmed := false) -> bool:
	if not _valid(n) or not confirmed or (enabled and n == slot):
		return false
	_keep_old(n)
	return not FileAccess.file_exists(path_for(n))


## What the slot screens show of slot `n`, read without loading the game: {slot, state (EMPTY, READY,
## UNREADABLE), active, and once READY: region, region_name, objective, play_time (s), lead_name,
## lead_level, saved_at (unix s), finished (the end seen: fin_vue)}.
func slot_summary(n: int) -> Dictionary:
	var file := path_for(n)
	var out := {"slot": n, "state": EMPTY, "active": n == slot}
	if not FileAccess.file_exists(file):
		return out
	out["state"] = UNREADABLE
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(file)) != OK or not json.data is Dictionary:
		return out
	var data: Dictionary = json.data
	if not data.get("game") is Dictionary or _number(data.get("version"), 0.0) > VERSION:
		return out
	# (every field read with its type checked: a damaged file says « illisible », it never stops the title)
	var game: Dictionary = data["game"]
	var flags: Dictionary = game["flags"] if game.get("flags") is Dictionary else {}
	var summary: Dictionary = data["summary"] if data.get("summary") is Dictionary else {}
	var lead := _lead_of(game)
	var region: String = game["region"] if game.get("region") is String else String(Game.START_REGION)
	var objective: String = summary["objective"] if summary.get("objective") is String else ""
	out.merge({"state": READY, "region": region, "region_name": place_name(region), "objective": objective,
		"play_time": _number(game.get("play_time"), 0.0), "lead_name": lead[0], "lead_level": lead[1],
		"saved_at": int(_number(data.get("saved_at"), 0.0)), "finished": flags.get("fin_vue", false) == true}, true)
	return out


## The slot remembered as the last one used (save_meta.json), 0 if none.
func remembered_slot() -> int:
	var file := dir.path_join(META_FILE)
	if not FileAccess.file_exists(file):
		return 0
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(file))
	var n := int(_number(data.get("slot"), 0.0)) if data is Dictionary else 0
	return n if _valid(n) else 0


## The save from before the slots (save.json in the slots' folder) becomes a slot: slot 1, or the
## first free one if slot 1 already holds another game. Copied, read back, then the old file is
## renamed save.json.migre (never deleted). Returns the slot it went to, 0 when there was nothing to
## do (or no room: then save.json stays as it is).
func migrate() -> int:
	var legacy := dir.path_join(LEGACY_FILE)
	if not FileAccess.file_exists(legacy):
		return 0
	var text := FileAccess.get_file_as_string(legacy)
	var target := 0
	var copied := false
	for n in range(1, SLOTS + 1):   # copied already (the renaming failed last time)
		if FileAccess.file_exists(path_for(n)) and FileAccess.get_file_as_string(path_for(n)) == text:
			target = n
			break
	if target == 0:
		copied = true
		for n in range(1, SLOTS + 1):
			if not FileAccess.file_exists(path_for(n)):
				target = n
				break
		if target == 0:
			push_warning("Ancienne sauvegarde gardée telle quelle : les %d emplacements sont pris" % SLOTS)
			return 0
		if not _write(path_for(target), text) or FileAccess.get_file_as_string(path_for(target)) != text:
			push_error("Migration de la sauvegarde impossible : %s reste en place" % legacy)
			return 0
	var kept := _free_name(legacy + LEGACY_KEPT)
	var err := DirAccess.rename_absolute(legacy, kept)
	if err != OK:
		push_warning("Ancienne sauvegarde copiée, mais pas renommée (%s)" % error_string(err))
	if copied or remembered_slot() == 0:   # (not at every start when save.json could not be renamed)
		path = path_for(target)
		_remember(target)
	return target


## A zone's name as the game writes it (« Prairie du Grand Crâne »).
static func place_name(region: String) -> String:
	if Game.OLD_ZONES.has(region):
		region = "plaines"
	var zone: Dictionary = DexPlaces.ZONES.get(StringName(region), {})
	return String(zone.get("name", region.capitalize()))


# ------------------------------------------------------------------ inside

func _valid(n: int) -> bool:
	return n >= 1 and n <= SLOTS


func _may_overwrite(n: int, confirmed: bool) -> bool:
	return confirmed or not FileAccess.file_exists(path_for(n))


## The main objective, for the slot screens. Worked out while a game runs only (Objectives reads the
## zones' scenes, already read by the quest tracker then); else the screens show the place.
func _summary() -> Dictionary:
	var objective := ""
	if enabled:
		for o: Dictionary in Objectives.current():
			if o["main"]:
				objective = String(o["title"])
				break
	return {"objective": objective}


## The dino in the lead of a saved game: [its name, its level].
static func _lead_of(game: Dictionary) -> Array:
	var party: Array = game["party"] if game.get("party") is Array else []
	if party.is_empty() or not party[0] is Dictionary:
		return ["", 0]
	var d: Dictionary = party[0]
	var shown := String(d.get("nickname", ""))
	var build: Dictionary = d["build"] if d.get("build") is Dictionary else {}
	var head := StringName(String(build.get("head", "")))
	if shown == "" and SpeciesDB.PATHS.has(head):
		shown = SpeciesDB.get_species(head).display_name
	return [shown, int(_number(d.get("level"), 1.0))]


## `value` if it is a number, else `default` (JSON gives floats; a damaged file, anything).
static func _number(value: Variant, default: float) -> float:
	return float(value) if value is int or value is float else default


func _remember(n: int) -> void:
	_write(dir.path_join(META_FILE), JSON.stringify({"slot": n}))


## A slot about to be overwritten or deleted: its file put aside (.ancienne, .ancienne2…: never one
## over another).
func _keep_old(n: int) -> void:
	var file := path_for(n)
	if FileAccess.file_exists(file):
		DirAccess.rename_absolute(file, _free_name(file + OLD_COPY))


## `base`, or base2, base3… the first name not taken.
static func _free_name(base: String) -> String:
	var candidate := base
	var i := 2
	while FileAccess.file_exists(candidate):
		candidate = base + str(i)
		i += 1
	return candidate


## Writes `text` to a temporary file, then renames it: a crash mid-write never leaves half a file.
func _write(file: String, text: String) -> bool:
	DirAccess.make_dir_recursive_absolute(file.get_base_dir())
	var out := FileAccess.open(file + ".tmp", FileAccess.WRITE)
	if out == null:
		push_error("Sauvegarde impossible (%s)" % error_string(FileAccess.get_open_error()))
		return false
	out.store_string(text)
	out.close()
	var err := DirAccess.rename_absolute(file + ".tmp", file)
	if err != OK:
		push_error("Sauvegarde : renommage impossible (%s)" % error_string(err))
		return false
	return true
