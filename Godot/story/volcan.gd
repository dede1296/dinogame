class_name Volcan
## Chapter 8, the Plaine Volcanique (docs/chapitre-8-scenes.md), the way down and the first zone:
## the Descente de Cendre (two pairs of boots in the ash, and three big toes: Caillou caught them
## up); the Champs de Cendre (everything grey, the volcano right there, seven red fires « comme sur
## la page de Bertille »); the traces round a flat stone (two hollows side by side); the first
## corrupted dino, a Styracosaurus with an iron plate « 3 »: calmed, it trots off towards the forges.
## What the chapter's files share: the places by name (read from story/volcan_places.gd, the CARTE
## agent's, with fallbacks so a scene never breaks), the species or their stand-ins, who crosses
## the lava (a lead dino of stone or fire: « le cuir pour »), a corrupted dino calmed, the events of
## the chapter (run: one branch of Story._run), the scenes on entering its zones (on_zone), the first
## sightings (a thought, once). The forges are in story/volcan_forges.gd and volcan_suie.gd, the
## lava and the sanctuary in volcan_sanctuaire.gd, the crater's door in volcan_porte.gd, Roc,
## Bertille, Joss and Léonce at the port in volcan_autour.gd.
## Flags: volcan_ouvert, descente_cendre, cendres_arrivee, traces_vues, premier_corrompu_volcan,
## numero_3_tente; pensee_saichania, pensee_daspletosaurus (first sightings).

