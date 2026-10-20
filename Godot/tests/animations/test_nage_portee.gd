extends GdUnitTestSuite
## Chloé couchée sur le dos de son nageur (actors/swim_rider.gd ; docs/sprites-mouvements.md, « Nageur »), sans
## fenêtre : la planche `<espèce>_nage.png` (le Kronosaurus ressuscité, lot B') est reconnue, pas celle d'une espèce
## qui n'en a pas ; ses images (toutes les cases, dans l'ordre, au tempo de la nage de profil) ; à l'écran, le
## nageur garde la taille et la ligne de ventre de sa planche de profil (même longueur dessinée, même bas) ; elle ne
## se montre que de profil (de face, de dos : la selle marine, Saddle).

const SR := preload("res://actors/swim_rider.gd")
const KRONO := &"kronosaurus"
## Tolérances (px de la planche de profil, à l'échelle 1).
const LENGTH_TOLERANCE := 1.0
const FEET_TOLERANCE := 0.5


static func _sp(id: StringName) -> DinoSpecies:
	return SpeciesDB.get_species(id)


## La place de l'image dans le nœud, comme Companion.refresh la pose (centrée sur offset, 0,46 d'une case de profil).
static func _offset(sp: DinoSpecies) -> Vector2:
	return Vector2(0.0, -sp.sheet.get_height() / float(sp.sheet_rows) * 0.46)


func test_la_planche_du_kronosaurus_est_reconnue() -> void:
	assert_bool(SR.drawn(_sp(KRONO))).override_failure_message("dinos/kronosaurus_nage.png pas trouvée (importée ?)").is_true()
	for id: StringName in [&"plesiosaurus", &"baryonyx", &"spinosaurus", &"archelon"]:
		assert_bool(SR.drawn(_sp(id))).override_failure_message("%s n'a pas de planche de nage" % id).is_false()


func test_les_images_de_la_nage_portee() -> void:
	var sp := _sp(KRONO)
	var frames := SheetFrames.dino(sp)
	SR.add_to(frames, sp)
	SR.add_to(frames, sp)   # (deux fois : rien en double)
	assert_bool(frames.has_animation(SR.SWIM)).is_true()
	var count := sp.sheet_columns * sp.sheet_rows
	assert_int(frames.get_frame_count(SR.SWIM)).is_equal(count)
	assert_bool(frames.get_animation_loop(SR.SWIM)).is_true()
	assert_float(frames.get_animation_speed(SR.SWIM)).is_equal_approx(sp.walk_fps * SheetFrames.DINO_WALK_TEMPO, 0.01)
	var sheet: Texture2D = load(SR.SHEET % sp.id)
	var cell := Vector2(sheet.get_width() / float(sp.sheet_columns), sheet.get_height() / float(sp.sheet_rows))
	for i in count:
		var frame := frames.get_frame_texture(SR.SWIM, i) as AtlasTexture
		assert_object(frame).is_not_null()
		assert_object(frame.atlas).is_same(sheet)
		var at := Vector2((i % sp.sheet_columns) * cell.x, floori(i / float(sp.sheet_columns)) * cell.y)
		assert_vector(frame.region.position).override_failure_message("image %d : case %s" % [i, frame.region]).is_equal(at)
		assert_vector(frame.region.size).is_equal(cell)


func test_sans_planche_rien_n_est_ajoute() -> void:
	var sp := _sp(&"plesiosaurus")
	var frames := SheetFrames.dino(sp)
	SR.add_to(frames, sp)
	assert_bool(frames.has_animation(SR.SWIM)).is_false()
	assert_dict(SR.fit(sp, _offset(sp))).is_empty()


func test_meme_longueur_et_meme_ventre_que_de_profil() -> void:
	var sp := _sp(KRONO)
	var offset := _offset(sp)
	var fit := SR.fit(sp, offset)
	assert_dict(fit).contains_keys(["scale", "shift"])
	var k: float = fit["scale"]
	var shift: Vector2 = fit["shift"]
	var side_cell := Vector2(sp.sheet.get_width() / float(sp.sheet_columns), sp.sheet.get_height() / float(sp.sheet_rows))
	var side := SheetFrames.drawn_rect(sp.sheet, Rect2(Vector2.ZERO, side_cell))
	var sheet: Texture2D = load(SR.SHEET % sp.id)
	var swim_cell := Vector2(sheet.get_width() / float(sp.sheet_columns), sheet.get_height() / float(sp.sheet_rows))
	var swim := SheetFrames.drawn_rect(sheet, Rect2(Vector2.ZERO, swim_cell))
	assert_float(swim.size.x * k).override_failure_message("longueur dessinée %.1f, de profil %.1f" % [swim.size.x * k, side.size.x]) \
		.is_equal_approx(side.size.x, LENGTH_TOLERANCE)
	# Le bas dessiné (le ventre, les nageoires), dans le nœud : de profil, et avec Chloé dessus (mise à l'échelle k, décalée).
	var side_bottom := offset.y - side_cell.y / 2.0 + side.end.y
	var swim_bottom := k * (offset.y - swim_cell.y / 2.0 + swim.end.y) + shift.y
	assert_float(swim_bottom).override_failure_message("bas %.2f, de profil %.2f" % [swim_bottom, side_bottom]).is_equal_approx(side_bottom, FEET_TOLERANCE)
	var side_middle := offset.x - side_cell.x / 2.0 + side.get_center().x
	var swim_middle := k * (offset.x - swim_cell.x / 2.0 + swim.get_center().x) + shift.x
	assert_float(swim_middle).is_equal_approx(side_middle, FEET_TOLERANCE)


func test_seulement_de_profil() -> void:
	for anim: StringName in [&"walk", &"idle", &"attack", SR.SWIM]:
		assert_bool(SR.side_view(anim)).override_failure_message("%s : de profil" % anim).is_true()
	for anim: StringName in [&"walk_down", &"idle_down", &"walk_up", &"idle_up"]:
		assert_bool(SR.side_view(anim)).override_failure_message("%s : de face ou de dos, la selle" % anim).is_false()
