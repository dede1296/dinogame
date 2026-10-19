extends GdUnitTestSuite
## Les cinématiques (docs/cinematiques.md, story/cinematiques.gd, ui/cinematic.gd), sans fenêtre : les
## deux séquences sont complètes (nombre de plans, durées, une ou deux phrases de 18 mots au plus par
## image, exactement les textes de docs/cinematiques_textes.md, les noms des peintures du document), et
## chaque phrase tient dans le bandeau (trois lignes au plus) ; F-06 suit le dino de départ (sa
## peinture, son nom) ; une image absente
## donne un fond uni avec la phrase, sans planter ; « Passer » demande deux appuis (ou un clic sur le
## bouton), termine le film et pose son drapeau (intro_vue, fin_vue) ; la fin ne se joue qu'une fois ;
## l'intro est proposée en Nouvelle partie et en Nouvelle partie+ ; une musique absente retombe sur
## titre.ogg. Le film est avancé à la main (advance) : rien n'attend les vraies secondes.

const SAVE_PATH := "user://test_gdunit_cinematiques.json"
const STEP := 0.1

var _saved_path: String


func before() -> void:
	_saved_path = Save.path
	Save.path = SAVE_PATH   # (jamais la partie de Greg)
	Cinematic.pause_tree = false   # (un arbre en pause arrêterait GdUnit4)


func after() -> void:
	Save.path = _saved_path
	Cinematic.pause_tree = true
	Game.new_game()
	await Router.fade_in(0.0)


func before_test() -> void:
	Game.new_game()


func after_test() -> void:
	if is_instance_valid(Cinematic.current):
		Cinematic.current._finish_now()


## The film moves on by `secs`, frame by frame.
static func run(film: Cinematic, secs: float) -> void:
	for i in int(round(secs / STEP)):
		film.advance(STEP)


## A few frames, until the film has closed the curtain, said « finished » and gone (and whatever was
## waiting for it has gone on).
func settle(film) -> void:
	for i in 30:
		if not is_instance_valid(film):
			break
		await await_idle_frame()
	await await_idle_frame()


static func ids(seq: Dictionary) -> Array:
	return (seq["plans"] as Array).map(func(p: Dictionary) -> String: return String(p["id"]))


static func durations(seq: Dictionary) -> Array:
	return (seq["plans"] as Array).map(func(p: Dictionary) -> float: return float(p["secs"]))


static func total(seq: Dictionary) -> float:
	var sum := 0.0
	for s: float in durations(seq):
		sum += s
	return sum


static func files(seq: Dictionary) -> Array:
	return Cinematiques.pictures(seq).map(func(p: String) -> String: return p.get_file())


func assert_phrases(seq: Dictionary) -> void:
	for plan: Dictionary in seq["plans"]:
		if plan.get("kind", "") != "":
			continue
		assert_phrase(String(plan["id"]), String(plan["text"]))


## One or two short sentences, 8 to 18 words (docs/cinematiques_textes.md: 18 at most).
func assert_phrase(id: String, text: String) -> void:
	var n := Cinematiques.word_count(text)
	assert_int(n).override_failure_message("%s : « %s » a %d mots (%d à %d)" % [id, text, n, Cinematiques.WORDS_MIN,
		Cinematiques.WORDS_MAX]).is_between(Cinematiques.WORDS_MIN, Cinematiques.WORDS_MAX)
	var sentences := Cinematiques.sentence_count(text)
	assert_int(sentences).override_failure_message("%s : « %s » a %d phrases (1 ou 2)" % [id, text, sentences]) \
		.is_between(1, Cinematiques.SENTENCES_MAX)


## Every phrase of both films (F-06 in its three variants): {id: text}.
static func all_phrases() -> Dictionary:
	var out := {}
	for species: StringName in Cinematiques.STARTER_VARIANTS:
		Game.new_game()
		Game.give_starter(species)
		for seq: Dictionary in [Cinematiques.intro_sequence(), Cinematiques.end_sequence()]:
			for plan: Dictionary in seq["plans"]:
				if plan.has("text"):
					var id := String(plan["id"]) + (" %s" % species if plan["id"] == "F-06" else "")
					out[id] = String(plan["text"])
	return out


