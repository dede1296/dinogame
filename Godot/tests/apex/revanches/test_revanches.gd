extends GdUnitTestSuite
## Les revanches du post-game (docs/post-game-plan.md § 3, post-game-scenes.md R2 à R4), sans fenêtre : la table des
## Alphas (sept, niveaux 50 à 53 dans l'ordre de l'île, ni capture ni fuite, la musique des Alphas, « lose_spawn »,
## jamais « K.O. », leur Sceau jamais contre eux ; le Roi des Cieux et le Souverain absents), une revanche par Alpha et
## par jour, la première victoire éveille le Sceau (une fois), les pièces à chaque victoire ; le pari d'Isaure (son
## équipe sans hésiter, une fois par jour, la page de la mer à la première victoire, des pièces ensuite) ; Hélène
## (une fois, dès le premier Sceau) ; l'objectif ; les répliques qui ont du sens (le dino en tête nommé).

const SAVE_PATH := "user://test_gdunit_revanches_save.json"
const ORDER: Array[StringName] = [&"plaines", &"foret", &"marais", &"desert", &"cote", &"monts", &"volcan"]
## Les « lose_spawn » des chapitres, pour vérifier que la table les suit (constantes des scènes).
const SPAWNS := {&"marais": "MaraisTemple.TEMPLE_SPAWN", &"desert": "DesertPlaces.LOSE_BRAC", &"cote": "CotePlaces.LOSE_RECIF",
	&"monts": "MontsPlaces.SPAWN_SANCTUAIRE_DEPUIS_MONTS", &"volcan": "VolcanPlaces.SPAWN_COULEES"}

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
	Game.set_flag(&"post_game")
	Game.day = 5


# ------------------------------------------------------------------ la table

func test_sept_alphas_dans_l_ordre_de_l_ile_niveaux_50_a_53() -> void:
	assert_array(RevancheBattles.ids()).is_equal(ORDER)
	var last := 0
	for id in ORDER:
		var a: Dictionary = RevancheBattles.ALPHAS[id]
		assert_int(int(a["level"])).override_failure_message("%s : niveau %d" % [id, a["level"]]).is_between(50, 53)
		assert_int(int(a["level"])).override_failure_message("%s : plus bas que l'Alpha d'avant" % id).is_greater_equal(last)
		last = a["level"]
		assert_bool(SpeciesDB.PATHS.has(a["species"])).override_failure_message("%s : espèce %s inconnue" % [id, a["species"]]).is_true()
		assert_bool(ApexEngine.libre(a["sceau"]).is_empty()).override_failure_message("%s : Sceau %s sans effet" % [id, a["sceau"]]).is_false()
		assert_int(int(a["coins"])).is_between(60, 90)
	assert_int(RevancheBattles.ALPHAS[&"plaines"]["level"]).is_equal(50)
	assert_int(RevancheBattles.ALPHAS[&"volcan"]["level"]).is_equal(53)


func test_ni_le_roi_des_cieux_ni_le_souverain() -> void:
	for a: Dictionary in RevancheBattles.ALPHAS.values():
		assert_str(String(a["species"])).is_not_equal("quetzalcoatlus_roi")
		assert_str(String(a["species"])).is_not_equal("souverain")
		assert_str(String(a["sceau"])).is_not_equal("sceau_cieux")
	for s: Dictionary in ApexEngine.LIBRES:
		assert_str(String(s["id"])).is_not_equal("sceau_cieux")
	assert_bool(RevancheBattles.ALPHAS.has(&"cieux")).is_false()
	assert_object(RevancheBattles.alpha(&"cieux")).is_null()


func test_regles_d_un_alpha() -> void:
	for id in ORDER:
		var a: Dictionary = RevancheBattles.ALPHAS[id]
		var rules := RevancheBattles.alpha_rules(id)
		assert_bool(rules["catch"] or rules["run"]).override_failure_message("%s : collier ou fuite" % id).is_false()
		assert_str(String(rules["foe_faint"])).override_failure_message("%s : « K.O. »" % id).is_equal("Il s'arrête. Il a vu.")
		assert_str(String(rules["alpha"])).is_equal(a["sceau"])
		assert_bool(rules["music"] is AudioStream).override_failure_message("%s : pas la musique des Alphas" % id).is_true()
		assert_str(String(rules["intro"])).contains("pour voir")
		var foe := RevancheBattles.alpha(id)
		assert_bool(foe.corrupted).override_failure_message("%s : corrompu" % id).is_false()
		assert_int(foe.level).is_equal(a["level"])
		assert_str(foe.nickname).is_equal(a["title"])
	var mosa := RevancheBattles.alpha_rules(&"cote")
	assert_bool(mosa.get("underwater", false) and mosa.get("abyss", false)).override_failure_message("Minuit : sous l'eau, l'abîme").is_true()
	for id in [&"marais", &"monts", &"volcan"]:
		assert_bool(RevancheBattles.alpha_rules(id).has("underwater")).override_failure_message("%s : sous l'eau ?" % id).is_false()