const S := preload("res://story/story.gd")
const CS := preload("res://story/cote_stage.gd")
const MS := preload("res://story/monts_stage.gd")
const Act := preload("res://story/marais_stage.gd")
const CHLOE := "Chloé"
## The zones of the chapter.
const CHAMPS := &"champs_cendres"
const FORGES := &"forges_ombre"
const COULEES := &"coulees_lave"
const SANCTUAIRE := &"sanctuaire_magma"
const PORTE := &"porte_cratere"
## The places' script (the CARTE agent's, class VolcanPlaces): read by path, never by its class.
const PLACES_SCRIPT := "res://story/volcan_places.gd"
## Where things are when VolcanPlaces does not say yet (tiles): only so the objectives have a
## marker. The scenes act round Chloé instead (spot) when a place is missing.
## (Copied from VolcanPlaces of 18/10: the names the scenes read.)
const FALLBACK_PLACES := {
	# champs_cendres (90 x 70)
	"ENTREE_ARCHE": Vector2(45.0, 66.5), "PIERRE_PLATE": Vector2(43.6, 28.6), "CREUX_CAILLOU": Vector2(46.8, 27.6),
	"NUMERO_3": Vector2(36.0, 21.8), "CAGE_OUVERTE": Vector2(35.0, 19.8), "SORTIE_FORGES": Vector2(45.0, 0.5),
	# forges_ombre (80 x 60)
	"ENTREE_FORGES": Vector2(40.5, 56.5), "LEONCE": Vector2(44.6, 50.2), "FORGE_1": Vector2(15.0, 41.0),
	"FORGE_2": Vector2(26.0, 32.0), "FORGE_3": Vector2(64.0, 37.0), "FUT_FORGE_3": Vector2(66.2, 37.4),
	"BARRICADE": Vector2(40.5, 25.3), "BRAC": Vector2(42.0, 17.2), "MASTOC": Vector2(45.8, 18.8),
	"CABOSSE": Vector2(35.0, 19.0), "GROGNON": Vector2(46.6, 15.2), "FOURNAISE": Vector2(51.6, 15.6),
	"MASQUE_BRAC": Vector2(41.0, 18.6), "GRANDE_FORGE": Vector2(40.0, 7.6), "SUIE": Vector2(46.4, 11.0),
	"ETABLI": Vector2(46.4, 9.4), "GANTS": Vector2(45.4, 10.1), "SORTIE_COULEES": Vector2(56.5, 0.5),
	# coulees_lave (80 x 60)
	"ENTREE_COULEES": Vector2(40.5, 56.5), "PREMIERE_COULEE": Vector2(40.5, 45.0), "ROCHER_36": Vector2(29.5, 27.3),
	"FAILLE": Vector2(40.5, 8.05), "PIED_CHEMIN_CRATERE": Vector2(64.5, 11.5), "SORTIE_PORTE": Vector2(64.5, 0.5),
	# sanctuaire_magma (48 x 42)
	"SANCTUAIRE_ENTREE": Vector2(24.5, 37.0), "VASQUE": Vector2(21.4, 26.0), "AUTEL_MAGMA": Vector2(24.0, 17.6),
	"LAVE_PAROI": Vector2(24.0, 8.4), "TREX_MAGMA": Vector2(24.0, 11.4), "TREX_COUCHE": Vector2(27.6, 16.4),
	"PAGE_35": Vector2(28.4, 9.8),
	# porte_cratere (50 x 40)
	"PORTE_ENTREE": Vector2(24.5, 37.0), "PORTAIL": Vector2(25.0, 6.4), "CAMP_HELENE": Vector2(15.4, 7.8),
	"PAGE_38": Vector2(13.8, 9.6), "ISAURE": Vector2(25.0, 10.4), "MAIA": Vector2(20.2, 11.8), "CAILLOU": Vector2(31.0, 9.6),
}
## The spawns' names when VolcanPlaces does not say yet.
const FALLBACK_SPAWNS := {
	"SPAWN_ARCHE": &"DepuisArche", "SPAWN_CHAMPS": &"DepuisChamps", "SPAWN_FORGES": &"DepuisForges",
	"SPAWN_COULEES": &"DepuisCoulees", "SPAWN_SANCTUAIRE": &"DepuisSanctuaire", "SPAWN_PORTE": &"DepuisPorte",
}
## The chapter's species and what stands in for them while their sheets are not in SpeciesDB.
const STAND_INS := {
	&"styracosaurus": &"triceratops", &"saichania": &"ankylosaurus", &"daspletosaurus": &"allosaurus",
	&"trex_magma": &"allosaurus",
}
## The chapter's battles, the MÉCANIQUES agent's (class VolcanBattles: brac_team, BRAC_RULES, trex,
## trex_rules, numero, fournaise), read by path: the scenes fall back on their own until it is there.
const BATTLES_SCRIPT := "res://battle/volcan_battles.gd"
## Ash thrown up, embers; the fires' red.
const ASH_BITS: Array[Color] = [Color(0.62, 0.6, 0.58), Color(0.48, 0.46, 0.45), Color(0.75, 0.73, 0.7)]
const EMBER_BITS: Array[Color] = [Color(1.0, 0.55, 0.2), Color(1.0, 0.8, 0.35), Color(0.9, 0.3, 0.12)]
const FIRE_RED := Color(1.0, 0.42, 0.18)
## Sounds (CS.sfx: nothing when the file is missing): iron that rings, a heavy blow, stone.
const TINKLE := "res://assets/audio/sfx/latch.wav"
const BLOW := "res://assets/audio/sfx/rock_heavy.wav"
const STONE := "res://assets/audio/sfx/pierre.mp3"
const XP_ARRIVEE := 30
const XP_TRACES := 10
const XP_CORROMPU := 20
## Numéro 3 (the bestiary: 42), how far it trots off (tiles), the seven fires' spacing (tiles).
const NUMERO_3_LEVEL := 42
const TROT_TILES := 8.0
const FIRES_GAP := 3.0
## Moustique perched on a shoulder (CieuxArche's shoulder: Maïa's at the crater's door).
const SHOULDER := Vector2(14.0, 2.0)
const SHOULDER_UP := 34.0
## Moustique hidden in Chloé's collar (shoulder_peek, « seulement le bec »): just behind her (north:
## her picture hides his body), lower and closer to her neck than the perch, so only his head shows,
## between her shoulder and her cheek (measured on captures, 18/10: tools/scenarios/ch8_feux_col_test.gd).
const COLLAR := Vector2(6.0, -3.0)
const COLLAR_UP := 21.0
const MOUSTIQUE_LEVEL := 36
## A lead dino named like the starters of the scenes' text (« Écho … Elle réessaie »).
const SHE := ["Écho"]
## First sightings: a thought once, when a wild one of `species` is in sight (tiles), at `phase`
## ("" any), in `zones` ([] any of the chapter's).
const SIGHT_TILES := 7.0
const SIGHT_EVERY := 0.5
const SIGHTINGS := [
	[&"saichania", &"pensee_saichania", "", [],
		"(Un cuirassé. De pierre, celui-là. Hélène a écrit qu'il ne faut pas marcher sur ce qui est rouge… sauf avec le cuir pour.)", true],
	[&"daspletosaurus", &"pensee_daspletosaurus", "night", [&"coulees_lave"],
		"Un Daspletosaurus. La nuit, les coulées l'éclairent par en dessous : il a l'air d'un dino en braise. Il ne charge pas tout de suite : il regarde.", false],
]


# ------------------------------------------------------------------ places and species

## Where `name` is (tiles): VolcanPlaces when the CARTE agent has written it, else the fallback.
static func place(name: String) -> Vector2:
	var places := _places()
	if places.has(name) and places[name] is Vector2:
		return places[name]
	return FALLBACK_PLACES.get(name, Vector2.ZERO)


