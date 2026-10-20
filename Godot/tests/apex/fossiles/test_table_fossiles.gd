extends GdUnitTestSuite
## Les fossiles légendaires : les lignes « F » de la table « Carte des drapeaux, objets, événements » de
## docs/post-game-scenes.md (lue à chaque passage : le test suit le document) confrontées au code du lot B
## (story/fossiles.gd, data/dialogue_fossiles.gd, world/os_enfoui.gd), sans fenêtre ; et chaque script se
## compile. Les jetons à motif de la table (`os_titanosaure_1..5`, `helene_os_<squelette>`,
## `ressuscite_<id>`) sont dépliés : une plage donne ses cinq drapeaux, un motif son format (« %s »).
## Les objets doivent aussi être dans ItemsDB (patch_B.md).

const DOC := "res://docs/post-game-scenes.md"
const TABLE_TITLE := "## Carte des drapeaux, objets, événements"
const SCRIPTS := ["res://story/fossiles.gd", "res://data/dialogue_fossiles.gd", "res://world/os_enfoui.gd", "res://ui/dex_entry.gd",
	"res://tools/zones/os_legendaires.gd"]

var _code := ""
var _rows: Array[Dictionary] = []


func before() -> void:
	for p: String in SCRIPTS:
		_code += FileAccess.get_file_as_string(p) + "\n"
	_rows = _read_table()


func test_chaque_script_se_compile() -> void:
	for p: String in SCRIPTS:
		var script := load(p) as GDScript
		assert_object(script).override_failure_message("%s ne se charge pas" % p).is_not_null()
		if script and p.ends_with("os_legendaires.gd"):
			continue   # (a tool: not a scene's script)
		if script:
			assert_bool(script.can_instantiate()).override_failure_message("%s ne compile pas" % p).is_true()


func test_les_cinq_lignes_f_se_lisent() -> void:
	assert_array(_rows.map(func(r: Dictionary) -> String: return String(r["scene"]).left(2))).contains_exactly(["F1", "F2", "F3", "F4", "F5"])


func test_drapeaux_des_lignes_f_dans_le_code() -> void:
	var nowhere: Array[String] = []
	for r in _rows:
		for t: String in r["flags"]:
			for want in _expand(t):
				if not _code.contains(want):
					nowhere.append("%s (%s)" % [want, r["scene"]])
	assert_array(nowhere).override_failure_message("drapeaux absents du code : %s" % [nowhere]).is_empty()


func test_objets_des_lignes_f_dans_items_db_et_le_code() -> void:
	var missing: Array[String] = []
	for r in _rows:
		for t: String in r["items"]:
			if not ItemsDB.ITEMS.has(t):
				missing.append(t + " (ItemsDB, patch_B.md)")
			if not (_code.contains("\"%s\"" % t) or (t.begins_with("os_") and _code.contains("\"os_%s\""))):
				missing.append(t + " (code)")
	assert_array(missing).override_failure_message("objets : %s" % [missing]).is_empty()


# ------------------------------------------------------------------ outils

## `os_titanosaure_1..5` → its five quoted flags; `helene_os_<squelette>` → `"helene_os_%s"`; else quoted.
static func _expand(token: String) -> Array[String]:
	var out: Array[String] = []
	if token.ends_with("_1..5"):
		var stem := token.trim_suffix("1..5")
		for i in range(1, 6):
			out.append("\"%s%d\"" % [stem, i])
	elif token.contains("<"):
		out.append("\"%s\"" % RegEx.create_from_string("<[a-z_]+>").sub(token, "%s", true))
	else:
		out.append("\"%s\"" % token)
	return out


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
		if cells.size() < 5 or not cells[1].strip_edges().begins_with("F"):
			continue
		out.append({"scene": cells[1].strip_edges(), "flags": _ticks(tick, cells[2]), "items": _ticks(tick, cells[3]).filter(
			func(t: String) -> bool: return t.begins_with("os_") or t.begins_with("carnet"))})
	return out


static func _ticks(tick: RegEx, cell: String) -> Array[String]:
	var out: Array[String] = []
	for m in tick.search_all(cell):
		var t := m.get_string(1)
		if not t in out:
			out.append(t)
	return out
