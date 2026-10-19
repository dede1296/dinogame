extends GdUnitTestSuite
## Les vues de trois-quarts de Chloé (docs/sprites-mouvements.md § Trois-quarts de Chloé), sans fenêtre :
## - SheetFrames.diagonal_name : 8 directions, seuils (DIAGONAL_DEG), marge contre le scintillement ;
## - SheetFrames.next_view : la diagonale tient DIAGONAL_HOLD_S avant de céder à un de ses axes, et reste
##   quand on lâche les touches pendant ce temps ; un tour voulu (scène, face_towards) est immédiat ;
## - SheetFrames.character : sans planche compagnon, exactement les animations d'avant (8 : 16 images) ; avec une
##   planche compagnon synthétique, les 8 animations de diagonale (bonnes cellules, attente = 1re image,
##   droites = miroir des gauches) ;
## - SheetFrames.walk_dir : retombée sur l'axe dominant quand la diagonale manque (look sans _diag) ;
## - Outfits._merge : les diagonales d'un look (bottes:, manteau:) suivent leur préfixe.

const CELL := Vector2i(6, 8)   # une petite cellule : la planche d'essai fait 24 x 32 (4 x 4)
const FRAME := 1.0 / 60.0
const BASE_ANIMS := ["walk_down", "idle_down", "walk_left", "idle_left", "walk_right", "idle_right", "walk_up", "idle_up"]
const DIAG_ANIMS := ["walk_down_left", "idle_down_left", "walk_up_left", "idle_up_left",
	"walk_down_right", "idle_down_right", "walk_up_right", "idle_up_right"]


# ------------------------------------------------------------------ planches d'essai (en mémoire)

## Une planche de `cols` x `rows` cellules, chacune d'une couleur qui dit sa place, avec une marque
## à gauche (pour que le miroir se voie).
static func _sheet(cols: int, rows: int) -> ImageTexture:
	var image := Image.create_empty(cols * CELL.x, rows * CELL.y, false, Image.FORMAT_RGBA8)
	for r in rows:
		for c in cols:
			var at := Vector2i(c * CELL.x, r * CELL.y)
			image.fill_rect(Rect2i(at, CELL), Color8(40 * c + 20, 60 * r + 30, 90, 255))
			image.fill_rect(Rect2i(at + Vector2i(1, 2), Vector2i(1, 3)), Color.WHITE)   # la marque, à gauche
	return ImageTexture.create_from_image(image)


static func _pixels(frame: Texture2D) -> Image:
	var atlas := frame as AtlasTexture
	var image := atlas.atlas.get_image()
	if image.is_compressed():
		image.decompress()
	var region := image.get_region(Rect2i(atlas.region))
	region.clear_mipmaps()   # (get_region keeps the flag, not the smaller pictures: only the picture itself)
	return region


static func _names(frames: SpriteFrames) -> Array:
	var names := []
	for n in frames.get_animation_names():
		names.append(String(n))
	names.sort()
	return names


# ------------------------------------------------------------------ diagonal_name

func test_les_huit_directions() -> void:
	var cases := {
		Vector2(0, 1): &"down", Vector2(0, -1): &"up", Vector2(-1, 0): &"left", Vector2(1, 0): &"right",
		Vector2(-1, 1): &"down_left", Vector2(1, 1): &"down_right", Vector2(-1, -1): &"up_left", Vector2(1, -1): &"up_right",
	}
	for dir: Vector2 in cases:
		assert_str(String(SheetFrames.diagonal_name(dir))).override_failure_message("%s" % dir).is_equal(String(cases[dir]))


func test_le_seuil_de_la_diagonale_sans_direction_precedente() -> void:
	var limit := SheetFrames.DIAGONAL_DEG
	# (l'angle compté depuis l'axe horizontal ; y vers le bas de l'écran)
	assert_str(String(SheetFrames.diagonal_name(Vector2.from_angle(deg_to_rad(limit - 1.0))))).is_equal("right")
	assert_str(String(SheetFrames.diagonal_name(Vector2.from_angle(deg_to_rad(limit + 1.0))))).is_equal("down_right")
	assert_str(String(SheetFrames.diagonal_name(Vector2.from_angle(deg_to_rad(90.0 - limit + 1.0))))).is_equal("down")
	assert_str(String(SheetFrames.diagonal_name(Vector2.from_angle(deg_to_rad(90.0 - limit - 1.0))))).is_equal("down_right")
	assert_str(String(SheetFrames.diagonal_name(Vector2.from_angle(deg_to_rad(180.0 + limit + 1.0))))).is_equal("up_left")