# ------------------------------------------------------------------ the sequences

func test_l_intro_neuf_images_et_le_carton() -> void:
	var seq := Cinematiques.intro_sequence()
	assert_array(ids(seq)).contains_exactly(["I-01", "I-02", "I-03", "I-04", "I-05", "I-06", "I-07", "I-08", "I-09", "carton"])
	assert_array(durations(seq)).contains_exactly([7.0, 7.0, 8.0, 7.0, 9.0, 8.0, 7.0, 8.0, 9.0, 4.0])
	assert_float(total(seq)).override_failure_message("intro prévue : 60 à 80 s").is_between(60.0, 80.0)
	var real := Cinematic.sequence_length(seq)
	assert_float(real).override_failure_message("intro, le temps de lire compris : %.1f s (60 à 95)" % real).is_between(60.0, 95.0)
	var card: Dictionary = seq["plans"][9]
	assert_str(String(card["kind"])).is_equal("card")
	assert_str(String(card["title"])).is_equal("Ambrelune")
	assert_phrases(seq)
	assert_str(String(seq["plans"][0]["text"])).starts_with("Moi, c'est Chloé, douze ans.")
	assert_str(String(seq["plans"][6]["text"])).ends_with("« Monte, moussaillon. Les légendes, ça se trouve. »")
	assert_str(String(seq["plans"][8]["text"])).is_equal("Et l'île est apparue. Hélène était quelque part là-dedans. Et les gens masqués aussi.")
	assert_str(String(seq["flag"])).is_equal("intro_vue")
	assert_str(String(seq["end"])).is_equal("black")
	assert_array(files(seq)).contains_exactly(["intro_01_large.jpg", "intro_02_falaises.jpg", "intro_03_cabinet.jpg",
		"intro_04_oeufs.jpg", "intro_05_carte_vide.jpg", "intro_05_carte.jpg", "intro_06_chambre.jpg", "intro_07_ponton.jpg",
		"intro_08_brume.jpg", "intro_09_arrivee.jpg"])


func test_la_fin_dix_plans_puis_les_credits() -> void:
	Game.give_starter(&"velociraptor")
	var seq := Cinematiques.end_sequence()
	assert_array(ids(seq)).contains_exactly(["F-01", "F-02", "F-03", "F-04", "F-05", "F-06", "F-07", "F-08", "F-09", "F-10"])
	assert_array(durations(seq)).contains_exactly([10.0, 9.0, 9.0, 11.0, 9.0, 10.0, 9.0, 11.0, 11.0, 8.0])
	assert_float(total(seq)).override_failure_message("fin prévue : 90 à 120 s hors crédits").is_between(90.0, 120.0)
	var real := Cinematic.sequence_length(seq)
	assert_float(real).override_failure_message("fin, le temps de lire compris : %.1f s (70 à 130 hors crédits)" % real) \
		.is_between(70.0, 130.0)
	var last: Dictionary = seq["plans"][9]
	assert_str(String(last["kind"])).is_equal("credits")
	assert_float(float(last["opening_secs"])).is_equal(8.0)
	assert_phrases(seq)
	assert_str(String(seq["plans"][8]["text"])).starts_with("« Ce qui dort n'est pas mort. »")
	assert_str(String(seq["flag"])).is_equal("fin_vue")
	assert_array(files(seq)).contains_exactly(["fin_01_jetee_fete.jpg", "fin_02_barque_visiteurs.jpg", "fin_03_forges.jpg",
		"fin_04_tasse_bleue.jpg", "fin_05_gardiennes.jpg", "fin_06_dinos_vif.jpg", "fin_06_dinos_base.jpg", "fin_07_brac_nuit.jpg",
		"fin_08_souverain.jpg", "fin_09_journal_sans_trait.jpg", "fin_09_journal.jpg", "credits_fond_sans_lanterne.jpg", "credits_fond.jpg"])


