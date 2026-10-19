extends GdUnitTestSuite
## Chapitre 9, scène 1 (l'aube devant la porte, docs/chapitre-9-scenes.md § 1), sans fenêtre : quand le
## chapitre 9 prend Isaure à son compte, le dino de départ exigé, le nombre de bulles de chaque moment
## (jamais plus d'une douzaine d'affilée), les drapeaux posés par chaque moment, l'aveu de l'œuf selon
## où est le petit, le CHOIX avant Carène (trois phrases, aucune mauvaise), le vrai dilemme (ouvrir /
## laisser fermée : les deux chemins se rejoignent), les Cœurs rendus puis posés dans la porte, le duel
## d'Isaure tel que les scènes le lancent (ApexBattles), et l'aiguillage d'Apex.run.

const A := preload("res://story/apex.gd")
const AUBE := preload("res://story/apex_aube.gd")
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


## Les bulles d'une suite d'étapes (une ligne de texte, ou une ligne dont le texte vient avec son geste).
static func bulles(steps: Array) -> int:
	return steps.filter(func(s: Dictionary) -> bool: return s.has("text") or s.has("text_fn")).size()


## Les drapeaux qu'une suite d'étapes pose.
static func drapeaux(steps: Array) -> Array:
	return steps.filter(func(s: Dictionary) -> bool: return s.has("flag")).map(func(s: Dictionary) -> String: return String(s["flag"]))


# ------------------------------------------------------------------ quand le chapitre 9 commence

func test_isaure_reste_au_chapitre_8_avant_maia() -> void:
	assert_bool(AUBE.takes_over()).override_failure_message("rien vu : le ch. 9 ne doit pas prendre Isaure").is_false()
	Game.set_flag(&"isaure_porte_vue")
	assert_bool(AUBE.takes_over()).override_failure_message("Isaure vue, pas Maïa : encore le ch. 8").is_false()
	Game.set_flag(&"maia_porte_vue")
	assert_bool(AUBE.takes_over()).override_failure_message("Isaure et Maïa vues : l'aube peut venir").is_true()
	Game.set_flag(&"apex_ouvert")
	assert_bool(AUBE.takes_over()).override_failure_message("porte ouverte : Isaure n'est plus là").is_false()


func test_apex_run_laisse_les_evenements_du_chapitre_8() -> void:
	assert_bool(await A.run(&"isaure_porte", null)).override_failure_message("avant l'aube, isaure_porte est au ch. 8").is_false()
	assert_bool(await A.run(&"brac_jetee", null)).override_failure_message("avant l'épilogue, Brac est au ch. 8").is_false()
	assert_bool(await A.run(&"leonce_port", null)).override_failure_message("avant l'épilogue, Léonce est au ch. 8").is_false()
	assert_bool(await A.run(&"evenement_inconnu", null)).is_false()


func test_dino_de_depart_exige() -> void:
	assert_bool(A.starter_in_party()).override_failure_message("Vif est dans l'équipe").is_true()
	var vif: Dino = Game.party[0]
	Game.party.erase(vif)
	Game.box.append(vif)
	assert_bool(A.starter_in_party()).override_failure_message("Vif au Cabinet : l'aube attend").is_false()
	var lines := AUBE.fetch_starter()
	assert_int(bulles(lines)).is_equal(2)
	assert_str(String(lines[0]["text"])).contains("Va le chercher")


# ------------------------------------------------------------------ les moments, les bulles, les drapeaux

func test_derniere_demande_six_bulles_et_le_pari() -> void:
	var lines := AUBE.last_demand(null, {})
	assert_int(bulles(lines)).is_equal(6)
	assert_array(drapeaux(lines)).contains_exactly(["isaure_pari"])


func test_les_miens_huit_bulles_et_l_aveu() -> void:
	var lines := AUBE.her_own(null, {})
	assert_int(bulles(lines)).is_equal(8)
	assert_array(drapeaux(lines)).contains_exactly(["isaure_aveu_oeuf"])


func test_aveu_selon_ou_est_le_petit() -> void:
	Game.set_flag(&"oeuf_vole_apaise")
	var little := Dino.create(ForetCamp.stolen_species(), 40, ForetCamp.stolen_name())
	Game.box.append(little)
	assert_str(AUBE.confession()).override_failure_message("au Cabinet").contains("ramené au Cabinet")
	Game.box.erase(little)
	Game.party.append(little)
	assert_bool(AUBE.egg_in_party()).is_true()
	assert_str(AUBE.confession()).override_failure_message("dans l'équipe").contains("dans ton équipe")


