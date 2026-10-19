extends GdUnitTestSuite
## Ce qui entre et sort du sac et de l'équipe au chapitre 9 (ApexBag), et le réveil des géants au post-game
## (ApexGiants), sans fenêtre : les Cœurs rendus puis posés dans la porte (les drapeaux restent), le dino de départ à
## Lien 5, Moustique rendu à Maïa (de l'équipe ou de la réserve, jamais en laissant Chloé seule), le masque, les
## moufles, la lettre, l'insigne ; les géants, un à un, un jour à la fois.

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


func test_les_geants_se_reveillent_un_a_un() -> void:
	assert_int(ApexGiants.current()).override_failure_message("un géant se réveille avant la fin").is_equal(0)
	assert_bool(ApexGiants.sit(1)["ok"]).is_false()
	Game.set_flag(&"post_game")
	assert_int(ApexGiants.current()).is_equal(1)
	assert_str(String(ApexGiants.state(2))).override_failure_message("le 2e attend avant le 1er").is_equal(String(ApexGiants.ASLEEP))
	assert_bool(ApexGiants.sit(2)["ok"]).is_false()
	var vif := Game.lead_dino()
	var points := vif.bond_points
	for day in ApexGiants.SITS_TO_WAKE:
		Game.day = 10 + day
		var r := ApexGiants.sit(1)
		assert_bool(r["ok"]).override_failure_message("jour %d : Chloé ne s'assoit pas" % day).is_true()
		assert_bool(ApexGiants.sit(1)["ok"]).override_failure_message("deux fois le même jour").is_false()
		assert_bool(r["woke"]).is_equal(day == ApexGiants.SITS_TO_WAKE - 1)
	assert_bool(ApexGiants.awake(1)).is_true()
	assert_bool(vif.bond > 1 or vif.bond_points > points).override_failure_message("le Lien ne monte pas à côté du géant").is_true()
	assert_int(ApexGiants.current()).is_equal(2)
	assert_str(String(ApexGiants.state(1))).is_equal(String(ApexGiants.AWAKE))
	for n in range(2, ApexGiants.COUNT + 1):
		for day in ApexGiants.SITS_TO_WAKE:
			Game.day += 1
			ApexGiants.sit(n)
	assert_int(ApexGiants.awake_count()).is_equal(ApexGiants.COUNT)
	assert_int(ApexGiants.current()).is_equal(0)
