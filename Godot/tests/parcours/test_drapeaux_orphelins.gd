extends GdUnitTestSuite
## Le parcours de sécurité, les drapeaux orphelins (sans fenêtre, le code et les scènes lus comme du
## texte) : chaque drapeau dont la progression dépend doit être POSÉ par une scène ou un événement qui
## existe, sinon la porte, l'objectif ou le personnage qui l'attend attendrait pour toujours.
## Les drapeaux attendus :
## - le `required_flag` de chaque sortie (ZoneExit) et de chaque déclencheur (StoryTrigger) de regions/** ;
## - chaque drapeau que lisent les objectifs (story/objectives.gd et story/*_objectives.gd : Game.flag(&"…")) ;
## - le `show_flag` de chaque nœud de l'histoire (un événement, une page) des zones des chapitres 6 à 9, du
##   port, du Cabinet et du Havre (sinon il n'apparaît jamais) ;
## - chaque drapeau que les étapes du parcours (tests/parcours/test_chaine_ch6_ch9.gd) donnent au joueur.
## Les poseurs : dans le code du jeu, Game.set_flag(&"x") / set_flag("x"), une réplique {"flag": &"x"},
## Game.flags["x"] = …, une constante qui vaut "x" passée à set_flag ou à « flag », un nom calculé
## (set_flag(StringName("forge_%d_eteinte" % n))) ; dans les scènes, le `taken_flag` d'une page ramassée
## et le `cleared_flag` d'un obstacle dégagé (ils le posent eux-mêmes).
## Un drapeau qui n'a AUCUN poseur fait échouer le test. Un drapeau cité ailleurs dans le code sans être
## posé de façon reconnue (une table, une variable) est listé « à vérifier » dans la sortie, sans échec.

const U := preload("res://tests/parcours/outils_parcours.gd")
const CH := preload("res://tests/parcours/test_chaine_ch6_ch9.gd")
const REGIONS := "res://regions"
## Le code du jeu (hors tests/, tools/, addons/, world3d/).
const CODE_DIRS := ["res://core", "res://data", "res://actors", "res://world", "res://battle", "res://story", "res://ui", "res://game"]
const OBJECTIVE_FILES := "res://story"
## Les zones dont les nœuds de l'histoire doivent pouvoir apparaître.
## Les portes fermées exprès, pour toujours (un décor qui dit « pas par là ») : drapeau -> [zone, sortie,
## pourquoi]. Chacune doit ramener dans sa propre zone (elle ne mène nulle part ailleurs) : vérifié.
const SEALED := {
	"gardien_eveille": [&"antre_crane", "VersAntreCrane", "le tunnel du gardien, au fond de l'Antre du Grand Crâne : « Le gardien dort. Mieux vaut ne pas le déranger. »"],
}
const SHOWN_ZONES := [&"monts", &"grottes_glace", &"sanctuaire_givre", &"cieux", &"nids_geants", &"arche_du_vent", &"champs_cendres",
	&"forges_ombre", &"coulees_lave", &"sanctuaire_magma", &"porte_cratere", &"terre_apex", &"coeur_apex", &"port_ambre", &"cabinet",
	&"havre_dore", &"cote"]

var _code := {}          # path -> text
var _setters := {}       # flag -> Array[String] (where)
var _dynamic: Array = [] # [RegEx, where]
var _consts := {}        # NAME -> Array[String] (values)


func before() -> void:
	for path in _files(CODE_DIRS, ".gd"):
		_code[path] = FileAccess.get_file_as_string(path)
	_read_consts()
	_read_setters()


func after() -> void:
	U.free_all()


# ------------------------------------------------------------------ the setters

func _read_consts() -> void:
	var re := RegEx.create_from_string("(?m)^\\s*(?:static\\s+)?const\\s+([A-Z][A-Z0-9_]*)\\s*(?::\\s*\\w+\\s*)?:?=\\s*(?:&|StringName\\()?\"([a-z0-9_]+)\"")
	for path: String in _code:
		for m in re.search_all(_code[path]):
			if not _consts.has(m.get_string(1)):
				_consts[m.get_string(1)] = []
			(_consts[m.get_string(1)] as Array).append(m.get_string(2))


