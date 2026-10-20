extends GdUnitTestSuite
## Les revanches dans la table « Carte des drapeaux, objets, événements » de docs/post-game-scenes.md (lignes R1 à R4,
## lues à chaque passage : le test suit le document), confrontées au code, sans fenêtre, comme
## tests/apex/histoire/test_table_ch9.gd : chaque drapeau sans gabarit est cité dans le code du lot (story/revanches.gd,
## data/dialogue_revanches.gd, battle/revanche_battles.gd, battle/apex_battles.gd, battle/apex_engine.gd) ; ceux à
## gabarit (`alpha_<id>_…`, `sceau_<region>_eveille`) sont ceux que le code construit, pour chacune des sept régions ;
## et chaque script du lot se compile (avec les autoloads).

const DOC := "res://docs/post-game-scenes.md"
const TABLE_TITLE := "## Carte des drapeaux, objets, événements"
const SCRIPTS := ["res://story/revanches.gd", "res://data/dialogue_revanches.gd", "res://battle/revanche_battles.gd",
	"res://battle/apex_battles.gd", "res://battle/apex_engine.gd"]

var _code := {}
var _rows: Array[Dictionary] = []


func before() -> void:
	for p: String in SCRIPTS:
		_code[p] = FileAccess.get_file_as_string(p)
	_rows = _read_table()


func test_chaque_script_du_lot_se_compile() -> void:
	for p: String in SCRIPTS:
		var script := load(p) as GDScript
		assert_object(script).override_failure_message("%s ne se charge pas" % p).is_not_null()
		if script:
			assert_bool(script.can_instantiate()).override_failure_message("%s ne compile pas" % p).is_true()


func test_les_quatre_lignes_r_se_lisent() -> void:
	var scenes: Array = _rows.map(func(r: Dictionary) -> String: return String(r["scene"]).get_slice(" ", 0))
	assert_array(scenes).is_equal(["R1", "R2", "R3", "R4"])


func test_drapeaux_cites_ou_construits() -> void:
	var nowhere: Array[String] = []
	for r in _rows:
		for f: String in r["flags"]:
			if f.contains("<"):
				for t in _built(f):
					if not t in _expected(f):
						nowhere.append(t)
				continue
			if not _code.values().any(func(text: String) -> bool: return text.contains("\"%s\"" % f)):
				nowhere.append(f)
	assert_array(nowhere).override_failure_message("drapeaux de la table absents du code : %s" % [nowhere]).is_empty()


## Ce que le code construit pour un gabarit, sur les sept régions.
static func _built(token: String) -> Array[String]:
	var out: Array[String] = []
	for id in RevancheBattles.ids():
		match token:
			"alpha_<id>_jour":
				out.append(String(Revanches.day_flag(id)))
			"alpha_<id>_reconnu":
				out.append(String(Revanches.known_flag(id)))
			"sceau_<region>_eveille":
				out.append(String(ApexEngine.woken_flag(RevancheBattles.ALPHAS[id]["sceau"])))
	return out


## Ce que dit la table pour ce gabarit, déplié sur les sept régions.
static func _expected(token: String) -> Array[String]:
	var out: Array[String] = []
	for id in RevancheBattles.ids():
		out.append(token.replace("<id>", String(id)).replace("<region>", String(id)))
	return out


func _read_table() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var text := FileAccess.get_file_as_string(DOC)
	var at := text.find(TABLE_TITLE)
	if at < 0:
		return out
	var tick := RegEx.create_from_string("`([a-z0-9_<>]+)`")
	var started := false
	for line in text.substr(at).split("\n").slice(1):
		if not line.begins_with("|"):
			if started:
				break
			continue
		started = true
		var cells := line.split("|")
		if cells.size() < 5 or not cells[1].strip_edges().begins_with("R"):
			continue
		var flags: Array[String] = []
		for m in tick.search_all(cells[2]):
			flags.append(m.get_string(1))
		out.append({"scene": cells[1].strip_edges(), "flags": flags})
	return out
