extends GdUnitTestSuite
## Le chapitre 8 : la table « Carte des drapeaux, objets, événements » de docs/chapitre-8-scenes.md
## (lue à chaque passage : le test suit le document) confrontée au code et aux zones, sans fenêtre.
## - chaque drapeau, objet, événement de la table est référencé dans le code : d'abord dans
##   story/volcan*.gd et story/story.gd ; trouvé seulement ailleurs (data/dialogue_volcan.gd,
##   actors/lava.gd…), il est accepté mais listé ; trouvé nulle part : un écart ;
## - chaque nœud cité (la table, et les scènes : `PierrePlate`, les Pickup des pages) existe dans la
##   Entities de sa zone (regions/volcan/*.tscn, ouverte sans être affichée), et son `event` est traité ;
## - chaque nœud que le code des scènes cherche par son nom (V.at_node, V.actor_of, S.actor) existe
##   dans une des zones de son fichier (sinon la scène joue à une position de repli).
## Les écarts sont des résultats : ce test ne corrige rien.

const DOC := "res://docs/chapitre-8-scenes.md"
const TABLE_TITLE := "## Carte des drapeaux, objets, événements"
## Les lignes de la table → la zone de leurs nœuds ("" : pas de nœud de zone).
const ROW_ZONES := {
	"Descente de Cendre": "", "Arrivée aux champs": "champs_cendres", "Premier corrompu": "champs_cendres",
	"Arrivée aux forges": "forges_ombre", "Les trois petites forges": "forges_ombre", "Brac": "forges_ombre",
	"Dame Suie": "forges_ombre", "Coulées": "coulees_lave", "Sanctuaire": "sanctuaire_magma", "Porte": "porte_cratere",
	"Autour": "",
}
## Les nœuds que les scènes citent hors de la table (§ 2 bis : « Prop examinable `PierrePlate` »).
const SCENE_NODES := {"PierrePlate": "champs_cendres"}
## Les pages trouvées (Pickup) : § 7 c (la 36), § 8 e (la 35), § 9 b (la 38), avec leur drapeau.
const PAGES := {"page_36": "coulees_lave", "page_35": "sanctuaire_magma", "page_38": "porte_cratere"}
const ZONES := ["champs_cendres", "forges_ombre", "coulees_lave", "sanctuaire_magma", "porte_cratere"]
## Les fichiers des scènes → les zones où leurs nœuds sont cherchés (volcan_autour.gd : hors du volcan).
const FILE_ZONES := {
	"volcan.gd": ["champs_cendres"], "volcan_forges.gd": ["forges_ombre"], "volcan_suie.gd": ["forges_ombre"],
	"volcan_sanctuaire.gd": ["coulees_lave", "sanctuaire_magma"], "volcan_porte.gd": ["porte_cratere"],
	"volcan_places.gd": ZONES,
}
## Le code du jeu (hors tests/, tools/, addons/).
const CODE_DIRS := ["res://core", "res://data", "res://actors", "res://world", "res://battle", "res://story", "res://ui", "res://game"]
const NODE_FLAGS := ["hide_flag", "show_flag", "after_flag", "once_flag", "taken_flag"]

var _rows: Array[Dictionary] = []      # {scene, zone, flags, items, events, nodes, pickups}
var _story := {}                       # chemin -> texte (story/volcan*.gd, story/story.gd)
var _code := {}                        # chemin -> texte (tout le code du jeu)
var _zones := {}                       # zone -> Region (ouverte, pas affichée)


func before() -> void:
	_rows = _read_table()
	for path: String in _gd_files(["res://story"]):
		if path.get_file().begins_with("volcan") or path.get_file() == "story.gd":
			_story[path] = FileAccess.get_file_as_string(path)
	for path: String in _gd_files(CODE_DIRS):
		_code[path] = FileAccess.get_file_as_string(path)
	for zone: String in ZONES:
		var path := "res://regions/volcan/%s.tscn" % zone
		if ResourceLoader.exists(path):
			_zones[zone] = Region.open_for_preview(path)


func after() -> void:
	for r: Node in _zones.values():
		r.free()
	_zones.clear()


# ------------------------------------------------------------------ la table

func test_la_table_du_document_se_lit() -> void:
	assert_int(_rows.size()).override_failure_message("table « Carte des drapeaux » : %d lignes lues" % _rows.size()).is_greater_equal(10)
	var unknown := _rows.filter(func(r: Dictionary) -> bool: return not ROW_ZONES.has(r["scene"])).map(func(r: Dictionary) -> String: return r["scene"])
	assert_array(unknown).override_failure_message("lignes de la table sans zone connue (à ajouter à ROW_ZONES) : %s" % [unknown]).is_empty()
	assert_int(_story.size()).override_failure_message("story/volcan*.gd introuvables").is_greater(1)
	var count := func(key: String) -> int: return _rows.reduce(func(n: int, r: Dictionary) -> int: return n + (r[key] as Array).size(), 0)
	prints("   table : %d lignes, %d drapeaux, %d objets, %d événements, %d nœuds, %d Pickup ; %d fichiers de scènes, %d du code" % [
		_rows.size(), count.call("flags"), count.call("items"), count.call("events"), count.call("nodes"), count.call("pickups"),
		_story.size(), _code.size()])


