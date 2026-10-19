extends GdUnitTestSuite
## Le parcours de sécurité, la sauvegarde (sans fenêtre) : à la fin de chaque chapitre (6, 7, 8, 9), l'état
## d'un joueur arrivé là (tests/parcours/test_chaine_ch6_ch9.gd : drapeaux, objets, équipe, réserve,
## zone, position de Chloé, heure, carte explorée) est écrit par Save.save_game dans un fichier d'essai
## (user://test_gdunit_*, jamais la partie de Greg), la partie est effacée, puis Save.load_game la relit :
## - sans erreur (load_game vrai, Game.from_dict) ;
## - tout revient à l'identique (zone, position, drapeaux, objets, chaque dino, carte explorée) ;
## - la zone existe (world.gd ZONES : la partie rouvre là, pas au port), Chloé tient sur une case
##   praticable de sa carte ;
## - le même objectif principal revient, et Chloé, de là où elle est, l'atteint à pied (la chaîne :
##   tests/parcours/outils_parcours.gd) ; après la fin, la liste de l'après revient.

const U := preload("res://tests/parcours/outils_parcours.gd")
const CH := preload("res://tests/parcours/test_chaine_ch6_ch9.gd")
const SAVE_PATH := "user://test_gdunit_parcours_sauvegarde.json"
## Où Chloé se tient à la fin de chaque chapitre : [zone, nœud de la zone (elle est devant lui), à défaut
## une case].
const STANDS := {
	6: [&"monts", "MaiaMonts", Vector2(109.5, 14.0)],
	7: [&"arche_du_vent", "MasqueObsidienne", Vector2(27.0, 23.5)],
	8: [&"porte_cratere", "IsaurePorte", Vector2(25.0, 12.0)],
	9: [&"port_ambre", "", Vector2(19.5, 17.6)],
}

var _saved_path: String
var _before_save: Callable


func before() -> void:
	_saved_path = Save.path
	_before_save = Save.before_save
	Save.path = SAVE_PATH   # (jamais la partie de Greg)
	Save.before_save = Callable()


func after() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	Save.path = _saved_path
	Save.before_save = _before_save
	Game.new_game()
	U.free_all()


static func _stage_of(chapter: int) -> int:
	for i in CH.STAGES.size():
		if int(CH.STAGES[i].get("fin", 0)) == chapter:
			return i
	return -1


## The chapter's end, Chloé standing where it left her (in front of `node`), the clock and the map seen.
static func set_up(chapter: int) -> Vector2:
	CH.apply(_stage_of(chapter))
	var stand: Array = STANDS[chapter]
	var r := U.zone(stand[0])
	var at: Vector2 = stand[2] * U.TILE
	var n := r.entities.get_node_or_null(String(stand[1])) as Node2D if String(stand[1]) != "" else null
	if n:
		at = n.position + Vector2(0.0, 1.4 * U.TILE)
	Game.region_id = stand[0]
	Game.player_position = at
	Game.has_position = true
	Game.clock = 17.0 * 60.0 + chapter
	Game.day = 10 + chapter
	Game.weather = &"mist"
	Game.explore(stand[0], r.map_size(), at / U.TILE, 8.0)
	Game.set_flag(&"titan_n", 2)   # (a counter: a number, not true)
	return at


static func _plain(v: Variant) -> Variant:
	return JSON.parse_string(JSON.stringify(v))


static func _main_of() -> Dictionary:
	for o: Dictionary in Objectives.current():
		if o["main"]:
			return o
	return {}


func test_fin_du_chapitre_6() -> void:
	_round_trip(6)


func test_fin_du_chapitre_7() -> void:
	_round_trip(7)


func test_fin_du_chapitre_8() -> void:
	_round_trip(8)


func test_fin_du_chapitre_9() -> void:
	_round_trip(9)


