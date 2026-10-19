extends GdUnitTestSuite
## Chapitre 9, scènes 2 et 3 (le cratère, le fond, Hélène ; docs/chapitre-9-scenes.md § 2 et 3), sans
## fenêtre : les bulles et les drapeaux de chaque moment, la page 39, les blocs des géants, les trois
## essais (grisés sans la capacité, « Je ne sais pas »), la goutte, le dino de départ monté à Lien 5,
## le dernier combat tel que la scène le lance (ApexBattles : Sceaux, Caillou, l'Ambre clair aux deux
## tiers, pas de défaite), Hélène qui reconnaît le petit, Moustique et le masque rendus (avec ou sans
## le masque), le Roi, et la reprise d'une partie rechargée au fond.

const A := preload("res://story/apex.gd")
const COEUR := preload("res://story/apex_coeur.gd")
const HELENE := preload("res://story/apex_helene.gd")
const SAVE_PATH := "user://test_gdunit_apex_histoire.json"
const MAX_BULLES := 12

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


static func bulles(steps: Array) -> int:
	return steps.filter(func(s: Dictionary) -> bool: return s.has("text") or s.has("text_fn")).size()


static func drapeaux(steps: Array) -> Array:
	return steps.filter(func(s: Dictionary) -> bool: return s.has("flag")).map(func(s: Dictionary) -> String: return String(s["flag"]))


# ------------------------------------------------------------------ le cratère

func test_arrivee_au_cratere_sept_bulles() -> void:
	var lines := A.arrival_lines({})
	assert_int(bulles(lines)).is_equal(7)
	assert_array(drapeaux(lines)).contains_exactly(["apex_arrivee"])


func test_page_39_deux_bulles_la_page_deux_bulles() -> void:
	var lines := DialogueApex.lines(&"page_39")
	assert_int(bulles(lines)).is_equal(4)
	var letters := lines.filter(func(s: Dictionary) -> bool: return s.has("letter"))
	assert_int(letters.size()).is_equal(1)
	assert_str(String((letters[0]["letter"] as Array)[-1])).is_equal("Il a peur. Moi aussi. J'y vais.")
	assert_array(drapeaux(lines)).contains_exactly(["found_journal_39", "page_39"])


func test_quatre_blocs_de_geants_distincts() -> void:
	var seen := {}
	for n in [1, 2, 3, 4]:
		var lines := DialogueApex.lines(StringName("bloc_geant_%d" % n))
		assert_int(bulles(lines)).is_equal(1)
		assert_array(drapeaux(lines)).contains_exactly(["bloc_geant_vu"])
		seen[lines[0]["text"]] = true
	assert_int(seen.size()).is_equal(4)


# ------------------------------------------------------------------ le bloc, les essais, la goutte

func test_le_bloc_et_ses_drapeaux() -> void:
	var lines := COEUR.the_block({})
	assert_int(bulles(lines)).override_failure_message("le bloc : %d bulles" % bulles(lines)).is_less_equal(MAX_BULLES)
	assert_array(drapeaux(lines)).contains_exactly(["coeur_apex_arrivee", "helene_vue"])


func test_essais_grises_sans_la_capacite() -> void:
	Game.party.clear()
	Game.party.append(Dino.create(&"dimorphodon", 40, "Moustique"))
	var shown := COEUR.trial_options([])
	var labels: Array = shown["labels"]
	assert_int(labels.size()).is_equal(4)
	for i in 3:
		assert_str(String(labels[i])).override_failure_message("sans la capacité : grisé").ends_with(COEUR.NOBODY)
	assert_str(String(labels[3])).is_equal("Je ne sais pas")


func test_essais_selon_l_equipe_et_ceux_deja_faits() -> void:
	Game.party.clear()
	Game.party.append(Dino.create(&"velociraptor", 40, "Vif"))
	Game.party.append(Dino.create(&"ankylosaurus", 40, "Bastion"))
	Game.party.append(Dino.create(&"parasaurolophus", 40, "Écho"))
	var labels: Array = COEUR.trial_options([])["labels"]
	assert_array(labels).contains_exactly(["Les griffes", "La charge", "Le chant", "Je ne sais pas"])
	labels = COEUR.trial_options(["griffes", "chant"])["labels"]
	assert_array(labels).contains_exactly(["La charge", "Je ne sais pas"])
	var over := COEUR.tries_over()
	assert_int(bulles(over)).is_equal(1)
	assert_array(drapeaux(over)).contains_exactly(["essais_finis"])


func test_la_goutte_six_bulles_un_choix_deux_bulles() -> void:
	assert_int(bulles(COEUR.the_drop({}))).is_equal(6)
	for pick in 2:
		var lines := COEUR.drop_answer(pick)
		assert_int(bulles(lines)).is_equal(2)
		assert_str(String(lines[1]["text"])).contains("La même erreur qu'elle")
		assert_array(drapeaux(lines)).contains_exactly(["goutte_noire"])


