extends GdUnitTestSuite
## La lave du chapitre 8 (Lava, LavaField, Heat, Player), sans fenêtre : la logique de
## tools/test_lave_volcan.gd sans la marche au clavier ni les captures. La même petite zone d'essai
## (une coulée en rectangles « lave_cases », une en image « lave », une qui se retire « lave_retrait ») ;
## Chloé (player.tscn) y est posée par téléportation, et ce que sa physique ferait est appelé
## directement (masque, lave sous ses pieds, poussée contre la coulée) ou demandé au moteur physique
## (test_move) : rien n'est affiché, aucune touche n'est simulée.
## Les zones de regions/volcan/*.tscn sont ouvertes sans être affichées (Region.open_for_preview).

const TILE := 48.0
const PLAN := [
	"rrrrrrrrrrrrrrrrrrrrrrrrrr",
	"rrrrrrrrrrrrrrrrrrrrrrrrrr",
	"rrrrrrrrrrrrrrrrrrrrrrrrrr",
	"rrrrrrrrrrrrrrrrrrrrrrrrrr",
	"rrrrrrrrrrrrrrrrrrrrrrrrrr",
	"rrrrrrrrrrrrrrrrrrrrrrrrrr",
	"rrrrrrrrrrrrrrrrrrrrrrrrrr",
	"rrrrrrrrrrrrrrrrrrrrrrrrrr",
]
const FLOW_A := Rect2i(8, 0, 4, 8)     # « lave_cases »
const FLOW_B_X := Vector2i(15, 16)     # « lave » (image), colonnes
const RETREAT := Rect2i(20, 0, 2, 8)   # « lave_retrait »
const RETREAT_FLAG := &"test_lave_retiree"
const ROW := 3.5
const ZONES := ["champs_cendres", "forges_ombre", "coulees_lave", "sanctuaire_magma", "porte_cratere"]
const SAVE_PATH := "user://test_gdunit_lave_save.json"
const STEP := 1.0 / 60.0

var _saved_path: String


func before() -> void:
	_saved_path = Save.path
	Save.path = SAVE_PATH   # (jamais la partie de Greg)


func after() -> void:
	Save.path = _saved_path
	Game.new_game()


func before_test() -> void:
	Game.new_game()
	Game.give_starter(&"velociraptor")
	Game.set_flag(&"prologue_done")
	Game.set_flag(&"tuto_commandes")


func after_test() -> void:
	await _close_dialogue()


# ------------------------------------------------------------------ (a) les règles

func test_cuir_de_feu_pierre_et_feu_adultes() -> void:
	var cases := [[&"saichania", 44, true], [&"ankylosaurus", 20, true], [&"stygimoloch", 30, true], [&"daspletosaurus", 46, true],
		[&"trex_magma", 48, true], [&"allosaurus", 20, true], [&"velociraptor", 40, false], [&"styracosaurus", 44, false],
		[&"plesiosaurus", 40, false], [&"pteranodon", 40, false]]
	for c: Array in cases:
		var d := Dino.create(c[0], c[1])
		assert_bool(Abilities.usable(d, Lava.ABILITY)).override_failure_message(
			"%s niv. %d (%s) : Cuir de feu %s attendu" % [c[0], c[1], d.type(), "oui" if c[2] else "non"]).is_equal(c[2])
		if c[2]:
			assert_str(Lava.type_word(d)).override_failure_message("%s : type %s, ni Pierre ni Feu" % [c[0], d.type()]).is_not_empty()


func test_un_jeune_a_le_cuir_mais_ne_porte_pas() -> void:
	var young := Dino.create(&"saichania", 8)
	assert_bool(Abilities.has(young, Lava.ABILITY)).override_failure_message("un Saichania niv. 8 n'a pas le Cuir de feu").is_true()
	assert_bool(Abilities.usable(young, Lava.ABILITY)).override_failure_message("un Saichania niv. 8 porte déjà Chloé (adulte au niv. %d)" % Abilities.ADULT_LEVEL).is_false()