func test_choix_avant_carene_trois_phrases_aucune_mauvaise() -> void:
	assert_int(DialogueApex.CARENE_OPTIONS.size()).is_equal(3)
	for pick in 3:
		var lines := DialogueApex.carene_reply(pick)
		assert_int(bulles(lines)).override_failure_message("réponse %d" % pick).is_equal(2)
		assert_str(String(lines[1]["text"])).contains("prend son temps")
		assert_array(drapeaux(lines)).override_failure_message("le choix ne pose aucun drapeau").is_empty()


func test_parole_tenue_les_coeurs_rendus() -> void:
	for i in range(1, 6):
		Game.set_flag(StringName("coeur_%d" % i))
	Game.give_item("coeur_5")
	var lines := AUBE.word_kept(null)
	assert_int(bulles(lines)).is_equal(6)
	assert_array(drapeaux(lines)).contains_exactly(["coeurs_rendus"])
	AUBE.hearts_back()
	for i in range(1, 6):
		assert_int(Game.item_count("coeur_%d" % i)).override_failure_message("coeur_%d dans le sac" % i).is_equal(1)
	assert_bool(Game.flag(&"coeurs_rendus")).is_true()


func test_le_dilemme_les_deux_chemins_se_rejoignent() -> void:
	var open := AUBE.decision(true)
	var shut := AUBE.decision(false)
	assert_int(bulles(open)).override_failure_message("« Ouvrir » : les 3 bulles communes").is_equal(3)
	assert_int(bulles(shut)).override_failure_message("« Fermée » : 3 bulles, puis les 3 communes").is_equal(6)
	assert_array(drapeaux(open)).contains_exactly(["apex_decision"])
	assert_array(drapeaux(shut)).contains_exactly(["apex_decision"])
	assert_str(String(open[-2]["text"])).contains("tant qu'il y aura un autre moyen")
	assert_str(String(shut[-2]["text"])).contains("tant qu'il y aura un autre moyen")


func test_la_porte_les_cinq_coeurs_restent_dedans() -> void:
	for i in range(1, 6):
		Game.set_flag(StringName("coeur_%d" % i))
		Game.give_item("coeur_%d" % i)
	assert_int(bulles(AUBE.through(null, {}))).is_equal(3)
	AUBE.hearts_in_the_door()
	for i in range(1, 6):
		assert_int(Game.item_count("coeur_%d" % i)).override_failure_message("coeur_%d hors du sac" % i).is_equal(0)
		assert_bool(Game.flag(StringName("coeur_%d" % i))).override_failure_message("le drapeau coeur_%d reste" % i).is_true()
	assert_bool(Game.flag(&"apex_ouvert")).override_failure_message("apex_ouvert : ce que DialogueVolcan attend").is_true()


func test_aucun_moment_ne_depasse_une_douzaine_de_bulles() -> void:
	var moments := {"demande": AUBE.last_demand(null, {}), "miens": AUBE.her_own(null, {}), "parole": AUBE.word_kept(null),
		"fermee": AUBE.decision(false), "porte": AUBE.through(null, {}), "depart": AUBE.fetch_starter()}
	for k: String in moments:
		assert_int(bulles(moments[k])).override_failure_message("%s : trop de bulles d'affilée" % k).is_less_equal(MAX_BULLES)


# ------------------------------------------------------------------ le duel tel que la scène le lance

func test_duel_d_isaure_quatre_dinos_de_la_mer() -> void:
	var team: Array = A.from_battles(&"isaure_team", [], AUBE.team())
	assert_int(team.size()).is_equal(4)
	var names := team.map(func(m: Array) -> String: return m[2])
	assert_array(names).contains_exactly(["Hauban", "Bouline", "Étrave", "Carène"])
	for m: Array in team:
		var opts: Dictionary = m[3] if m.size() > 3 else {}
		assert_bool(opts.get("corrupted", false)).override_failure_message("%s : jamais corrompu" % m[2]).is_false()
	var rules: Dictionary = A.from_battles(&"isaure_rules", [], {})
	assert_bool(rules.has("music") and rules["music"] == null).override_failure_message("aucune musique à l'aube").is_true()
	assert_str(String(rules.get("hesitates", ""))).override_failure_message("Carène hésite").is_equal("Carène")


func test_perdu_au_camp_d_helene() -> void:
	assert_str(String(A.spawn("LOSE_AUBE"))).override_failure_message("le duel perdu : près du camp d'Hélène").is_equal("DevantCamp")
	assert_str(DialogueApex.ISAURE_LOST).contains("L'aube peut attendre")
