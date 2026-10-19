class_name Cinematiques
extends RefCounted
## Les deux cinématiques d'Ambrelune et le fond des crédits (docs/cinematiques.md, décisions de Greg du
## 19/10) : la DESCRIPTION des séquences, lue par ui/cinematic.gd, et les points d'entrée.
## - L'INTRO, « Les légendes, ça se trouve » : 9 images + le carton « Ambrelune » (~74 s), au lancement
##   d'une Nouvelle partie, et en Nouvelle partie+ (elle se rejoue) : scenes/boot/boot.gd ; puis le quai
##   de Port-Ambre (Prologue.arrival). « Revoir l'intro » : Paramètres.
## - LA FIN, « Ce qui dort n'est pas mort » : 9 images + F-10, les crédits sur le fond C-01 (~97 s hors
##   crédits), après la page 40 sur la jetée (story/apex_jetee.gd::_the_end), une fois (drapeau fin_vue) ;
##   F-06 suit le dino de départ (trois peintures : Vif, Bastion avec Maïa assise dessus, Écho qui chante
##   faux ; son nom : celui que le joueur lui a donné).
## - LES CRÉDITS seuls : bouton « Crédits » du titre et des Paramètres ; à la fin, retour où l'on était.
##
## Les peintures : assets/art/cinematiques/<nom>.png (2560 × 1440), faites par l'agent IMAGES. Tant
## qu'une peinture manque, son plan se joue sur un fond uni avec sa phrase. Les calques détourés, eux,
## sont facultatifs : <nom de la peinture>_<calque>.png (ex. intro_02_falaises_ambre.png) ; absents, le
## plan se joue sans eux (les effets du moteur — halos, brume, fumée, poussière, étoiles, les dinos du jeu
## qui passent — n'ont besoin d'aucune image). Les positions des halos et des passages (0..1 dans
## l'image) sont posées à l'aveugle : à reprendre ici quand les peintures existent.
## Musiques : assets/audio/music/cinematique_intro_a.ogg, _b.ogg, cinematique_fin.ogg, credits.ogg
## (à produire ; absentes : titre.ogg). Bruitages : ceux du document ; absents, on n'entend rien.

const FOLDER := "res://assets/art/cinematiques/%s.png"
const MUSIC := "res://assets/audio/music/%s.ogg"
const SFX := "res://assets/audio/sfx/%s.ogg"
const AMB := "res://assets/audio/ambience/%s.ogg"
const CRY := "res://assets/audio/cries/%s.mp3"
const INTRO_FLAG := &"intro_vue"
const END_FLAG := &"fin_vue"
const GAME_TITLE := "Ambrelune"
## The phrase on each picture: one sentence, 8 to 14 words (docs/cinematiques.md § Format commun).
const WORDS_MIN := 8
const WORDS_MAX := 14
## F-06: the starter's species → its painting, its phrase (%s: its name, as the player gave it).
const STARTER_VARIANTS := {
	&"velociraptor": ["vif", "%s a deux dents de plus, et ne tient toujours pas en place."],
	&"ankylosaurus": ["bastion", "%s a grandi. Tout le monde s'assoit encore dessus."],
	&"parasaurolophus": ["echo", "%s chante toujours faux le matin. Ça ne fait rien."],
}
const STARTER_CRIES := {&"velociraptor": "raptor-neutre", &"ankylosaurus": "cuirasse-neutre", &"parasaurolophus": "hadrosaure-neutre"}
const PTERO := "res://assets/art/dinos/pteranodon_vol.png"
const DRAGONFLY := "res://assets/art/fauna/libellule.png"
const SOUVERAIN_BREATH := "res://assets/audio/cries/souverain-souffle.ogg"
const AMBER_GLOW := Color(1.0, 0.72, 0.3, 0.32)
const LAMP_GLOW := Color(1.0, 0.75, 0.4, 0.5)


# ------------------------------------------------------------------ entry points

## Does a new game open on the intro? Yes, and in Nouvelle partie+ too (Greg, 19/10: « elle se
## rejoue »; it is short, and « Passer » is there).
static func intro_on_new_game(_plus := false) -> bool:
	return true


## The intro of a new game (boot.gd, after Game.new_game(); Nouvelle partie+ the same way): ends on
## black, the Router's curtain closed, for the quay of Port-Ambre to fade in.
static func new_game_intro(parent: Node, plus := false) -> void:
	if not intro_on_new_game(plus):
		return
	await Cinematic.play(parent, intro_sequence()).finished


## The end of the game, at the end of the jetty (ApexJetee._the_end, the curtain closed): the end
## film and the credits, once (fin_vue, saved at once); after that, only the « Ambrelune » card.
static func the_end() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if not end_wanted() or tree == null:
		await Epilogue.card(GAME_TITLE, 3.4)
		return
	await Cinematic.play(tree.root, end_sequence()).finished
	Game.set_flag(END_FLAG)
	if Save.enabled:
		Save.save_game()


## True until the end has been seen (or skipped).
static func end_wanted() -> bool:
	return not Game.flag(END_FLAG)