func test_f06_suit_le_dino_de_depart() -> void:
	var expected := {&"velociraptor": ["vif", "Vif a deux dents"], &"ankylosaurus": ["bastion", "Plume a grandi"],
		&"parasaurolophus": ["echo", "Écho chante toujours faux"]}
	for species: StringName in expected:
		Game.new_game()
		var d := Game.give_starter(species)
		if species == &"ankylosaurus":
			d.nickname = "plume"   # (renamed by the player, written small: the phrase opens with a capital)
		var f06: Dictionary = Cinematiques.end_sequence()["plans"][5]
		assert_str(String(f06["id"])).is_equal("F-06")
		assert_str(String(f06["image"]).get_file()).is_equal("fin_06_dinos_%s.jpg" % expected[species][0])
		assert_str(String(f06["text"])).starts_with(expected[species][1])
		assert_str(String(f06["text"])).override_failure_message("F-06 : la promesse des œufs, pour les trois") \
			.ends_with(". Et bientôt d'autres bébés : Hélène m'apprend à réveiller les derniers œufs.")
		assert_phrase("F-06 %s" % species, String(f06["text"]))
		var notes := (f06["layers"] as Array).any(func(l: Dictionary) -> bool: return l.get("kind", "") == "notes")
		assert_bool(notes).override_failure_message("les notes d'Écho seulement pour Écho").is_equal(species == &"parasaurolophus")


## docs/cinematiques_textes.md, relu ici : chaque plan dit EXACTEMENT le « NOUVEAU texte » du document,
## avec le nombre de mots qu'il donne ; les totaux de l'intro et de la fin aussi ; F-06 dans ses trois
## variantes (§ f, le nom du dino de départ à la place de %s) ; le carton « Pour Chloé. » des crédits.
func test_les_mots_comptes_comme_le_document() -> void:
	var doc := FileAccess.get_file_as_string(Cinematiques.TEXTS_DOC).replace("\r\n", "\n")
	assert_str(doc).override_failure_message("%s introuvable" % Cinematiques.TEXTS_DOC).is_not_empty()
	var wanted := {}
	var rows := RegEx.create_from_string("(?m)^\\| ([IF]-\\d\\d) \\|[^|]*\\|[^|]*\\| \\*\\*(.+?)\\*\\* \\((\\d+)\\)")
	for m in rows.search_all(doc):
		wanted[m.get_string(1)] = [m.get_string(2), int(m.get_string(3))]
	assert_int(wanted.size()).override_failure_message("17 textes dans les tableaux (I-01 à I-09, F-01 à F-09 sans F-06)").is_equal(17)
	Game.give_starter(&"velociraptor")
	var shown := {}
	for seq: Dictionary in [Cinematiques.intro_sequence(), Cinematiques.end_sequence()]:
		for plan: Dictionary in seq["plans"]:
			if plan.has("text"):
				shown[String(plan["id"])] = String(plan["text"])
	var sums := {"I": 0, "F": 0}
	for id: String in wanted:
		var text: String = wanted[id][0]
		assert_str(String(shown.get(id, ""))).override_failure_message("%s : le texte du jeu n'est pas celui du document" % id).is_equal(text)
		assert_int(Cinematiques.word_count(text)).override_failure_message("%s : %d mots, le document dit %d" % [id,
			Cinematiques.word_count(text), wanted[id][1]]).is_equal(wanted[id][1])
		sums[id.left(1)] += Cinematiques.word_count(text)
	# F-06 (§ f): « - **Vif** (`fin_06_dinos_vif.png`) : **« %s a deux dents… »** (17) », on two lines.
	var f := doc.substr(doc.find("## f."), doc.find("## g.") - doc.find("## f."))
	f = RegEx.create_from_string("\\n\\s+").sub(f, " ", true)
	var variants := RegEx.create_from_string("- \\*\\*(.+?)\\*\\* \\(`fin_06_dinos_(\\w+)\\.png`\\) : \\*\\*« (.+?) »\\*\\* \\((\\d+)\\)").search_all(f)
	assert_int(variants.size()).override_failure_message("§ f : trois variantes de F-06").is_equal(3)
	var f06_most := 0   # (the document's total counts F-06 at its longest: 17-18 words)
	for m in variants:
		var species: StringName = &""
		for s: StringName in Cinematiques.STARTER_VARIANTS:
			if Cinematiques.STARTER_VARIANTS[s][0] == m.get_string(2):
				species = s
		assert_str(String(species)).override_failure_message("F-06 : pas de dino de départ pour « %s »" % m.get_string(2)).is_not_empty()
		assert_str(String(Cinematiques.STARTER_VARIANTS[species][1])).override_failure_message("F-06 %s" % m.get_string(1)) \
			.is_equal(m.get_string(3))
		Game.new_game()
		Game.give_starter(species)
		var f06 := String(Cinematiques.end_sequence()["plans"][5]["text"])
		assert_str(f06).is_equal(m.get_string(3) % m.get_string(1))
		assert_int(Cinematiques.word_count(f06)).override_failure_message("F-06 %s : mots" % m.get_string(1)).is_equal(int(m.get_string(4)))
		f06_most = maxi(f06_most, Cinematiques.word_count(f06))
	# The totals: « 17+15+…= **137 mots » (intro), « 16+18+…= **155 mots » (end, F-06 at its longest).
	var totals := RegEx.create_from_string("= \\*\\*(\\d+) mots").search_all(doc)
	assert_int(totals.size()).is_equal(2)
	assert_int(sums["I"]).override_failure_message("mots de l'intro").is_equal(int(totals[0].get_string(1)))
	assert_int(sums["F"] + f06_most).override_failure_message("mots de la fin").is_equal(int(totals[1].get_string(1)))
	# The « Pour Chloé » card (§ Les cartons de crédits): two lines.
	var card := RegEx.create_from_string("(?m)^> \\*\\*(.+?)\\*\\*\\n> (.+)$").search(doc)
	assert_object(card).override_failure_message("le carton « Pour Chloé » du document").is_not_null()
	assert_str(CreditsRoll.DEDICATION).is_equal(card.get_string(1))
	assert_str(CreditsRoll.DEDICATION_LINE).is_equal(card.get_string(2))


