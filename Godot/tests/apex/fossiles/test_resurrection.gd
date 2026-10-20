extends GdUnitTestSuite
## La résurrection au Cabinet (docs/post-game-plan.md § 2, post-game-scenes.md F3-F5), sans fenêtre :
## refus à 4 os sur 5, sans vingt larmes, avec un œuf déjà porté ; les vingt larmes consommées, l'œuf
## posé (Doré, Cronos, Plume ; 300 pas), le drapeau ; une seule fois par bête ; l'œuf des os reconnu,
## l'éclosion au niveau 45, rareté légendaire, capturé (équipe ou Cabinet) ; ce qu'Hélène dit d'abord
## (après l'éclosion, le premier os, cinq os, quatre os : une fois chaque) ; les bulles de F4 (9, sans
## le temps regardé) et leurs variantes des deuxième et troisième fois.

const F := preload("res://story/fossiles.gd")
const DF := preload("res://data/dialogue_fossiles.gd")
const SAVE_PATH := "user://test_gdunit_fossiles_resurrection.json"
const MAX_BULLES := 10

var _saved_path: String


func before() -> void:
	_saved_path = Save.path
	Save.path = SAVE_PATH   # (jamais la partie de Greg)
	# (les espèces, avant que le patch de SpeciesDB soit appliqué : test_especes_fossiles le vérifie)
	for b in F.BEASTS:
		var sp: StringName = F.SPECIES[b]
		if not SpeciesDB.PATHS.has(sp):
			SpeciesDB._cache[sp] = load("res://data/species/%s.tres" % sp)


func after() -> void:
	Save.path = _saved_path
	Game.new_game()


func before_test() -> void:
	Game.new_game()
	Game.set_flag(&"prologue_done")
	Game.give_starter(&"ankylosaurus")
	Game.set_flag(&"epilogue_fini")
	Game.set_flag(&"post_game")


static func bulles(steps: Array) -> int:
	return steps.filter(func(s: Dictionary) -> bool: return s.has("text") or s.has("text_fn")).size()


static func drapeaux(steps: Array) -> Array:
	return steps.filter(func(s: Dictionary) -> bool: return s.has("flag")).map(func(s: Dictionary) -> String: return String(s["flag"]))


func _tears(n: int) -> void:
	for i in n:
		Game.set_flag(StringName("galet_test_%02d" % i))


func _bones(beast: StringName, n: int) -> void:
	for i in n:
		Game.set_flag(F.flag_of(beast, i))
		Game.give_item(F.item_of(beast))


# ------------------------------------------------------------------ les conditions

func test_refus_a_quatre_os() -> void:
	_tears(25)
	_bones(&"titanosaure", 4)
	assert_str(String(F.cannot(&"titanosaure"))).is_equal("manque")
	assert_bool(F.resurrect(&"titanosaure")).is_false()
	assert_int(Game.tears()).override_failure_message("des larmes prises pour rien").is_equal(25)


func test_refus_sans_vingt_larmes() -> void:
	_tears(19)
	_bones(&"titanosaure", 5)
	assert_str(String(F.cannot(&"titanosaure"))).is_equal("larmes")
	assert_str(String(DF.refusal(&"larmes", Game.tears())[0]["text"])).contains("Tu en as 19")
	assert_bool(F.resurrect(&"titanosaure")).is_false()


func test_refus_si_un_oeuf_est_porte() -> void:
	_tears(40)
	_bones(&"gigantoraptor", 5)
	Game.egg = {"species": "protoceratops", "name": "Pépite", "steps": 100}
	assert_str(String(F.cannot(&"gigantoraptor"))).is_equal("oeuf")
	assert_str(String(DF.refusal(&"oeuf")[0]["text"])).contains("Un à la fois")


func test_la_resurrection_prend_vingt_larmes_et_pose_l_oeuf() -> void:
	_tears(25)
	_bones(&"kronosaurus", 5)
	assert_str(String(F.cannot(&"kronosaurus"))).is_equal("")
	assert_bool(F.resurrect(&"kronosaurus")).is_true()
	assert_int(Game.tears()).override_failure_message("les vingt larmes consommées").is_equal(5)
	assert_str(String(Game.egg.get("species"))).is_equal("kronosaurus")
	assert_str(String(Game.egg.get("name"))).is_equal("Cronos")
	assert_int(int(Game.egg.get("steps"))).is_equal(F.EGG_STEPS)
	assert_bool(Game.flag(&"ressuscite_kronosaurus")).is_true()
	assert_int(Game.item_count("os_kronosaurus")).override_failure_message("les os restent dans le sac").is_equal(5)
	assert_str(String(F.cannot(&"kronosaurus"))).override_failure_message("une seule fois").is_equal("fait")
	assert_bool(F.is_fossil_egg(Game.egg)).is_true()
	assert_bool(F.is_fossil_egg({"species": "protoceratops"})).is_false()


