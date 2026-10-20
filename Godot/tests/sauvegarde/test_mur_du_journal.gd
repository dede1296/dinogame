extends GdUnitTestSuite
## Le mur du journal (ui/journal_pages.gd, ui/journal_wall.gd ; docs/post-game-scenes.md § N3), sans fenêtre :
## - les 40 pages d'Hélène et les 3 des Anciens se relisent (titre, texte, « — H. »), et les lire ne change
##   rien à la partie ;
## - une page trouvée se relit ; une page lue à la partie précédente (Nouvelle partie+) et pas retrouvée est
##   grise avec une coche, « déjà lue », et ne se relit pas (on ne gâche pas la partie) ; retrouvée, elle se
##   relit ; une page jamais trouvée : son numéro, sans plus ;
## - les pages grises ne comptent pas comme trouvées (ni au mur ni dans les objectifs) ;
## - B / Échap ferme le mur ; A sur une page la relit (le mur se cache le temps de la lettre).

var _wall: JournalWall


func before_test() -> void:
	Game.new_game()


func after_test() -> void:
	if is_instance_valid(_wall):
		_wall.close_wall()
	for letter in get_tree().root.get_children():
		if letter is LetterView:
			letter.queue_free()
	await await_idle_frame()
	get_tree().paused = false


func after() -> void:
	Game.new_game()


static func _page(flag: String) -> Dictionary:
	for p in JournalPages.all():
		if String(p["flag"]) == flag:
			return p
	return {}


## A NG+ in which pages 1, 2 and the Ancien of the Forêt were read before; page 2 found again.
static func _second_game() -> void:
	Game.new_game()
	Game.give_starter(&"velociraptor")
	for f in ["found_journal_1", "found_journal_2", "found_journal_ancien", "fin_vue"]:
		Game.set_flag(StringName(f))
	Game.new_game_plus(Game.to_dict())
	Game.set_flag(&"found_journal_2")


func _open() -> JournalWall:
	_wall = JournalWall.open(self)
	await await_idle_frame()
	return _wall


# ------------------------------------------------------------------ the pages

func test_les_quarante_trois_pages_se_relisent() -> void:
	# Arrange
	var flags_before := Game.flags.duplicate(true)
	var pages := JournalPages.all()
	# Act + Assert
	assert_int(pages.size()).is_equal(43)
	assert_int(JournalPages.sections()[0]["pages"].size()).is_equal(40)
	for p in pages:
		var letter := JournalPages.letter(p)
		var paragraphs: Array = letter.get("paragraphs", [])
		assert_int(paragraphs.size()).override_failure_message("%s : pas de lettre" % p["flag"]).is_greater_equal(2)
		assert_str(JournalPages.title(p)).override_failure_message("%s : pas de titre" % p["flag"]).is_not_empty()
		var want_sign := "[Le coin de la page est arraché.]" if p["flag"] == &"found_journal_34" else "— H."   # (page 34: torn)
		assert_str(String(letter.get("sign", ""))).override_failure_message("%s : signature" % p["flag"]).is_equal(want_sign)
	assert_str(JournalPages.title(_page("found_journal_1"))).is_equal("Le premier réveil")
	assert_str(String(JournalPages.letter(_page("found_journal_1"))["voice"])).ends_with("journal-1.mp3")
	assert_str(JournalPages.title(_page("found_journal_23"))).is_equal("Marraine")
	assert_str(JournalPages.title(_page("found_journal_40"))).is_equal("Ce qui dort n'est pas mort")
	assert_dict(Game.flags).override_failure_message("relire ne change rien à la partie").is_equal(flags_before)


func test_chaque_page_a_son_drapeau() -> void:
	var flags: Array = JournalPages.all().map(func(p: Dictionary) -> String: return String(p["flag"]))
	for n in range(1, 41):
		assert_array(flags).contains(["found_journal_%d" % n])
	assert_array(flags).contains(["found_journal_ancien", "found_journal_ancien_rempart", "found_journal_ancien_voix"])
	var unique := {}
	for f in flags:
		unique[f] = true
	assert_int(unique.size()).is_equal(flags.size())