## The sentences as the document counts them: a quotation does not cut its sentence, a sentence opening
## on « Et » or « Enfin » carries on the one before; a third real sentence is one too many.
func test_les_phrases_comptees_comme_le_document() -> void:
	assert_int(Cinematiques.sentence_count("Un an sans nouvelles, puis une lettre du professeur Roc : « Viens vite. » J'ai fait mon sac.")).is_equal(2)
	assert_int(Cinematiques.sentence_count("Au port, une seule capitaine connaissait le chemin. « Monte, moussaillon. Les légendes, ça se trouve. »")).is_equal(2)
	assert_int(Cinematiques.sentence_count("Dans la brume, je ne pensais qu'à Hélène. Pas peur du tout. Enfin, presque.")).is_equal(2)
	assert_int(Cinematiques.sentence_count("Et l'île est apparue. Hélène était quelque part là-dedans. Et les gens masqués aussi.")).is_equal(2)
	assert_int(Cinematiques.sentence_count("Brac connaissait les cages ; maintenant, il garde les dinos la nuit. Enfin, « BARC », d'après le panneau.")).is_equal(1)
	assert_int(Cinematiques.sentence_count("« Ce qui dort n'est pas mort. » Le Cabinet est à moi, et il reste des pages blanches.")).is_equal(2)
	assert_int(Cinematiques.sentence_count("Une île. Un volcan. Des dinos.")).override_failure_message("trois phrases").is_equal(3)


