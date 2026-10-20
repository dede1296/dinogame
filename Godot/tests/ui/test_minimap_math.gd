extends GdUnitTestSuite
## La géométrie de la mini-carte (MinimapMath), sans fenêtre : du monde à la fenêtre ronde (nord en
## haut, comme ZoneMap), les objectifs hors cadre ramenés sur le bord, l'angle et la distance de la
## flèche, la bascule petite → grande → masquée, les niveaux de zoom, le trapèze du sol que la caméra
## inclinée voit, quand redessiner la texture, la place laissée sous la colonne de boutons.


func test_du_monde_a_la_fenetre_nord_en_haut() -> void:
	var chloe := Vector2(50, 40)
	assert_vector(MinimapMath.to_window(chloe, chloe, 4.0)).is_equal(Vector2.ZERO)
	# Au nord (y plus petit) : en haut ; à l'est (x plus grand) : à droite.
	assert_vector(MinimapMath.to_window(Vector2(50, 30), chloe, 4.0)).is_equal(Vector2(0, -40))
	assert_vector(MinimapMath.to_window(Vector2(55, 40), chloe, 4.0)).is_equal(Vector2(20, 0))


func test_un_objectif_dans_le_cadre_reste_a_sa_place() -> void:
	var r := MinimapMath.rim(Vector2(30, -40), 100.0, 9.0)
	assert_bool(r["inside"]).is_true()
	assert_vector(r["at"]).is_equal(Vector2(30, -40))


func test_un_objectif_hors_cadre_va_sur_le_bord_dans_sa_direction() -> void:
	var r := MinimapMath.rim(Vector2(300, 0), 100.0, 9.0)
	assert_bool(r["inside"]).is_false()
	assert_vector(r["at"]).is_equal_approx(Vector2(91, 0), Vector2(0.01, 0.01))
	assert_vector(r["dir"]).is_equal_approx(Vector2.RIGHT, Vector2(0.001, 0.001))
	var diag := MinimapMath.rim(Vector2(-400, -400), 100.0, 9.0)
	assert_float((diag["at"] as Vector2).length()).is_equal_approx(91.0, 0.01)
	assert_float((diag["dir"] as Vector2).angle()).is_equal_approx(Vector2(-1, -1).angle(), 0.001)


func test_angle_et_distance_de_la_fleche() -> void:
	assert_float(MinimapMath.angle_to(Vector2(10, 10), Vector2(20, 10))).is_equal_approx(0.0, 0.0001)
	assert_float(MinimapMath.angle_to(Vector2(10, 10), Vector2(10, 0))).is_equal_approx(-PI / 2.0, 0.0001)
	assert_str(QuestTracker.distance_text(2.4)).is_equal("ici")
	assert_str(QuestTracker.distance_text(41.6)).is_equal("42 m")


func test_bascule_petite_grande_masquee() -> void:
	var M := MinimapMath.Mode
	assert_int(MinimapMath.next_mode(M.SMALL)).is_equal(M.LARGE)
	assert_int(MinimapMath.next_mode(M.LARGE)).is_equal(M.HIDDEN)
	assert_int(MinimapMath.next_mode(M.HIDDEN)).is_equal(M.SMALL)
	assert_int(MinimapMath.next_mode(99)).is_equal(M.SMALL)


func test_zoom_par_paliers_et_bornes() -> void:
	var last := MinimapMath.ZOOM_TILES.size() - 1
	assert_int(MinimapMath.zoom_level(MinimapMath.ZOOM_DEFAULT, 1)).is_equal(MinimapMath.ZOOM_DEFAULT + 1)
	assert_int(MinimapMath.zoom_level(0, -1)).is_equal(0)
	assert_int(MinimapMath.zoom_level(last, 1)).is_equal(last)
	# Plus de zoom : plus de pixels par case.
	assert_float(MinimapMath.px_per_tile(2, 100.0)).is_greater(MinimapMath.px_per_tile(1, 100.0))
	assert_float(MinimapMath.px_per_tile(1, 100.0)).is_equal_approx(100.0 / MinimapMath.ZOOM_TILES[1], 0.0001)


## La caméra de l'exploration (CameraRig) : inclinée de 40°, derrière Chloé au sud, regardant le nord.
func _camera(focus: Vector3, distance: float) -> Transform3D:
	var pitch := deg_to_rad(CameraRig.PITCH_DEG)
	var back := Vector3(0.0, sin(pitch), cos(pitch))
	var at := focus + Vector3(0, CameraRig.LOOK_HEIGHT, 0) + back * distance
	return Transform3D(Basis(), at).looking_at(at - back, Vector3.UP)


func test_le_trapeze_du_sol_vu_par_la_camera() -> void:
	var chloe := Vector3(50, 0, 40)
	var quad := MinimapMath.footprint(_camera(chloe, 12.0), 38.0, 16.0 / 9.0, 0.0)
	assert_int(quad.size()).is_equal(4)
	var top_w := quad[1].x - quad[0].x
	var bottom_w := quad[2].x - quad[3].x
	# Le haut de l'écran voit plus loin et plus large (perspective), et se trouve au nord de Chloé.
	assert_float(top_w).is_greater(bottom_w)
	assert_float(quad[0].y).is_less(40.0)
	assert_float(quad[3].y).is_greater(40.0)
	# Chloé est dans ce qu'elle voit, au milieu en largeur.
	assert_bool(Geometry2D.is_point_in_polygon(Vector2(50, 40), quad)).is_true()
	assert_float((quad[0].x + quad[1].x) / 2.0).is_equal_approx(50.0, 0.01)


func test_une_camera_qui_regarde_le_ciel_ne_donne_rien() -> void:
	var up := Transform3D(Basis(), Vector3(0, 5, 0)).looking_at(Vector3(0, 10, -5), Vector3.UP)
	assert_int(MinimapMath.footprint(up, 38.0, 1.5, 0.0).size()).is_equal(0)


func test_quand_redessiner_la_texture() -> void:
	assert_bool(MinimapMath.needs_render(Vector2(5, 0), 48.0, 0.2, 1.0)).is_false()
	assert_bool(MinimapMath.needs_render(Vector2(30, 0), 48.0, 0.2, 1.0)).is_true()
	assert_bool(MinimapMath.needs_render(Vector2.ZERO, 48.0, 1.0, 1.0)).is_true()


func test_la_fenetre_ne_monte_pas_sur_les_boutons() -> void:
	# Ordinateur : 900 px de haut, les boutons ronds descendent jusqu'à 452 px : la grande tient.
	assert_float(MinimapMath.diameter(344.0, 900.0, 12.0, 452.0, 12.0)).is_equal(344.0)
	# Téléphone : 720 px, boutons jusqu'à 442 px : la grande est ramenée à ce qui reste.
	assert_float(MinimapMath.diameter(430.0, 720.0, 12.0, 442.0, 12.0)).is_equal(254.0)
	assert_float(MinimapMath.diameter(430.0, 300.0, 12.0, 442.0, 12.0)).is_equal(0.0)


func test_montree_seulement_si_voulue_dehors_et_libre() -> void:
	var M := MinimapMath.Mode
	assert_bool(MinimapMath.should_show(M.SMALL, true, true)).is_true()
	assert_bool(MinimapMath.should_show(M.LARGE, true, true)).is_true()
	assert_bool(MinimapMath.should_show(M.HIDDEN, true, true)).is_false()
	assert_bool(MinimapMath.should_show(M.SMALL, false, true)).is_false()   # (une grotte, une maison)
	assert_bool(MinimapMath.should_show(M.SMALL, true, false)).is_false()   # (une scène, un dialogue)
