extends RefCounted
## Le Cœur des Apex (chapter 9), the fond of the crater, 50 x 40 tiles, built as `coeur_apex` (painted by
## tools/zones/apex_canvas.gd, decor of apex_decor.gd, checks of apex_verif.gd; places in
## story/apex_places.gd). Down the ramp from terre_apex, Chloé comes in by the NORTH edge (x 41-43): a
## corridor goes down along the east wall into a round hall open to the sky (34 x 25), its walls veined
## with amber; those of its north half high (they face the camera), those of its south half low (the
## camera sees in). In the north half of the hall, THE BLOC (« BlocSouverain »): the Souverain lying in it,
## eyes open, Hélène against his flank, her hand on him (all in its picture); Isaure, Maïa and Caillou
## wait before it. West of it, the rock where Maïa pulls her mother and Hélène (« ROCHER_ABRI »). The
## states the story leaves the hall in, at each load: before the waking (the bloc, the three before it);
## awake (« souverain_eveille »: what is left of the bloc, him against the north wall, corrupted; Isaure
## holding Hélène behind the rock, Maïa holding both, Caillou on the line); calm (« souverain_apaise »: he
## lies in the middle); after « apex_fini », only him and the broken bloc. No wild dinos, no music (the
## Alphas' is the battle's), a little mist.
## Build: --script res://tools/build_zone.gd -- apex_coeur --force

const PATH := "res://regions/apex/coeur_apex.tscn"
const RES_DIR := "res://regions/apex"
const B := preload("res://tools/zone_builder.gd")
const AC := preload("res://tools/zones/apex_canvas.gd")
const A := preload("res://tools/zones/apex_decor.gd")
const AV := preload("res://tools/zones/apex_verif.gd")
const P := preload("res://story/apex_places.gd")
const MUSIC := ["res://assets/audio/music/coeur_apex.ogg"]
const W := 50
const H := 40
const SEED := 9203
const SALT := 97.0
## Heights (m): the hall's floor; the walls of its north half, of its south half (low: 1.8 m over the
## floor, the camera sees over them); the corridor from the north edge (as the ramp's foot in terre_apex).
const H_SALLE := P.H_SALLE
const H_MUR_NORD := 6.0
const H_MUR_SUD := -1.2
const MUR_SUD_DES := 22
const H_COULOIR := 0.0
## The hall (an ellipse: [centre, radii]), the corridor down along the east wall.
const SALLE := [Vector2(24.0, 21.0), Vector2(17.5, 12.5)]
const COULOIR := Rect2i(41, 0, 3, 22)
## The trail from the corridor's foot to the bloc.
const SENTIER := [Vector2(41.5, 21.0), Vector2(34.0, 21.6), Vector2(27.5, 20.6)]
## The veins of amber: from the bloc out to the walls.
const VEINES := [
	[Vector2(21.0, 15.0), Vector2(15.0, 12.5), Vector2(9.5, 13.5)],
	[Vector2(27.0, 15.0), Vector2(33.0, 11.5), Vector2(37.5, 12.5)],
	[Vector2(20.0, 18.0), Vector2(14.0, 23.0), Vector2(8.0, 25.0)],
	[Vector2(28.5, 18.5), Vector2(33.0, 25.0), Vector2(38.0, 27.5)],
	[Vector2(24.5, 19.5), Vector2(23.0, 26.0), Vector2(25.0, 32.0)],
	[Vector2(24.0, 13.5), Vector2(23.0, 10.0)],
]
## Amber crystals (lit) round the hall: angles (degrees, 0 east, clockwise), at this share of its radii.
const CRISTAUX := [8.0, 38.0, 142.0, 172.0, 205.0, 238.0, 302.0, 335.0]
const CRISTAUX_RAYON := 0.88
## The proposed solid feet (px) of the pictures still to be drawn (docs/zones/apex.md): checked to fit.
const PIED_BLOC := Vector2(480, 100)
const PIED_BLOC_ECLATE := Vector2(420, 90)
const PIED_ISAURE_HELENE := Vector2(70, 22)