## The same, in world pixels.
static func px(name: String) -> Vector2:
	var tile := place(name)
	return S.at(tile.x, tile.y)


## True when VolcanPlaces names `name` and Chloé is in one of the chapter's zones (the scenes then
## act there, not round Chloé: a test on another zone plays round her).
static func has_place(name: String) -> bool:
	return Game.region_id in [CHAMPS, FORGES, COULEES, SANCTUAIRE, PORTE] and _places().get(name) is Vector2


## Where a scene acts (px): the place `name` when VolcanPlaces has it, else Chloé + `offset` (px),
## so a scene plays anywhere (a test on another zone) without looking off the map.
static func spot(name: String, offset := Vector2.ZERO) -> Vector2:
	if has_place(name):
		return px(name)
	var chloe := Stage.chloe()
	return (chloe.global_position if chloe else Vector2.ZERO) + offset


## The place `name` (px) when VolcanPlaces has it, else `fallback_px` (near the actor of a scene).
static func spot_or(name: String, fallback_px: Vector2) -> Vector2:
	return px(name) if has_place(name) else fallback_px


## A spawn's name (VolcanPlaces.SPAWN_*), else the fallback.
static func spawn(name: String) -> StringName:
	var places := _places()
	if places.get(name) is StringName:
		return places[name]
	return FALLBACK_SPAWNS.get(name, &"Depart")


static func _places() -> Dictionary:
	if ResourceLoader.exists(PLACES_SCRIPT):
		return (load(PLACES_SCRIPT) as Script).get_script_constant_map()
	return {}


## `id` when SpeciesDB has it, else its stand-in (a scene never breaks for a missing sheet).
static func species_or(id: StringName) -> StringName:
	if SpeciesDB.PATHS.has(id):
		return id
	return STAND_INS.get(id, MS.species_or(id))


## A dino only a scene needs (CS.stand_in), its species or its stand-in; invisible at first.
static func stand_in(id: StringName, at_px: Vector2, node_name: String, level := 0, size := 1.0, corrupted := false) -> DinoNpc:
	var w = S.world()
	if w == null or w.get("region") == null:
		return null
	var species := species_or(id)
	if not SpeciesDB.PATHS.has(species):
		return null
	var d := DinoNpc.new()
	d.name = node_name
	d.species_id = species
	d.level = level
	d.size_scale = size if SpeciesDB.PATHS.has(id) else 1.0
	d.corrupted = corrupted
	d.position = at_px
	d.modulate.a = 0.0
	w.region.entities.add_child(d)
	d.collision_layer = 0
	return d


## The first of `names` that is a node of the zone (null when none is).
static func actor_of(names: Array):
	for n: String in names:
		var a = S.actor(n)
		if a != null:
			return a
	return null


## Where a node of the zone stands (px), else `fallback`.
static func at_node(names: Array, fallback: Vector2) -> Vector2:
	var a = actor_of(names)
	return (a as Node2D).global_position if a is Node2D else fallback


## The first of `sheets` that is drawn (assets/art/characters/<sheet>.png).
static func sheet(sheets: Array) -> String:
	for s: String in sheets:
		if ResourceLoader.exists("res://assets/art/characters/%s.png" % s):
			return s
	return sheets[-1]


## « Il » or « Elle » for a lead dino (the text's own starters: Écho is a she).
static func pronoun(d: Dino) -> String:
	return "Elle" if d and d.nickname in SHE else "Il"


# ------------------------------------------------------------------ the lava (« le cuir pour »)

## The lead dino when it carries Chloé over the lava (the « Cuir de feu »: actors/lava.gd, the
## MÉCANIQUES agent's rule), else null.
static func lava_crosser() -> Dino:
	return Lava.walker()


## What keeps Chloé from crossing ("" when she can): who of the party or the Cabinet could (name,
## type), or where to find one (Lava.who_could).
static func lava_step() -> String:
	return "" if Lava.can_cross() else Lava.who_could()


# ------------------------------------------------------------------ the battles

## The MÉCANIQUES agent's battles of the chapter (VolcanBattles), null while it is not there.
static func battles():
	return load(BATTLES_SCRIPT) if ResourceLoader.exists(BATTLES_SCRIPT) else null


## `method` of VolcanBattles called with `args` when it has it, else `fallback`.
static func from_battles(method: StringName, args: Array, fallback: Variant) -> Variant:
	var b = battles()
	if b and (b as Script).get_script_method_list().any(func(m: Dictionary) -> bool: return m["name"] == String(method)):
		return b.callv(method, args)
	return fallback