func test_l_eclosion_niveau_45_legendaire() -> void:
	for b in F.BEASTS:
		var sp: StringName = F.SPECIES[b]
		assert_int(int(F.EGG_LEVELS[sp])).is_equal(45)
		var d := Dino.create(sp, F.EGG_LEVELS[sp], F.EGG_NAMES[b])
		assert_int(d.level).is_equal(45)
		assert_str(d.species().rarity).is_equal("legendary")
		assert_str(d.nickname).is_equal(F.EGG_NAMES[b])
	var lines := DF.hatching(&"titanosaure", "Doré")
	assert_int(bulles(lines)).is_equal(3)
	assert_array(drapeaux(lines)).contains_exactly(["eclos_titanosaure"])
	assert_str(String(lines[2]["text"])).is_equal("Bonjour, Doré.")


# ------------------------------------------------------------------ Hélène, dans l'ordre

func test_helene_dans_l_ordre_une_fois_chaque() -> void:
	assert_bool(F.helene_step().is_empty()).override_failure_message("rien sans os").is_true()
	_bones(&"gigantoraptor", 4)
	var step := F.helene_step()
	assert_str(String(step["say"])).override_failure_message("le premier os d'abord").is_equal("premier")
	assert_str(String(step["beast"])).is_equal("gigantoraptor")
	Game.set_flag(&"helene_os_gigantoraptor")
	step = F.helene_step()
	assert_str(String(step["say"])).is_equal("manque")
	assert_int(int(step["piece"])).override_failure_message("il manque la queue").is_equal(4)
	assert_str(String(DF.missing(&"gigantoraptor", 4)[0]["text"])).contains("une bête sans queue")
	Game.set_flag(&"helene_manque_gigantoraptor")
	assert_bool(F.helene_step().is_empty()).override_failure_message("« il en manque un » une seule fois").is_true()
	_bones(&"gigantoraptor", 5)
	assert_str(String(F.helene_step()["say"])).is_equal("pret")
	Game.set_flag(&"ressuscite_gigantoraptor")
	Game.set_flag(&"eclos_gigantoraptor")
	assert_str(String(F.helene_step()["say"])).override_failure_message("après l'éclosion").is_equal("eclos")
	Game.set_flag(&"helene_eclos_gigantoraptor")
	assert_bool(F.helene_step().is_empty()).is_true()


func test_helene_premier_os_selon_la_piece() -> void:
	var line := DF.helene_first(&"titanosaure", 2)
	assert_str(String(line[0]["text"])).contains("Tu as trouvé une côte. Ce n'est pas rien, une côte")
	assert_str(String(DF.helene_first(&"titanosaure", 0)[0]["text"])).contains("Tu as trouvé la tête")
	assert_array(drapeaux(line)).contains_exactly(["helene_os_titanosaure"])
	assert_str(String(DF.helene_first(&"kronosaurus", 1)[0]["text"])).contains("battu Isaure")
	assert_str(String(DF.missing(&"kronosaurus", 3)[0]["text"])).contains("sans nageoires")


func test_f4_neuf_bulles_et_les_fois_suivantes() -> void:
	for n in 3:
		var first_half := DF.resurrection_before(&"titanosaure", n)
		var after_ := DF.resurrection_after(&"titanosaure", n)
		assert_int(bulles(first_half) + bulles(after_)).is_equal(9)
		assert_int(bulles(first_half + after_)).is_less_equal(MAX_BULLES)
		assert_array(drapeaux(after_)).contains_exactly(["ressuscite_titanosaure"])
	assert_str(String(DF.resurrection_before(&"titanosaure", 0)[4]["text"])).contains("Je ne l'ai jamais fait")
	assert_str(String(DF.resurrection_before(&"titanosaure", 1)[4]["text"])).not_contains("jamais fait")
	assert_str(String(DF.resurrection_after(&"titanosaure", 2)[3]["text"])).not_contains("première fois")
	assert_str(String(DF.resurrection_before(&"kronosaurus", 0)[0]["text"])).contains("les nageoires")
	assert_str(String(DF.resurrection_after(&"gigantoraptor", 0)[0]["text"])).contains("tacheté comme une plume")
	for b in F.BEASTS:
		assert_int(bulles(DF.helene_after(b))).is_equal(1)
		assert_array(drapeaux(DF.helene_after(b))).contains_exactly(["helene_eclos_%s" % b])


func test_le_compte_des_resurrections() -> void:
	assert_int(F.done()).is_equal(0)
	Game.set_flag(&"ressuscite_titanosaure")
	Game.set_flag(&"ressuscite_kronosaurus")
	assert_int(F.done()).is_equal(2)
