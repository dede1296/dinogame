extends GdUnitTestSuite
## Le post-game : la table « Carte des drapeaux, objets, événements » de docs/post-game-scenes.md (lue à chaque
## passage : le test suit le document) confrontée au code, sans fenêtre, comme tests/apex/histoire/test_table_ch9.gd.
## - les lignes des géants (G…) : chaque drapeau cité dans le code (`geant_<n>_…` déplié en 1 à 4), chaque objet
##   dans ItemsDB (sauté tant que le correctif d'ItemsDB de patch_A.md n'est pas appliqué) ;
## - les autres lignes (F, R, N, B : lots B, C, D, E) : ce qui manque est AFFICHÉ, pas compté (le chef d'équipe
##   passe une lettre dans STRICT quand son lot est intégré) ;
## - les scripts des géants se compilent (avec les autoloads).
## Les écarts sont des résultats : ce test ne corrige rien.

const DOC := "res://docs/post-game-scenes.md"
const TABLE_TITLE := "## Carte des drapeaux, objets, événements"
## Les lignes vérifiées strictement : leur première lettre (G : les géants, lot A).
const STRICT := ["G"]
const SCRIPTS := ["res://story/apex_geants.gd", "res://story/apex_geants_reveil.gd", "res://data/dialogue_geants.gd"]
const CODE_DIRS := ["res://core", "res://data", "res://actors", "res://world", "res://battle", "res://story", "res://ui", "res://game"]

var _code := {}
var _rows: Array[Dictionary] = []


func before() -> void:
	for p: String in _gd_files(CODE_DIRS):
		_code[p] = FileAccess.get_file_as_string(p)
	_rows = _read_table()


static func _patched_items() -> bool:
	return ItemsDB.ITEMS.has("plume_helene")


func test_les_scripts_des_geants_se_compilent() -> void:
	for p: String in SCRIPTS:
		var script := load(p) as GDScript
		assert_object(script).override_failure_message("%s ne se charge pas" % p).is_not_null()
		if script:
			assert_bool(script.can_instantiate()).override_failure_message("%s ne compile pas" % p).is_true()


func test_la_table_se_lit() -> void:
	assert_int(_rows.size()).override_failure_message("table lue : %d lignes" % _rows.size()).is_greater_equal(15)
	assert_int(_rows.filter(func(r: Dictionary) -> bool: return _strict(r)).size()).is_equal(5)


func test_drapeaux_des_geants_cites_dans_le_code() -> void:
	var nowhere: Array[String] = []
	for r in _rows:
		if not _strict(r):
			continue
		for f: String in r["flags"]:
			for t in _expand(f):
				if _where(t, _code).is_empty():
					nowhere.append(t)
	assert_array(nowhere).override_failure_message("drapeaux de la table cités nulle part : %s" % [nowhere]).is_empty()


func test_objets_des_geants_dans_items_db(_do_skip := not _patched_items(), _skip_reason := "correctif ItemsDB (plume_helene) de patch_A.md pas encore appliqué") -> void:
	var unknown: Array[String] = []
	for r in _rows:
		if not _strict(r):
			continue
		for it: String in r["items"]:
			for t in _expand(it):
				if not ItemsDB.ITEMS.has(t):
					unknown.append(t)
	assert_array(unknown).override_failure_message("objets absents d'ItemsDB : %s" % [unknown]).is_empty()


func test_les_autres_lots_affiches() -> void:
	var missing: Array[String] = []
	for r in _rows:
		if _strict(r):
			continue
		for f: String in r["flags"] + r["items"]:
			for t in _expand(f):
				if _where(t, _code).is_empty() and not ItemsDB.ITEMS.has(t):
					missing.append("%s (%s)" % [t, String(r["scene"]).get_slice(" ", 0)])
	if not missing.is_empty():
		prints("   post-game, pas encore dans le code (autres lots) : %s" % ", ".join(missing))
	assert_bool(true).is_true()


# ------------------------------------------------------------------ outils

static func _strict(r: Dictionary) -> bool:
	return STRICT.any(func(letter: String) -> bool: return String(r["scene"]).begins_with(letter))


## A token of the table → the tokens to look for: `geant_<n>_x` → geant_1_x … geant_4_x ; `os_x_1..5` →
## os_x_1 … os_x_5 ; others as they are.
static func _expand(token: String) -> Array[String]:
	var out: Array[String] = []
	if token.contains("<n>"):
		for n in range(1, 5):
			out.append(token.replace("<n>", str(n)))
		return out
	var range_re := RegEx.create_from_string("^(.*_)(\\d+)\\.\\.(\\d+)$")
	var m := range_re.search(token)
	if m:
		for i in range(int(m.get_string(2)), int(m.get_string(3)) + 1):
			out.append("%s%d" % [m.get_string(1), i])
		return out
	out.append(token)
	return out


func _where(token: String, texts: Dictionary) -> Array:
	var quoted := "\"%s\"" % token
	return texts.keys().filter(func(p: String) -> bool: return (texts[p] as String).contains(quoted))


## The table's rows: the `…` tokens of the flags and items columns.
func _read_table() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var text := FileAccess.get_file_as_string(DOC)
	var at := text.find(TABLE_TITLE)
	if at < 0:
		return out
	var tick := RegEx.create_from_string("`([a-z0-9_<>.]+)`")
	var started := false
	for line in text.substr(at).split("\n").slice(1):
		if not line.begins_with("|"):
			if started:
				break
			continue
		started = true
		var cells := line.split("|")
		if cells.size() < 5 or cells[1].strip_edges() in ["Scène", ""] or cells[1].begins_with("---"):
			continue
		out.append({"scene": cells[1].strip_edges(), "flags": _ticks(tick, cells[2]), "items": _ticks(tick, cells[3])})
	return out


static func _ticks(tick: RegEx, cell: String) -> Array[String]:
	var out: Array[String] = []
	for m in tick.search_all(cell):
		var t := m.get_string(1)
		if not t in out and not t.ends_with("."):
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
