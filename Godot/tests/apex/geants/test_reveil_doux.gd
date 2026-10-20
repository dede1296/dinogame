extends GdUnitTestSuite
## Le réveil doux des géants du cratère (docs/post-game-plan.md § 1, post-game-scenes.md § G), sans fenêtre :
## l'ordre (le 4 d'abord, puis un à un : 4 → 2 → 1 → 3), « son heure » par phase (aube tout de suite, pleine
## lune, crépuscule, nuit), le conseil d'Hélène obligatoire, le bon dino en tête (nage / herbivore / Tranche /
## Résonance), le réveil (+1 cœur, le Dinodex, la plume), les scènes d'Hélène dans l'ordre (conseil, après,
## « Quatre. »), son pool, l'objectif qui dit lequel, le nombre de bulles et le dino en tête nommé.

const AG := preload("res://story/apex_geants.gd")
const DG := preload("res://data/dialogue_geants.gd")
const SAVE_PATH := "user://test_gdunit_apex_geants.json"
const MAX_BULLES := 12
const NOON := 12.0
const DUSK := 19.0
const NIGHT := 23.0
## Une nuit de pleine lune (Game.FULL_MOON_FIRST = 2) et une nuit ordinaire.
const MOON_DAY := 2
const PLAIN_DAY := 3

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
	Game.set_flag(&"epilogue_fini")
	Game.set_flag(&"post_game")
	_at(NOON)


static func _at(hour: float, day := PLAIN_DAY) -> void:
	Game.day = day
	Game.clock = hour * 60.0


static func bulles(steps: Array) -> int:
	return steps.filter(func(s: Dictionary) -> bool: return s.has("text") or s.has("text_fn")).size()


static func drapeaux(steps: Array) -> Array:
	return steps.filter(func(s: Dictionary) -> bool: return s.has("flag")).map(func(s: Dictionary) -> String: return String(s["flag"]))


static func textes(steps: Array) -> String:
	return " ".join(steps.filter(func(s: Dictionary) -> bool: return s.has("text")).map(func(s: Dictionary) -> String: return String(s["text"])))


## Un dino de l'espèce `id` en tête de l'équipe.
static func _lead(id: StringName, nick := "") -> Dino:
	var d := Dino.create(id, 45, nick)
	Game.party.insert(0, d)
	return d


## Les géants avant `n` (dans l'ordre) réveillés, et racontés à Hélène.
static func _awake_before(n: int) -> void:
	for m: int in AG.ORDER:
		if m == n:
			return
		AG.wake(m)
		Game.set_flag(AG.FLAGS[m]["raconte"])


# ------------------------------------------------------------------ l'ordre et l'heure

func test_rien_avant_le_post_game() -> void:
	Game.set_flag(&"post_game", false)
	assert_int(AG.current()).is_equal(0)
	for n in [1, 2, 3, 4]:
		assert_str(String(AG.state(n))).override_failure_message("bloc %d avant le post-game" % n).is_equal(String(AG.ASLEEP))


func test_le_4_d_abord_tout_de_suite() -> void:
	assert_array(AG.ORDER).contains_exactly([4, 2, 1, 3])
	assert_int(AG.current()).is_equal(4)
	for hour in [6.0, NOON, DUSK, NIGHT]:
		_at(hour)
		assert_str(String(AG.state(4))).override_failure_message("le petit bloc à %dh" % int(hour)).is_equal(String(AG.EYE))
	for n in [1, 2, 3]:
		assert_str(String(AG.state(n))).override_failure_message("le bloc %d avant son tour" % n).is_equal(String(AG.ASLEEP))


func test_un_a_un_dans_l_ordre() -> void:
	var seen: Array[int] = []
	while AG.current() != 0:
		var n: int = AG.current()
		seen.append(n)
		AG.wake(n)
	assert_array(seen).contains_exactly([4, 2, 1, 3])
	assert_bool(AG.all_awake()).is_true()


