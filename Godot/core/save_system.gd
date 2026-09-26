extends Node
## Local save (user://, i.e. the app's private storage on Android, IndexedDB on the Web).
## Written to a temporary file then renamed, so a crash mid-write never corrupts the save.
## Saves automatically when the app goes to the background and every AUTOSAVE_S seconds.

signal saved

const PATH := "user://save.json"
const TMP_PATH := "user://save.json.tmp"
const VERSION := 1
const AUTOSAVE_S := 30.0

## Set by the world while a game is running; nothing is saved from the title screen.
var enabled := false
## Called before writing, so the world can store Chloé's position in Game.
var before_save: Callable

var _timer := 0.0


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


func has_save() -> bool:
	return FileAccess.file_exists(PATH)


func save_game() -> bool:
	_timer = 0.0
	if before_save.is_valid():
		before_save.call()
	var data := {"version": VERSION, "saved_at": int(Time.get_unix_time_from_system()), "game": Game.to_dict()}
	var file := FileAccess.open(TMP_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Sauvegarde impossible (%s)" % error_string(FileAccess.get_open_error()))
		return false
	file.store_string(JSON.stringify(data))
	file.close()
	var err := DirAccess.rename_absolute(TMP_PATH, PATH)
	if err != OK:
		push_error("Sauvegarde : renommage impossible (%s)" % error_string(err))
		return false
	saved.emit()
	return true


## Loads the save into Game. Returns false (and leaves Game untouched) if it is missing or unreadable.
func load_game() -> bool:
	if not has_save():
		return false
	var text := FileAccess.get_file_as_string(PATH)
	var data: Variant = JSON.parse_string(text)
	if not data is Dictionary or not data.has("game"):
		push_error("Sauvegarde illisible : %s" % PATH)
		return false
	if int(data.get("version", 0)) > VERSION:
		push_error("Sauvegarde d'une version plus récente du jeu")
		return false
	Game.from_dict(data["game"])
	return true


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(PATH)