## The credits alone (the title screen's « Crédits », Paramètres): back where one was, at the end.
static func play_credits(parent: Node) -> Cinematic:
	return Cinematic.play(parent, credits_sequence())


## « Revoir l'intro » / « Crédits » from Paramètres: the film over the screen, then back to it.
static func replay(parent: Node, what: String) -> Cinematic:
	if what == "credits":
		return play_credits(parent)
	var seq := intro_sequence()
	seq["end"] = "reveal"
	seq["restore_music"] = true
	return Cinematic.play(parent, seq)


# ------------------------------------------------------------------ the intro

static func intro_sequence() -> Dictionary:
	var sea := [AMB % "vagues"]
	return {
		"id": "intro", "flag": INTRO_FLAG, "end": "black", "restore_music": false, "fade_in": 1.5, "fade_out": 1.5,
		"plans": [
			# (Positions measured on the paintings of 19/10: 0..1 of the picture.)
			_plan("I-01", "intro_01_large", 7.0, 1.0, _zoom(1.0, 1.08, Vector2(0.5, 0.5), Vector2(0.62, 0.42)),
				"Au large de toutes les cartes, une île que personne ne trouve.", Color(0.13, 0.38, 0.48), {
				"music": MUSIC % "cinematique_intro_a", "loops": sea + [AMB % "brise"],
				"sfx": [[3.5, CRY % "pterosaure-neutre", -16.0]],
				"layers": [
					_layer("intro_01_large", "mer", {"anim": "bob", "amp": 0.004, "angle": 0.0, "period": 5.0}),
					_layer("intro_01_large", "brume", {"anim": "drift", "from": Vector2(-0.02, 0.0), "to": Vector2(0.02, 0.0)}),
					_fx("mist", Rect2(0.5, 0.35, 0.45, 0.06), {"amount": 7}),
					_fx("smoke", Rect2(0.705, 0.29, 0.0, 0.0), {"amount": 6, "color": Color(0.96, 0.93, 0.9, 0.24)}),
					_fx("sparkle", Rect2(0.38, 0.41, 0.28, 0.07)),
					_ptero(Vector2(0.47, 0.2), Vector2(0.26, 0.15), 0.5, 6.5, 0.02),
					_ptero(Vector2(0.5, 0.18), Vector2(0.29, 0.13), 0.5, 6.5, 0.018),
					_ptero(Vector2(0.5, 0.22), Vector2(0.29, 0.17), 0.5, 6.5, 0.018),
				]}),
			_plan("I-02", "intro_02_falaises", 7.0, 1.2, _pan(1.08, 0.465, 0.535),
				"Les nuits de pleine lune, ses falaises brillent comme du miel.", Color(0.08, 0.1, 0.22), {
				"loops": sea,
				"layers": [
					_layer("intro_02_falaises", "ambre", {"anim": "pulse", "min": 0.35, "max": 1.0, "period": 3.2}),
					_glow(Vector2(0.83, 0.22), 0.22, Color(1.0, 0.96, 0.82, 0.2), {"pulse": 0.7, "period": 5.0}),
					_glow(Vector2(0.3, 0.45), 0.3, Color(AMBER_GLOW, 0.22), {"pulse": 0.35, "period": 3.2, "wide": 1.6}),
					_fx("sparkle", Rect2(0.6, 0.66, 0.35, 0.18), {"color": Color(1.0, 0.97, 0.85, 0.9)}),
				]}),
			_plan("I-03", "intro_03_cabinet", 8.0, 1.2, _zoom(1.0, 1.1, Vector2(0.5, 0.5), Vector2(0.52, 0.6)),
				"Là-bas, une grand-mère réveillait des dinosaures. Des vrais.", Color(0.2, 0.13, 0.08), {
				"loops": [AMB % "maison", SFX % "horloge-tictac", SFX % "lampe-huile"],
				"sfx": [[2.4, SFX % "page-froissee", -6.0], [2.5, "res://assets/audio/sfx/page.wav", -12.0]],
				"layers": [
					_layer("intro_03_cabinet", "page", {"anim": "bob", "amp": 0.0, "angle": 1.2, "period": 4.0, "pivot": Vector2(0.5, 0.7)}),
					_layer("intro_03_cabinet", "flamme", {"anim": "flicker"}),
					_glow(Vector2(0.356, 0.46), 0.1, LAMP_GLOW, {"flicker": true}),
					_fx("dust", Rect2(0.25, 0.2, 0.4, 0.45)),
				]}),
			_plan("I-04", "intro_04_oeufs", 7.0, 0.8, _zoom(1.0, 1.06, Vector2(0.5, 0.5), Vector2(0.5, 0.52)),
				"Puis elle est partie. Elle a laissé trois œufs, et un mot.", Color(0.26, 0.16, 0.07), {
				"loops": [AMB % "labo"],
				"sfx": [[4.3, SFX % "oeuf-toc", -4.0]],
				"layers": [
					_layer("intro_04_oeufs", "lueur", {"anim": "pulse", "min": 0.5, "max": 1.0, "period": 2.8}),
					_glow(Vector2(0.5, 0.56), 0.22, AMBER_GLOW, {"pulse": 0.55, "period": 2.8, "wide": 1.3}),
					_glow(Vector2(0.5, 0.82), 0.04, Color(1.0, 0.6, 0.25, 0.5), {"pulse": 0.5, "period": 2.8}),
					_glow(Vector2(0.33, 0.43), 0.05, LAMP_GLOW, {"flicker": true}),
					_fx("bubbles", Rect2(0.44, 0.6, 0.12, 0.0), {"amount": 3}),
				]}),
			_plan("I-05", "intro_05_carte_vide", 9.0, 0.8, _zoom(1.12, 1.0, Vector2(0.38, 0.66), Vector2(0.5, 0.5)),
				"Chaque région a ses dinos. Au milieu, un volcan qui gronde.", Color(0.88, 0.82, 0.68), {
				"image_or": [FOLDER % "intro_05_carte"],
				"sfx": [[0.6, SFX % "plume-gratte", -6.0], [7.6, AMB % "volcan-grondement", -10.0]],
				"layers": [
					# The ink from the rim to the volcano (0.51, 0.47), starting with the prairie (bottom left).
					{"kind": "reveal", "path": FOLDER % "intro_05_carte", "over": FOLDER % "intro_05_carte_vide",
						"mode": 1, "origin": Vector2(0.51, 0.47), "start_angle": 2.4, "start": 0.5, "dur": 7.0},
					_fx("smoke", Rect2(0.52, 0.37, 0.0, 0.0), {"start": 7.4, "amount": 6, "color": Color(0.35, 0.25, 0.18, 0.4)}),
				]}),
			_plan("I-06", "intro_06_chambre", 8.0, 1.2, _zoom(1.0, 1.08, Vector2(0.5, 0.5), Vector2(0.5, 0.46)),
				"Chloé a douze ans, un sac trop plein et une grand-mère à retrouver.", Color(0.55, 0.42, 0.3), {
				"music": MUSIC % "cinematique_intro_b", "loops": [AMB % "maison"],
				"sfx": [[1.5, SFX % "lacet-fermeture-eclair", -4.0], [4.6, SFX % "objet-tombe-toc", -4.0]],
				"layers": [
					_layer("intro_06_chambre", "rideau", {"anim": "sway", "strength": 4.0}),
					_layer("intro_06_chambre", "lacet", {"anim": "bob", "amp": 0.002, "angle": 3.0, "period": 1.2, "pivot": Vector2(0.5, 0.0)}),
					_layer("intro_06_chambre", "peluche", {"anim": "bob", "amp": 0.0, "angle": 4.0, "period": 0.9}),
					_fx("dust", Rect2(0.62, 0.1, 0.3, 0.6)),
				]}),
			_plan("I-07", "intro_07_ponton", 7.0, 1.2, _pan(1.08, 0.535, 0.47),
				"Une capitaine connaît le chemin. « Monte, moussaillon. On y va. »", Color(0.62, 0.55, 0.45), {
				"loops": sea + [SFX % "rames"],
				"sfx": [[1.1, SFX % "saut-planches-plouf", -2.0], [1.5, SFX % "mouette-vexee", -4.0], [1.6, AMB % "mouettes", -8.0]],
				"layers": [
					_layer("intro_07_ponton", "mouette", {"anim": "drift", "from": Vector2.ZERO, "to": Vector2(0.06, -0.12), "start": 1.4, "dur": 4.0}),
					_fx("splash", Rect2(0.5, 0.62, 0.16, 0.0), {"start": 1.0}),
					_fx("splash", Rect2(0.76, 0.86, 0.2, 0.0), {"start": 1.3, "amount": 24}),
					_fx("sparkle", Rect2(0.05, 0.08, 0.9, 0.12)),
				]}),
			_plan("I-08", "intro_08_brume", 8.0, 0.8, _zoom(1.0, 1.06, Vector2(0.5, 0.5), Vector2(0.3, 0.45)),
				"La brume avale tout. Chloé n'a pas peur. Enfin, presque.", Color(0.72, 0.72, 0.68), {
				"loops": sea + [AMB % "brume-vent-feutre", SFX % "rames"],
				"sfx": [[5.0, "res://assets/audio/sfx/colonne_bulles.mp3", -16.0]],
				"layers": [
					_layer("intro_08_brume", "ombre", {"anim": "drift", "from": Vector2(0.0, 0.0), "to": Vector2(0.03, 0.0)}),
					_layer("intro_08_brume", "barque", {"anim": "bob", "amp": 0.003, "angle": 0.8, "period": 4.5}),
					_fx("mist", Rect2(0.0, 0.05, 1.0, 0.25), {"amount": 12}),
					_fx("mist", Rect2(0.0, 0.7, 1.0, 0.25), {"amount": 12}),
				]}),
			_plan("I-09", "intro_09_arrivee", 9.0, 0.8, _zoom(1.08, 1.0, Vector2(0.5, 0.45), Vector2(0.5, 0.5)),
				"Et l'île apparaît. Les légendes, ça se trouve.", Color(0.45, 0.66, 0.8), {
				"loops": sea + [AMB % "mouettes"],
				"sfx": [[0.3, SFX % "brume-se-dechire", -4.0], [2.2, CRY % "pterosaure-neutre", -8.0], [5.6, CRY % "pterosaure-neutre", -11.0]],
				"layers": [
					_layer("intro_09_arrivee", "brume_g", {"anim": "drift", "from": Vector2.ZERO, "to": Vector2(-0.45, 0.0), "dur": 4.0}),
					_layer("intro_09_arrivee", "brume_d", {"anim": "drift", "from": Vector2.ZERO, "to": Vector2(0.45, 0.0), "dur": 4.0}),
					_fx("mist", Rect2(0.0, 0.8, 1.0, 0.2), {"amount": 10, "stop": 5.0}),
					_fx("sparkle", Rect2(0.3, 0.6, 0.45, 0.06)),
					_ptero(Vector2(0.86, 0.17), Vector2(0.66, 0.09), 1.0, 7.0, 0.03),
				]}),
			{"id": "carton", "kind": "card", "title": GAME_TITLE, "secs": 4.0, "fade": 1.2, "loops": sea},
		],
	}