func test_son_heure_par_phase() -> void:
	_awake_before(2)
	_at(NOON)
	assert_str(String(AG.state(2))).override_failure_message("le grand bloc, à midi").is_equal(String(AG.CLOSED))
	_at(NIGHT, PLAIN_DAY)
	assert_str(String(AG.state(2))).override_failure_message("le grand bloc, une nuit sans pleine lune").is_equal(String(AG.CLOSED))
	_at(NIGHT, MOON_DAY)
	assert_bool(Game.is_full_moon()).is_true()
	assert_str(String(AG.state(2))).override_failure_message("le grand bloc, à la pleine lune").is_equal(String(AG.EYE))
	_awake_before(1)
	_at(NOON)
	assert_str(String(AG.state(1))).is_equal(String(AG.CLOSED))
	_at(DUSK)
	assert_str(String(AG.state(1))).override_failure_message("le bloc aux griffes, au crépuscule").is_equal(String(AG.EYE))
	_awake_before(3)
	_at(DUSK)
	assert_str(String(AG.state(3))).is_equal(String(AG.CLOSED))
	_at(NIGHT)
	assert_str(String(AG.state(3))).override_failure_message("le bloc qui ronfle, la nuit").is_equal(String(AG.EYE))


func test_conseil_obligatoire_puis_l_heure_dite() -> void:
	Game.set_flag(AG.FLAGS[4]["oeil"])
	assert_str(String(AG.state(4))).override_failure_message("l'œil vu, sans Hélène").is_equal(String(AG.TELL))
	Game.set_flag(AG.FLAGS[4]["conseil"])
	for hour in [6.0, NOON, NIGHT]:
		_at(hour)
		assert_str(String(AG.state(4))).override_failure_message("le petit à %dh : Hélène n'a pas dit d'heure" % int(hour)).is_equal(String(AG.READY))
	_awake_before(1)
	Game.set_flag(AG.FLAGS[1]["oeil"])
	Game.set_flag(AG.FLAGS[1]["conseil"])
	_at(NOON)
	assert_str(String(AG.state(1))).override_failure_message("« il dort le jour »").is_equal(String(AG.NOT_NOW))
	_at(DUSK)
	assert_str(String(AG.state(1))).is_equal(String(AG.READY))
	_at(NIGHT)
	assert_str(String(AG.state(1))).is_equal(String(AG.READY))
	_awake_before(3)
	Game.set_flag(AG.FLAGS[3]["oeil"])
	Game.set_flag(AG.FLAGS[3]["conseil"])
	_at(DUSK)
	assert_str(String(AG.state(3))).override_failure_message("« Vas-y la nuit »").is_equal(String(AG.NOT_NOW))
	_at(NIGHT)
	assert_str(String(AG.state(3))).is_equal(String(AG.READY))


# ------------------------------------------------------------------ le bon dino en tête

func test_le_bon_dino_en_tete() -> void:
	var cases := [
		[4, &"spinosaurus", true], [4, &"plesiosaurus", true], [4, &"velociraptor", false], [4, &"parasaurolophus", false],
		[2, &"parasaurolophus", true], [2, &"ankylosaurus", true], [2, &"velociraptor", false], [2, &"spinosaurus", false],
		[1, &"velociraptor", true], [1, &"therizinosaurus", true], [1, &"ankylosaurus", false], [1, &"spinosaurus", false],
		[3, &"parasaurolophus", true], [3, &"corythosaurus", true], [3, &"ankylosaurus", false], [3, &"velociraptor", false],
	]
	for c: Array in cases:
		assert_bool(AG.right_lead(c[0], Dino.create(c[1], 45))) \
			.override_failure_message("bloc %d avec %s : %s attendu" % [c[0], c[1], c[2]]).is_equal(c[2])
	assert_bool(AG.right_lead(4, null)).is_false()