func test_hors_diagonale_c_est_l_axe_dominant_comme_avant() -> void:
	for deg in range(0, 360, 3):
		var dir := Vector2.from_angle(deg_to_rad(float(deg)))
		var seen := SheetFrames.diagonal_name(dir)
		if not SheetFrames.is_diagonal(seen):
			assert_str(String(seen)).override_failure_message("%d°" % deg).is_equal(SheetFrames.direction_name(dir))


func test_la_marge_evite_le_scintillement_au_bord() -> void:
	var limit := SheetFrames.DIAGONAL_DEG
	var margin := SheetFrames.DIAGONAL_MARGIN_DEG
	var inside := Vector2.from_angle(deg_to_rad(limit - margin + 1.0))   # un peu sous le seuil
	var outside := Vector2.from_angle(deg_to_rad(limit + margin - 1.0))  # un peu au-dessus
	# Une diagonale montrée tient sous le seuil ; un axe montré ne cède pas juste au-dessus.
	assert_str(String(SheetFrames.diagonal_name(inside, &"down_right"))).is_equal("down_right")
	assert_str(String(SheetFrames.diagonal_name(outside, &"right"))).is_equal("right")
	# Au-delà de la marge, ça bascule.
	assert_str(String(SheetFrames.diagonal_name(Vector2.from_angle(deg_to_rad(limit - margin - 1.0)), &"down_right"))).is_equal("right")
	assert_str(String(SheetFrames.diagonal_name(Vector2.from_angle(deg_to_rad(limit + margin + 1.0)), &"right"))).is_equal("down_right")
	# Une autre diagonale avant (pas celle-ci) : pas de faveur.
	assert_str(String(SheetFrames.diagonal_name(outside, &"up_left"))).is_equal("right")


func test_sans_direction_la_precedente_reste() -> void:
	assert_str(String(SheetFrames.diagonal_name(Vector2.ZERO, &"up_left"))).is_equal("up_left")
	assert_str(String(SheetFrames.diagonal_name(Vector2.ZERO))).is_equal("down")


# ------------------------------------------------------------------ next_view (le petit temps)

func test_la_diagonale_cede_a_son_axe_apres_le_petit_temps() -> void:
	var view := SheetFrames.next_view({}, Vector2(-1, 1).normalized(), true, FRAME)
	assert_str(String(view["view"])).is_equal("down_left")
	var frames_held := 0
	while String(view["view"]) == "down_left" and frames_held < 60:
		view = SheetFrames.next_view(view, Vector2(0, 1), true, FRAME)
		frames_held += 1
	assert_str(String(view["view"])).is_equal("down")
	assert_float(frames_held * FRAME).is_between(SheetFrames.DIAGONAL_HOLD_S - FRAME, SheetFrames.DIAGONAL_HOLD_S + FRAME)


func test_touches_lachees_pendant_le_petit_temps_la_diagonale_reste() -> void:
	var view := SheetFrames.next_view({}, Vector2(-1, -1).normalized(), true, FRAME)
	view = SheetFrames.next_view(view, Vector2(0, -1), true, FRAME)   # une touche lâchée avant l'autre
	view = SheetFrames.next_view(view, Vector2(0, -1), true, FRAME)
	for i in 30:   # puis plus rien de tenu : elle s'arrête de trois-quarts dos
		view = SheetFrames.next_view(view, Vector2(0, -1), false, FRAME)
	assert_str(String(view["view"])).is_equal("up_left")


func test_un_tour_voulu_ou_un_grand_tour_est_immediat() -> void:
	var view := SheetFrames.next_view({}, Vector2(1, 1).normalized(), true, FRAME)
	# Une scène la tourne (rien de tenu) : tout de suite.
	assert_str(String(SheetFrames.next_view(view, Vector2(0, 1), false, FRAME)["view"])).is_equal("down")
	# Un grand tour (pas un des deux axes de la diagonale) : tout de suite.
	assert_str(String(SheetFrames.next_view(view, Vector2(-1, 0), true, FRAME)["view"])).is_equal("left")
	assert_str(String(SheetFrames.next_view(view, Vector2(-1, -1).normalized(), true, FRAME)["view"])).is_equal("up_left")
	# D'un axe vers une diagonale : tout de suite aussi.
	var axis := SheetFrames.next_view({}, Vector2(0, 1), true, FRAME)
	assert_str(String(SheetFrames.next_view(axis, Vector2(1, 1).normalized(), true, FRAME)["view"])).is_equal("down_right")


