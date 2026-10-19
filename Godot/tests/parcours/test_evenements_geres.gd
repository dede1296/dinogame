extends GdUnitTestSuite
## Le parcours de sécurité, les événements (sans fenêtre, rien n'est joué) : chaque `event` posé sur un
## nœud des zones (toutes les scènes de regions/**, ouvertes sans être affichées : Npc, DinoNpc,
## StoryProp, StoryTrigger) est traité par Story.run, sans tomber sur « Scène inconnue ». Story.run
## essaie, dans l'ordre : son propre `match` (story/story.gd _run), puis Apex.run (story/apex.gd), puis
## Volcan.run (story/volcan.gd) ; les branches sont lues dans le code. Une branche d'Apex.run qui peut
## répondre « pas encore » (`return false` : Isaure à la porte avant l'aube, Brac et Léonce au port avant
## la fin) doit aussi exister dans Volcan.run.
## Et chaque `dialogue_id` d'un nœud sans événement (panneaux, pages, PNJ qui parlent seulement) a des
## répliques (DialogueDB.lines n'est pas vide).

const U := preload("res://tests/parcours/outils_parcours.gd")
const REGIONS := "res://regions"
## Les fonctions qui jouent les événements : [fichier, fonction], dans l'ordre où Story.run les essaie.
const STORY := ["res://story/story.gd", "_run"]
const APEX := ["res://story/apex.gd", "run"]
const VOLCAN := ["res://story/volcan.gd", "run"]
const SAVE_PATH := "user://test_gdunit_parcours_evenements.json"

var _saved_path: String
var _scenes: Array[String] = []


func before() -> void:
	_saved_path = Save.path
	Save.path = SAVE_PATH   # (jamais la partie de Greg)
	_scenes = _tscn(REGIONS)


func after() -> void:
	Save.path = _saved_path
	Game.new_game()


func before_test() -> void:
	Game.new_game()
	Game.give_starter(&"velociraptor")
	Game.set_flag(&"prologue_done")


# ------------------------------------------------------------------ les branches du code

## The labels of the `match` arms of function `fn` in `path`: label -> true when the arm may give up
## (`return false` inside it).
static func arms(path: String, fn: String) -> Dictionary:
	var out := {}
	var text := FileAccess.get_file_as_string(path)
	var lines := text.split("\n")
	var head := RegEx.create_from_string("^static func %s\\(" % fn)
	var arm := RegEx.create_from_string("^\\t\\t(&\"[a-z0-9_]+\"(?:\\s*,\\s*&\"[a-z0-9_]+\")*)\\s*:")
	var label := RegEx.create_from_string("&\"([a-z0-9_]+)\"")
	var inside := false
	var current: Array[String] = []
	for line in lines:
		if not inside:
			inside = head.search(line) != null
			continue
		if line != "" and not line.begins_with("\t"):
			break   # (the next function)
		var m := arm.search(line)
		if m:
			current.clear()
			for l in label.search_all(m.get_string(1)):
				current.append(l.get_string(1))
				out[l.get_string(1)] = false
			continue
		if line.begins_with("\t\t") and not line.begins_with("\t\t\t"):
			current.clear()   # (another statement at the arms' depth: `_:`…)
		if line.begins_with("\t\t\t") and line.strip_edges().begins_with("return false"):
			for l in current:
				out[l] = true
	return out


func test_les_branches_se_lisent() -> void:
	var story := arms(STORY[0], STORY[1])
	var apex := arms(APEX[0], APEX[1])
	var volcan := arms(VOLCAN[0], VOLCAN[1])
	prints("   branches : story.gd %d, apex.gd %d (dont %d « pas encore »), volcan.gd %d" % [story.size(), apex.size(),
		apex.values().count(true), volcan.size()])
	assert_int(story.size()).override_failure_message("story.gd _run : branches pas lues").is_greater(100)
	assert_int(apex.size()).override_failure_message("apex.gd run : branches pas lues").is_greater(10)
	assert_int(volcan.size()).override_failure_message("volcan.gd run : branches pas lues").is_greater(20)
	assert_bool(apex.get("isaure_porte", false)).override_failure_message("apex.gd : isaure_porte devrait être « pas encore » avant l'aube").is_true()
	assert_bool(story.has("roc") and story.has("grand_voyageur")).is_true()


# ------------------------------------------------------------------ les événements des zones

func test_chaque_evenement_des_zones_est_joue() -> void:
	var story := arms(STORY[0], STORY[1])
	var apex := arms(APEX[0], APEX[1])
	var volcan := arms(VOLCAN[0], VOLCAN[1])
	var unknown: Array[String] = []
	var count := 0
	for path in _scenes:
		var r := Region.open_for_preview(path)
		for n in U.nodes_with(r, "event"):
			count += 1
			var e := String(n.get("event"))
			var handled: bool = story.has(e) or (apex.has(e) and not apex[e]) or volcan.has(e)
			if not handled:
				var why := " (apex.gd peut dire « pas encore », volcan.gd ne le joue pas)" if apex.has(e) else ""
				unknown.append("%s : %s [%s] event=%s%s%s" % [path.trim_prefix(REGIONS + "/"), n.name, U.kind_of(n), e,
					_flags_of(n), why])
		r.free()
	prints("   %d zones, %d nœuds à événement" % [_scenes.size(), count])
	assert_int(count).override_failure_message("aucun événement lu dans regions/**").is_greater(100)
	assert_array(unknown).override_failure_message("« Scène inconnue » (%d) :\n%s" % [unknown.size(), "\n".join(unknown)]).is_empty()


func test_chaque_dialogue_des_zones_a_des_repliques() -> void:
	var empty: Array[String] = []
	var count := 0
	for path in _scenes:
		var r := Region.open_for_preview(path)
		for n in U.nodes_with(r, "dialogue_id"):
			if "event" in n and String(n.get("event")) != "":
				continue   # (the event plays instead)
			count += 1
			var id := StringName(n.get("dialogue_id"))
			if DialogueDB.lines(id).is_empty():
				empty.append("%s : %s [%s] dialogue_id=%s%s" % [path.trim_prefix(REGIONS + "/"), n.name, U.kind_of(n), id, _flags_of(n)])
		r.free()
	prints("   %d nœuds à dialogue" % count)
	assert_array(empty).override_failure_message("dialogues sans répliques (%d) :\n%s" % [empty.size(), "\n".join(empty)]).is_empty()


# ------------------------------------------------------------------ outils

static func _flags_of(n: Node) -> String:
	var bits: Array[String] = []
	for k: String in ["show_flag", "hide_flag", "required_flag", "once_flag"]:
		if k in n and String(n.get(k)) != "":
			bits.append("%s=%s" % [k, n.get(k)])
	return "" if bits.is_empty() else " (" + ", ".join(bits) + ")"


static func _tscn(dir_path: String) -> Array[String]:
	var out: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	for f in dir.get_files():
		if f.ends_with(".tscn"):
			out.append(dir_path.path_join(f))
	for d in dir.get_directories():
		out.append_array(_tscn(dir_path.path_join(d)))
	return out