## A constant of VolcanBattles (BRAC_RULES…), else `fallback`.
static func battles_const(name: String, fallback: Variant) -> Variant:
	var b = battles()
	return (b as Script).get_script_constant_map().get(name, fallback) if b else fallback


# ------------------------------------------------------------------ the chapter's events

## The way down opens as soon as the mask has fallen (masque_tombe): the Arche's exit to the
## volcano (its required_flag). Called on entering a zone; DialogueVolcan does it too.
static func update_access() -> void:
	if Game.flag(&"masque_tombe") and not Game.flag(&"volcan_ouvert"):
		Game.set_flag(&"volcan_ouvert")


## The scene on entering one of the chapter's zones (Story._on_zone_entered).
static func on_zone(zone: StringName) -> void:
	watch_sightings(zone)   # (not awaited: a thought once, while she is in the zone)
	match zone:
		&"champs_cendres":
			await arrival()
		&"forges_ombre":
			await VolcanForges.arrival()
		&"coulees_lave":
			await VolcanSanctuaire.coulees()
		&"sanctuaire_magma":
			await VolcanSanctuaire.arrival()
		&"porte_cratere":
			await VolcanPorte.arrival()


## The chapter's scenes started by talking to someone or something, or by walking somewhere (one
## branch of Story._run). False when `event` is not one of the chapter's.
static func run(event: StringName, who: Node) -> bool:
	match event:
		# The champs (this file)
		&"traces":
			await traces(who)
		&"pierre_plate":
			await S.say([{"text": "Deux creux dans la cendre, côte à côte. Et un énorme, un peu plus loin."}])
		&"numero_3", &"numero3", &"corrompu_3":
			await numero_3(who)
		&"cage_ouverte", &"cage_ouverte_cendres":
			await S.say(DialogueVolcan.lines(&"cage_ouverte_cendres"))
		&"fut_renverse", &"fut_renverse_cendres":
			await S.say(DialogueVolcan.lines(&"fut_renverse"))
		# The forges (story/volcan_forges.gd, volcan_suie.gd)
		&"leonce":
			await VolcanForges.leonce(who)
		&"masques_os":   # (the bone masks sitting by the barrels, Npcs « MasqueOs1/2 »: the arrival's words)
			await S.say([{"text": "Les masques d'os qui restent sont assis par terre. Ils ne font rien. L'un d'eux dort."}])
		&"numero_7", &"numero7", &"forge_1", &"forge1":
			await VolcanForges.forge(1, who)
		&"numero_11", &"numero11", &"forge_2", &"forge2":
			await VolcanForges.forge(2, who)
		&"numero_12", &"numero12", &"forge_3", &"forge3":
			await VolcanForges.forge(3, who)
		&"barricade":
			await VolcanForges.barricade(who)
		&"brac_volcan":
			await VolcanForges.brac(who)
		&"masque_brac":
			await VolcanForges.masque_brac(who)
		&"suie_volcan":
			await VolcanSuie.suie(who)
		&"grande_forge":
			await VolcanSuie.grande_forge(who)
		&"etabli", &"etabli_suie":
			await VolcanSuie.etabli(who)
		# The lava and the sanctuary (story/volcan_sanctuaire.gd)
		&"premiere_coulee":
			await VolcanSanctuaire.premiere_coulee(who)
		&"faille_sanctuaire", &"faille":
			await VolcanSanctuaire.faille(who)
		&"vasque", &"vasque_source":
			await VolcanSanctuaire.vasque(who)
		&"trex_magma":
			await VolcanSanctuaire.trex(who)
		&"autel_magma":
			await VolcanSanctuaire.autel(who)
		# The crater's door (story/volcan_porte.gd)
		&"camp_helene":
			await VolcanPorte.camp(who)
		&"isaure_porte":
			await VolcanPorte.isaure(who)
		&"maia_porte":
			await VolcanPorte.maia(who)
		&"caillou_porte":
			await VolcanPorte.caillou(who)
		&"portail_apex":
			await VolcanPorte.portail(who)
		# Around (story/volcan_autour.gd): Léonce on the pontoon of Port-Ambre, Brac at the end of it
		&"leonce_port":
			await VolcanAutour.leonce_port(who)
		&"brac_jetee":
			await VolcanAutour.brac_jetee(who)
		_:
			return false
	return true


# ------------------------------------------------------------------ the Descente de Cendre