static func build() -> Region:
	var c := AC.new(W, H, H_SALLE, SALT)
	_paint(c)
	var root := c.apex_region(&"coeur_apex", "Terre des Apex", "Le Cœur des Apex", Vector2i(50, 50), RES_DIR, AC.ROCHE_FOND_TEX, AC.CHEMIN_FOND_TEX)
	A.climate(root, &"coeur_apex", MUSIC, 0.04)
	var entities: Node2D = root.get_node("Entities")
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	_story(root, entities)
	for a: float in CRISTAUX:
		var at: Vector2 = SALLE[0] + Vector2(cos(deg_to_rad(a)) * SALLE[1].x, sin(deg_to_rad(a)) * SALLE[1].y) * CRISTAUX_RAYON
		A.put(entities, A.CRISTAUX, at, a > 90.0 and a < 270.0)
	B.hide_pebbles(root, entities, Vector2i(P.COEUR_ENTREE.floor()), 9211, 0, 0, [], [Vector2(9.5, 26.0)])
	_places(root)
	B.habitat(root, "Le Cœur des Apex", Rect2(6, 8, 38, 27), [], 0)   # (its name on the map)
	var floating := AV.settle_all(root)
	AV.check(root, "Cœur des Apex", Vector2i(P.COEUR_ENTREE.floor()), _on_foot(), floating, {
		"out": {"sur le mur nord": Vector2(24.0, 5.0), "sur le mur sud": Vector2(24.0, 36.5), "derrière le couloir": Vector2(46.5, 10.0)},
		"footprints": {"bloc_souverain": [P.BLOC, PIED_BLOC], "bloc_souverain_eclate": [P.BLOC, PIED_BLOC_ECLATE],
			"isaure_helene": [P.ABRI, PIED_ISAURE_HELENE]},
	})
	return root


static func _paint(c: AC) -> void:
	var open := func(x: int, y: int) -> bool:
		return c.in_ellipse(x, y, SALLE[0], SALLE[1], 0.2) or COULOIR.has_point(Vector2i(x, y))
	c.mass(func(x: int, y: int) -> bool: return not open.call(x, y) and y < MUR_SUD_DES, H_MUR_NORD, 0.5)
	c.mass(func(x: int, y: int) -> bool: return not open.call(x, y) and y >= MUR_SUD_DES, H_MUR_SUD, 0.15)
	c.keep_level(Rect2i(0, 0, W, H))   # (the hall's floor level: the bloc, the people, the scenes)
	c.ramp(COULOIR, "y", H_COULOIR, H_SALLE)
	c.trail(SENTIER)
	for pts: Array in VEINES:
		c.vein(pts, 1.0)
	c.finish(0.0)