func test_next_view_ne_change_pas_l_etat_recu() -> void:
	var view := SheetFrames.next_view({}, Vector2(-1, 1).normalized(), true, FRAME)
	var snapshot := view.duplicate()
	SheetFrames.next_view(view, Vector2(0, 1), true, FRAME)
	SheetFrames.next_view(view, Vector2(1, 0), true, FRAME)
	assert_dict(view).is_equal(snapshot)


func test_revenir_a_la_diagonale_annule_le_petit_temps() -> void:
	var diag := Vector2(-1, 1).normalized()
	var view := SheetFrames.next_view({}, diag, true, FRAME)
	view = SheetFrames.next_view(view, Vector2(0, 1), true, FRAME)
	assert_float(float(view["hold"])).is_greater(0.0)
	view = SheetFrames.next_view(view, diag, true, FRAME)   # la touche reprise
	assert_float(float(view["hold"])).is_equal(0.0)
	# Puis une scène la fait marcher droit vers le bas : pas de diagonale gardée par erreur.
	assert_str(String(SheetFrames.next_view(view, Vector2(0, 1), false, FRAME)["view"])).is_equal("down")


# ------------------------------------------------------------------ character

## (16 images en 8 animations : marche et attente dans les 4 sens)
func test_sans_planche_compagnon_les_animations_d_avant() -> void:
	var frames := SheetFrames.character(_sheet(4, 4), 15.0)
	assert_int(frames.get_animation_names().size()).is_equal(8)
	var names := _names(frames)
	var expected := BASE_ANIMS.duplicate()
	expected.sort()
	assert_array(names).is_equal(expected)
	for dir in ["down", "left", "right", "up"]:
		assert_int(frames.get_frame_count(StringName("walk_" + dir))).is_equal(4)
		assert_int(frames.get_frame_count(StringName("idle_" + dir))).is_equal(1)


func test_une_planche_de_chloe_sans_diag_n_a_pas_de_diagonales() -> void:
	# (chloe_assise : une pose, jamais de _diag ; lue comme une planche de marche, sans erreur)
	var sheet: Texture2D = load("res://assets/art/characters/chloe_assise.png")
	assert_object(SheetFrames.diag_sheet(sheet)).is_null()
	assert_bool(SheetFrames.character(sheet).has_animation(&"walk_down_left")).is_false()


func test_le_chemin_de_la_planche_compagnon() -> void:
	assert_str(SheetFrames.diag_path("res://assets/art/characters/chloe.png")).is_equal("res://assets/art/characters/chloe_diag.png")
	assert_str(SheetFrames.diag_path("res://assets/art/characters/chloe_bottes.png")).is_equal("res://assets/art/characters/chloe_bottes_diag.png")
	assert_object(SheetFrames.diag_sheet(_sheet(4, 4))).is_null()   # (une planche en mémoire : pas de compagnon)


func test_avec_planche_compagnon_les_huit_diagonales() -> void:
	var diag := _sheet(4, 2)
	var frames := SheetFrames.character(_sheet(4, 4), 15.0, diag)
	var expected := BASE_ANIMS + DIAG_ANIMS
	expected.sort()
	assert_array(_names(frames)).is_equal(expected)
	for anim_name: String in DIAG_ANIMS:
		var anim := StringName(anim_name)
		var walk := anim_name.begins_with("walk")
		assert_int(frames.get_frame_count(anim)).override_failure_message(anim_name).is_equal(4 if walk else 1)
		assert_float(frames.get_animation_speed(anim)).is_equal(15.0 if walk else 1.0)
	# Les gauches : les cellules de la planche compagnon, ligne 0 vers le bas, ligne 1 vers le haut.
	for row in 2:
		var dir: String = ["down", "up"][row]
		for i in 4:
			var frame := frames.get_frame_texture(StringName("walk_%s_left" % dir), i) as AtlasTexture
			assert_object(frame.atlas).is_same(diag)
			assert_vector(frame.region.position).is_equal(Vector2(i * CELL.x, row * CELL.y))
			assert_vector(frame.region.size).is_equal(Vector2(CELL))
		var idle := frames.get_frame_texture(StringName("idle_%s_left" % dir), 0) as AtlasTexture
		assert_vector(idle.region.position).is_equal(Vector2(0, row * CELL.y))   # l'attente : la 1re image