# ------------------------------------------------------------------ the end

static func end_sequence() -> Dictionary:
	var sea := [AMB % "vagues"]
	var variant := starter_variant()
	var species := starter_species()
	var f06: Array = STARTER_VARIANTS[species]
	var f06_layers: Array = [
		_fx("sparkle", Rect2(0.2, 0.47, 0.55, 0.12)),
		_fx("pollen", Rect2(0.05, 0.35, 0.9, 0.5)),
		{"kind": "sprite", "sheet": DRAGONFLY, "cols": 2, "rows": 1, "fps": 14.0, "from": Vector2(0.12, 0.7), "to": Vector2(0.34, 0.6),
			"start": 1.0, "dur": 5.0, "height": 0.03, "arc": 0.02, "arc_period": 0.9},
	]
	var f06_sfx: Array = [[1.8, CRY % STARTER_CRIES[species], -6.0]]
	if species == &"parasaurolophus":
		f06_layers.append({"kind": "notes", "at": Vector2(0.45, 0.45), "start": 1.5})
		f06_layers.append(_layer("fin_06_dinos_echo", "notes", {"anim": "drift", "from": Vector2.ZERO, "to": Vector2(0.0, -0.05)}))
		f06_sfx.append([2.2, SFX % "echo-notes-fausses", -4.0])
	return {
		"id": "fin", "flag": END_FLAG, "end": "black", "restore_music": true, "fade_in": 1.5, "fade_out": 1.5,
		"plans": [
			_plan("F-01", "fin_01_jetee_fete", 10.0, 1.5, _zoom(1.08, 1.0, Vector2(0.5, 0.5), Vector2(0.5, 0.5)),
				"L'île ne se vend pas, pas un galet. Mais elle se montre.", Color(0.5, 0.68, 0.78), {
				"music": MUSIC % "cinematique_fin",
				"loops": sea + [AMB % "village", SFX % "fanions-vent", SFX % "brouhaha-village"],
				"sfx": [[1.0, AMB % "mouettes", -8.0]],
				"layers": [
					_layer("fin_01_jetee_fete", "fanions", {"anim": "sway", "strength": 3.0, "speed": 2.2}),
					_layer("fin_01_jetee_fete", "mer", {"anim": "bob", "amp": 0.003, "angle": 0.0, "period": 5.0}),
					_fx("smoke", Rect2(0.37, 0.41, 0.0, 0.0), {"amount": 7, "color": Color(0.92, 0.92, 0.92, 0.25)}),
					_fx("sparkle", Rect2(0.05, 0.8, 0.9, 0.15)),
				]}),
			_plan("F-02", "fin_02_barque_visiteurs", 9.0, 0.8, _pan(1.08, 0.47, 0.53),
				"Les barques de la capitaine amènent les visiteurs. Tarif unique : rien.", Color(0.4, 0.6, 0.68), {
				"loops": sea + [SFX % "rames"],
				"sfx": [[3.0, CRY % "marin-neutre", -12.0]],
				"layers": [
					_layer("fin_02_barque_visiteurs", "barque", {"anim": "bob", "amp": 0.003, "angle": 0.7, "period": 4.0}),
					_layer("fin_02_barque_visiteurs", "masque", {"anim": "bob", "amp": 0.0, "angle": 5.0, "period": 1.6, "pivot": Vector2(0.5, 0.0)}),
					_fx("sparkle", Rect2(0.05, 0.78, 0.9, 0.15)),
				]}),
			_plan("F-03", "fin_03_forges", 9.0, 1.2, _zoom(1.0, 1.08, Vector2(0.5, 0.5), Vector2(0.58, 0.55)),
				"Isaure démonte les forges. Avec ses mains. Roc tient l'échelle, les yeux fermés.", Color(0.22, 0.2, 0.2), {
				"loops": [AMB % "forge-eteinte"],
				"sfx": [[1.8, SFX % "metal-grince-boulon", -4.0], [4.4, SFX % "echelle-craque", -4.0], [6.2, "res://assets/audio/sfx/latch.wav", -8.0]],
				"layers": [
					_layer("fin_03_forges", "piece", {"anim": "bob", "amp": 0.0, "angle": 6.0, "period": 2.2}),
					_fx("ash", Rect2(0.05, 0.05, 0.9, 0.5), {"amount": 30}),
					_fx("steam", Rect2(0.735, 0.69, 0.0, 0.0)),
					_glow(Vector2(0.31, 0.62), 0.05, Color(1.0, 0.45, 0.15, 0.45), {"pulse": 0.3, "period": 2.0}),
				]}),
			# (No Compsognathus at the door: the painting shows no door to peek through.)
			_plan("F-04", "fin_04_tasse_bleue", 11.0, 1.2, _zoom(1.0, 1.1, Vector2(0.5, 0.5), Vector2(0.5, 0.62)),
				"Deux vieilles amies, une tasse bleue ébréchée, et vingt ans à rattraper.", Color(0.36, 0.26, 0.16), {
				"loops": [AMB % "maison", SFX % "horloge-tictac"],
				"sfx": [[1.2, SFX % "the-verse", -4.0], [3.0, SFX % "tasse-porcelaine", -4.0], [8.0, SFX % "tasse-porcelaine", -10.0]],
				"layers": [
					_layer("fin_04_tasse_bleue", "rideau", {"anim": "sway", "strength": 3.0}),
					_fx("steam", Rect2(0.6, 0.62, 0.0, 0.0)),
					_fx("steam", Rect2(0.385, 0.62, 0.0, 0.0), {"amount": 6}),
					_glow(Vector2(0.335, 0.49), 0.08, LAMP_GLOW, {"flicker": true}),
					_fx("dust", Rect2(0.55, 0.05, 0.25, 0.4)),
				]}),
			_plan("F-05", "fin_05_gardiennes", 9.0, 1.2, _pan(1.08, 0.535, 0.465),
				"Deux gardiennes. Pas de cages : des gens que les bêtes connaissent.", Color(0.5, 0.7, 0.45), {
				"loops": [AMB % "brise"],
				"sfx": [[3.0, SFX % "eternuement-triceratops", -2.0], [3.1, CRY % "ceratopsien-neutre", -10.0],
					[5.0, CRY % "pterosaure-neutre", -14.0], [7.0, CRY % "sauropode-neutre", -16.0]],
				"layers": [
					_layer("fin_05_gardiennes", "herbes", {"anim": "sway", "strength": 3.5}),
					_fx("sneeze", Rect2(0.6, 0.3, 0.0, 0.0), {"start": 3.0}),
					_fx("pollen", Rect2(0.05, 0.4, 0.9, 0.45)),
				]}),
			_plan("F-06", "fin_06_dinos_%s" % variant, 10.0, 1.2, _zoom(1.0, 1.08, Vector2(0.5, 0.5), Vector2(0.62, 0.55)),
				String(f06[1]) % starter_display_name(), Color(0.75, 0.55, 0.3), {
				"image_or": [FOLDER % "fin_06_dinos_base"],
				"loops": [AMB % "eau", AMB % "brise"], "sfx": f06_sfx, "layers": f06_layers}),
			_plan("F-07", "fin_07_brac_nuit", 9.0, 1.2, _zoom(1.0, 1.08, Vector2(0.5, 0.5), Vector2(0.62, 0.45)),
				"Gardien de nuit : Brac. Enfin, « BARC », d'après le panneau.", Color(0.08, 0.1, 0.2), {
				"loops": sea + [AMB % "grillons-nuit", SFX % "ronflement-dino"],
				"sfx": [[4.0, SFX % "gemissement-mastoc", -6.0]],
				"layers": [
					_layer("fin_07_brac_nuit", "flamme", {"anim": "flicker"}),
					_glow(Vector2(0.54, 0.43), 0.08, LAMP_GLOW, {"flicker": true}),
					_glow(Vector2(0.85, 0.22), 0.18, Color(0.85, 0.9, 1.0, 0.16), {"pulse": 0.7, "period": 5.0}),
					_glow(Vector2(0.25, 0.35), 0.28, Color(AMBER_GLOW, 0.2), {"pulse": 0.4, "period": 3.2, "wide": 1.6}),
					_fx("bubbles", Rect2(0.7, 0.72, 0.0, 0.0)),
					_fx("sparkle", Rect2(0.55, 0.48, 0.4, 0.14), {"color": Color(0.85, 0.9, 1.0, 0.8)}),
				]}),
			# (The pterosaur over the sea is painted: no sprite on top of it.)
			_plan("F-08", "fin_08_souverain", 11.0, 1.2, _zoom(1.1, 1.0, Vector2(0.5, 0.3), Vector2(0.5, 0.5)),
				"Au bord du volcan, le Souverain regarde la mer. Les yeux ouverts. Sans peur.", Color(0.45, 0.32, 0.4), {
				"loops": [AMB % "vent-hauteurs"],
				"sfx": [[1.5, SOUVERAIN_BREATH, -4.0], [6.5, SOUVERAIN_BREATH, -6.0]],
				"layers": [
					_fx("ash", Rect2(0.47, 0.25, 0.02, 0.01), {"amount": 24, "breath": 5.0}),
					_fx("stars", Rect2(0.0, 0.0, 1.0, 0.15), {"amount": 25, "life": 22.0}),
					_glow(Vector2(0.13, 0.71), 0.02, LAMP_GLOW, {"pulse": 0.4, "period": 1.3}),
					_glow(Vector2(0.16, 0.73), 0.015, LAMP_GLOW, {"pulse": 0.3, "period": 1.7}),
				]}),
			_plan("F-09", "fin_09_journal_sans_trait", 11.0, 1.2, _zoom(1.0, 1.1, Vector2(0.5, 0.5), Vector2(0.7, 0.55)),
				"Page 40 : « Ce qui dort n'est pas mort. » Il reste des pages blanches.", Color(0.3, 0.2, 0.12), {
				"image_or": [FOLDER % "fin_09_journal"],
				"loops": [SFX % "horloge-tictac", SFX % "lampe-huile"],
				"sfx": [[1.4, SFX % "crayon-papier", -4.0], [7.0, "res://assets/audio/sfx/page.wav", -12.0]],
				"layers": [
					{"kind": "reveal", "path": FOLDER % "fin_09_journal", "over": FOLDER % "fin_09_journal_sans_trait",
						"mode": 0, "span": Vector2(0.55, 0.86), "start": 1.2, "dur": 8.0},
					_layer("fin_09_journal_sans_trait", "flamme", {"anim": "flicker"}),
					_glow(Vector2(0.5, 0.02), 0.18, LAMP_GLOW, {"flicker": true}),
					_fx("dust", Rect2(0.3, 0.05, 0.4, 0.5)),
				]}),
			_credits_plan("F-10", 8.0, 3.5, 1.2, MUSIC % "credits"),
		],
	}