## Scene 1, the way down from the Arche (the dialogue « volcan_bloque » once the mask has fallen,
## or the start of the arrival): the boots in the ash, Caillou's toes, Moustique afraid of the
## fire. `go_down`: Chloé then goes down at once (she walked into the Arche's exit while it was
## still closed: the way opens with these lines).
static func descent(go_down: bool) -> Array:
	var chloe := Stage.chloe()
	var lines: Array = [
		{"text": "La Descente de Cendre. Un sentier gris qui descend vers le volcan, en lacets, dans un vent chaud qui sent le soufre. À chaque lacet, la cendre est marquée de pas : deux paires de bottes, une grande, une petite. Et, par-dessus, trois gros orteils qui traînent."},
		{"who": CHLOE, "text": "(Caillou. Il les a rattrapées. Évidemment. … Pas de « c'est stylé ». Pas de Maïa qui râle parce que ça descend. Elle aurait râlé quand même.)"},
		CS.cue({"text": "Moustique s'aplatit sur l'épaule de Chloé. En bas, ça brille rouge, et il a peur du feu."},
			func() -> void:
				if chloe:
					Stage.tremble(chloe, 0.6, 1.2)
					shoulder_peek(chloe, 1.8)),
		{"flag": &"volcan_ouvert"},
		{"flag": &"descente_cendre"},
	]
	var last := {"who": CHLOE, "text": "Moi aussi, un peu. On y va quand même. Elle m'a dit de te garder, pas de te laisser."}
	lines.append(CS.cue(last, _go_down_when_done) if go_down else last)
	return lines


## Once the lines are over, Chloé goes down the Descente de Cendre (to the Champs de Cendre).
static func _go_down_when_done() -> void:
	while Dialogue.active:
		await S.wait(0.1)
	await S.wait(0.2)
	var w = S.world()
	if w and w.has_method(&"goto_zone"):
		w.call(&"goto_zone", CHAMPS, spawn("SPAWN_ARCHE"))


# ------------------------------------------------------------------ the Champs de Cendre

## Scene 2, the first time in the Champs de Cendre: grey everywhere, the ash like flour; the
## volcano right there, the seven fires; the lead dino and the ash; the hot wind; Chloé alone,
## « Il reste un Cœur »; Moustique peeks out and hides again.
static func arrival() -> void:
	if Game.flag(&"cendres_arrivee"):
		return
	var w = S.world()
	if w == null:
		return
	S.lock(true)
	await S.wait(0.4)
	var chloe := Stage.chloe()
	if not Game.flag(&"descente_cendre"):
		await S.say(descent(false))
	var fires := spot("FEUX_FORGES", Vector2(0.0, -8.0 * S.CELL))   # (north: the volcano's foot)
	var grey := func() -> void:
		await Stage.bow(chloe, 0.7)
		for i in 3:
			Act.burst(chloe.global_position + Vector2(randf_range(-16.0, 16.0), 4.0), ASH_BITS, 10, 0.15, 0.35)
			await S.wait(0.35)
	var volcano := func() -> void:
		# (just above the line of fires: 2 tiles higher, they fell under the dialogue box)
		await Stage.look_at(fires + Vector2(0.0, -0.5 * S.CELL), 1.6)
		seven_fires(fires)
		Stage.shake(0.8, 0.6)
	var wind := func() -> void:
		Stage.look_back(1.0)
		for i in 4:
			Act.burst(chloe.global_position + Vector2(-40.0 + 26.0 * i, -6.0), ASH_BITS, 8, 0.6, 0.5)
			await S.wait(0.25)
		Stage.recoil(chloe, chloe.global_position + Vector2(40.0, 0.0), 8.0)
	var lines: Array = [
		CS.cue({"text": "Le vert a disparu il y a longtemps, le blanc aussi. Ici, tout est gris : la cendre monte jusqu'aux chevilles et se soulève à chaque pas, comme de la farine qu'on aurait laissée refroidir."}, grey),
		CS.cue({"text": "Le volcan n'est plus « au loin ». Il est là, devant, et il fume. À son pied, des feux rouges, en ligne. Sept. Comme sur la page de Bertille."}, volcano),
	]
	var lead := Game.lead_dino()
	if lead:
		lines.append_array(_lead_in_the_ash(lead))
	lines.append_array([
		CS.cue({"text": "Le vent est chaud. Pas chaud comme le Désert : chaud comme la porte d'un four quand on passe devant."}, wind),
		{"who": CHLOE, "text": "(Elle est passée par là, les Cœurs contre elle, sans courir. Et Maïa à côté. Pas derrière : à côté. … Il reste un Cœur, là-dessous, quelque part, à battre tout seul. Comme moi.)"},
		CS.cue({"who": CHLOE, "text": "Ça va. Ils sont loin. … Bon. Ils ne sont pas si loin."}, func() -> void: shoulder_peek(chloe, 1.4)),
		{"flag": &"cendres_arrivee"},
	])
	await S.say(lines)
	_ash_off()
	CS.lead_back()
	Stage.look_back()
	Game.award_team_xp(XP_ARRIVEE)
	Save.save_game()
	S.lock(false)