func test_trouvee_deja_lue_ou_inconnue() -> void:
	# Arrange
	_second_game()
	# Assert : 2 found again, 1 and the Ancien read before, 3 never
	assert_int(JournalPages.state(_page("found_journal_2"))).is_equal(JournalPages.State.FOUND)
	assert_int(JournalPages.state(_page("found_journal_1"))).is_equal(JournalPages.State.READ_BEFORE)
	assert_int(JournalPages.state(_page("found_journal_ancien"))).is_equal(JournalPages.State.READ_BEFORE)
	assert_int(JournalPages.state(_page("found_journal_3"))).is_equal(JournalPages.State.UNKNOWN)
	assert_bool(Game.flag(&"found_journal_1") == true).override_failure_message("une page grise n'est pas trouvée").is_false()
	assert_int(Game.pebbles_found()).is_equal(0)
	assert_str(JournalWall.counts_text()).is_equal("1 page sur 40  ·  2 déjà lues à retrouver")
	# Found again: readable again.
	Game.set_flag(&"found_journal_1")
	assert_int(JournalPages.state(_page("found_journal_1"))).is_equal(JournalPages.State.FOUND)


func test_le_mur_est_propose_des_qu_il_y_a_une_page() -> void:
	assert_bool(JournalWall.available()).is_false()
	Game.set_flag(&"found_journal_5")
	assert_bool(JournalWall.available()).is_true()
	_second_game()
	Game.flags.erase("found_journal_2")
	assert_bool(JournalWall.available()).override_failure_message("pages lues avant : le mur, gris").is_true()


# ------------------------------------------------------------------ the wall

func test_les_tuiles_du_mur() -> void:
	# Arrange
	_second_game()
	# Act
	var wall := await _open()
	# Assert : 43 tiles; found = gold, readable; read before = ✓, grey, not readable; never = its number, dim
	var tiles := wall.find_children("Page_*", "Button", true, false)
	assert_int(tiles.size()).is_equal(43)
	var found := wall.find_child("Page_2", true, false) as Button
	var grey := wall.find_child("Page_1", true, false) as Button
	var never := wall.find_child("Page_3", true, false) as Button
	var ancien := wall.find_child("Page_ancien", true, false) as Button
	var other := wall.find_child("Page_ancien_voix", true, false) as Button
	assert_bool(found.disabled).is_false()
	assert_str(found.text).is_equal("2")
	assert_bool(grey.disabled).is_true()
	assert_str(grey.text).is_equal("✓ 1")
	assert_bool(never.disabled).is_true()
	assert_str(never.text).is_equal("3")
	assert_str(ancien.text).is_equal("✓ Griffe-Grise")
	assert_str(other.text).is_equal("?")
	assert_bool(get_tree().paused).override_failure_message("le jeu en pause").is_true()
	# The line under the tiles
	grey.mouse_entered.emit()
	assert_str((wall.find_child("Detail", true, false) as Label).text).contains("déjà lue").contains("Retrouve-la")
	found.focus_entered.emit()
	assert_str((wall.find_child("Detail", true, false) as Label).text).is_equal("Page 2 : « Chacun chez soi »")
	never.mouse_entered.emit()
	assert_str((wall.find_child("Detail", true, false) as Label).text).is_equal("Page 3 : pas encore trouvée.")


func test_relire_une_page_puis_fermer() -> void:
	# Arrange
	_second_game()
	var wall := await _open()
	var closed := [false]
	wall.closed.connect(func() -> void: closed[0] = true)
	# Act : A on page 2
	(wall.find_child("Page_2", true, false) as Button).pressed.emit()
	await await_idle_frame()
	# Assert : the letter over the hidden wall
	var letters := get_tree().root.get_children().filter(func(n: Node) -> bool: return n is LetterView)
	assert_int(letters.size()).is_equal(1)
	assert_bool(wall.visible).is_false()
	# A grey page: nothing.
	(wall.find_child("Page_1", true, false) as Button).pressed.emit()
	await await_idle_frame()
	assert_int(get_tree().root.get_children().filter(func(n: Node) -> bool: return n is LetterView).size()).is_equal(1)
	# The letter put away: the wall again; B closes it, the game goes on.
	(letters[0] as LetterView).closed.emit()
	await await_idle_frame()
	assert_bool(wall.visible).is_true()
	var cancel := InputEventAction.new()
	cancel.action = &"cancel"
	cancel.pressed = true
	wall._unhandled_input(cancel)
	assert_bool(closed[0]).is_true()
	assert_bool(get_tree().paused).is_false()