# ------------------------------------------------------------------ drapeaux, objets, événements → le code

func test_drapeaux_references_dans_le_code() -> void:
	var tokens: Array[String] = []
	for r in _rows:
		tokens.append_array(r["flags"])
	_assert_referenced("drapeaux", tokens)


func test_objets_references_et_dans_items_db() -> void:
	var tokens: Array[String] = []
	for r in _rows:
		tokens.append_array(r["items"])
	assert_array(tokens).override_failure_message("aucun objet lu dans la table").is_not_empty()
	var unknown := tokens.filter(func(t: String) -> bool: return not ItemsDB.ITEMS.has(t))
	assert_array(unknown).override_failure_message("objets de la table absents d'ItemsDB : %s" % [unknown]).is_empty()
	_assert_referenced("objets", tokens)


func test_evenements_references_dans_le_code() -> void:
	var tokens: Array[String] = []
	for r in _rows:
		tokens.append_array(r["events"])
		tokens.append_array(r["pickups"])
	_assert_referenced("événements", tokens)


# ------------------------------------------------------------------ nœuds → les zones

func test_noeuds_de_la_table_et_des_scenes_dans_leur_zone() -> void:
	var cited := {}   # nœud -> zone
	for r in _rows:
		for n: String in r["nodes"]:
			cited[n] = r["zone"]
	cited.merge(SCENE_NODES)
	assert_int(cited.size()).override_failure_message("aucun nœud lu dans la table").is_greater(10)
	var missing: Array[String] = []
	var unhandled: Array[String] = []
	var flags_nowhere: Array[String] = []
	for n: String in cited:
		var zone: String = cited[n]
		var node := _node(zone, n)
		if node == null:
			missing.append("%s (%s)" % [n, zone if zone != "" else "sans zone"])
			continue
		var event := String(node.get("event")) if "event" in node else ""
		if event != "" and _where(event, _story).is_empty():
			unhandled.append("%s.event = %s" % [n, event])
		for key: String in NODE_FLAGS:
			var f := String(node.get(key)) if key in node else ""
			if f != "" and _where(f, _code).is_empty():
				flags_nowhere.append("%s.%s = %s" % [n, key, f])
	assert_array(missing).override_failure_message("nœuds cités absents de leur zone : %s" % [missing]).is_empty()
	assert_array(unhandled).override_failure_message("événements de nœuds que les scènes ne traitent pas : %s" % [unhandled]).is_empty()
	assert_array(flags_nowhere).override_failure_message("drapeaux de nœuds que le code ne pose ni ne lit : %s" % [flags_nowhere]).is_empty()


func test_pages_ramassees_dans_leur_zone() -> void:
	var gaps: Array[String] = []
	for page: String in PAGES:
		var zone: String = PAGES[page]
		var found: Node = null
		if _zones.has(zone):
			for n in (_zones[zone] as Region).entities.get_children():
				if "dialogue_id" in n and String(n.get("dialogue_id")) == page:
					found = n
		if found == null:
			gaps.append("%s : pas de Pickup dans %s" % [page, zone])
			continue
		var want := "found_journal_%s" % page.get_slice("_", 1)
		if String(found.get("taken_flag")) != want:
			gaps.append("%s (%s) : taken_flag %s au lieu de %s" % [page, found.name, found.get("taken_flag"), want])
	assert_array(gaps).override_failure_message("pages : %s" % [gaps]).is_empty()


func test_noeuds_cherches_par_le_code_des_scenes() -> void:
	var lookup := RegEx.create_from_string("(?:at_node|actor_of)\\(\\[([^\\]]*)\\](\\s*\\+)?|S\\.actor\\(\"([^\"]+)\"\\)")
	var name_re := RegEx.create_from_string("\"([^\"]+)\"")
	var checked := 0
	var missing: Array[String] = []
	for path: String in _story:
		var file := path.get_file()
		if not FILE_ZONES.has(file):
			continue
		var text: String = _story[path]
		for m in lookup.search_all(text):
			if m.get_string(2) != "":
				continue   # (une liste prolongée par une constante : TREX_NODES…)
			var names: Array[String] = []
			if m.get_string(3) != "":
				names.append(m.get_string(3))
			for q in name_re.search_all(m.get_string(1)):
				names.append(q.get_string(1))
			if names.is_empty():
				continue   # (un nom calculé)
			checked += 1
			var zones: Array = FILE_ZONES[file]
			if not names.any(func(n: String) -> bool: return zones.any(func(z: String) -> bool: return _node(z, n) != null)):
				var line := text.substr(0, m.get_start()).count("\n") + 1
				missing.append("%s:%d %s (cherché dans %s)" % [file, line, names, ", ".join(zones)])
	assert_int(checked).override_failure_message("aucune recherche de nœud lue dans story/volcan*.gd").is_greater(10)
	assert_array(missing).override_failure_message("nœuds cherchés par les scènes, absents de leur zone (repli sur une position calculée) : %s" % [missing]).is_empty()


