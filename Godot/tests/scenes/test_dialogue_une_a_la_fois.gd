extends GdUnitTestSuite
## Une scène à la fois, la boîte de dialogue (ui/dialogue.gd), sans fenêtre : deux répliques demandées en même
## temps ne se mélangent jamais (la seconde attend la fin de la première, dans l'ordre) ; une question et des
## répliques non plus — le cas du Havre : Joss pose sa question, la nuit tombe et la barque d'Isaure demande ses
## répliques (avant : la question finie, la boîte se fermait sous les répliques de la nuit, qui n'avançaient plus
## jamais, et Chloé restait bloquée) ; abort() (Se débloquer) ferme tout, ce qui attendait rend la main sans poser
## ses drapeaux ; skip_lines fait passer les répliques sans les montrer.

const SAVE_PATH := "user://test_gdunit_scenes_dialogue.json"
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
	Dialogue.skip_lines = false
	Dialogue.abort()


# ------------------------------------------------------------------ outils

## La réplique à l'écran tapée en entier, puis une pression : la suivante (ou la fin).
func _next() -> void:
	for i in MAX_FRAMES:
		if not Dialogue.get("_typing"):
			break
		Dialogue.advance()
		await get_tree().process_frame
	Dialogue.advance()
	await get_tree().process_frame
	await get_tree().process_frame


func _until(done: Callable) -> bool:
	for i in MAX_FRAMES:
		if done.call():
			return true
		await get_tree().process_frame
	return false


# ------------------------------------------------------------------ deux à la fois

func test_deux_repliques_en_meme_temps_passent_l_une_apres_l_autre() -> void:
	var order: Array[String] = []
	(func() -> void:
		await Dialogue.run([{"who": "Joss", "text": "A1"}, {"who": "Joss", "text": "A2"}])
		order.append("A")).call()
	(func() -> void:
		await Dialogue.run([{"text": "B1"}])
		order.append("B")).call()
	assert_int(Dialogue.pending()).override_failure_message("les deux demandes ne sont pas en file").is_equal(2)
	assert_str(Dialogue.shown_text()).override_failure_message("la seconde a pris la boîte de la première").is_equal("A1")
	await _next()
	assert_str(Dialogue.shown_text()).override_failure_message("la seconde coupe la première").is_equal("A2")
	await _next()
	assert_bool(await _until(func() -> bool: return order.has("A"))).is_true()
	assert_str(Dialogue.shown_text()).override_failure_message("la seconde ne vient pas après la première").is_equal("B1")
	assert_bool(Dialogue.active).override_failure_message("la boîte fermée sous la seconde").is_true()
	await _next()
	assert_bool(await _until(func() -> bool: return order.size() == 2)).override_failure_message("la seconde n'avance plus").is_true()
	assert_array(order).is_equal(["A", "B"])
	assert_bool(Dialogue.active).is_false()
	assert_int(Dialogue.pending()).is_equal(0)


## Le bug du Havre (Greg, 20/10) : la question de Joss, puis la scène de la nuit qui demande ses répliques.
func test_question_de_joss_puis_la_nuit_ne_bloque_plus() -> void:
	var got := {}
	(func() -> void:
		got["pick"] = await Dialogue.choose("Joss", "Il me manque encore la boucle d'ambre.", ["Comment gagner des pièces ?", "Au revoir"])).call()
	(func() -> void:
		await Dialogue.run([{"text": "Au bout du quai, une barque accoste sans lumière."}, {"flag": &"test_nuit_vue"}])
		got["nuit"] = true).call()
	assert_bool(await _until(func() -> bool: return Dialogue.get("_choosing"))).override_failure_message("la question de Joss n'est pas posée").is_true()
	assert_str(Dialogue.shown_text()).starts_with("Il me manque")
	assert_int(Dialogue.pending()).is_equal(2)
	Dialogue.answer(1)
	assert_bool(await _until(func() -> bool: return got.has("pick"))).is_true()
	assert_int(got["pick"]).is_equal(1)
	assert_bool(Dialogue.active).override_failure_message("la nuit ne prend pas la boîte après la question").is_true()
	assert_str(Dialogue.shown_text()).starts_with("Au bout du quai")
	await _next()
	assert_bool(await _until(func() -> bool: return got.has("nuit"))).override_failure_message("les répliques de la nuit n'avancent plus : Chloé bloquée").is_true()
	assert_bool(Game.flag(&"test_nuit_vue")).is_true()
	assert_bool(Dialogue.active).is_false()


func test_une_question_attend_la_fin_des_repliques() -> void:
	var got := {}
	(func() -> void:
		await Dialogue.run([{"who": "Maïa", "text": "Te voilà !"}])
		got["run"] = true).call()
	(func() -> void:
		got["pick"] = await Dialogue.choose("Maïa", "Un défi ?", ["Oui", "Plus tard"])).call()
	await get_tree().process_frame
	assert_bool(Dialogue.get("_choosing")).override_failure_message("la question coupe la réplique").is_false()
	assert_int(Dialogue.find_children("*", "Button", true, false).size()).is_equal(0)
	await _next()
	assert_bool(await _until(func() -> bool: return Dialogue.get("_choosing"))).is_true()
	assert_bool(got.has("run")).is_true()
	Dialogue.answer(0)
	assert_bool(await _until(func() -> bool: return got.has("pick"))).is_true()
	assert_int(got["pick"]).is_equal(0)


# ------------------------------------------------------------------ Se débloquer

func test_abort_ferme_tout_et_rend_la_main_sans_poser_les_drapeaux() -> void:
	var got := {}
	(func() -> void:
		await Dialogue.run([{"text": "Une réplique qui ne répond plus."}, {"flag": &"test_jamais"}])
		got["a"] = true).call()
	(func() -> void:
		got["pick"] = await Dialogue.choose("", "Et ça ?", ["Oui", "Non"])).call()
	(func() -> void:
		await Dialogue.run([{"text": "Après."}, {"flag": &"test_jamais_2"}])
		got["c"] = true).call()
	assert_int(Dialogue.pending()).is_equal(3)
	Dialogue.abort()
	assert_bool(await _until(func() -> bool: return got.size() == 3)).override_failure_message("après abort(), quelqu'un attend encore : %s" % got).is_true()
	assert_int(got["pick"]).override_failure_message("une question fermée répond sa dernière option").is_equal(1)
	assert_bool(Game.flag(&"test_jamais") or Game.flag(&"test_jamais_2")).override_failure_message("abort() a posé les drapeaux de répliques jamais lues").is_false()
	assert_bool(Dialogue.active).is_false()
	assert_int(Dialogue.pending()).is_equal(0)
	# Et la boîte marche encore ensuite.
	(func() -> void:
		await Dialogue.run([{"text": "Encore là."}])
		got["d"] = true).call()
	assert_str(Dialogue.shown_text()).is_equal("Encore là.")
	await _next()
	assert_bool(await _until(func() -> bool: return got.has("d"))).is_true()


func test_skip_lines_passe_sans_montrer() -> void:
	Dialogue.skip_lines = true
	await Dialogue.run([{"text": "Pas vu."}, {"flag": &"test_saute"}])
	var pick := await Dialogue.choose("", "?", ["Oui", "Non"])
	Dialogue.skip_lines = false
	assert_bool(Dialogue.active).is_false()
	assert_bool(Game.flag(&"test_saute")).is_false()
	assert_int(pick).is_equal(1)