## Each phrase holds in the band at the bottom: on the narrowest screen (1280 wide), three lines at most,
## inside its box (it never leaves the screen); on a computer (1600 wide), two lines at most. The film
## shows it with its French punctuation held (« Viens vite. » never cut), and gives its words back as is.
func test_chaque_phrase_tient_dans_le_bandeau() -> void:
	var phrases := all_phrases()
	var label := Cinematic.caption_label()
	label.set_anchors_preset(Control.PRESET_TOP_LEFT)   # (its width set by hand below)
	add_child(label)
	var box := Cinematic.TEXT_LINES_MAX * Cinematic.TEXT_LINE_PX
	assert_float(Cinematic.BAND_PX).override_failure_message("le bandeau sombre couvre les trois lignes") \
		.is_greater_equal(Cinematic.TEXT_BOTTOM + box)
	var report := PackedStringArray()
	for screen_width: float in [1280.0, 1600.0]:
		var most := 3 if screen_width < 1600.0 else 2
		for id: String in phrases:
			label.text = Cinematic.display_text(phrases[id])
			label.size = Vector2(screen_width - 2.0 * Cinematic.TEXT_SIDE, box)
			var lines := label.get_line_count()
			assert_int(lines).override_failure_message("%s, écran de %d : %d lignes (%d au plus)" % [id, screen_width, lines, most]) \
				.is_between(1, most)
			assert_float(float(lines * label.get_line_height())).override_failure_message("%s : le texte déborde du bandeau" % id) \
				.is_less_equal(box)
			if screen_width == 1600.0:
				report.append("%s %d" % [id, lines])
	print("Lignes à 1600 px : ", ", ".join(report))
	label.queue_free()
	var film := Cinematic.play(self, Cinematiques.intro_sequence())
	film.set_process(false)
	film.seek(5)   # (I-06: « Viens vite. »)
	run(film, 2.0)
	assert_str(film.caption_text()).is_equal(String(film.plan_now()["text"]))
	assert_int(film.caption_lines()).is_between(1, Cinematic.TEXT_LINES_MAX)
	assert_str(Cinematic.display_text("Roc : « Viens vite. »")).is_equal("Roc : « Viens vite. »")


# ------------------------------------------------------------------ missing pictures

func test_une_image_absente_donne_un_fond_uni_et_la_phrase() -> void:
	var phrase := "Une phrase de test, sur un fond uni, sans aucune peinture."
	var plan := {"id": "X-01", "image": "res://assets/art/cinematiques/n_existe_pas.png", "secs": 4.0, "text": phrase,
		"camera": [1.0, Vector2(0.5, 0.5), 1.1, Vector2(0.4, 0.6)], "color": Color(0.2, 0.3, 0.4),
		"layers": [{"kind": "image", "path": "res://n_existe_pas_calque.png", "anim": "pulse"},
			{"kind": "reveal", "path": "res://n_existe_pas_trait.png", "over": "res://n_existe_pas.png"},
			{"kind": "sprite", "sheet": "res://n_existe_pas_planche.png"},
			{"kind": "particles", "preset": "mist", "rect": Rect2(0, 0.4, 1, 0.2)},
			{"kind": "glow", "at": Vector2(0.3, 0.3)}]}
	var alone := CinematicPlan.create(plan, 5.0)
	add_child(alone)
	assert_bool(alone.has_picture).is_false()
	assert_object(alone.fallback).is_not_null()
	alone.tick(2.0)
	alone.queue_free()
	var film := Cinematic.play(self, {"plans": [plan, plan.merged({"id": "X-02"}, true)], "end": "reveal", "restore_music": true})
	film.set_process(false)
	run(film, 2.6)
	assert_str(film.caption_text()).is_equal(phrase)
	assert_float(film.caption_alpha()).override_failure_message("la phrase se lit sur le fond uni").is_greater(0.9)
	assert_bool((film.stage_now() as CinematicPlan).has_picture).is_false()
	run(film, 6.0)   # (4 s planned, made 7.5 s long: ten words to read)
	assert_str(String(film.plan_now()["id"])).is_equal("X-02")
	run(film, 9.0)
	assert_bool(film.done).override_failure_message("le film va au bout sans peinture").is_true()


func test_toute_l_intro_se_joue_sans_ses_peintures() -> void:
	var film := Cinematic.play(self, Cinematiques.intro_sequence())
	film.set_process(false)
	var seen := []
	for i in 1000:   # 100 s (the intro: ~91 s)
		film.advance(STEP)
		if film.done:
			break
		if not seen.has(film.plan_now().get("id", "")):
			seen.append(film.plan_now().get("id", ""))
	assert_bool(film.done).is_true()
	assert_bool(film.skipped).is_false()
	assert_array(seen).contains_exactly(ids(Cinematiques.intro_sequence()))
	assert_bool(Game.flag(&"intro_vue") == true).is_true()
	await settle(film)
	await Router.fade_in(0.0)


# ------------------------------------------------------------------ « Passer »