# ------------------------------------------------------------------ outils

## Chaque jeton doit être cité entre guillemets ("x" ou &"x") dans le code ; d'abord les scènes.
func _assert_referenced(what: String, tokens: Array[String]) -> void:
	assert_array(tokens).override_failure_message("aucun jeton « %s » lu dans la table" % what).is_not_empty()
	var elsewhere: Array[String] = []
	var nowhere: Array[String] = []
	for t in tokens:
		if not _where(t, _story).is_empty():
			continue
		var files := _where(t, _code)
		if files.is_empty():
			nowhere.append(t)
		else:
			elsewhere.append("%s (%s)" % [t, ", ".join(files.map(func(p: String) -> String: return p.trim_prefix("res://")))])
	if not elsewhere.is_empty():
		prints("   %s hors de story/volcan*.gd et story.gd : %s" % [what, "; ".join(elsewhere)])
	assert_array(nowhere).override_failure_message("%s de la table référencés nulle part dans le code : %s" % [what, nowhere]).is_empty()


func _where(token: String, texts: Dictionary) -> Array:
	var quoted := "\"%s\"" % token
	return texts.keys().filter(func(p: String) -> bool: return (texts[p] as String).contains(quoted))


func _node(zone: String, node_name: String) -> Node:
	if not _zones.has(zone):
		return null
	return (_zones[zone] as Region).entities.get_node_or_null(node_name)


## Les lignes de la table : les jetons `…` de chaque colonne, rangés (drapeaux, objets, événements en
## minuscules, nœuds en majuscule, Pickup).
func _read_table() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var text := FileAccess.get_file_as_string(DOC)
	var at := text.find(TABLE_TITLE)
	if at < 0:
		return out
	var tick := RegEx.create_from_string("`([^`]+)`")
	var pickup := RegEx.create_from_string("Pickup\\s+`([^`]+)`")
	var range_re := RegEx.create_from_string("^([A-Za-z]+?)(\\d+)\\.\\.(\\d+)$")
	var started := false
	for line in text.substr(at).split("\n").slice(1):
		if not line.begins_with("|"):
			if started:
				break
			continue
		started = true
		var cells := line.split("|")
		if cells.size() < 6 or cells[1].strip_edges() in ["Scène", ""] or cells[1].begins_with("---"):
			continue
		var scene := cells[1].strip_edges()
		var row := {"scene": scene, "zone": ROW_ZONES.get(scene, ""), "flags": _ticks(tick, cells[2]), "items": _ticks(tick, cells[3]),
			"events": [] as Array[String], "nodes": [] as Array[String], "pickups": [] as Array[String]}
		var pickups := pickup.search_all(cells[4]).map(func(m: RegExMatch) -> String: return m.get_string(1))
		for t in _ticks(tick, cells[4]):
			if t in pickups:
				(row["pickups"] as Array[String]).append(t)
			elif t.substr(0, 1) == t.substr(0, 1).to_upper() and t.substr(0, 1) != t.substr(0, 1).to_lower():
				var m := range_re.search(t)
				if m:
					for i in range(int(m.get_string(2)), int(m.get_string(3)) + 1):
						(row["nodes"] as Array[String]).append("%s%d" % [m.get_string(1), i])
				else:
					(row["nodes"] as Array[String]).append(t)
			else:
				(row["events"] as Array[String]).append(t)
		out.append(row)
	return out


static func _ticks(tick: RegEx, cell: String) -> Array[String]:
	var out: Array[String] = []
	for m in tick.search_all(cell):
		var t := m.get_string(1)
		if not t in out:
			out.append(t)
	return out


static func _gd_files(dirs: Array) -> Array[String]:
	var out: Array[String] = []
	for d: String in dirs:
		var dir := DirAccess.open(d)
		if dir == null:
			continue
		for f in dir.get_files():
			if f.ends_with(".gd"):
				out.append(d.path_join(f))
		out.append_array(_gd_files(Array(dir.get_directories()).map(func(s: String) -> String: return d.path_join(s))))
	return out