func test_mauvais_dino_une_bulle_qui_le_nomme() -> void:
	for n in [1, 2, 3, 4]:
		var lines: Array = DG.wrong_lead(n, "Gros-Caillou")
		assert_int(bulles(lines)).is_equal(1)
		assert_str(textes(lines)).contains("Gros-Caillou")
		assert_str(String(lines[0]["who"])).is_equal("Chloé")
	for n in [1, 3]:
		assert_int(bulles(DG.not_now(n))).is_equal(1)
	assert_int(bulles(DG.no_advice())).is_equal(1)


# ------------------------------------------------------------------ le réveil

func test_le_reveil_un_coeur_le_dinodex_la_plume() -> void:
	var lead := _lead(&"spinosaurus", "Plouf")
	var hearts_before := lead.bond
	var hearts: int = AG.wake(4)
	assert_int(hearts).is_equal(1)
	assert_int(lead.bond).is_equal(hearts_before + 1)
	assert_bool(Game.flag(AG.FLAGS[4]["reveille"])).is_true()
	assert_str(str(Game.flag(AG.FLAGS[4]["lien"]))).override_failure_message("le nom du dino qui s'est assis").is_equal("Plouf")
	assert_bool(Game.dex_seen.has("deinocheirus")).override_failure_message("le Deinocheirus vu au Dinodex").is_true()
	assert_int(Game.item_count(AG.PLUME)).is_equal(1)
	assert_int(AG.wake(4)).override_failure_message("deux fois").is_equal(0)
	assert_int(lead.bond).is_equal(hearts_before + 1)
	assert_int(Game.item_count(AG.PLUME)).is_equal(1)
	assert_int(AG.current()).is_equal(2)


## Le correctif de DexDB (la région `apex` complète : patch_A.md) est appliqué.
static func _dex_patched() -> bool:
	return (load("res://data/dex_db.gd") as Script).get_script_method_list().any(func(m: Dictionary) -> bool: return m["name"] == "_uniques_seen")


static func _rewards() -> Array:
	return DexDB.pending_rewards().map(func(r: Dictionary) -> String: return String(r["flag"]))


func test_quatre_debout_la_region_apex_complete(_do_skip := not _dex_patched(), _skip_reason := "correctif DexDB (région apex) de patch_A.md pas encore appliqué") -> void:
	Game.mark_seen(&"souverain")
	for n: int in AG.ORDER:
		assert_array(_rewards()).override_failure_message("récompense avant le géant %d" % n).not_contains(["dex_region_apex"])
		AG.wake(n)
	assert_array(_rewards()).contains(["dex_region_apex"])


func test_chaque_geant_son_espece_au_dinodex() -> void:
	for n: int in AG.ORDER:
		AG.wake(n)
		assert_bool(Game.dex_seen.has(String(AG.SPECIES[n]))).override_failure_message("bloc %d" % n).is_true()
	assert_int(Game.item_count(AG.PLUME)).override_failure_message("une seule plume").is_equal(1)


# ------------------------------------------------------------------ Hélène

func test_helene_dans_l_ordre_conseil_apres_quatre() -> void:
	assert_bool(AG.helene_next().is_empty()).override_failure_message("rien à lui dire avant l'œil").is_true()
	Game.set_flag(AG.FLAGS[4]["oeil"])
	assert_dict(AG.helene_next()).is_equal({"scene": &"conseil", "n": 4})
	Game.set_flag(AG.FLAGS[4]["conseil"])
	assert_bool(AG.helene_next().is_empty()).is_true()
	AG.wake(4)
	assert_dict(AG.helene_next()).is_equal({"scene": &"apres", "n": 4})
	var after4: Array = AG.helene_lines(AG.helene_next())
	assert_array(drapeaux(after4)).contains_exactly_in_any_order(["geant_4_raconte", "plume_rendue"])
	Game.set_flag(AG.FLAGS[4]["raconte"])
	for n in [2, 1, 3]:
		AG.wake(n)
		Game.set_flag(AG.FLAGS[n]["raconte"])
	Game.set_flag(AG.FLAGS[3]["raconte"], false)
	var last: Array = AG.helene_lines(AG.helene_next())
	assert_array(drapeaux(last)).override_failure_message("G4 du ronfleur puis G5").contains_exactly(["geant_3_raconte", "geants_reveilles"])
	assert_int(bulles(last)).is_less_equal(MAX_BULLES)