func test_passer_deux_appuis_pose_le_drapeau_de_l_intro() -> void:
	var film := Cinematic.play(self, Cinematiques.intro_sequence())
	film.set_process(false)
	run(film, 3.0)
	film.press_skip()
	assert_bool(film.skipped).override_failure_message("un appui ne passe pas : il allume le bouton").is_false()
	assert_bool(film.skip_control().armed).is_true()
	assert_float(film.skip_control().lit).is_greater(0.0)
	run(film, 0.5)
	film.press_skip()
	assert_bool(film.skipped).override_failure_message("le deuxième appui passe").is_true()
	run(film, 1.0)
	assert_bool(film.done).is_true()
	assert_bool(Game.flag(&"intro_vue") == true).override_failure_message("intro passée : drapeau posé").is_true()
	await settle(film)
	assert_bool(is_instance_valid(film)).override_failure_message("le film s'en va").is_false()
	await Router.fade_in(0.0)


func test_un_appui_puis_trop_tard_ne_passe_pas() -> void:
	var film := Cinematic.play(self, Cinematiques.intro_sequence())
	film.set_process(false)
	run(film, 1.0)
	film.press_skip()
	run(film, CinematicSkip.LIT_S + 0.3)
	assert_bool(film.skip_control().armed).override_failure_message("le bouton s'éteint et se désarme").is_false()
	film.press_skip()
	assert_bool(film.skipped).is_false()
	film.press_skip()
	assert_bool(film.skipped).is_true()


func test_le_bouton_passer_passe_d_un_clic() -> void:
	var film := Cinematic.play(self, Cinematiques.credits_sequence())
	film.set_process(false)
	run(film, 0.5)
	film.skip_control().skip_button.pressed.emit()
	assert_bool(film.skipped).is_true()
	run(film, 1.5)
	assert_bool(film.done).is_true()


func test_suivant_finit_d_afficher_puis_tourne_la_page() -> void:
	var film := Cinematic.play(self, Cinematiques.intro_sequence())
	film.set_process(false)
	run(film, 0.5)
	assert_float(film.caption_alpha()).is_less(0.1)
	film.go_on()   # (the phrase is not there yet: it finishes appearing, nothing is skipped)
	film.advance(STEP)
	assert_str(String(film.plan_now()["id"])).override_failure_message("trop tôt : on reste sur l'image").is_equal("I-01")
	assert_float(film.caption_alpha()).override_failure_message("la phrase finit d'apparaître").is_equal(1.0)
	assert_bool(film.phrase_read()).is_true()
	film.go_on()   # (now it is there: the next picture)
	film.advance(STEP)
	assert_str(String(film.plan_now()["id"])).is_equal("I-02")
	run(film, 3.0)   # (I-02's phrase wholly shown by now: one press turns the page)
	assert_float(film.caption_alpha()).is_equal(1.0)
	film.go_on()
	film.advance(STEP)
	assert_str(String(film.plan_now()["id"])).is_equal("I-03")
	film.seek(9)   # (the card: no phrase, A turns the page once it has shown a moment)
	film.go_on()
	film.advance(STEP)
	assert_str(String(film.plan_now()["id"])).is_equal("carton")
	run(film, Cinematic.ADVANCE_AFTER)
	film.go_on()
	run(film, 0.3)
	assert_bool(film._ending).override_failure_message("après le carton : le noir de la fin").is_true()


func test_echap_maintenu_passe_tout() -> void:
	var film := Cinematic.play(self, Cinematiques.intro_sequence())
	film.set_process(false)
	run(film, 2.0)
	Input.action_press(&"cancel")
	run(film, Cinematic.HOLD_S - 0.2)
	assert_bool(film.skipped).override_failure_message("pas encore assez longtemps").is_false()
	run(film, 0.4)
	Input.action_release(&"cancel")
	assert_bool(film.skipped).override_failure_message("Échap / B maintenu : on passe").is_true()


# ------------------------------------------------------------------ the time to read