## How the lead dino meets the ash (the raptor sneezes; the armoured one turns into a grey rock;
## the duck-bill's « tuut » goes « puff »).
static func _lead_in_the_ash(lead: Dino) -> Array:
	var dino := CS.lead()
	var chloe := Stage.chloe()
	match lead.species().family:
		&"raptor":
			return [CS.cue({"text": "%s éternue. Une fois, deux fois, et il regarde la cendre comme si elle l'avait fait exprès." % lead.nickname},
				func() -> void:
					if dino:
						for i in 2:
							Stage.hop(dino, 1, 5.0)
							Stage.cry(dino, &"neutre")
							Act.burst(dino.global_position + Vector2(0.0, -10.0), ASH_BITS, 6, 0.5, 0.2)
							await S.wait(0.6)
						Stage.turn_to(dino, dino.global_position + Vector2(0.0, 40.0))
						Stage.emote(dino, "?"))]
		&"armored":
			return [CS.cue({"text": "%s avance, et la cendre le recouvre peu à peu. %s devient gris. %s devient un rocher gris. « Je sais. Je ne m'assois pas dessus. »" % [lead.nickname, pronoun(lead), pronoun(lead)]},
				func() -> void:
					if dino:
						CS.lead_walk(chloe.global_position + Vector2(50.0, -30.0), 30.0)
						var sprite := Stage.sprite_of(dino)
						if sprite:
							sprite.set_meta(&"ash_grey", true)
							sprite.create_tween().tween_property(sprite, "self_modulate", Color(0.66, 0.65, 0.64), 2.4)
						Stage.turn_to(chloe, dino.global_position))]
		&"hadrosaur":
			return [CS.cue({"text": "%s souffle un petit « tuut » plein de cendre, et tousse. %s réessaie. Ça fait « puff »." % [lead.nickname, pronoun(lead)]},
				func() -> void:
					if dino:
						Stage.rear(dino, 0.8)
						Stage.cry(dino, &"neutre")
						await S.wait(0.9)
						Stage.tremble(dino, 0.5, 1.5)
						await S.wait(0.6)
						Act.burst(dino.global_position + Vector2(0.0, -30.0), ASH_BITS, 10, 1.0, 0.2))]
	return []


## The lead dino's colours back after the ash (the armoured one turned grey).
static func _ash_off() -> void:
	var dino := CS.lead()
	var sprite := Stage.sprite_of(dino)
	if sprite and sprite.has_meta(&"ash_grey"):
		sprite.remove_meta(&"ash_grey")
		sprite.create_tween().tween_property(sprite, "self_modulate", Color.WHITE, 1.0)


## Seven red fires in a line at the volcano's foot (lights of the 3D view pulsing there).
static func seven_fires(centre: Vector2, times := 2) -> void:
	for i in 7:
		CS.pulse(centre + Vector2((i - 3) * FIRES_GAP * S.CELL, 0.0), FIRE_RED, times, 1.6, 2.4, 4.0)
		await S.wait(0.12)


## Moustique peeks out of Chloé's collar and hides again: a small stand-in on her shoulder.
static func shoulder_peek(chloe: Node2D, secs := 1.4) -> void:
	if chloe == null:
		return
	var bird := stand_in(&"dimorphodon", chloe.global_position + COLLAR, "MoustiqueCol", MOUSTIQUE_LEVEL, 0.8)
	if bird == null:
		return
	var sprite := Stage.sprite_of(bird)
	if sprite:
		sprite.position.y = -COLLAR_UP
		sprite.set_meta(&"stage_rest", sprite.position)
	await Stage.fade_in(bird, 0.3)
	Stage.emote(bird, "…")
	await S.wait(secs)
	Stage.fade_out(bird, 0.4, true)


# ------------------------------------------------------------------ the traces, Numéro 3