## The starter's species (the flag set when Chloé chose her egg; Vif's when none).
static func starter_species() -> StringName:
	var species := StringName(str(Game.flag(&"starter"))) if Game.flag(&"starter") is String else &""
	if not STARTER_VARIANTS.has(species):
		var d := Game.starter_dino()
		species = d.species().id if d else &"velociraptor"
	return species if STARTER_VARIANTS.has(species) else &"velociraptor"


## F-06's painting: "vif", "bastion" or "echo".
static func starter_variant() -> String:
	return String(STARTER_VARIANTS[starter_species()][0])


## Its name as the player gave it (else its first name: Vif, Bastion, Écho), capitalised (it opens the
## sentence).
static func starter_display_name() -> String:
	var d := Game.starter_dino()
	var shown := d.nickname if d and d.nickname != "" else String(Game.STARTERS.get(starter_species(), "Vif"))
	return shown.left(1).to_upper() + shown.substr(1)


# ------------------------------------------------------------------ the credits

## The credits from the menu: the opening card alone for 5 s, the roll, « Pour Chloé », « Merci d'avoir
## joué »; then back to the screen one came from.
static func credits_sequence() -> Dictionary:
	return {"id": "credits", "end": "reveal", "restore_music": true, "fade_in": 1.2, "fade_out": 1.5,
		"plans": [_credits_plan("C-01", 5.0, 0.0, 1.2, MUSIC % "credits")]}