func _read_setters() -> void:
	var literal := RegEx.create_from_string("(?:set_flag\\(\\s*|\"flag\"\\s*:\\s*|flags\\[\\s*)(?:&|StringName\\()?\"([a-z0-9_]+)\"")
	var named := RegEx.create_from_string("(?:set_flag\\(\\s*|\"flag\"\\s*:\\s*)(?:[A-Za-z_][A-Za-z0-9_]*\\.)*([A-Z][A-Z0-9_]*)\\s*[,)}\\]]")
	var computed := RegEx.create_from_string("(?:set_flag\\(\\s*|\"flag\"\\s*:\\s*)StringName\\(\"([^\"]*%[^\"]*)\"")
	# (a name computed into a local variable, then set: `var flag := StringName("temple_vanne_%d" % n)`)
	var local := RegEx.create_from_string("var\\s+(\\w+)\\s*:?=\\s*StringName\\(\"([^\"]*%[^\"]*)\"")
	for path: String in _code:
		var text: String = _code[path]
		var where := path.trim_prefix("res://")
		for m in literal.search_all(text):
			_add(m.get_string(1), where)
		for m in named.search_all(text):
			for v: String in _consts.get(m.get_string(1), []):
				_add(v, "%s (%s)" % [where, m.get_string(1)])
		for m in computed.search_all(text):
			_dynamic.append([_pattern(m.get_string(1)), "%s (« %s »)" % [where, m.get_string(1)]])
		for m in local.search_all(text):
			var used := RegEx.create_from_string("(?:set_flag\\(\\s*|\"flag\"\\s*:\\s*)%s\\s*[,)}]" % m.get_string(1))
			if used.search(text):
				_dynamic.append([_pattern(m.get_string(2)), "%s (« %s »)" % [where, m.get_string(2)]])
	# In the scenes: a page picked up sets its taken_flag, an obstacle cleared its cleared_flag.
	var scene_re := RegEx.create_from_string("(?m)^(taken_flag|cleared_flag) = &\"([a-z0-9_]+)\"")
	for path in _files([REGIONS], ".tscn"):
		for m in scene_re.search_all(FileAccess.get_file_as_string(path)):
			_add(m.get_string(2), "%s (%s)" % [path.trim_prefix(REGIONS + "/"), m.get_string(1)])


func _add(flag: String, where: String) -> void:
	if not _setters.has(flag):
		_setters[flag] = []
	if not where in _setters[flag]:
		(_setters[flag] as Array).append(where)


static func _pattern(format: String) -> RegEx:
	var re := format.replace("%d", "\u0001").replace("%s", "\u0002")
	re = re.replace(".", "\\.")
	re = re.replace("\u0001", "[0-9]+").replace("\u0002", "[a-z0-9_]+")
	return RegEx.create_from_string("^" + re + "$")


## Who sets `flag`: the recognised setters, else a computed name that matches; [] when none.
func setters_of(flag: String) -> Array:
	var out: Array = _setters.get(flag, []).duplicate()
	for d: Array in _dynamic:
		if (d[0] as RegEx).search(flag):
			out.append(d[1])
	return out


## Where `flag` is quoted in the game's code other than read (`flag(&"x")`): a table, a variable…
func elsewhere(flag: String) -> Array:
	var out: Array = []
	var quoted := RegEx.create_from_string("(?<!flag\\()(?<!flag\\(&)&?\"%s\"" % flag)
	for path: String in _code:
		if quoted.search(_code[path]):
			out.append(path.trim_prefix("res://"))
	return out


# ------------------------------------------------------------------ what waits for a flag

## flag -> Array[String] (who waits for it).
func wanted() -> Dictionary:
	var out := {}
	var put := func(flag: String, who: String) -> void:
		if flag == "":
			return
		if not out.has(flag):
			out[flag] = []
		(out[flag] as Array).append(who)
	# The exits and triggers of every zone.
	for path in _files([REGIONS], ".tscn"):
		var r := Region.open_for_preview(path)
		var zone := path.get_file().get_basename()
		for n in r.find_children("*", "", true, false):
			if n is ZoneExit:
				put.call(String((n as ZoneExit).required_flag), "sortie %s/%s" % [zone, n.name])
			elif n is StoryTrigger:
				put.call(String((n as StoryTrigger).required_flag), "déclencheur %s/%s" % [zone, n.name])
		if StringName(zone) in SHOWN_ZONES:
			for n in r.entities.find_children("*", "", true, false):
				var story: bool = ("event" in n and String(n.get("event")) != "") or (n is Pickup and String(n.get("dialogue_id")) != "")
				if story and "show_flag" in n:
					put.call(String(n.get("show_flag")), "apparition %s/%s" % [zone, n.name])
		r.free()
	# The objectives' reads.
	var read := RegEx.create_from_string("flag\\(&\"([a-z0-9_]+)\"\\)")
	for path in _files([OBJECTIVE_FILES], ".gd"):
		if not path.get_file().ends_with("objectives.gd"):
			continue
		for m in read.search_all(FileAccess.get_file_as_string(path)):
			put.call(m.get_string(1), "objectif %s" % path.get_file())
	# The safety walk's stages.
	for f: StringName in CH.BASE:
		put.call(String(f), "parcours (fin du ch. 5)")
	for s: Dictionary in CH.STAGES:
		for f: StringName in s.get("plus", []):
			put.call(String(f), "parcours « %s »" % s["nom"])
	return out