## 2 bis, the traces (StoryTrigger « Traces », once_flag traces_vues): round the flat stone, two
## hollows side by side; a huge third one further on, and reeds half chewed.
static func traces(_trigger: Node) -> void:
	if Game.flag(&"traces_vues"):
		return
	S.lock(true)
	var chloe := Stage.chloe()
	var stone := at_node(["PierrePlate"], spot("PIERRE_PLATE", Vector2(60.0, -50.0)))
	var round_it := func() -> void:
		await Stage.look_at(stone, 1.0)
		await CS.chloe_walk(stone + Vector2(-40.0, 34.0), 90.0, 2.2)
		Stage.turn_to(chloe, stone)
		MS.kneel()
	var further := func() -> void:
		var big := stone + Vector2(2.5 * S.CELL, -1.5 * S.CELL)
		MS.stand_up(chloe)
		Stage.look_at(big, 1.0)
		Stage.turn_to(chloe, big)
		Act.burst(big, ASH_BITS, 8, 0.2, 0.4)
	await S.say([
		CS.cue({"text": "Dans la cendre, les traces continuent. Elles tournent une fois autour d'une grosse pierre plate, puis repartent droit vers les feux. Sur la pierre, quelqu'un s'est assis : il y a deux creux, côte à côte."}, round_it),
		{"who": CHLOE, "text": "(Elles se sont arrêtées ici. Pas longtemps. … Deux creux. Côte à côte.)"},
		CS.cue({"text": "Un peu plus loin, un troisième creux, énorme, et des roseaux à moitié mâchés. Caillou n'attend jamais, mais il mange toujours."}, further),
		{"flag": &"traces_vues"},
	])
	MS.stand_up(chloe)
	Stage.look_back()
	Game.award_team_xp(XP_TRACES)
	Save.save_game()
	S.lock(false)


## 2 ter, Numéro 3 (DinoNpc « Numero3 », corrupted, hide_flag premier_corrompu_volcan): a
## Styracosaurus with an iron plate « 3 » by an open cage; it charges; calmed, it looks at Chloé,
## at the cage, at the fires, and trots off towards the forges, head down. It does not join.
static func numero_3(who: Node) -> void:
	if Game.flag(&"premier_corrompu_volcan"):
		return
	var chloe := Stage.chloe()
	var at: Vector2 = (who as Node2D).global_position if who is Node2D else chloe.global_position + Vector2(0.0, -80.0)
	var seen := "Un Styracosaurus. Des veines violettes sous la cendre, des yeux troubles, et une plaque de fer au cou, gravée au clou : « 3 »."
	if not Game.flag(&"numero_3_tente"):
		Game.set_flag(&"numero_3_tente")
		S.lock(true)
		await S.say([
			CS.cue({"text": seen}, func() -> void:
				Stage.look_at(at.lerp(chloe.global_position, 0.4), 0.8)
				Stage.tremble(who, 1.2, 2.0)),
			{"who": CHLOE, "text": "(Pas de nom. Un numéro. … Même Brac donnait des noms.)"},
			CS.cue({"text": "Il charge."}, func() -> void: Stage.lunge(who, chloe.global_position, 1.6)),
		])
		S.lock(false)
	elif await Dialogue.choose("", seen, ["L'approcher doucement", "Pas maintenant"]) != 0:
		return
	if not await calm(who, 3, &"styracosaurus", NUMERO_3_LEVEL,
		["Les corrompus des forges ne rejoignent pas l'équipe : une fois apaisés, ils ont une chose à régler là-bas."]):
		return
	await _numero_3_calmed(who)


## Calmed: the plate rings against its horns; it looks at Chloé, the cage, the fires, and trots off
## towards the forges (also the test's entry: static_champs).
static func _numero_3_calmed(who: Node) -> void:
	S.lock(true)
	var chloe := Stage.chloe()
	var at: Vector2 = (who as Node2D).global_position if who is Node2D else chloe.global_position + Vector2(0.0, -80.0)
	var cage := at_node(["CageOuverte", "CageNumero3"], spot_or("CAGE_OUVERTE", at + Vector2(-50.0, -90.0)))
	var forges := spot_or("SORTIE_FORGES", at + Vector2(0.0, TROT_TILES * S.CELL))
	var shakes := func() -> void:
		Stage.tremble(who, 0.5, 3.0)
		CS.sfx(TINKLE, -10.0)
	var looks := func() -> void:
		Stage.turn_to(who, chloe.global_position)
		await S.wait(0.9)
		Stage.turn_to(who, cage)
		await S.wait(0.9)
		Stage.turn_to(who, forges)
	var trots := func() -> void:
		if who is DinoNpc:
			var dir: Vector2 = (forges - at).normalized() if forges.distance_to(at) > 1.0 else Vector2(0.0, -1.0)
			Stage.fade_out(who, 2.6, true)
			(who as DinoNpc).walk_to(at + dir * TROT_TILES * S.CELL, 150.0)
	await S.say([
		CS.cue({"text": "Les veines s'éteignent. Le Styracosaurus secoue la tête, et la plaque « 3 » tinte contre ses cornes."}, shakes),
		CS.cue({"text": "Il regarde Chloé, puis la cage ouverte, puis les feux au loin. Et il part. Pas vers les champs : vers les forges, au trot, la tête baissée."}, looks),
		CS.cue({"who": CHLOE, "text": "(Il n'a pas peur. Il est en colère. … Et il sait où aller.)"}, trots),
		{"flag": &"premier_corrompu_volcan"},
	])
	Stage.look_back()
	Game.award_team_xp(XP_CORROMPU)
	Save.save_game()
	S.lock(false)


