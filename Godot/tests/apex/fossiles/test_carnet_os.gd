extends GdUnitTestSuite
## Le carnet des os (docs/post-game-scenes.md F1, R3 pour la page de la mer), sans fenêtre : la scène de
## Sirocco (9 bulles, avec ou sans la page 17 trouvée ; drapeaux carnet_os, carnet_terre) ; trois pages
## de cinq devinettes (« — S. » pour la terre, « — I. » pour la mer) ; la terre connue après Sirocco, la
## mer après le pari d'Isaure (drapeau isaure_pari_gagne, posé par le lot C) ; les pages pour le mur du
## journal ; l'objectif « Les fossiles » qui dit quoi faire, dans l'ordre.

const F := preload("res://story/fossiles.gd")
const DF := preload("res://data/dialogue_fossiles.gd")
const JP := preload("res://ui/journal_pages.gd")   # (lot D, le mur du journal)


func before_test() -> void:
	Game.new_game()
	Game.set_flag(&"prologue_done")
	Game.set_flag(&"post_game")


func after() -> void:
	Game.new_game()


static func bulles(steps: Array) -> int:
	return steps.filter(func(s: Dictionary) -> bool: return s.has("text") or s.has("text_fn")).size()


static func drapeaux(steps: Array) -> Array:
	return steps.filter(func(s: Dictionary) -> bool: return s.has("flag")).map(func(s: Dictionary) -> String: return String(s["flag"]))


func test_sirocco_neuf_bulles_avec_ou_sans_la_page_17() -> void:
	for page_17 in [true, false]:
		var lines := DF.carnet(page_17)
		assert_int(bulles(lines)).is_equal(9)
		assert_array(drapeaux(lines)).contains_exactly(["carnet_os", "carnet_terre"])
		assert_str(String(lines[DF.TAP]["text"])).starts_with("Ceux-là.")
		assert_str(String(lines[DF.GIVE]["text"])).contains("c'est mon carnet")
		for l: Dictionary in lines:
			if l.has("text") and l.get("who", "") != DF.CHLOE:
				assert_str(String(l["text"])).override_failure_message("une didascalie dans la bouche de Sirocco").not_contains("(")
	assert_str(String(DF.carnet(true)[3]["text"])).is_equal("Page 17. Je l'ai.")
	assert_str(String(DF.carnet(false)[4]["text"])).contains("va la lire")


func test_trois_pages_cinq_devinettes() -> void:
	for b in F.BEASTS:
		var p := DF.page(b)
		var letter: Array = p["letter"]
		assert_int(letter.size()).override_failure_message("%s : un titre et cinq devinettes" % b).is_equal(6)
		assert_str(String(p["sign"])).is_equal("— I." if b == &"kronosaurus" else "— S.")
		var heads := ["La tête", "Le dos", "Les côtes", "Les pattes", "La queue"]
		for i in 5:
			assert_str(String(letter[i + 1])).starts_with(heads[i])
			assert_str(F.riddle(b, i)).is_equal(String(letter[i + 1]))


func test_la_terre_apres_sirocco_la_mer_apres_isaure() -> void:
	assert_int(F.carnet_pages().size()).is_equal(0)
	assert_bool(F.shown(&"titanosaure")).is_false()
	Game.set_flag(&"carnet_os")
	Game.set_flag(&"carnet_terre")
	assert_array(F.carnet_pages().map(func(p: Dictionary) -> String: return String(p["id"]))).contains_exactly(["titanosaure", "gigantoraptor"])
	assert_bool(F.shown(&"gigantoraptor")).is_true()
	assert_bool(F.shown(&"kronosaurus")).is_false()
	Game.set_flag(&"isaure_pari_gagne")   # (lot C, le pari gagné la première fois)
	assert_int(F.carnet_pages().size()).is_equal(3)
	assert_bool(F.shown(&"kronosaurus")).is_true()
	var mer: Dictionary = F.carnet_pages()[2]
	assert_str(String(mer["title"])).is_equal("La mer")
	assert_int((mer["letter"] as Array).size()).is_equal(6)


func test_la_section_du_mur_du_journal() -> void:
	assert_bool(F.journal_section().is_empty()).override_failure_message("rien avant le carnet").is_true()
	Game.set_flag(&"carnet_os")
	Game.set_flag(&"carnet_terre")
	var section := F.journal_section()
	assert_str(String(section["title"])).is_equal("Le carnet des os")
	var pages: Array = section["pages"]
	assert_array(pages.map(func(p: Dictionary) -> String: return p["label"])).contains_exactly(["Le doré", "Le plumeux", "La mer"])
	assert_int(pages.filter(func(p: Dictionary) -> bool: return JP.state(p) == JP.State.FOUND).size()).is_equal(2)
	var sea: Dictionary = JP.letter(pages[2])
	assert_str(String(sea["sign"])).is_equal("— I.")
	assert_int((sea["paragraphs"] as Array).size()).is_equal(6)
	Game.set_flag(&"isaure_pari_gagne")
	assert_int(JP.counts(pages).x).is_equal(3)


func test_rien_avant_la_fin_du_jeu() -> void:
	Game.flags.erase("post_game")
	Game.set_flag(&"carnet_terre")
	assert_bool(F.shown(&"titanosaure")).override_failure_message("les os attendent la fin du jeu").is_false()


func test_l_objectif_dit_quoi_faire() -> void:
	assert_str(String(F.objective()["zone"])).is_equal("desert")
	Game.set_flag(&"carnet_os")
	Game.set_flag(&"carnet_terre")
	var o := F.objective()
	assert_str(String(o["text"])).contains("0 sur 15")
	assert_str(String(o["text"])).contains("Isaure")
	for i in 5:
		Game.set_flag(F.flag_of(&"gigantoraptor", i))
	assert_str(String(F.objective()["zone"])).is_equal("cabinet")
	assert_str(String(F.objective()["text"])).contains("du Gigantoraptor")
	Game.set_flag(&"ressuscite_gigantoraptor")
	Game.set_flag(&"isaure_pari_gagne")
	assert_str(String(F.objective()["text"])).contains("5 sur 15")
	assert_str(String(F.objective()["text"])).not_contains("Isaure")


func test_les_toasts_et_les_cranes() -> void:
	assert_str(DF.toast(&"kronosaurus", 1)).is_equal("Un os du Kronosaurus ! Il en reste 4.")
	assert_str(DF.toast(&"gigantoraptor", 5)).starts_with("Le dernier os du Gigantoraptor !")
	assert_str(String(DF.skull(&"titanosaure", "")[0]["text"])).contains("sans une goutte d'ambre")