func test_les_poseurs_se_lisent() -> void:
	assert_int(_setters.size()).override_failure_message("poseurs de drapeaux pas lus").is_greater(300)
	assert_bool(not setters_of("forge_2_eteinte").is_empty()).override_failure_message("un nom calculé (forge_%d_eteinte) pas reconnu").is_true()
	assert_bool(not setters_of("harnais_vol").is_empty()).override_failure_message("une constante (HARNESS_FLAG) pas reconnue").is_true()
	assert_bool(not setters_of("found_journal_36").is_empty()).override_failure_message("une page ramassée (taken_flag) pas reconnue").is_true()
	assert_bool(not setters_of("mur_glace_1_brise").is_empty()).override_failure_message("un obstacle dégagé (cleared_flag) pas reconnu").is_true()
	assert_bool(setters_of("drapeau_que_personne_ne_pose").is_empty()).is_true()
	prints("   %d drapeaux posés en clair, %d noms calculés, %d constantes" % [_setters.size(), _dynamic.size(), _consts.size()])


func test_aucun_drapeau_attendu_sans_poseur() -> void:
	var waiting := wanted()
	var orphans: Array[String] = []
	var to_check: Array[String] = []
	for flag: String in waiting:
		if not setters_of(flag).is_empty() or SEALED.has(flag):
			continue
		var who: Array = waiting[flag]
		var seen := elsewhere(flag)
		var line := "%s ← attendu par %s" % [flag, ", ".join(who.slice(0, 4)) + (" (+%d)" % (who.size() - 4) if who.size() > 4 else "")]
		if seen.is_empty():
			orphans.append(line)
		else:
			to_check.append("%s ; cité dans %s" % [line, ", ".join(seen)])
	prints("   %d drapeaux attendus ; sans poseur reconnu mais cités ailleurs (à vérifier) : %d" % [waiting.size(), to_check.size()])
	for l in to_check:
		prints("     à vérifier : " + l)
	assert_array(orphans).override_failure_message("drapeaux attendus que rien ne pose (%d) :\n%s" % [orphans.size(), "\n".join(orphans)]).is_empty()


## The doors closed for good lead back into their own zone (nothing lies behind them), and nothing sets
## their flag (else they would not be sealed).
func test_portes_scellees_expres() -> void:
	for flag: String in SEALED:
		var s: Array = SEALED[flag]
		var e := U.exit_named(U.zone(s[0]), s[1])
		assert_object(e).override_failure_message("%s/%s n'existe plus" % [s[0], s[1]]).is_not_null()
		if e == null:
			continue
		assert_str(String(e.required_flag)).is_equal(flag)
		assert_str(String(e.target_zone)).override_failure_message("%s/%s, fermée exprès, mène à %s : ce n'est plus un décor" % [s[0], s[1], e.target_zone]).is_equal(String(s[0]))
		assert_array(setters_of(flag)).override_failure_message("%s est posé quelque part : %s" % [flag, setters_of(flag)]).is_empty()
		prints("   fermée exprès : %s/%s (%s) — %s" % [s[0], s[1], flag, s[2]])


# ------------------------------------------------------------------ outils

static func _files(dirs: Array, ext: String) -> Array[String]:
	var out: Array[String] = []
	for d: String in dirs:
		var dir := DirAccess.open(d)
		if dir == null:
			continue
		for f in dir.get_files():
			if f.ends_with(ext):
				out.append(d.path_join(f))
		out.append_array(_files(Array(dir.get_directories()).map(func(s: String) -> String: return d.path_join(s)), ext))
	return out