func test_les_droites_sont_le_miroir_des_gauches() -> void:
	var frames := SheetFrames.character(_sheet(4, 4), 15.0, _sheet(4, 2))
	for dir in ["down", "up"]:
		for kind in ["walk", "idle"]:
			var left := StringName("%s_%s_left" % [kind, dir])
			var right := StringName("%s_%s_right" % [kind, dir])
			assert_int(frames.get_frame_count(right)).is_equal(frames.get_frame_count(left))
			for i in frames.get_frame_count(left):
				var seen := _pixels(frames.get_frame_texture(left, i))
				seen.flip_x()
				var mirrored := _pixels(frames.get_frame_texture(right, i))
				assert_bool(mirrored.get_data() == seen.get_data()).override_failure_message("%s %d" % [right, i]).is_true()


# ------------------------------------------------------------------ walk_dir, looks

func test_retombee_sur_l_axe_dominant_quand_la_diagonale_manque() -> void:
	var view := SheetFrames.next_view({}, Vector2(-1, 1).normalized(), true, FRAME)
	var facing := Vector2(-0.8, 0.6)   # (dominant : la gauche)
	var plain := SheetFrames.character(_sheet(4, 4), 15.0)
	assert_str(SheetFrames.walk_dir(plain, "", view, facing)).is_equal("left")
	var with_diag := SheetFrames.character(_sheet(4, 4), 15.0, _sheet(4, 2))
	assert_str(SheetFrames.walk_dir(with_diag, "", view, facing)).is_equal("down_left")
	# Un look sans trois-quarts (bottes: sans _diag) : l'axe dominant, même si la base les a.
	Outfits._merge(with_diag, SheetFrames.character(_sheet(4, 4), 15.0), Outfits.BOOTS)
	assert_str(SheetFrames.walk_dir(with_diag, Outfits.BOOTS, view, facing)).is_equal("left")
	# Rien de choisi encore : l'axe dominant.
	assert_str(SheetFrames.walk_dir(with_diag, "", {}, facing)).is_equal("left")


func test_les_diagonales_d_un_look_suivent_son_prefixe() -> void:
	var frames := SheetFrames.character(_sheet(4, 4), 15.0)
	Outfits._merge(frames, SheetFrames.character(_sheet(4, 4), 15.0, _sheet(4, 2)), Outfits.COAT)
	for anim_name: String in DIAG_ANIMS:
		assert_bool(frames.has_animation(StringName(Outfits.COAT + anim_name))).override_failure_message(anim_name).is_true()
		assert_bool(frames.has_animation(StringName(anim_name))).is_false()   # (la base n'en a pas)
	var view := SheetFrames.next_view({}, Vector2(1, -1).normalized(), true, FRAME)
	assert_str(SheetFrames.walk_dir(frames, Outfits.COAT, view, Vector2(1, -1))).is_equal("up_right")
	assert_str(SheetFrames.walk_dir(frames, "", view, Vector2(1, -1))).is_equal("up")


func test_les_planches_de_chloe_ont_leurs_diagonales_si_et_seulement_si_dessinees() -> void:
	# (l'agent images livre chloe_diag.png… en parallèle : vrai avant comme après)
	for sheet_name in ["chloe", "chloe_bottes", "chloe_manteau"]:
		var path := "res://assets/art/characters/%s.png" % sheet_name
		var drawn := ResourceLoader.exists(SheetFrames.diag_path(path))
		var frames := SheetFrames.character(load(path), 15.0)
		assert_bool(frames.has_animation(&"walk_down_left")).override_failure_message(sheet_name).is_equal(drawn)
		assert_bool(frames.has_animation(&"walk_up_right")).override_failure_message(sheet_name).is_equal(drawn)
		assert_int(frames.get_animation_names().size()).is_equal(16 if drawn else 8)
		if drawn:   # (la vraie planche, importée : son miroir se lit aussi)
			var seen := _pixels(frames.get_frame_texture(&"idle_up_left", 0))
			seen.flip_x()
			var mirrored := _pixels(frames.get_frame_texture(&"idle_up_right", 0))
			assert_vector(Vector2(mirrored.get_size())).is_equal(Vector2(seen.get_size()))
			assert_bool(mirrored.get_data() == seen.get_data()).override_failure_message(sheet_name).is_true()
