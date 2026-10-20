extends GdUnitTestSuite
## La voleuse de boussole (story/plaines_annexes.gd, docs/histoire.md « La chapardeuse »), sans fenêtre. Avant :
## seule la Maïa du carrefour volait et reprenait sa boussole ; elle s'en va avec le Sceau des Plaines, et une
## boussole trouvée ensuite ne pouvait plus être rendue (« Rendre la boussole à Maïa, au carrefour » pour
## toujours), un vol jamais vu ne pouvait plus arriver. Maintenant : la boussole se rend à Maïa où elle est
## (au pied du Crâne, au Havre) et l'objectif dit où ; au pied du Crâne, si Chloé ne lui avait jamais parlé,
## le vol arrive là (la zone et Chipie sont nécessaires : sans elle, rien ne se joue).

const SAVE_PATH := "user://test_gdunit_scenes_boussole.json"
const MAX_FRAMES := 900

var _saved_path: String


func before() -> void:
	_saved_path = Save.path
	Save.path = SAVE_PATH   # (jamais la partie de Greg)


func after() -> void:
	Dialogue.abort()
	Save.path = _saved_path
	Game.new_game()


func before_test() -> void:
	Game.new_game()
	Game.give_starter(&"velociraptor")
	Game.set_flag(&"prologue_done")
	Dialogue.skip_lines = false
	Dialogue.abort()
	Scenes.reset()
	Scenes.forget_stale()


func _objective(id: String) -> String:
	for o: Dictionary in Objectives.current():
		if o.get("id", "") == id:
			return String(o.get("text", ""))
	return ""


func _close_dialogues() -> void:
	for i in MAX_FRAMES:
		if not Dialogue.active and Dialogue.pending() == 0:
			return
		Dialogue.advance()
		await get_tree().process_frame


func test_l_objectif_dit_ou_est_maia() -> void:
	Game.set_flag(&"met_maia")
	Game.set_flag(&"boussole_volee")
	Game.set_flag(&"boussole_trouvee")
	assert_str(_objective("boussole")).contains("au carrefour")
	Game.set_flag(&"sceau_plaines")
	assert_str(_objective("boussole")).contains("au pied du Grand Crâne")
	Game.set_flag(&"maia_defi_1")
	assert_str(_objective("boussole")).contains("au Havre")
	Game.set_flag(&"boussole_rendue")
	assert_str(_objective("boussole")).is_empty()


func test_la_boussole_se_rend_a_maia_au_havre() -> void:
	for f in [&"met_maia", &"boussole_volee", &"boussole_trouvee", &"sceau_plaines", &"maia_defi_1"]:
		Game.set_flag(f)
	var maia := Node2D.new()
	add_child(auto_free(maia))
	var colliers := Game.item_count("collier")
	var got := {}
	(func() -> void: got["joue"] = await PlainesAnnexes.maia_elsewhere(maia, false)).call()
	assert_bool(Dialogue.active).override_failure_message("Maïa au Havre ne reprend pas sa boussole").is_true()
	await _close_dialogues()
	assert_bool(got.get("joue", false)).is_true()
	assert_bool(Game.flag(&"boussole_rendue")).is_true()
	assert_int(Game.item_count("collier")).is_equal(colliers + 3)
	# Une seule fois : ensuite, Maïa parle d'autre chose.
	var again: bool = await PlainesAnnexes.maia_elsewhere(maia, false)
	assert_bool(again).is_false()


func test_sans_chipie_dans_la_zone_pas_de_vol_ailleurs() -> void:
	Game.set_flag(&"sceau_plaines")
	var maia := Node2D.new()
	add_child(auto_free(maia))
	var played: bool = await PlainesAnnexes.maia_elsewhere(maia)
	assert_bool(played).is_false()
	assert_bool(Game.flag(&"boussole_volee")).is_false()