## A numbered corrupted dino of the chapter (its iron plate `plate`) calmed in battle (the rule of
## the game: it cannot be beaten, only calmed with Apaiser; « calmed » is a win): its species, level
## and rules from VolcanBattles.numero(plate) / numero_rules when there, else these; its veins go out
## (DinoNpc.cleanse). True when calmed. No collar: they do not join (« une chose à régler là-bas »).
static func calm(who: Node, plate: int, species: StringName, level: int, lesson := []) -> bool:
	var w = S.world()
	if w == null or Game.party.is_empty():
		return false
	var foe = from_battles(&"numero", [plate], null)
	if not foe is Dino:
		foe = Dino.create(species_or(species), level)
		foe.corrupted = true
	var rules: Dictionary = from_battles(&"numero_rules", [plate, not lesson.is_empty()], {"catch": false})
	if not lesson.is_empty():   # (the scenes' own lesson, after the mechanics' one)
		rules["lesson"] = (rules.get("lesson", []) as Array) + lesson
	var result: String = await w.call(&"_battle", foe, rules)
	if result != "calmed" and result != "win":
		return false
	if who is DinoNpc and is_instance_valid(who):
		await (who as DinoNpc).cleanse()
	return true


# ------------------------------------------------------------------ first sightings

## While Chloé is in zone `zone`, a thought the first time a wild one of SIGHTINGS is in sight
## (once each, never during a scene). Not awaited: it ends with the zone.
static func watch_sightings(zone: StringName) -> void:
	var w = S.world()
	if w == null or w.get("region") == null:
		return
	var region: Node = w.region
	while is_instance_valid(region) and region.is_inside_tree() and _pending(zone):
		await S.wait(SIGHT_EVERY)
		if not is_instance_valid(region) or S.world() == null or S.world().get("region") != region:
			return
		var chloe := Stage.chloe() as Player
		if chloe == null or not chloe.can_move() or S.playing > 0:
			continue
		for row: Array in SIGHTINGS:
			if _due(row, zone) and _in_sight(row[0], chloe):
				Game.set_flag(row[1])
				await S.say([{"who": CHLOE, "text": row[4]} if row[5] else {"text": row[4]}])
				break


## A first sighting still to say in this zone.
static func _pending(zone: StringName) -> bool:
	for row: Array in SIGHTINGS:
		if not Game.flag(row[1]) and ((row[3] as Array).is_empty() or zone in row[3]):
			return true
	return false


static func _due(row: Array, zone: StringName) -> bool:
	if Game.flag(row[1]) or not ((row[3] as Array).is_empty() or zone in row[3]):
		return false
	return row[2] == "" or Game.phase() == StringName(row[2])


## A wild dino of `species` close to Chloé, in plain sight.
static func _in_sight(species: StringName, chloe: Node2D) -> bool:
	var tree := chloe.get_tree()
	for n in tree.get_nodes_in_group(&"dino_actor"):
		if n is WildDino and (n as WildDino).species_id == species and (n as Node2D).visible \
			and (n as Node2D).global_position.distance_to(chloe.global_position) < SIGHT_TILES * S.CELL:
			return true
	return false


# ------------------------------------------------------------------ for the tests

## The lines of each of `ids` said now, one after the other (tools/capture.gd « static »: pages,
## signs, closed ways).
static func say_lines(ids: Array) -> void:
	S.playing += 1
	for id in ids:
		await S.say(DialogueVolcan.lines(StringName(id)))
	S.playing -= 1


## For the tests (tools/capture.gd « static »): Moustique peeking out of Chloé's collar, held `secs`
## (where his beak shows, against her collar).
static func static_col(secs := 6.0) -> void:
	S.playing += 1
	await shoulder_peek(Stage.chloe(), float(secs))
	S.playing -= 1


## For the tests (tools/capture.gd « static »): the Descente and the Champs de Cendre on any zone
## (the arrival, the traces, Numéro 3 calmed: a stand-in brought by Chloé, no battle).
static func static_champs() -> void:
	S.playing += 1
	await arrival()
	await traces(null)
	var chloe := Stage.chloe()
	var three := stand_in(&"styracosaurus", S.ground_near(chloe.global_position + Vector2(0.0, -2.5 * S.CELL), 3), "Numero3Test", 0, 1.0, true)
	if three:
		await Stage.fade_in(three, 0.4)
		await (three as DinoNpc).cleanse()
		await _numero_3_calmed(three)
	S.playing -= 1
