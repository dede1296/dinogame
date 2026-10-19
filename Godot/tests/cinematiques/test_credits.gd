extends GdUnitTestSuite
## Les crédits (ui/credits.gd), sans fenêtre : ils se construisent depuis CreditsData (la seule source,
## tirée de docs/credits.md : chaque titre, chaque ligne, « ## » en sous-titre, « Powered by Stability
## AI »), s'ouvrent sur le carton de Grégory Cuypers, finissent par « Pour Chloé. » (et sa ligne « Cette
## île est à toi. Elle l'a toujours été. ») puis « Merci d'avoir joué » ; le défilé va au bout, s'arrête
## en pause et repart ; depuis le menu, on retrouve l'écran d'avant.

const STEP := 0.25


func before() -> void:
	Cinematic.pause_tree = false


func after() -> void:
	Cinematic.pause_tree = true


func after_test() -> void:
	if is_instance_valid(Cinematic.current):
		Cinematic.current._finish_now()


func test_les_credits_viennent_de_credits_data() -> void:
	var entries := CreditsRoll.entries()
	var texts := entries.map(func(e: Dictionary) -> String: return String(e["text"]))
	for i in CreditsData.SECTIONS.size():
		var section: Dictionary = CreditsData.SECTIONS[i]
		if i > 0:
			assert_bool(texts.has(String(section["title"]))).override_failure_message("titre : %s" % section["title"]).is_true()
		for line in section["lines"]:
			var text := String(line)
			if text == "":
				continue
			var shown := text.substr(3) if text.begins_with("## ") else text
			assert_bool(texts.has(shown)).override_failure_message("ligne absente : %s" % shown).is_true()
	assert_bool(texts.has(CreditsData.POWERED_BY_STABILITY)).is_true()
	assert_bool(texts.any(func(t: String) -> bool: return t.begins_with("## "))).override_failure_message("« ## » devient un sous-titre").is_false()
	assert_str(String(entries[0]["text"])).is_equal("Ambrelune")
	assert_str(String(entries[0]["style"])).is_equal("card_title")
	assert_bool(entries.any(func(e: Dictionary) -> bool: return e["text"] == "Grégory Cuypers" and e["style"] == "card_name")).is_true()
	assert_array(texts.slice(-2)).contains_exactly(["Pour Chloé.", "Merci d'avoir joué"])
	assert_str(String(entries[-2].get("line", ""))).is_equal("Cette île est à toi. Elle l'a toujours été.")


func test_le_rouleau_montre_chaque_ligne() -> void:
	var plan: Dictionary = Cinematiques.credits_sequence()["plans"][0]
	assert_str(String(plan["kind"])).is_equal("credits")
	var roll := CreditsRoll.create(plan)
	add_child(roll)
	var shown := roll.shown_texts()
	for entry: Dictionary in CreditsRoll.entries():
		if String(entry["text"]) != "":
			assert_bool(shown.has(String(entry["text"]))).override_failure_message("à l'écran : %s" % entry["text"]).is_true()
	roll.tick(1.0)
	roll.queue_free()


func test_le_defile_va_au_bout_avec_une_pause() -> void:
	var film := Cinematiques.play_credits(self)
	film.set_process(false)
	await await_idle_frame()
	await await_idle_frame()   # (the roll's lines laid out: their height is known)
	var roll := film.stage_now() as CreditsRoll
	assert_object(roll).is_not_null()
	var phases := ["opening"]
	var cards := []
	var paused_once := false
	var elapsed := 0.0
	while not film.done and elapsed < 400.0:
		film.advance(STEP)
		elapsed += STEP
		if is_instance_valid(roll) and phases[-1] != roll.phase:
			phases.append(roll.phase)
			cards.append(roll.card_text())
		if not paused_once and is_instance_valid(roll) and roll.phase == "roll" and elapsed > 20.0:
			paused_once = true
			film.go_on()   # (A, a click: pause)
			assert_bool(roll.paused).is_true()
			var y := roll.content.position.y
			for i in 12:
				film.advance(STEP)
			assert_float(roll.content.position.y).override_failure_message("en pause, le défilé ne bouge pas").is_equal(y)
			film.go_on()
			assert_bool(roll.paused).is_false()
	print("Crédits depuis le menu : %.0f s" % elapsed)
	assert_bool(film.done).override_failure_message("les crédits vont au bout (%.0f s)" % elapsed).is_true()
	assert_array(phases).contains_exactly(["opening", "roll", "dedication", "thanks"])
	assert_str(String(cards[1])).override_failure_message("le carton de la dédicace : deux lignes").is_equal(
		"Pour Chloé.\nCette île est à toi. Elle l'a toujours été.")
	assert_str(String(cards[2])).is_equal("Merci d'avoir joué")
	assert_float(elapsed).override_failure_message("durée des crédits : %.0f s" % elapsed).is_between(45.0, 160.0)
	assert_str(String(film.sequence["end"])).override_failure_message("depuis le menu : retour à l'écran d'avant").is_equal("reveal")


func test_le_fond_des_credits_sans_peinture() -> void:
	var background := Cinematiques.credits_background()
	var plan := CinematicPlan.create(background, 100.0)
	add_child(plan)
	assert_bool(plan.has_picture).is_equal(CinematicPlan.picture_of(background) != "")
	for i in 40:
		plan.tick(2.5)   # (100 s: the night falls, the dinos pass, Mastoc takes the lantern)
	plan.queue_free()
