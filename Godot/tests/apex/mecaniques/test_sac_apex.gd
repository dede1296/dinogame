extends GdUnitTestSuite
## Ce qui entre et sort du sac et de l'équipe au chapitre 9 (ApexBag), sans fenêtre : les Cœurs rendus puis posés
## dans la porte (les drapeaux restent), le dino de départ à Lien 5, Moustique rendu à Maïa (de l'équipe ou de la
## réserve, jamais en laissant Chloé seule), le masque, les moufles, la lettre, l'insigne. (Le réveil des géants du
## post-game : story/apex_geants.gd, tests/apex/geants/.)

const SAVE_PATH := "user://test_gdunit_apex_sac_save.json"

var _saved_path: String


func before() -> void:
	_saved_path = Save.path
	Save.path = SAVE_PATH   # (jamais la partie de Greg)


func after() -> void:
	Save.path = _saved_path
	Game.new_game()


func before_test() -> void:
	Game.new_game()
	Game.set_flag(&"prologue_done")
	Game.give_starter(&"velociraptor")


func test_les_coeurs_rendus_puis_poses_dans_la_porte() -> void:
	Game.give_item("coeur_5")
	for n in range(1, 6):
		Game.set_flag(StringName("coeur_%d" % n))
	assert_int(ApexBag.return_hearts()).is_equal(4)
	for n in range(1, 6):
		assert_int(Game.item_count("coeur_%d" % n)).override_failure_message("coeur_%d pas dans le sac" % n).is_equal(1)
	assert_int(ApexBag.return_hearts()).override_failure_message("des Cœurs en double").is_equal(0)
	ApexBag.hearts_in_door()
	for n in range(1, 6):
		assert_int(Game.item_count("coeur_%d" % n)).override_failure_message("coeur_%d encore dans le sac" % n).is_equal(0)
		assert_bool(Game.flag(StringName("coeur_%d" % n))).override_failure_message("le drapeau coeur_%d est tombé" % n).is_true()


func test_le_dino_de_depart_a_lien_5() -> void:
	var vif := Game.starter_dino()
	assert_int(vif.bond).is_equal(1)
	assert_int(ApexBag.starter_full_bond()).is_equal(4)
	assert_int(vif.bond).is_equal(Dino.MAX_BOND)
	assert_int(ApexBag.starter_full_bond()).override_failure_message("des cœurs au-delà de 5").is_equal(0)


func test_moustique_rendu_a_maia() -> void:
	Game.add_caught(Dino.create(&"dimorphodon", 36, "Moustique"))
	assert_int(Game.party.size()).is_equal(2)
	assert_bool(ApexBag.moustique_leaves()).is_true()
	assert_int(Game.party.size()).is_equal(1)
	assert_object(ApexBag.moustique()).is_null()
	assert_bool(ApexBag.moustique_leaves()).override_failure_message("Moustique part deux fois").is_false()
	# À la réserve (équipe pleine) : il part aussi.
	for k in 4:
		Game.add_caught(Dino.create(&"compsognathus", 20))
	Game.add_caught(Dino.create(&"dimorphodon", 36, "Moustique"))
	assert_int(Game.box.size()).is_equal(1)
	assert_bool(ApexBag.moustique_leaves()).is_true()
	assert_int(Game.box.size()).is_equal(0)
	assert_int(Game.party.size()).is_equal(5)
	# Un autre Dimorphodon, capturé, reste.
	Game.add_caught(Dino.create(&"dimorphodon", 30))
	assert_bool(ApexBag.moustique_leaves()).is_false()


func test_masque_moufles_lettre_insigne() -> void:
	for id in ["masque_carton", "moufles_helene", "lettre_isaure"]:
		Game.give_item(id)
		assert_int(ApexBag.take(id)).is_equal(1)
		assert_int(Game.item_count(id)).is_equal(0)
		assert_int(ApexBag.take(id)).is_equal(0)
	ApexBag.give_insigne()
	ApexBag.give_insigne()
	assert_int(Game.item_count("insigne_gardienne")).override_failure_message("deux insignes").is_equal(1)