func test_dino_de_tete_et_qui_pourrait() -> void:
	assert_bool(Lava.can_cross()).override_failure_message("Vif (raptor) en tête passe la lave").is_false()
	assert_object(Lava.walker()).is_null()
	assert_str(Lava.who_could()).override_failure_message("personne : « %s »" % Lava.who_could()).is_equal(Lava.NOBODY)
	Game.party.append(Dino.create(&"saichania", 44, "Caillasse"))
	assert_str(Lava.who_could()).override_failure_message("dans l'équipe : « %s »" % Lava.who_could()) \
		.starts_with("Caillasse (Pierre) a le cuir pour : mets-le en tête")
	assert_bool(Lava.can_cross()).override_failure_message("le Saichania n'est pas en tête : seul le dino de tête porte").is_false()
	Game.party.pop_back()
	Game.box.append(Dino.create(&"allosaurus", 30, "Mastoc"))
	assert_str(Lava.who_could()).override_failure_message("au Cabinet : « %s »" % Lava.who_could()).contains("Mastoc (Feu)").contains("Cabinet")
	Game.box.clear()
	var young := Dino.create(&"saichania", 8, "Gravier")
	Game.party.insert(0, young)
	assert_str(Lava.who_could()).override_failure_message("un jeune en tête : « %s »" % Lava.who_could()).contains("trop jeune")
	Game.party.pop_front()
	var caillasse := Dino.create(&"saichania", 44, "Caillasse")
	Game.add_caught(caillasse)
	Game.set_lead(Game.party.find(caillasse))
	assert_bool(Lava.can_cross()).override_failure_message("le Saichania en tête ne passe pas").is_true()
	assert_object(Lava.walker()).is_same(caillasse)


func test_textes_lave_bloquee_et_lave_franchie() -> void:
	var blocked := Lava.blocked_lines()
	assert_int(blocked.size()).is_equal(3)
	assert_str(String(blocked[2]["text"])).override_failure_message("lave_bloquee ne dit pas qui pourrait").is_equal(Lava.who_could())
	var lines := Lava.crossed_lines(Dino.create(&"saichania", 44, "Caillasse"))
	assert_int(lines.size()).override_failure_message("lave_franchie : %d lignes au lieu de 4" % lines.size()).is_equal(4)
	assert_str(String(lines[0]["text"])).contains("Caillasse")


# ------------------------------------------------------------------ les métas lues par Lava / LavaField

func test_metas_de_la_zone_d_essai_lues() -> void:
	var region := _zone()   # (pas dans l'arbre : rien ne s'affiche ni ne bouge)
	assert_bool(Lava.has_lava(region)).is_true()
	var f := Lava.field(region)
	assert_object(f).is_not_null()
	assert_int(f.cell_count()).override_failure_message("cases franchissables : %d" % f.cell_count()).is_equal(FLOW_A.get_area() + 2 * PLAN.size())
	assert_bool(f.is_crossable(_px(FLOW_A.position.x + 1.5))).override_failure_message("« lave_cases » pas lue").is_true()
	assert_bool(f.is_crossable(_px(FLOW_B_X.x + 0.5))).override_failure_message("« lave » (image) pas lue").is_true()
	assert_bool(f.is_crossable(_px(RETREAT.position.x + 0.5))).override_failure_message("la lave qui se retire se franchit").is_false()
	assert_bool(f.is_lava(_px(3.5))).override_failure_message("de la lave sur la roche").is_false()
	assert_float(f.distance_tiles(_px(FLOW_A.position.x - 0.5))).is_equal_approx(1.0, 0.01)
	assert_float(Lava.near(region, _px(FLOW_A.position.x + 0.5))).is_equal_approx(1.0, 0.01)
	region.free()


func test_metas_des_zones_du_volcan_lues() -> void:
	var with_lava := 0
	for zone: String in ZONES:
		var path := "res://regions/volcan/%s.tscn" % zone
		assert_bool(ResourceLoader.exists(path)).override_failure_message("%s : zone pas construite" % zone).is_true()
		if not ResourceLoader.exists(path):
			continue
		var r := Region.open_for_preview(path)
		var f := Lava.field(r)
		if f == null or f.cell_count() == 0:
			prints("   %s : pas de lave (%s)" % [zone, "pas de méta" if f == null else "masque vide"])
			r.free()
			continue
		with_lava += 1
		var img: Image = r.get_meta(Lava.META, null)
		if img and not r.has_meta(Lava.META_CELLS):
			var white := LavaField.cells_of(img, []).size()
			assert_int(f.cell_count()).override_failure_message("%s : %d cases lues, %d blanches dans l'image « lave »" % [zone, f.cell_count(), white]).is_equal(white)
		var bad := 0
		for c: Vector2i in f.get("_cells"):
			var kind: StringName = r.surface_at((Vector2(c) + Vector2(0.5, 0.5)) * TILE)
			if kind == &"water" or kind == &"forest":
				bad += 1
		assert_int(bad).override_failure_message("%s : %d cases de lave sur l'eau ou les bois (sur %d)" % [zone, bad, f.cell_count()]).is_equal(0)
		r.free()
	assert_int(with_lava).override_failure_message("aucune zone du Volcan n'a de lave").is_greater(0)