## The bloc and what is left of it, the Souverain (awake against the wall, then lying), the three who wait
## before the bloc, then behind the rock (and Hélène with them), the rock.
static func _story(root: Region, entities: Node2D) -> void:
	A.story_prop(entities, A.BLOC_SOUVERAIN, P.BLOC, "BlocSouverain", &"bloc_souverain", {"hide_flag": &"souverain_eveille"})
	A.story_prop(entities, A.BLOC_ECLATE, P.BLOC, "BlocEclate", &"bloc_eclate", {"show_flag": &"souverain_eveille"})
	A.souverain(root, "Souverain", P.SOUVERAIN_PAROI, {"event": &"souverain", "corrupted": true, "show_flag": &"souverain_eveille",
		"hide_flag": &"souverain_apaise"})
	A.souverain(root, "SouverainCouche", P.SOUVERAIN_COUCHE, {"event": &"souverain_couche", "show_flag": &"souverain_apaise"})
	# Before the waking: at the bloc.
	A.person(root, "IsaureCoeur", "Isaure", ["isaure_sans_masque"], P.ISAURE, {"facing": "up", "event": &"isaure_coeur",
		"hide_flag": &"souverain_eveille"})
	A.person(root, "MaiaCoeur", "Maïa", ["maia_arche"], P.MAIA, {"facing": "up", "event": &"maia_coeur", "hide_flag": &"souverain_eveille"})
	B.dino_npc(root, "CaillouCoeur", &"triceratops", P.CAILLOU.x, P.CAILLOU.y, {"event": &"caillou_coeur", "hide_flag": &"souverain_eveille"})
	# Awake: behind the rock (Isaure holding Hélène: one picture, until she wakes; then the two of them).
	A.put(entities, A.ROCHER_ABRI, P.ROCHER_ABRI)
	A.put(entities, ["rocher_grotte"], P.ROCHER_ABRI + Vector2(1.7, 0.4), true)
	A.story_prop(entities, A.ISAURE_HELENE, P.ABRI, "IsaureHelene", &"isaure_helene", {"show_flag": &"souverain_eveille",
		"hide_flag": &"helene_reveillee"})
	A.person(root, "IsaureAbri", "Isaure", ["isaure_sans_masque"], P.ISAURE_ABRI, {"facing": "right", "event": &"isaure_abri",
		"show_flag": &"helene_reveillee", "hide_flag": &"apex_fini"}, Color.WHITE, true)
	A.person(root, "HeleneAbri", "Hélène", A.HELENE, P.HELENE_ABRI, {"facing": "down", "event": &"helene_abri",
		"show_flag": &"helene_reveillee", "hide_flag": &"apex_fini"}, Color.WHITE, true)   # (on the ground: helene_sol)
	A.person(root, "MaiaAbri", "Maïa", ["maia_arche"], P.MAIA_ABRI, {"facing": "left", "event": &"maia_abri",
		"show_flag": &"souverain_eveille", "hide_flag": &"apex_fini"})
	B.dino_npc(root, "CaillouRempart", &"triceratops", P.CAILLOU_REMPART.x, P.CAILLOU_REMPART.y, {"event": &"caillou_rempart",
		"show_flag": &"souverain_eveille", "hide_flag": &"apex_fini"})


static func _places(root: Region) -> void:
	B.spawn(root, "Depart", P.COEUR_ENTREE.x, P.COEUR_ENTREE.y)
	# North: back up the ramp to terre_apex (Chloé comes out at its top).
	B.spawn(root, String(P.SPAWN_TERRE), P.COEUR_ENTREE.x, P.COEUR_ENTREE.y)
	B.exit(root, Rect2(41.0, 0.0, 3.0, 0.55), &"terre_apex", P.SPAWN_COEUR)


static func _on_foot() -> Dictionary:
	return {
		"entrée": P.COEUR_ENTREE, "sortie vers le cratère": P.SORTIE_TERRE_COEUR + Vector2(0.0, 0.6), "bas du couloir": P.COULOIR_BAS,
		"la salle": P.SALLE, "devant le bloc": P.CHLOE_BLOC, "la main d'Hélène": P.MAIN_HELENE, "les essais": P.ESSAIS,
		"Isaure (au bloc)": P.ISAURE + Vector2(0.0, 1.0), "Maïa (au bloc)": P.MAIA + Vector2(0.0, 1.0),
		"Caillou (au bloc)": P.CAILLOU + Vector2(0.0, 1.6), "devant l'abri": P.ABRI + Vector2(0.0, 1.2), "Isaure (abri)": P.ISAURE_ABRI + Vector2(0.0, 0.8),
		"Hélène (abri)": P.HELENE_ABRI + Vector2(0.0, 0.8), "Maïa (abri)": P.MAIA_ABRI + Vector2(0.0, 0.8),
		"Caillou (la ligne)": P.CAILLOU_REMPART + Vector2(0.0, 1.6), "contre la paroi (lui, réveillé)": P.SOUVERAIN_PAROI + Vector2(0.0, 1.4),
		"l'aire du combat": P.AIRE_COMBAT, "Chloé (combat)": P.COMBAT_CHLOE, "son dino (combat)": P.COMBAT_DINO,
		"où le Roi se pose": P.ROI_POSE,
	}