func test_je_te_tiens_et_lien_5() -> void:
	var lines := COEUR.holding({})
	assert_int(bulles(lines)).is_equal(5)
	assert_array(drapeaux(lines)).contains_exactly(["starter_lien_5"])
	var vif := Game.starter_dino()
	assert_int(vif.bond).is_less(Dino.MAX_BOND)
	COEUR.raise_bond()
	assert_int(vif.bond).override_failure_message("Lien 5 avant le dernier combat").is_equal(Dino.MAX_BOND)
	assert_bool(Game.flag(&"starter_lien_5")).is_true()


# ------------------------------------------------------------------ le dernier combat tel que la scène le lance

func test_le_souverain_les_regles_du_document() -> void:
	var rules: Dictionary = A.from_battles(&"souverain_rules", [], COEUR.battle_rules())
	for key: String in ["sceaux", "caillou", "antidote"]:
		assert_bool(rules.get(key, false)).override_failure_message("règle « %s »" % key).is_true()
	assert_int(int(rules.get("calm_factor", 0))).override_failure_message("jauge triple").is_equal(3)
	assert_float(float(rules.get("antidote_min_calm", 0.0))).override_failure_message("l'Ambre clair aux deux tiers").is_equal_approx(0.66, 0.01)
	assert_bool(rules.get("catch", true)).override_failure_message("jamais capturé").is_false()
	assert_bool(rules.get("run", true)).override_failure_message("on ne fuit pas").is_false()
	var team: Array = A.from_battles(&"souverain_team", [], [])
	assert_int(team.size()).is_equal(1)
	assert_bool((team[0][3] as Dictionary).get("corrupted", false)).override_failure_message("il est corrompu : « calmed » est gagné").is_true()


func test_les_regles_de_secours_sans_defaite() -> void:
	var mine := COEUR.battle_rules()
	assert_bool(mine.get("rally", false)).override_failure_message("pas de défaite sèche").is_true()
	assert_int(int(mine["calm_factor"])).is_equal(3)


# ------------------------------------------------------------------ Hélène, Moustique, le masque, le Roi

func test_helene_reconnait_le_petit_selon_le_depart() -> void:
	for species: StringName in [&"velociraptor", &"ankylosaurus", &"parasaurolophus"]:
		Game.new_game()
		Game.give_starter(species)
		var lines := HELENE.she_wakes({})
		assert_int(bulles(lines)).is_equal(10)
		assert_str(String(lines[1]["text"])).override_failure_message(String(species)).is_equal(HELENE.KNOWS[species])
		assert_array(drapeaux(lines)).contains_exactly(["helene_reveillee"])


func test_moustique_et_le_masque_avec_et_sans_masque() -> void:
	Game.give_item("masque_carton")
	var with_mask := HELENE.moustique_and_mask({})
	assert_int(bulles(with_mask)).is_equal(10)
	assert_array(drapeaux(with_mask)).contains_exactly(["moustique_rendu", "masque_carton_rendu", "masque_carton_pris"])
	Game.items.erase("masque_carton")
	var without := HELENE.moustique_and_mask({})
	assert_int(bulles(without)).override_failure_message("sans le masque : les bulles du masque sautent").is_equal(7)
	assert_array(drapeaux(without)).contains_exactly(["moustique_rendu"])


func test_moustique_repart_avec_maia_le_masque_aussi() -> void:
	var bird := Dino.create(&"dimorphodon", 36, "Moustique")
	Game.add_caught(bird)
	Game.give_item("masque_carton")
	HELENE.moustique_leaves()
	HELENE.mask_taken()
	assert_bool(Game.party.has(bird) or Game.box.has(bird)).override_failure_message("Moustique est à Maïa").is_false()
	assert_int(Game.item_count("masque_carton")).is_equal(0)
	for f: StringName in [&"moustique_rendu", &"masque_carton_rendu", &"masque_carton_pris"]:
		assert_bool(Game.flag(f)).override_failure_message(String(f)).is_true()


func test_le_roi_trois_bulles_et_la_fin_du_chapitre() -> void:
	var lines := HELENE.the_roi({})
	assert_int(bulles(lines)).is_equal(3)
	assert_array(drapeaux(lines)).contains_exactly(["apex_fini"])


func test_aucun_moment_du_fond_ne_depasse_une_douzaine_de_bulles() -> void:
	Game.give_item("masque_carton")
	var moments := {"arrivee": A.arrival_lines({}), "bloc": COEUR.the_block({}), "goutte": COEUR.the_drop({}),
		"tiens": COEUR.holding({}), "helene": HELENE.she_wakes({}), "masque": HELENE.moustique_and_mask({}), "roi": HELENE.the_roi({})}
	for k: String in moments:
		assert_int(bulles(moments[k])).override_failure_message("%s : trop de bulles d'affilée" % k).is_less_equal(MAX_BULLES)


# ------------------------------------------------------------------ une partie rechargée au fond

func test_le_souverain_couche_apres_le_chapitre() -> void:
	var lines := DialogueApex.lines(&"souverain_couche")
	assert_int(bulles(lines)).is_equal(1)
	assert_str(String(lines[0]["text"])).contains("Il n'a plus peur")
