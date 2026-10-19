extends GdUnitTestSuite
## Le chapitre 9 : la table « Carte des drapeaux, objets, événements » de docs/chapitre-9-scenes.md (lue
## à chaque passage : le test suit le document) confrontée au code des scènes, sans fenêtre ; et chaque
## script des scènes se compile (avec les autoloads, ce que « --check-only » ne sait pas faire).
## - chaque drapeau et chaque objet de la table est cité dans le code des scènes (story/apex*.gd,
##   story/epilogue.gd, data/dialogue_apex.gd) ou, à défaut, ailleurs dans le code du jeu (listé) ;
## - chaque objet de la table existe dans ItemsDB.
## Les écarts sont des résultats : ce test ne corrige rien.

const DOC := "res://docs/chapitre-9-scenes.md"
const TABLE_TITLE := "## Carte des drapeaux, objets, événements"
const SCRIPTS := ["res://story/apex.gd", "res://story/apex_aube.gd", "res://story/apex_coeur.gd", "res://story/apex_helene.gd",
	"res://story/apex_autour.gd", "res://story/apex_objectives.gd", "res://story/apex_jetee.gd", "res://story/epilogue.gd",
	"res://data/dialogue_apex.gd"]
const CODE_DIRS := ["res://core", "res://data", "res://actors", "res://world", "res://battle", "res://story", "res://ui", "res://game"]

var _scenes := {}
var _code := {}
var _rows: Array[Dictionary] = []


func before() -> void:
	for p: String in SCRIPTS:
		if FileAccess.file_exists(p):
			_scenes[p] = FileAccess.get_file_as_string(p)
	for p: String in _gd_files(CODE_DIRS):
		_code[p] = FileAccess.get_file_as_string(p)
	_rows = _read_table()


func test_chaque_script_des_scenes_se_compile() -> void:
	for p: String in SCRIPTS:
		var script := load(p) as GDScript
		assert_object(script).override_failure_message("%s ne se charge pas" % p).is_not_null()
		if script:
			assert_bool(script.can_instantiate()).override_failure_message("%s ne compile pas" % p).is_true()


func test_la_table_se_lit() -> void:
	assert_int(_rows.size()).override_failure_message("table lue : %d lignes" % _rows.size()).is_greater_equal(9)


func test_drapeaux_de_la_table_cites_dans_le_code() -> void:
	var elsewhere: Array[String] = []
	var nowhere: Array[String] = []
	for r in _rows:
		for f: String in r["flags"]:
			for t in _expand(f):
				if _cited(t, _scenes):
					continue
				var files := _where(t, _code)
				if files.is_empty():
					nowhere.append(t)
				else:
					elsewhere.append("%s (%s)" % [t, ", ".join(files)])
	if not elsewhere.is_empty():
		prints("   drapeaux hors des scènes du ch. 9 : %s" % "; ".join(elsewhere))
	assert_array(nowhere).override_failure_message("drapeaux de la table cités nulle part : %s" % [nowhere]).is_empty()


func test_objets_de_la_table_dans_items_db_et_le_code() -> void:
	var unknown: Array[String] = []
	var nowhere: Array[String] = []
	for r in _rows:
		for it: String in r["items"]:
			for t in _expand(it):
				if not ItemsDB.ITEMS.has(t):
					unknown.append(t)
				if not _cited(t, _scenes) and _where(t, _code).is_empty():
					nowhere.append(t)
	assert_array(unknown).override_failure_message("objets absents d'ItemsDB : %s" % [unknown]).is_empty()
	assert_array(nowhere).override_failure_message("objets cités nulle part : %s" % [nowhere]).is_empty()


# ------------------------------------------------------------------ outils

## A token of the table → the tokens to look for (one, today: the ranges are unfolded when read).
static func _expand(token: String) -> Array[String]:
	var out: Array[String] = [token]
	return out


func _cited(token: String, texts: Dictionary) -> bool:
	return not _where(token, texts).is_empty()


func _where(token: String, texts: Dictionary) -> Array:
	var quoted := "\"%s\"" % token
	return texts.keys().filter(func(p: String) -> bool: return (texts[p] as String).contains(quoted)).map(func(p: String) -> String: return p.trim_prefix("res://"))


## Les lignes de la table : les jetons `…` des colonnes drapeaux et objets (les plages « a à b » et
## « coeur_1 à coeur_4 » dépliées ; les parenthèses ignorées).
func _read_table() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var text := FileAccess.get_file_as_string(DOC)
	var at := text.find(TABLE_TITLE)
	if at < 0:
		return out
	var tick := RegEx.create_from_string("`([a-z0-9_]+)`")
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
		var row := {"scene": cells[1].strip_edges(), "flags": _ticks(tick, cells[2]), "items": _items(tick, cells[3])}
		out.append(row)
	return out


static func _ticks(tick: RegEx, cell: String) -> Array[String]:
	var out: Array[String] = []
	for m in tick.search_all(cell):
		var t := m.get_string(1)
		if not t in out:
			out.append(t)
	return out


## Les objets : les jetons, avec « coeur_1 à coeur_4 » déplié (coeur_1, …, coeur_4).
static func _items(tick: RegEx, cell: String) -> Array[String]:
	var out: Array[String] = []
	var range_re := RegEx.create_from_string("`coeur_(\\d)` à `coeur_(\\d)`")
	for m in range_re.search_all(cell):
		for i in range(int(m.get_string(1)), int(m.get_string(2)) + 1):
			if not "coeur_%d" % i in out:
				out.append("coeur_%d" % i)
	for t in _ticks(tick, cell):
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
