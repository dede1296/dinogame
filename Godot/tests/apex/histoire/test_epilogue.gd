extends GdUnitTestSuite
## L'épilogue et l'après (docs/chapitre-9-scenes.md § 4, 5 et « Autour »), sans fenêtre : les bulles et
## les drapeaux du thé (avec ou sans les moufles), de la porte, de la tasse bleue, du choix, de la
## marche, de la jetée (la Réserve, Brac et Fournaise, les gardiennes, « Bouh », la page 40) ; les
## objets (moufles rendues, insigne de gardienne) ; l'enchaînement des objectifs du chapitre ; les
## répliques de l'après (Roc, Bertille une fois).

const A := preload("res://story/apex.gd")
const EPI := preload("res://story/epilogue.gd")
const JETEE := preload("res://story/apex_jetee.gd")
const OBJ := preload("res://story/apex_objectives.gd")
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
	Game.give_starter(&"ankylosaurus")


static func bulles(steps: Array) -> int:
	return steps.filter(func(s: Dictionary) -> bool: return s.has("text") or s.has("text_fn")).size()


static func drapeaux(steps: Array) -> Array:
	return steps.filter(func(s: Dictionary) -> bool: return s.has("flag")).map(func(s: Dictionary) -> String: return String(s["flag"]))


# ------------------------------------------------------------------ le Cabinet

func test_le_the_avec_et_sans_les_moufles() -> void:
	Game.give_item("moufles_helene")
	assert_int(bulles(EPI.tea({}))).override_failure_message("avec les moufles : 11 bulles").is_equal(11)
	EPI.mittens_back()
	assert_int(Game.item_count("moufles_helene")).override_failure_message("les moufles rendues").is_equal(0)
	assert_bool(Game.flag(&"moufles_rendues")).is_true()
	assert_int(bulles(EPI.tea({}))).override_failure_message("sans les moufles").is_equal(9)


func test_la_porte_et_la_tasse_bleue() -> void:
	var door := EPI.the_door({})
	assert_int(bulles(door)).is_equal(7)
	assert_array(drapeaux(door)).contains_exactly(["isaure_cabinet"])
	var cup := EPI.blue_cup({})
	assert_int(bulles(cup)).is_equal(10)
	assert_array(drapeaux(cup)).contains_exactly(["tasse_bleue", "reserve_dite"])
	assert_str(String(cup[8]["text"])).contains("Je n'ai toujours que toi")


func test_le_choix_reste_ou_les_laisse_une_bulle() -> void:
	assert_int(bulles(EPI.leaving(true))).is_equal(1)
	assert_int(bulles(EPI.leaving(false))).is_equal(1)
	assert_str(String(EPI.leaving(true)[0]["who"])).is_equal("Hélène")
	assert_str(String(EPI.leaving(false)[0]["who"])).is_equal("Chloé")


func test_la_marche_quatre_bulles() -> void:
	var lines := EPI.step_lines({})
	assert_int(bulles(lines)).is_equal(4)
	assert_array(drapeaux(lines)).contains_exactly(["epilogue_cabinet"])


# ------------------------------------------------------------------ la jetée

func test_la_reserve_annoncee() -> void:
	var lines := JETEE.reserve({})
	assert_int(bulles(lines)).is_less_equal(MAX_BULLES)
	assert_array(drapeaux(lines)).contains_exactly(["epilogue_port", "reserve_annoncee"])


func test_brac_gardien_selon_fournaise() -> void:
	var without := JETEE.brac({})
	assert_int(bulles(without)).is_equal(9)
	assert_str(String(without[8]["text"])).contains("Fournaise est aux coulées")
	Game.set_flag(&"fournaise_garde")
	assert_str(String(JETEE.brac({})[8]["text"])).contains("Et tu as gardé Fournaise")
	assert_array(drapeaux(without)).contains_exactly(["brac_gardien"])