func test_chaque_phrase_a_le_temps_d_etre_lue() -> void:
	assert_float(Cinematic.reading_secs("un deux trois quatre cinq six sept huit neuf dix onze douze treize quatorze")) \
		.override_failure_message("14 mots : 6,3 s").is_equal_approx(6.3, 0.001)
	assert_float(Cinematic.reading_secs("Sous le volcan dormait un secret énorme. Et des gens masqués voulaient ses dinos, pour les faire obéir.")) \
		.override_failure_message("18 mots (I-05) : 8,1 s").is_equal_approx(8.1, 0.001)
	assert_float(Cinematic.reading_secs("Et l'île apparaît.")).override_failure_message("plancher de 3 s").is_equal(3.0)
	for seq: Dictionary in [Cinematiques.intro_sequence(), Cinematiques.end_sequence()]:
		var plans: Array = seq["plans"]
		for i in plans.size():
			var plan: Dictionary = plans[i]
			if String(plan.get("text", "")) == "":
				continue
			var fade := float(plan["fade"]) if i > 0 else float(seq["fade_in"])
			var whole := Cinematic.plan_length(plan, fade) - fade - 2.0 * (Cinematic.TEXT_DELAY + Cinematic.TEXT_RAMP)
			assert_float(whole).override_failure_message("%s : phrase lisible %.2f s < %.2f s" % [plan["id"], whole,
				Cinematic.reading_secs(plan["text"])]).is_greater_equal(Cinematic.reading_secs(plan["text"]) - 0.001)
			assert_float(Cinematic.plan_length(plan, fade)).is_greater_equal(float(plan["secs"]))


## Played as it plays (nobody touches anything), frame by frame: how long each phrase stays wholly on
## screen, and how long the films last.
func test_duree_reelle_des_deux_films() -> void:
	Game.give_starter(&"parasaurolophus")
	var intro := Cinematiques.intro_sequence()
	var film := Cinematic.play(self, intro)
	film.set_process(false)
	var elapsed := 0.0
	var full := {}
	while not film.done and elapsed < 200.0:
		film.advance(STEP)
		elapsed += STEP
		if film.caption_alpha() >= 0.999:
			var id := String(film.plan_now()["id"])
			full[id] = float(full.get(id, 0.0)) + STEP
	print("Intro : %.1f s (prévu %.1f s)" % [elapsed, Cinematic.sequence_length(intro)])
	assert_float(elapsed).override_failure_message("intro : %.1f s (60 à 95)" % elapsed).is_between(60.0, 95.0)
	assert_float(elapsed).is_equal_approx(Cinematic.sequence_length(intro), 0.35)
	for plan: Dictionary in intro["plans"]:
		if plan.has("text"):
			assert_float(float(full.get(plan["id"], 0.0))).override_failure_message("%s : %.1f s lisibles" % [plan["id"], full.get(plan["id"], 0.0)]) \
				.is_greater_equal(Cinematic.reading_secs(plan["text"]) - 2.0 * STEP)
	await settle(film)
	var end := Cinematiques.end_sequence()
	film = Cinematic.play(self, end)
	film.set_process(false)
	elapsed = 0.0
	while elapsed < 300.0:
		film.advance(STEP)
		elapsed += STEP
		var stage := film.stage_now()
		if stage is CreditsRoll and (stage as CreditsRoll).phase != "opening":
			break
	print("Fin, jusqu'au défilé des crédits (F-10 compris) : %.1f s (prévu %.1f s)" % [elapsed, Cinematic.sequence_length(end)])
	assert_float(elapsed).override_failure_message("fin hors crédits : %.1f s (70 à 130)" % elapsed).is_between(70.0, 130.0)
	assert_float(elapsed).is_equal_approx(Cinematic.sequence_length(end), 0.35)
	await Router.fade_in(0.0)


# ------------------------------------------------------------------ the end, once

func test_la_fin_une_seule_fois_et_fin_vue() -> void:
	Game.give_starter(&"ankylosaurus")
	assert_bool(Cinematiques.end_wanted()).is_true()
	Cinematiques.the_end()
	var film := Cinematic.current
	assert_object(film).is_not_null()
	assert_str(String(film.sequence["id"])).is_equal("fin")
	film.set_process(false)
	run(film, 2.0)
	film.press_skip()
	film.press_skip()
	run(film, 1.0)
	await settle(film)
	assert_bool(Game.flag(&"fin_vue") == true).override_failure_message("fin passée : fin_vue posé").is_true()
	assert_bool(Cinematiques.end_wanted()).is_false()
	Cinematiques.the_end()   # (a second time: only the « Ambrelune » card)
	assert_object(Cinematic.current).override_failure_message("la fin ne se rejoue pas").is_null()
	await Router.fade_in(0.0)