func test_le_pool_d_helene_apres_les_quatre() -> void:
	var pool: Array = DialogueApex.HELENE_CABINET.duplicate()
	assert_array(AG.helene_pool(pool)).contains_exactly(pool)
	Game.set_flag(&"geants_reveilles")
	var later: Array = AG.helene_pool(pool)
	assert_array(later).not_contains([DialogueApex.HELENE_CABINET[0]])
	assert_array(later).contains([DG.HELENE_POOL_APRES])


# ------------------------------------------------------------------ l'objectif

func test_l_objectif_dit_lequel() -> void:
	var o: Dictionary = AG.objective()
	assert_str(String(o["text"])).contains("petit bloc")
	assert_str(String(o["zone"])).is_equal("terre_apex")
	assert_str(String(o["node"])).is_equal("BlocGeant4")
	Game.set_flag(AG.FLAGS[4]["oeil"])
	o = AG.objective()
	assert_str(String(o["text"])).contains("Hélène")
	assert_str(String(o["zone"])).is_equal("cabinet")
	Game.set_flag(AG.FLAGS[4]["conseil"])
	assert_str(String(AG.objective()["text"])).contains("nage")
	AG.wake(4)
	assert_str(String(AG.objective()["zone"])).override_failure_message("le raconter à Hélène").is_equal("cabinet")
	Game.set_flag(AG.FLAGS[4]["raconte"])
	o = AG.objective()
	assert_str(String(o["text"])).contains("grand bloc")
	assert_str(String(o["text"])).contains("pleine lune")
	assert_str(String(o["node"])).is_equal("BlocGeant2")


# ------------------------------------------------------------------ les bulles

func test_les_bulles_de_chaque_scene() -> void:
	var advice := {4: 8, 2: 7, 1: 7, 3: 8}
	var told := {4: 4, 2: 2, 1: 2, 3: 2}
	for n in [1, 2, 3, 4]:
		var eye: Array = DG.eye(n)
		assert_int(bulles(eye)).override_failure_message("G1 bloc %d" % n).is_equal(2)
		assert_array(drapeaux(eye)).contains_exactly(["geant_%d_oeil" % n])
		var g2: Array = DG.advice(n)
		assert_int(bulles(g2)).override_failure_message("G2 bloc %d" % n).is_equal(advice[n])
		assert_array(drapeaux(g2)).contains_exactly(["geant_%d_conseil" % n])
		assert_int(bulles(DG.wake(n, "Plouf"))).override_failure_message("G3 bloc %d" % n).is_equal(5)
		assert_int(bulles(DG.after(n, "Plouf"))).override_failure_message("G4 bloc %d" % n).is_equal(told[n])
		assert_str(DG.resident(n)).is_not_empty()
	var four: Array = DG.four()
	assert_int(bulles(four)).is_equal(6)
	assert_array(drapeaux(four)).contains_exactly(["geants_reveilles"])


func test_le_dino_en_tete_nomme_pas_le_dino_de_depart() -> void:
	for n in [1, 2, 3, 4]:
		var said := textes(DG.wake(n, "Plouf"))
		assert_str(said).override_failure_message("G3 bloc %d" % n).contains("Plouf")
		assert_str(said).not_contains("%s")
		assert_str(said).not_contains("Vif")
	assert_str(textes(DG.after(4, "Plouf"))).contains("Plouf")
	assert_str(textes(DG.after(3, "Plouf"))).contains("Plouf")