func _round_trip(chapter: int) -> void:
	assert_int(_stage_of(chapter)).override_failure_message("pas d'étape « fin » %d dans la chaîne" % chapter).is_greater_equal(0)
	var at := set_up(chapter)
	var want := {"region": Game.region_id, "flags": _plain(Game.flags), "items": _plain(Game.items),
		"party": _plain(Game.party.map(func(d: Dino) -> Dictionary: return d.to_dict())),
		"box": _plain(Game.box.map(func(d: Dino) -> Dictionary: return d.to_dict())),
		"explored": Game.explored_mask(Game.region_id, U.zone(Game.region_id).map_size()), "clock": Game.clock, "day": Game.day,
		"main": _main_of(), "all": Objectives.current().size()}
	assert_bool(Save.save_game()).override_failure_message("ch. %d : Save.save_game a échoué" % chapter).is_true()
	assert_bool(FileAccess.file_exists(SAVE_PATH)).is_true()
	Game.new_game()
	assert_bool(Game.flag(&"prologue_done")).is_false()
	assert_bool(Save.load_game()).override_failure_message("ch. %d : Save.load_game a échoué" % chapter).is_true()
	# Everything back.
	assert_str(String(Game.region_id)).override_failure_message("ch. %d : zone" % chapter).is_equal(String(want["region"]))
	assert_bool(Game.has_position).is_true()
	assert_vector(Game.player_position).override_failure_message("ch. %d : position" % chapter).is_equal_approx(at, Vector2(0.5, 0.5))
	assert_dict(_plain(Game.flags)).override_failure_message("ch. %d : drapeaux" % chapter).is_equal(want["flags"])
	assert_dict(_plain(Game.items)).override_failure_message("ch. %d : objets" % chapter).is_equal(want["items"])
	assert_array(_plain(Game.party.map(func(d: Dino) -> Dictionary: return d.to_dict()))).override_failure_message("ch. %d : équipe" % chapter).is_equal(want["party"])
	assert_array(_plain(Game.box.map(func(d: Dino) -> Dictionary: return d.to_dict()))).override_failure_message("ch. %d : réserve" % chapter).is_equal(want["box"])
	assert_bool(Game.explored_mask(Game.region_id, U.zone(Game.region_id).map_size()) == want["explored"]).override_failure_message("ch. %d : carte explorée" % chapter).is_true()
	assert_float(Game.clock).is_equal_approx(want["clock"], 0.01)
	assert_int(Game.day).is_equal(want["day"])
	assert_str(String(Game.weather)).is_equal("mist")
	assert_str(String(Game.starter_dino().nickname if Game.starter_dino() else "")).override_failure_message("ch. %d : le dino de départ perdu" % chapter).is_equal("Vif")
	# The zone reopens where she was, on her feet.
	assert_bool(U.paths().has(Game.region_id)).override_failure_message("ch. %d : zone %s inconnue de world.gd (retour au port)" % [chapter, Game.region_id]).is_true()
	var r := U.zone(Game.region_id)
	var tile := U.tile_of(Game.player_position)
	assert_bool(Rect2i(Vector2i.ZERO, r.map_size()).has_point(tile)).override_failure_message("ch. %d : Chloé hors de la carte (%s)" % [chapter, tile]).is_true()
	var data := r.terrain.get_cell_tile_data(tile)
	var ground := String(data.get_custom_data("terrain")) if data else ""
	assert_bool(ground in U.ZB.WALKABLE).override_failure_message("ch. %d : Chloé sur « %s » en %s" % [chapter, ground, tile]).is_true()
	# The same objective, reached on foot from there.
	var main := _main_of()
	var expected: Dictionary = want["main"]
	if expected.is_empty():
		assert_dict(main).override_failure_message("ch. %d : un objectif principal après la fin" % chapter).is_empty()
		assert_int(Objectives.current().size()).override_failure_message("ch. %d : la liste de l'après a disparu" % chapter).is_equal(want["all"])
		assert_int(Objectives.current().size()).is_greater(0)
	else:
		assert_str(String(main.get("id", ""))).override_failure_message("ch. %d : objectif après rechargement" % chapter).is_equal(String(expected["id"]))
		var walked := U.walk_island(Game.region_id, tile)
		var why := U.objective_reached(walked, main)
		assert_str(why).override_failure_message("ch. %d : « %s » : %s (depuis la position sauvée %s)" % [chapter, main.get("id"), why, tile]).is_empty()
	prints("   ch. %d : %s %s, %d drapeaux, %d dinos (+%d au Cabinet), objectif « %s »" % [chapter, Game.region_id, tile, Game.flags.size(),
		Game.party.size(), Game.box.size(), main.get("id", "(l'après)")])