func test_la_jetee_passe_par_la_fin() -> void:
	var jetty := FileAccess.get_file_as_string("res://story/apex_jetee.gd")
	var end_at := jetty.find("static func _the_end")
	assert_int(end_at).is_greater(0)
	var body := jetty.substr(end_at, 600)
	assert_str(body).contains("await Cinematiques.the_end()")
	assert_int(body.find("Router.fade_out(2.0)")).is_less(body.find("Cinematiques.the_end()"))
	assert_int(body.find("Cinematiques.the_end()")).is_less(body.find("L'île est à vous"))


# ------------------------------------------------------------------ new game, new game+

func test_l_intro_en_nouvelle_partie_et_en_nouvelle_partie_plus() -> void:
	assert_bool(Cinematiques.intro_on_new_game(false)).is_true()
	assert_bool(Cinematiques.intro_on_new_game(true)).override_failure_message("NG+ : l'intro se rejoue").is_true()
	var boot := FileAccess.get_file_as_string("res://scenes/boot/boot.gd")
	var at_new := boot.find("Game.new_game()")
	var at_intro := boot.find("await Cinematiques.new_game_intro(")
	var at_world := boot.find("Router.go_to(WORLD)", at_intro)
	assert_int(at_intro).override_failure_message("Nouvelle partie joue l'intro").is_greater(at_new)
	assert_int(at_world).override_failure_message("puis le quai de Port-Ambre").is_greater(at_intro)
	for plus in [false, true]:
		Cinematiques.new_game_intro(self, plus)
		var film := Cinematic.current
		assert_object(film).is_not_null()
		assert_str(String(film.sequence["id"])).is_equal("intro")
		film._finish_now()


func test_revoir_l_intro_et_credits_dans_les_menus() -> void:
	var menu := FileAccess.get_file_as_string("res://ui/settings_menu.gd")
	assert_str(menu).contains("\"Revoir l'intro\"")
	assert_str(menu).contains("\"Crédits\"")
	assert_str(FileAccess.get_file_as_string("res://scenes/boot/boot.tscn")).contains("text = \"Crédits\"")
	var film := Cinematiques.replay(self, "intro")
	assert_str(String(film.sequence["end"])).override_failure_message("revue : on retrouve l'écran d'avant").is_equal("reveal")
	film._finish_now()


# ------------------------------------------------------------------ music

func test_une_musique_absente_retombe_sur_titre() -> void:
	var stream := Cinematic.music_stream("res://assets/audio/music/n_existe_pas.ogg")
	assert_object(stream).is_not_null()
	assert_str(stream.resource_path.get_file()).is_equal("titre.ogg")
	assert_object(Cinematic.music_stream("res://assets/audio/music/n_existe_pas.ogg", "")).is_null()
	for track in ["cinematique_intro_a", "cinematique_intro_b", "cinematique_fin", "credits"]:
		assert_object(Cinematic.music_stream(Cinematiques.MUSIC % track)).override_failure_message(track).is_not_null()


func test_revoir_la_fin_seulement_une_fois_le_jeu_fini() -> void:
	# Arrange : une partie neuve, la fin pas encore vue
	assert_bool(Cinematiques.replay_available("intro")).is_true()
	assert_bool(Cinematiques.replay_available("credits")).is_true()
	assert_bool(Cinematiques.replay_available("end")).is_false()
	# Act : le joueur a fini le jeu (fin_vue)
	Game.set_flag(&"fin_vue")
	# Assert
	assert_bool(Cinematiques.replay_available("end")).is_true()


func test_la_fin_rejouee_ne_repose_pas_le_drapeau() -> void:
	# Arrange : fin déjà vue, drapeau posé
	Game.give_starter(&"velociraptor")
	Game.set_flag(&"fin_vue")
	# Act : « Revoir la fin » depuis les Paramètres
	var film := Cinematiques.replay(get_tree().root, "end")
	# Assert : un film de fin, qui revient à l'écran (reveal), sans drapeau à poser ni musique perdue
	assert_object(film).is_not_null()
	assert_str(String(film.sequence.get("end", ""))).is_equal("reveal")
	assert_bool(film.sequence.has("flag")).is_false()
	film.queue_free()