func test_coulees_lave_se_retire_au_drapeau_lave_retiree() -> void:
	assert_str(String(Lava.RETREAT_FLAG)).is_equal("lave_retiree")
	var r := Region.open_for_preview("res://regions/volcan/coulees_lave.tscn")
	assert_bool(r.has_meta(Lava.META_RETREAT)).override_failure_message("coulees_lave : pas de méta « lave_retrait » (le chemin du cratère)").is_true()
	var f := Lava.field(r)
	assert_int((f.get("_retreat") as Dictionary).size()).override_failure_message("coulees_lave : « lave_retrait » vide").is_greater(0)
	assert_str(String(f.get("_retreat_flag"))).override_failure_message("coulees_lave : la lave se retire au drapeau %s" % f.get("_retreat_flag")).is_equal("lave_retiree")
	r.free()


# ------------------------------------------------------------------ (b) à pied : bloquée, lave_bloquee une fois

func test_a_pied_chloe_bloquee_et_lave_bloquee_une_fois() -> void:
	var region := _zone_in_tree()
	var player := await _chloe(region, FLOW_A.position.x - 0.3)   # (au bord : là où le mur de lave l'arrête)
	var hp := _party_hp()
	player._update_water_mask()
	assert_int(player.collision_mask & Lava.LAYER).override_failure_message("à pied avec Vif, la lave n'arrête pas Chloé (masque)").is_equal(Lava.LAYER)
	assert_bool(player.test_move(player.global_transform, Vector2(TILE * 1.5, 0))) \
		.override_failure_message("à pied avec Vif, rien n'arrête Chloé au bord de la coulée").is_true()
	_push(player, Vector2.RIGHT, 2.0)
	assert_bool(player.get("_lava_told")).override_failure_message("pousser contre la coulée : `lave_bloquee` n'est pas dit").is_true()
	assert_bool(Dialogue.active).override_failure_message("`lave_bloquee` : pas de dialogue").is_true()
	assert_str((Dialogue.get("_text") as RichTextLabel).text).starts_with("La coulée barre tout le passage")
	await _close_dialogue()
	_push(player, Vector2.RIGHT, 2.0)
	assert_bool(Dialogue.active).override_failure_message("`lave_bloquee` redit dans la même zone").is_false()
	assert_int(_party_hp()).override_failure_message("des PV perdus au bord de la lave").is_equal(hp)


# ------------------------------------------------------------------ (c) sur le dos d'un dino de pierre en tête

func test_sur_le_dos_du_saichania_lave_franchie_une_fois() -> void:
	var region := _zone_in_tree()
	var saichania := Dino.create(&"saichania", 44, "Caillasse")
	Game.add_caught(saichania)
	Game.set_lead(Game.party.find(saichania))
	var player := await _chloe(region, FLOW_A.position.x - 0.6)
	var companion := _companion(region, player)
	player._update_water_mask()
	assert_int(player.collision_mask & Lava.LAYER).override_failure_message("Saichania en tête : la lave arrête encore Chloé (masque)").is_equal(0)
	assert_bool(player.test_move(player.global_transform, Vector2(TILE * 1.5, 0))) \
		.override_failure_message("Saichania en tête : quelque chose arrête Chloé au bord de la coulée").is_false()
	_put(player, FLOW_A.position.x + 1.5)
	assert_object(player.lava_walker).override_failure_message("sur la coulée, Chloé ne monte pas sur le dos du Saichania").is_same(saichania)
	assert_bool(companion.carrying()).override_failure_message("son dino ne la porte pas").is_true()
	assert_object(companion.dino).override_failure_message("le compagnon n'est pas le Saichania").is_same(saichania)
	assert_bool(Game.flag(Lava.FLAG_CROSSED)).override_failure_message("`lave_franchie` : pas de drapeau").is_true()
	assert_bool(Dialogue.active).override_failure_message("`lave_franchie` : pas de dialogue").is_true()
	await _close_dialogue()
	_put(player, FLOW_A.end.x + 0.8)
	assert_object(player.lava_walker).override_failure_message("sur la roche, Chloé reste sur son dos").is_null()
	assert_bool(companion.carrying()).override_failure_message("sur la roche, son dino la porte encore").is_false()
	_put(player, FLOW_B_X.x + 0.5)
	assert_object(player.lava_walker).override_failure_message("la coulée en image (méta « lave ») ne se franchit pas").is_same(saichania)
	assert_bool(Dialogue.active).override_failure_message("`lave_franchie` redit").is_false()
	_put(player, FLOW_B_X.y + 1.8)
	assert_object(player.lava_walker).override_failure_message("de nouveau sur la roche, toujours sur son dos").is_null()