func test_lose_spawn_comme_aux_chapitres() -> void:
	var want := {&"marais": MaraisTemple.TEMPLE_SPAWN, &"desert": DesertPlaces.LOSE_BRAC, &"cote": CotePlaces.LOSE_RECIF,
		&"monts": MontsPlaces.SPAWN_SANCTUAIRE_DEPUIS_MONTS, &"volcan": VolcanPlaces.SPAWN_COULEES}
	for id: StringName in want:
		assert_str(String(RevancheBattles.ALPHAS[id]["lose_spawn"])).override_failure_message("%s : %s ≠ %s (%s)" % [
			id, RevancheBattles.ALPHAS[id]["lose_spawn"], want[id], SPAWNS[id]]).is_equal(String(want[id]))
	assert_str(String(RevancheBattles.ALPHAS[&"plaines"]["lose_spawn"])).is_equal("Crane")
	assert_bool(RevancheBattles.ALPHAS[&"foret"].has("lose_spawn")).override_failure_message("la Forêt : l'entrée de la zone").is_false()


# ------------------------------------------------------------------ une fois par jour, les récompenses

func test_une_revanche_par_alpha_et_par_jour() -> void:
	for id in ORDER:
		assert_bool(Revanches.can_challenge(id)).is_true()
	Game.set_flag(Revanches.day_flag(&"plaines"), Game.day)
	assert_bool(Revanches.can_challenge(&"plaines")).override_failure_message("deux fois le même jour").is_false()
	assert_bool(Revanches.can_challenge(&"foret")).override_failure_message("un Alpha bloque l'autre").is_true()
	Game.day += 1
	assert_bool(Revanches.can_challenge(&"plaines")).override_failure_message("le lendemain").is_true()
	assert_str(String(Revanches.day_flag(&"plaines"))).is_equal("alpha_plaines_jour")


func test_rien_avant_le_post_game() -> void:
	Game.set_flag(&"post_game", false)
	for id in ORDER:
		assert_bool(Revanches.can_challenge(id)).is_false()
	assert_bool(Revanches.maia_can() or Revanches.isaure_can()).is_false()
	assert_bool(Revanches.can_challenge(&"cieux")).is_false()


func test_premiere_victoire_eveille_le_sceau_une_fois_et_des_pieces_a_chaque_fois() -> void:
	var coins := Game.item_count("piece")
	var won := Revanches.record_win(&"desert")
	assert_bool(won["first"]).is_true()
	assert_int(won["coins"]).is_equal(70)
	assert_bool(ApexEngine.woken("sceau_desert")).is_true()
	assert_bool(Game.flag(&"alpha_desert_reconnu")).is_true()
	assert_bool(Game.flag(&"sceau_desert_eveille")).is_true()
	assert_int(Game.item_count("piece")).is_equal(coins + 70)
	var again := Revanches.record_win(&"desert")
	assert_bool(again["first"]).override_failure_message("le Sceau s'éveille deux fois").is_false()
	assert_int(Game.item_count("piece")).is_equal(coins + 140)
	assert_int(Revanches.woken_count()).is_equal(1)
	assert_bool(ApexEngine.woken("sceau_volcan")).is_false()


func test_l_objectif_compte_les_sceaux() -> void:
	assert_str(Revanches.objective_text()).contains("aucun Sceau éveillé")
	Revanches.record_win(&"plaines")
	assert_str(Revanches.objective_text()).contains("1 Sceau éveillé sur 7")
	Revanches.record_win(&"volcan")
	assert_str(Revanches.objective_text()).contains("2 Sceaux éveillés sur 7")
	assert_str(Revanches.objective_text()).contains("Maïa au Grand Crâne")
	assert_str(Revanches.objective_text()).contains("Isaure")


# ------------------------------------------------------------------ le pari d'Isaure

