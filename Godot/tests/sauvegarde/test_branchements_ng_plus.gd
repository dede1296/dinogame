extends GdUnitTestSuite
## La Nouvelle partie+ et le mur du journal BRANCHÉS dans les fichiers communs (le correctif du lot D :
## scratchpad postgame/patch_D.md), lus comme du texte : ce test échoue tant que le correctif n'est pas
## appliqué, puis passe.
## - le menu titre : « Nouvelle partie+ » (save_slots.gd, plus_from) part de la partie finie, crée la
##   nouvelle partie (Save.start_new_game_plus), joue l'intro, puis le quai ;
## - tout combat passe par Game.strengthen (dresseurs et Alphas +2, sauvages +1) avant de commencer ;
## - la fiche du Dinodex dit « Possédé à la partie précédente » ;
## - le menu du jeu ouvre le mur du journal.


static func _text(path: String) -> String:
	return FileAccess.get_file_as_string(path)


static func _body(text: String, header: String, length := 900) -> String:
	var at := text.find(header)
	return text.substr(at, length) if at >= 0 else ""


func test_le_menu_titre_lance_la_nouvelle_partie_plus() -> void:
	var boot := _text("res://scenes/boot/boot.gd")
	assert_str(boot).contains("_plus_from = screen.plus_from")
	var plus := _body(boot, "func _start_plus(")
	assert_str(plus).override_failure_message("_start_plus absent de boot.gd").is_not_empty()
	var at_create := plus.find("Save.start_new_game_plus(_plus_from, n, true)")
	var at_intro := plus.find("await Cinematiques.new_game_intro(self, true)")
	var at_world := plus.find("Router.go_to(WORLD)")
	assert_int(at_create).is_greater(0)
	assert_int(at_intro).is_greater(at_create)
	assert_int(at_world).is_greater(at_intro)
	for entry in ["func _on_load()", "func _on_new_game()"]:
		assert_str(_body(boot, entry, 700)).override_failure_message("%s : la Nouvelle partie+" % entry).contains("_start_plus(n)")
	# (the order the other tests of the title screen read stays the same)
	assert_int(boot.find("Game.new_game()")).is_less(boot.find("await Cinematiques.new_game_intro("))
	assert_int(boot.find("func _on_new_game()")).is_less(boot.find("func _start_plus("))


func test_tout_combat_passe_par_le_renfort() -> void:
	var battle := _body(_text("res://world/world.gd"), "func _battle(wild: Dino", 400)
	var at := battle.find("Game.strengthen(wild, Game.foe_kind(rules))")
	assert_int(at).override_failure_message("World._battle sans Game.strengthen").is_greater(0)
	assert_int(at).is_less(battle.find("dismount()"))


func test_le_dinodex_dit_la_partie_precedente() -> void:
	var diary := _body(_text("res://ui/dex_entry.gd"), "func _diary(", 1200)
	assert_str(diary).contains("Game.owned_before(id)").contains("Possédé à la partie précédente.")


func test_le_menu_du_jeu_ouvre_le_mur() -> void:
	var menu := _text("res://ui/settings_menu.gd")
	assert_str(menu).contains("\"Journal d'Hélène\"").contains("JournalWall.available()").contains("JournalWall.open.call_deferred(root)")