## The credits as a plan (F-10 at the end of the game: « Ambrelune » alone first, then the roll).
static func _credits_plan(id: String, opening: float, title_alone: float, fade: float, music: String) -> Dictionary:
	return {"id": id, "kind": "credits", "secs": opening, "fade": fade, "opening_secs": opening, "title_alone": title_alone,
		"music": music, "music_loop": true, "music_fade": 2.5, "loops": [AMB % "vagues", AMB % "grillons-nuit"],
		"background": credits_background(), "background_secs": 100.0}


## C-01: the sea at dusk from the end of the jetty of Port-Ambre; the sky (top half, plain) goes from
## dusk to night in 90 s, the stars light up one by one, the moon rises, the amber cliffs glow as night
## falls, the lantern flickers; the dinos pass one at a time (Hauban fishing, Carène's shell, a Grand
## Voyageur on the far hill, two Compsognathus on the planks), and Mastoc comes for the lantern at the
## end and goes off with it.
## Mastoc's gag needs the lantern apart: credits_fond_sans_lanterne.png and its cut-out layer
## credits_fond_lanterne.png (optional). With credits_fond.png alone (the lantern painted on the crate),
## Mastoc comes, sniffs the lantern, and goes away without it.
static func credits_background() -> Dictionary:
	var painted := FOLDER % "credits_fond"
	var apart := FOLDER % "credits_fond_sans_lanterne"
	var lantern := Vector2(0.76, 0.6)
	var mouth := Vector2(0.07, -0.05)
	return {
		"id": "C-01", "image": apart, "image_or": [painted], "camera": _zoom(1.0, 1.04, Vector2(0.5, 0.55), Vector2(0.5, 0.5)),
		"gradient": [Color(0.22, 0.2, 0.42), Color(0.86, 0.52, 0.38)],
		"layers": [
			{"kind": "tint", "gradient": true, "rect": Rect2(0, 0, 1, 0.62), "from": Color(0.04, 0.06, 0.2, 0.0), "to": Color(0.04, 0.06, 0.2, 0.62),
				"start": 4.0, "dur": 86.0},
			{"kind": "tint", "from": Color(0.02, 0.03, 0.1, 0.0), "to": Color(0.02, 0.03, 0.1, 0.32), "start": 10.0, "dur": 80.0},
			_fx("stars", Rect2(0.02, 0.02, 0.96, 0.38), {"start": 10.0, "amount": 70, "life": 120.0}),
			_glow(Vector2(0.88, 0.44), 0.05, Color(1.0, 0.97, 0.86, 0.75), {"to": Vector2(0.84, 0.12), "start": 15.0, "dur": 75.0, "fade_in": true}),
			_glow(Vector2(0.88, 0.44), 0.16, Color(0.8, 0.85, 1.0, 0.18), {"to": Vector2(0.84, 0.12), "start": 15.0, "dur": 75.0, "fade_in": true}),
			_layer("credits_fond", "ambre", {"anim": "fade_in", "start": 30.0, "dur": 40.0}),
			_glow(Vector2(0.12, 0.38), 0.15, AMBER_GLOW, {"pulse": 0.5, "period": 3.5, "wide": 1.5, "fade_in": true, "start": 30.0, "dur": 40.0}),
			_layer("credits_fond", "mer", {"anim": "bob", "amp": 0.003, "angle": 0.0, "period": 5.0}),
			_fx("sparkle", Rect2(0.05, 0.48, 0.9, 0.2)),
			_layer("credits_fond", "lanterne", {"anim": "flicker", "over": apart, "at": lantern, "carried_by": "mastoc_repart", "carry_offset": mouth}),
			_glow(lantern, 0.06, LAMP_GLOW, {"flicker": true, "over": apart, "carried_by": "mastoc_repart", "carry_offset": mouth}),
			_glow(lantern, 0.06, LAMP_GLOW, {"flicker": true, "over": painted}),
			_ptero(Vector2(1.08, 0.2), Vector2(-0.1, 0.3), 8.0, 9.0, 0.06),
			{"kind": "sprite", "species": &"archelon", "from": Vector2(-0.12, 0.62), "to": Vector2(1.12, 0.6), "start": 24.0, "dur": 10.0,
				"height": 0.05, "tint": Color(0.55, 0.62, 0.75, 0.9)},
			{"kind": "sprite", "species": &"brachiosaurus", "from": Vector2(0.5, 0.405), "to": Vector2(0.68, 0.405), "start": 40.0, "dur": 10.0,
				"height": 0.035, "tint": Color(0.3, 0.32, 0.45, 0.9)},
			{"kind": "sprite", "species": &"compsognathus", "from": Vector2(1.05, 0.9), "to": Vector2(-0.05, 0.9), "start": 56.0, "dur": 6.0, "height": 0.07},
			{"kind": "sprite", "species": &"compsognathus", "from": Vector2(1.08, 0.93), "to": Vector2(-0.02, 0.93), "start": 56.6, "dur": 6.0, "height": 0.065},
			{"kind": "sprite", "species": &"allosaurus", "id": "mastoc_vient", "from": Vector2(1.15, 0.7), "to": Vector2(0.9, 0.7),
				"start": 70.0, "dur": 4.5, "height": 0.2},
			{"kind": "sprite", "species": &"allosaurus", "id": "mastoc_repart", "from": Vector2(0.9, 0.7), "to": Vector2(1.22, 0.7),
				"start": 76.0, "dur": 5.0, "height": 0.2},
		],
	}