# ------------------------------------------------------------------ (d) la lave qui se retire

func test_la_lave_profonde_tient_jusqu_au_drapeau() -> void:
	var region := _zone_in_tree()
	var saichania := Dino.create(&"saichania", 44, "Caillasse")
	Game.add_caught(saichania)
	Game.set_lead(Game.party.find(saichania))
	Game.set_flag(Lava.FLAG_CROSSED)   # (déjà franchie : pas de dialogue)
	var player := await _chloe(region, RETREAT.position.x - 0.6)
	var f := Lava.field(region)
	player._update_water_mask()
	assert_bool(f.retreat_holds()).override_failure_message("la lave qui se retire ne tient pas avant son drapeau").is_true()
	assert_bool(f.is_lava(_px(RETREAT.position.x + 0.5))).is_true()
	assert_bool(player.test_move(player.global_transform, Vector2(TILE * 1.5, 0))) \
		.override_failure_message("même sur le dos d'un dino de pierre, la lave profonde n'arrête pas Chloé").is_true()
	Game.set_flag(RETREAT_FLAG)
	assert_bool(f.retreat_holds()).override_failure_message("le drapeau posé : la lave ne se retire pas").is_false()
	assert_bool(f.is_lava(_px(RETREAT.position.x + 0.5))).override_failure_message("le drapeau posé : encore de la lave").is_false()
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_bool(player.test_move(player.global_transform, Vector2(TILE * 3.0, 0))) \
		.override_failure_message("le drapeau posé : Chloé ne passe toujours pas").is_false()


# ------------------------------------------------------------------ (e) la chaleur légère, sans dégâts

func test_chaleur_a_pied_pas_sur_le_dos_et_sans_degats() -> void:
	var region := _zone_in_tree()
	var saichania := Dino.create(&"saichania", 44, "Caillasse")
	Game.add_caught(saichania)
	Game.set_flag(Lava.FLAG_CROSSED)
	var player := await _chloe(region, FLOW_A.position.x - 0.7)
	var heat: Heat = player.heat
	heat.level = 0.0
	assert_float(heat.warmth()).override_failure_message("à pied près de la lave : pas de chaleur").is_greater(0.0)
	for i in 4:
		heat._process(0.25)
	assert_float(heat.level).override_failure_message("à pied près de la lave, la jauge ne monte pas (%.3f)" % heat.level).is_greater(0.03)
	assert_bool((heat.get("_gauge") as Control).visible).override_failure_message("la jauge ne se voit pas").is_true()
	var hp := _party_hp()
	heat.level = 0.999
	var cool := heat.cool_spot()
	assert_bool(cool != Vector2.INF).override_failure_message("aucune case fraîche où reculer").is_true()
	assert_float(Lava.field(region).distance_tiles(cool)).is_greater_equal(Heat.BACK_TILES)
	heat._process(0.25)
	var toast := get_tree().root.get_node_or_null("Toast")
	var said := toast != null and toast.find_children("*", "Label", true, false).any(func(l: Label) -> bool: return l.text == Heat.SAY_HOT)
	assert_bool(said).override_failure_message("pleine : pas de « Trop chaud ! »").is_true()
	assert_bool(player.get("_away_to") != Vector2.INF).override_failure_message("pleine : Chloé ne recule pas").is_true()
	for i in 240:   # (sa marche vers la roche fraîche : 4 s de jeu, sans attendre)
		player._physics_process(STEP)
		if player.get("_away_to") == Vector2.INF:
			break
	var d := Lava.field(region).distance_tiles(player.global_position)
	assert_float(d).override_failure_message("Chloé n'a pas reculé d'elle-même (à %.1f cases de la lave)" % d).is_greater_equal(3.0)
	assert_int(_party_hp()).override_failure_message("la chaleur a fait perdre des PV").is_equal(hp)
	Game.set_lead(Game.party.find(saichania))
	_put(player, FLOW_A.position.x + 1.5)
	assert_object(player.lava_walker).is_same(saichania)
	assert_float(heat.warmth()).override_failure_message("sur le dos du Saichania, sur la lave même : de la chaleur").is_equal(0.0)


# ------------------------------------------------------------------ le vol interdit, les sauvages