func test_les_gardiennes_et_l_insigne() -> void:
	var lines := JETEE.guardians({})
	assert_int(bulles(lines)).is_equal(8)
	assert_array(drapeaux(lines)).contains_exactly(["gardiennes_nommees"])
	JETEE.badge_given()
	assert_int(Game.item_count("insigne_gardienne")).is_equal(1)
	JETEE.badge_given()
	assert_int(Game.item_count("insigne_gardienne")).override_failure_message("une seule fois").is_equal(1)


func test_bouh_et_la_page_40() -> void:
	var bouh := JETEE.bouh({})
	assert_int(bulles(bouh)).is_equal(3)
	assert_array(drapeaux(bouh)).contains_exactly(["masque_carton_porte"])
	var page := JETEE.page_40({})
	assert_int(bulles(page)).is_equal(4)
	assert_int(page.filter(func(s: Dictionary) -> bool: return s.has("letter")).size()).is_equal(1)
	assert_array(drapeaux(page)).contains_exactly(["found_journal_40", "page_40", "epilogue_fini", "post_game"])


# ------------------------------------------------------------------ les objectifs, dans l'ordre du chapitre

func _main_id() -> String:
	var out: Array[Dictionary] = []
	OBJ.main(out)
	return String(out[0]["id"]) if not out.is_empty() else ""


func test_les_objectifs_s_enchainent() -> void:
	Game.set_flag(&"isaure_porte_vue")
	Game.set_flag(&"maia_porte_vue")
	assert_bool(OBJ.active()).is_true()
	assert_str(_main_id()).is_equal("aube")
	var bastion: Dino = Game.party[0]
	Game.party.erase(bastion)
	Game.box.append(bastion)
	assert_str(_main_id()).override_failure_message("le petit au Cabinet").is_equal("aube_depart")
	Game.box.erase(bastion)
	Game.party.append(bastion)
	var chain := [[&"isaure_vaincue", "porte_apex"], [&"apex_ouvert", "terre_apex"], [&"apex_arrivee", "fond"],
		[&"souverain_eveille", "souverain"], [&"souverain_apaise", "fond"], [&"apex_fini", "cabinet_epilogue"],
		[&"reserve_dite", "marche"], [&"epilogue_cabinet", "jetee"], [&"epilogue_fini", ""]]
	for step: Array in chain:
		Game.set_flag(step[0])
		assert_str(_main_id()).override_failure_message("après %s" % step[0]).is_equal(step[1])


func test_page_39_en_secondaire_puis_l_apres() -> void:
	Game.set_flag(&"apex_arrivee")
	var side: Array[Dictionary] = []
	OBJ.side(side)
	assert_array(side.map(func(o: Dictionary) -> String: return o["id"])).contains(["page_39"])
	Game.set_flag(&"found_journal_39")
	Game.set_flag(&"post_game")
	side.clear()
	OBJ.side(side)
	var ids := side.map(func(o: Dictionary) -> String: return o["id"])
	assert_array(ids).not_contains(["page_39"])
	assert_array(ids).contains(["geants", "dinodex", "fossiles", "revanches", "helene_cabinet", "nouvelle_partie"])


# ------------------------------------------------------------------ l'après

func test_roc_apres_l_epilogue() -> void:
	assert_array(DialogueApex.chatter(&"roc", ["avant"])).override_failure_message("avant la fin : son ancien bavardage").contains_exactly(["avant"])
	Game.set_flag(&"epilogue_fini")
	var said: Array = DialogueApex.chatter(&"roc", ["avant"])
	assert_int(said.size()).is_equal(1)
	assert_bool(String(said[0]) in DialogueApex.ROC_EPILOGUE).is_true()


func test_bertille_une_fois() -> void:
	assert_str(ApexAutour.bertille_line()).override_failure_message("avant la fin du chapitre : rien").is_empty()
	Game.set_flag(&"apex_fini")
	assert_str(ApexAutour.bertille_line()).contains("remontée")
	assert_str(ApexAutour.bertille_line()).override_failure_message("une seule fois").is_empty()