# ------------------------------------------------------------------ helpers

static func _plan(id: String, image: String, secs: float, fade: float, camera: Array, text: String, color: Color, extra := {}) -> Dictionary:
	var plan := {"id": id, "image": FOLDER % image, "secs": secs, "fade": fade, "camera": camera, "text": text, "color": color}
	plan.merge(extra, true)
	return plan


static func _zoom(from: float, to: float, aim_from: Vector2, aim_to: Vector2) -> Array:
	return [from, aim_from, to, aim_to]


## A pan: the zoom held, the aimed point from x0 to x1 (in the image's width).
static func _pan(zoom: float, x0: float, x1: float, y := 0.5) -> Array:
	return [zoom, Vector2(x0, y), zoom, Vector2(x1, y)]


## A cut-out layer of a painting: <painting>_<name>.png (optional).
static func _layer(painting: String, layer_name: String, extra := {}) -> Dictionary:
	var layer := {"kind": "image", "path": FOLDER % ("%s_%s" % [painting, layer_name])}
	layer.merge(extra, true)
	return layer


static func _fx(preset: String, rect: Rect2, extra := {}) -> Dictionary:
	var fx := {"kind": "particles", "preset": preset, "rect": rect}
	fx.merge(extra, true)
	return fx


static func _glow(at: Vector2, radius: float, color: Color, extra := {}) -> Dictionary:
	var glow := {"kind": "glow", "at": at, "radius": radius, "color": color}
	glow.merge(extra, true)
	return glow