func test_vol_interdit_dans_les_cinq_zones() -> void:
	Game.set_flag(Vol.FLAG)
	Game.give_item(Vol.ITEM)
	Game.add_caught(Dino.create(&"pteranodon", 44, "Ptéro"))
	for zone: String in ZONES:
		var region := Region.open_for_preview("res://regions/volcan/%s.tscn" % zone)
		assert_bool(bool(region.get_meta(Vol.NO_FLIGHT_META, false))).override_failure_message("%s : pas de méta « vol_interdit »" % zone).is_true()
		var world: FakeWorld = auto_free(FakeWorld.new())
		world.region = region
		world.player = auto_free(load("res://actors/player.tscn").instantiate())
		add_child(world)
		# (« forbidden » : la méta ; le sanctuaire, une salle fermée, dit d'abord « indoor » : pas de vol non plus)
		var problem := Vol.take_off_problem(world)
		assert_bool(problem in ["forbidden", "indoor"]).override_failure_message("%s : le vol n'est pas interdit (raison : « %s »)" % [zone, problem]).is_true()
		region.free()


func test_les_sauvages_heurtent_la_lave() -> void:
	var wild: Node = auto_free(load("res://actors/wild_dino.tscn").instantiate())
	assert_int(wild.collision_mask & Lava.LAYER).override_failure_message("les dinos sauvages traversent la lave (couche %d absente de leur masque)" % Lava.LAYER).is_equal(Lava.LAYER)


# ------------------------------------------------------------------ outils

## Le monde vu par Vol.take_off_problem : Chloé, sa zone, pas de changement de zone en cours.
class FakeWorld extends Node:
	var player: Player
	var region: Region
	@warning_ignore("unused_private_class_variable")
	var _changing_zone := false   # (lu par Vol : world.get(&"_changing_zone"))


## La zone d'essai (hors de l'arbre).
func _zone() -> Region:
	var region: Region = load("res://tools/zone_builder.gd").region(&"test_lave", "Essai", "Coulées", Vector2i(42, 44), PLAN)
	region.set_meta(Lava.META_CELLS, [FLOW_A])
	var img := Image.create_empty(PLAN[0].length(), PLAN.size(), false, Image.FORMAT_L8)
	for y in PLAN.size():
		for x in range(FLOW_B_X.x, FLOW_B_X.y + 1):
			img.set_pixel(x, y, Color.WHITE)
	region.set_meta(Lava.META, img)
	region.set_meta(Lava.META_RETREAT, [RETREAT])
	region.set_meta(Lava.META_RETREAT_FLAG, RETREAT_FLAG)
	return region


## La zone d'essai dans l'arbre (ses murs de lave existent pour la physique), jamais affichée.
func _zone_in_tree() -> Region:
	var region := _zone()
	add_child(auto_free(region))
	Lava.field(region)
	return region


## Chloé dans la zone, à la colonne `x` (cases) : sa physique et sa chaleur arrêtées (on les appelle).
func _chloe(region: Region, x: float) -> Player:
	var player: Player = load("res://actors/player.tscn").instantiate()
	region.entities.add_child(player)
	player.surface_at = region.surface_at
	player.set_physics_process(false)
	player.heat.set_process(false)
	player.teleport(_px(x))
	await get_tree().physics_frame   # (les murs de lave enregistrés pour test_move)
	return player


func _companion(region: Region, player: Player) -> Node2D:
	var companion: Node2D = load("res://actors/companion.tscn").instantiate()
	companion.player = player
	region.entities.add_child(companion)
	companion.set_physics_process(false)
	companion.set_process(false)
	return companion


## Chloé posée à la colonne `x` : ce que sa physique ferait de la lave sous ses pieds.
func _put(player: Player, x: float) -> void:
	player.teleport(_px(x))
	player._update_water_mask()
	player._update_lava()


## Elle pousse contre ce qui l'arrête pendant `seconds` (sans avancer).
func _push(player: Player, dir: Vector2, seconds: float) -> void:
	for i in int(seconds / STEP):
		player._watch_lava(dir, 0.0, STEP)


func _px(x: float) -> Vector2:
	return Vector2(x, ROW) * TILE


func _party_hp() -> int:
	var total := 0
	for d in Game.party:
		total += d.hp
	return total


## Ferme le dialogue en cours, comme des pressions sur « interagir ».
func _close_dialogue() -> void:
	for i in 600:
		if not Dialogue.active:
			return
		Dialogue.set("_advance_requested", true)
		await get_tree().process_frame