func test_l_equipe_du_pari_d_isaure() -> void:
	var team := RevancheBattles.isaure_team()
	assert_int(team.size()).is_equal(4)
	var names: Array = team.map(func(m: Array) -> String: return m[2])
	assert_array(names).is_equal(["Hauban", "Bouline", "Étrave", "Carène"])
	var levels: Array = team.map(func(m: Array) -> int: return m[1])
	assert_array(levels).is_equal([50, 50, 51, 52])
	for m: Array in team:
		var opts: Dictionary = m[3] if m.size() > 3 else {}
		assert_bool(opts.get("corrupted", false)).is_false()
	var rules := RevancheBattles.isaure_rules()
	assert_bool(rules.has("hesitates")).override_failure_message("Carène hésite encore").is_false()
	assert_object(rules["music"]).override_failure_message("une musique (le vent, la mer)").is_null()
	assert_str(String(rules["lose_spawn"])).is_equal("Embarcadere")


func test_le_pari_une_fois_par_jour_la_page_de_la_mer_puis_des_pieces() -> void:
	assert_bool(Revanches.isaure_can()).is_true()
	Game.set_flag(&"isaure_pari_jour", Game.day)
	assert_bool(Revanches.isaure_can()).is_false()
	var lost := Revanches.isaure_record(false)
	assert_bool(Game.flag(&"isaure_pari_gagne")).override_failure_message("perdu : la page quand même").is_false()
	assert_int(lost["coins"]).is_equal(0)
	var coins := Game.item_count("piece")
	var first := Revanches.isaure_record(true)
	assert_bool(first["first"]).is_true()
	assert_bool(Game.flag(&"isaure_pari_gagne") and Game.flag(&"carnet_mer")).is_true()
	assert_int(Game.item_count("piece")).override_failure_message("la page, pas de pièces").is_equal(coins)
	var again := Revanches.isaure_record(true)
	assert_bool(again["first"]).is_false()
	assert_int(Game.item_count("piece")).is_equal(coins + RevancheBattles.ISAURE_COINS)


func test_isaure_ne_cite_sirocco_que_si_elle_a_donne_la_terre() -> void:
	var before := _texts(DialogueRevanches.isaure_won_first(false))
	var after_land := _texts(DialogueRevanches.isaure_won_first(true))
	assert_str(before).contains("te donnera la terre")
	assert_str(before).not_contains("t'a donné")
	assert_str(after_land).contains("t'a donné la terre")
	assert_str(after_land).contains("La mer, c'est moi.")


# ------------------------------------------------------------------ Hélène, les répliques

func test_helene_les_sceaux_une_fois_des_le_premier() -> void:
	assert_str(Revanches.helene_line()).override_failure_message("avant tout Sceau éveillé").is_empty()
	Revanches.record_win(&"foret")
	assert_str(Revanches.helene_line()).contains("une fois par jour")
	assert_bool(Game.flag(&"helene_sceaux")).is_true()
	assert_str(Revanches.helene_line()).override_failure_message("deux fois").is_empty()


func test_les_repliques_des_alphas() -> void:
	for id in ORDER:
		var arrival := DialogueRevanches.arrival(id, "Vif")
		assert_int(arrival.size()).is_equal(2)
		for k in ["arrival", "after"]:
			var line := DialogueRevanches.alpha_line(id, k, "Vif")
			assert_str(line).override_failure_message("%s : %s vide" % [id, k]).is_not_empty()
			assert_str(line).not_contains("%s")
			assert_str(line).not_contains("K.O.")
		assert_str(DialogueRevanches.woken_toast(id)).contains("Sceau")
	assert_str(DialogueRevanches.alpha_line(&"cote", "arrival", "Nessie")).contains("Nessie")
	assert_str(DialogueRevanches.alpha_line(&"volcan", "after", "")).contains("son dino")
	assert_str(DialogueRevanches.ALPHA_TODAY % "Piment").not_contains("recouche")
	assert_str(DialogueRevanches.alpha_line(&"desert", "after", "")).not_contains("porte du sanctuaire")
	assert_str(DialogueRevanches.alpha_line(&"volcan", "arrival", "")).not_contains("sort de la faille")


func test_aucune_scene_trop_longue_mots_courants() -> void:
	var blocks := [DialogueRevanches.maia_before(), DialogueRevanches.maia_won(), DialogueRevanches.maia_lost(),
		DialogueRevanches.isaure_offer(), DialogueRevanches.isaure_won_first(true)]
	for b: Array in blocks:
		assert_int(b.size()).is_less_equal(10)
		var t := _texts(b)
		assert_str(t).not_contains(" anse")


static func _texts(lines: Array) -> String:
	return " ".join(lines.map(func(l: Dictionary) -> String: return String(l.get("text", ""))))