## A Pteranodon on the wing (the game's own sheet: 4 wingbeats, facing right).
static func _ptero(from: Vector2, to: Vector2, start: float, dur: float, height: float) -> Dictionary:
	return {"kind": "sprite", "sheet": PTERO, "cols": 4, "rows": 1, "fps": 6.0, "from": from, "to": to, "start": start, "dur": dur,
		"height": height, "arc": 0.006, "arc_period": 2.4}


## The words of a phrase, as the document counts them (« : », « « » » are not words).
static func word_count(text: String) -> int:
	return Cinematic.word_count(text)


## Every picture a sequence names (main paintings, their stand-ins and the reveals), and the ones
## that are not there yet.
static func pictures(seq: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for plan: Dictionary in seq.get("plans", []):
		var p: Dictionary = plan.get("background", plan)
		var paths: Array = [p.get("image", "")]
		paths.append_array(p.get("image_or", []))
		for layer: Dictionary in p.get("layers", []):
			if layer.get("kind", "") == "reveal":
				paths.append(layer["path"])
		for path in paths:
			if String(path) != "" and not out.has(String(path)):
				out.append(String(path))
	return out


static func missing_pictures(seq: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for path in pictures(seq):
		if not ResourceLoader.exists(path):
			out.append(path)
	return out


# ------------------------------------------------------------------ for the tests and the capture tool

## tools/capture.gd « static »: opens a film ("intro", "fin", "credits") at plan `at`.
static func debug_play(what: String, at := 0) -> String:
	var tree := Engine.get_main_loop() as SceneTree
	var seq: Dictionary = credits_sequence()
	if what == "intro":
		seq = intro_sequence()
	elif what == "fin":
		seq = end_sequence()
	seq["end"] = "reveal"
	var film := Cinematic.play(tree.root, seq)
	if at > 0:
		film.seek.call_deferred(at)
	var missing := PackedStringArray()
	for path in missing_pictures(seq):
		missing.append(path.get_file())
	return "%s : %d plans, images absentes : %s" % [what, seq["plans"].size(), ", ".join(missing)]


static func debug_seek(at: int) -> String:
	if Cinematic.current == null:
		return "aucun film"
	Cinematic.current.seek(at)
	return String(Cinematic.current.plan_now().get("id", ""))


## Time goes on by `secs` at once (the credits' roll, far into it).
static func debug_forward(secs: float) -> String:
	var film := Cinematic.current
	if film == null:
		return "aucun film"
	for i in int(secs * 10.0):
		if film.done:
			return "fini"
		film.advance(0.1)
	return String(film.plan_now().get("id", ""))


## How long each plan stayed on screen, in real time (the film playing, else the last one): « I-01
## 8,4 s · I-02 7,7 s · I-03 en cours depuis 1,2 s ».
static func debug_timeline() -> String:
	var marks: Array[Dictionary] = Cinematic.current.timeline() if Cinematic.current else Cinematic.last_timeline
	var parts := PackedStringArray()
	for i in marks.size():
		if i + 1 < marks.size():
			parts.append("%s %.1f s (horloge du film %.1f s)" % [marks[i]["id"], (marks[i + 1]["ms"] - marks[i]["ms"]) / 1000.0,
				float(marks[i + 1].get("film", 0.0)) - float(marks[i].get("film", 0.0))])
		elif marks[i]["id"] != "fin du film":
			parts.append("%s en cours depuis %.1f s" % [marks[i]["id"], (Time.get_ticks_msec() - marks[i]["ms"]) / 1000.0])
	if marks.size() > 1:
		var last_ms: int = Time.get_ticks_msec() if marks[-1]["id"] != "fin du film" else marks[-1]["ms"]
		parts.append("total %.1f s" % ((last_ms - int(marks[0]["ms"])) / 1000.0))
	var roll: Variant = Cinematic.current.stage_now() if Cinematic.current else null
	if roll is CreditsRoll:
		parts.append("crédits : %s" % (roll as CreditsRoll).phase)
	return " · ".join(parts)


## A key press as the player makes it: "next" (A), "skip" (B, Échap).
static func debug_press(what: String) -> String:
	if Cinematic.current == null:
		return "aucun film"
	if what == "next":
		Cinematic.current.go_on()
	else:
		Cinematic.current.press_skip()
	return "armé" if Cinematic.current and Cinematic.current.skip_control().armed else "—"
