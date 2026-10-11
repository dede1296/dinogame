class_name CieuxNids
## Chapter 7, the Cieux Éternels, the giant nests (zone nids_geants; docs/histoire.md, ch. 7,
## points 3 and 6): nests as big as boats, young ones « grands comme des Ptéranodons adultes »; up
## on the rim of the Grand Nid, the Quetzalcoatlus Roi. It opens its wings (the wind pushes Chloé
## back a step; she does not run), lowers its head to her, smells the Sceaux and the Cœurs; in its
## nest, kept twenty-five years, Hélène's old harness with a fern stamped in it; Chloé lays Joss's
## beside it: the same fern. Then it takes off and cries: a battle of honour in the wind (it never
## lands). Won: it bows its neck to the grass; under the old harness, the Sceau des Cieux; its
## second cry, and every piton answers: the Vol (free, piloted: story/vol.gd). It looks down at the
## Monts, long, and flies that way (it will bring Maïa to the Arche).
## Flags: nids_arrivee, quetzal_roi_parle, quetzal_roi_battu, quetzal_roi_confiance, sceau_cieux,
## vol_obtenu; roi_n (lines).

const S := preload("res://story/story.gd")
const CS := preload("res://story/cote_stage.gd")
const MS := preload("res://story/monts_stage.gd")
const C := preload("res://story/cieux.gd")
const CHLOE := "Chloé"
## The guardian: a battle of honour (levels 38-44 of the bestiary; to be simulated by the
## MÉCANIQUES agent), its size in the world and in battle.
const ROI := &"quetzalcoatlus"
const ROI_NAME := "Quetzalcoatlus Roi"
const ROI_NODES := ["QuetzalRoi", "QuetzalcoatlusRoi"]
const ROI_LEVEL := 44
const ROI_SIZE := 1.3
## How far above his feet the camera aims when it shows him from afar (tiles: he is very tall).
const ROI_FRAME_UP := 2.5
## Hélène's old harness in the nest (a StoryProp of the zone, or shown by the scene when its
## picture exists), the Sceau.
const OLD_HARNESS := "vieux_harnais"
const OLD_HARNESS_NODES := ["VieuxHarnais"]
const SEAL := "sceau_cieux"
## How high it hovers for the challenge (px), how long the wind of its wings blows (s).
const HOVER := CS.FLY_HEIGHT + 60.0
const WING_WIND := 1.6
const XP_ARRIVEE := 20
const XP_SCEAU := 120
## The young ones in the nests (stand-ins: species, offset in tiles from NIDS, size).
const YOUNG := [[&"quetzalcoatlus", Vector2(-3.0, 0.5), 0.55], [&"quetzalcoatlus", Vector2(2.5, 1.5), 0.6], [&"tapejara", Vector2(0.0, -2.0), 0.8]]
const ROI_AGAIN := [
	"Le Roi tourne la tête vers Chloé, un œil grand comme une assiette, et souffle. Le souffle sent la pluie.",
	"Le Roi regarde en bas, vers les Monts, longtemps. Puis vers l'Arche. Puis Chloé. Il a l'air de compter.",
	"Le Roi pose son bec sur le vieux harnais d'Hélène, au bord du nid, et ne bouge plus. Chloé ne le dérange pas.",
]


# ------------------------------------------------------------------ arriving

## The first time among the nests: the shells, the young ones, a pair of Tapejara; up on the Grand
## Nid, the Roi, still as a piton.
static func arrival() -> void:
	if Game.flag(&"nids_arrivee"):
		return
	var w = S.world()
	if w == null:
		return
	S.lock(true)
	await S.wait(0.4)
	var chloe := Stage.chloe()
	var nests := C.px("NIDS")
	var top := C.px("GRAND_NID")
	var cast := {}
	var roi = _actor(ROI_NODES)
	var shells := func() -> void:
		Stage.look_at(nests, 1.6)
		CS.sparkle(nests + Vector2(-40.0, 10.0), 0.3, 6, 0.3)
	var young := func() -> void:
		for i in YOUNG.size():
			var spec: Array = YOUNG[i]
			var d := C.stand_in(spec[0], nests + (spec[1] as Vector2) * S.CELL, "Petit%d" % i, 8, spec[2])
			if d:
				cast["young_%d" % i] = d
				Stage.fade_in(d, 0.8)
				Stage.hop(d, 2, 5.0)
	var up := func() -> void:
		# (Framed on the Roi himself, a little above his feet: the whole of him, head included.)
		var aim: Vector2 = (roi as Node2D).global_position + Vector2(0.0, -ROI_FRAME_UP * S.CELL) if roi is Node2D \
			else top + Vector2(0.0, 1.0 * S.CELL)
		await CS.pan(aim, 2.0)
		if roi:
			Stage.emote(chloe, "!")
	var lines: Array = [
		CS.cue({"text": "Des nids. Grands comme des barques, tressés de branches entières, posés en étages le long de la roche. Des coquilles cassées partout, épaisses comme des assiettes."}, shells),
		CS.cue({"text": "Dedans, des petits. Grands comme des Ptéranodons adultes… et ce sont des bébés. Ils regardent Chloé en penchant la tête, tous du même côté."}, young),
		{"who": CHLOE, "text": "(Si ce sont les petits… les parents, ils font quelle taille ?)"},
		CS.cue({"text": "Tout en haut, au bord du plus grand nid, quelque chose ne bouge pas. On dirait un piton de plus. Puis le piton tourne la tête."}, up),
		{"who": CHLOE, "text": "(Le Roi des Cieux.)"},
		{"text": "Une planchette, clouée sur un vieux poteau : « On ne grimpe pas dans les nids. Même vides. Surtout vides. — H. »"},
		{"flag": &"nids_arrivee"},
	]
	await S.say(lines)
	for k in cast:
		var n = cast[k]
		if is_instance_valid(n):
			Stage.fade_out(n, 1.0, true)
	Stage.look_back()
	Game.award_team_xp(XP_ARRIVEE)
	Save.save_game()
	S.lock(false)


# ------------------------------------------------------------------ the Roi

## The Quetzalcoatlus Roi (DinoNpc « QuetzalRoi », event « quetzal_roi »): its wings, its eye,
## the old harness; then it takes off and cries (the first time); a battle of honour in the wind;
## won, the Sceau and the Vol. Afterwards, a line at each visit.
static func roi(who: Node) -> void:
	if Game.flag(&"sceau_cieux"):
		await S.say([_again(who)])
		return
	if not Game.flag(&"quetzal_roi_battu"):
		if not Game.flag(&"quetzal_roi_parle"):
			S.lock(true)
			await S.say(_wings(who))
			await S.say(_sniffs(who))
			await S.say(_old_harness(who))
			S.lock(false)
		var pick := await Dialogue.choose("", "Le Quetzalcoatlus Roi plane au-dessus du nid, sans un battement d'ailes. Il veut savoir si l'héritière d'Hélène tient dans le vent.",
			["Relever le défi", "Pas encore"])
		if pick != 0:
			return
		await MS.rested("Le Roi attend pendant que tes dinos boivent l'eau de pluie du Grand Nid. Elle est froide, et elle les remet d'aplomb. Un combat d'honneur se livre reposé.",
			func() -> void:
				var dino := CS.lead()
				if dino:
					Stage.bow(dino, 0.8))
		var species := C.species_or(ROI)
		var foe := Dino.create(species, ROI_LEVEL, ROI_NAME)
		var rules := {"catch": false, "run": false, "lose_spawn": C.SPAWN_CIEUX, "size": ROI_SIZE,
			"intro": "Le Quetzalcoatlus Roi crie dans le vent ! (Combat d'honneur : pas de collier, pas de fuite. Il ne se posera pas.)",
			"lesson": _lesson(foe)}
		var theme: AudioStream = MS.music(MS.ALPHA_MUSIC)
		if theme:
			rules["music"] = theme
		var result: String = await S.world().call(&"_battle", foe, rules)
		if result != "win":
			return
		Game.set_flag(&"quetzal_roi_battu")
		Save.save_game()
	await _gives_seal(who)


## What the battle's first lines teach: what hits it hard, what its blows hurt (from its type).
static func _lesson(foe: Dino) -> Array:
	var type := foe.type()
	var weak := MS.weak_to(type)
	var hurts := MS.hurts(type, MS.TYPE_OF)
	var lines: Array = []
	if weak != "":
		lines.append("Le Roi est un dino %s : %s le touche%s fort." % [MS.TYPE_OF.get(type, type), weak, "nt" if " et " in weak else ""])
	if hurts != "":
		lines.append("Ses coups font très mal aux dinos %s. Tu peux changer de dino pendant le combat." % hurts)
	return lines


## It opens its wings: the wind pushes Chloé a step back, her lead dino flattens; she does not run.
static func _wings(who: Node) -> Array:
	var chloe := Stage.chloe()
	var at: Vector2 = (who as Node2D).global_position
	var opens := func() -> void:
		await CS.step_aside(who, 100.0)
		Stage.turn_to(who, chloe.global_position)
		Stage.rear(who, 1.6)
		Stage.cry(who, &"neutre")
		Stage.shake(2.0, WING_WIND)
		Stage.recoil(chloe, at, 22.0)
		var dino := CS.lead()
		if dino:
			CS.crouch(dino, 0.25, 0.8)
		for i in 4:
			MS.snow_puff(chloe.global_position + Vector2(randf_range(-60.0, 60.0), 10.0), 8, 0.4, 0.6)
			await S.wait(0.3)
	var stands := func() -> void:
		Stage.turn_to(chloe, at)
		Stage.emote(chloe, "…")
	return [
		CS.cue({"text": "Le Roi se dresse au bord du nid et ouvre les ailes. D'un bord à l'autre, elles cachent le ciel. Le vent qu'elles font pousse Chloé en arrière, d'un pas."}, opens),
		CS.cue({"who": CHLOE, "text": "(« La peur n'ouvre rien, ici. » … Je ne recule pas. Je ne recule plus.)" if Game.flag(&"found_journal_18")
			else "(Je ne recule pas. Je ne recule plus.)"}, stands),
	]


## It lowers its head to her, an eye like a plate; it smells the Sceaux, the Cœurs; it looks down,
## towards the Monts, long.
static func _sniffs(who: Node) -> Array:
	var chloe := Stage.chloe()
	var bends := func() -> void:
		await CS.Act.lean(who, chloe.global_position, 20.0, 2.4)
		MS.breath(who, 10)
	var smells := func() -> void:
		for i in 2:
			await CS.Act.lean(who, chloe.global_position, 12.0, 1.0)
		MS.hearts(3, 0.7)
	var down := func() -> void:
		var monts: Vector2 = (who as Node2D).global_position + Vector2(0.0, 300.0)
		Stage.turn_to(who, monts)
		await S.wait(1.2)
		Stage.emote(chloe, "?")
	var lines: Array = [
		CS.cue({"text": "Puis il replie les ailes, et baisse la tête jusqu'à Chloé. Lentement. Un œil grand comme une assiette la regarde, et ne cligne pas."}, bends),
		CS.cue({"text": "Il renifle les Sceaux, un par un. Les quatre. Il renifle les Cœurs, longtemps. Ils battent sous son bec."}, smells),
	]
	if Game.flag(&"sceau_monts"):
		lines.append({"text": "Au Sceau des Monts, il souffle un peu plus fort. Il connaît ce froid-là."})
	lines.append_array([
		CS.cue({"text": "Puis il tourne la tête et regarde en bas, vers les Monts. Longtemps. Comme s'il y voyait quelqu'un."}, down),
		{"who": CHLOE, "text": "(Maïa ? … Elle est restée au col. Elle n'a pas d'ailes, elle.)"},
	])
	return lines


## In the nest, kept twenty-five years: a strap of old leather, a fern stamped in it. Chloé lays
## Joss's harness beside it: the same fern. The Roi sets its beak on it.
static func _old_harness(who: Node) -> Array:
	var chloe := Stage.chloe()
	var at: Vector2 = _old_harness_px(who)
	var shows := func() -> void:
		Stage.look_at(at, 1.2)
		if _actor(OLD_HARNESS_NODES) == null:
			var thing := Stage.show_thing(OLD_HARNESS, at, "VieuxHarnaisScene")
			if thing:
				thing.set_meta(&"scene_thing", true)
		CS.sparkle(at, 0.3, 6, 0.2)
	var lays := func() -> void:
		await CS.chloe_walk(at + Vector2(-30.0, 30.0), 90.0, 2.0)
		Stage.turn_to(chloe, at)
		await Stage.bow(chloe, 1.0)
		if ItemsDB.ITEMS.has(C.HARNESS):
			CS.Act.pop(chloe.global_position, C.HARNESS, 0.8)
	var beak := func() -> void:
		Stage.turn_to(who, at)
		await CS.Act.lean(who, at, 16.0, 2.0)
		Stage.emote(chloe, "♥")
		Stage.look_back(1.0)
	return [
		CS.cue({"text": "Au bord du nid, entre deux branches, quelque chose qui n'est pas une branche : une lanière de cuir, usée, grise, avec une petite fougère frappée dedans."}, shows),
		{"who": CHLOE, "text": "(Un harnais… Celui d'Hélène. Il l'a gardé. Vingt-cinq ans.)"},
		CS.cue({"text": "Chloé s'agenouille et pose le harnais de Joss à côté du vieux. Deux fougères, l'une contre l'autre. La même."}, lays),
		CS.cue({"text": "Le Roi regarde les deux fougères. Puis il pose son bec dessus, doucement, et le laisse là un moment."}, beak),
		{"who": CHLOE, "text": "(Il se souvient d'elle. Comme les autres. Comme tous les autres.)"},
		{"flag": &"quetzal_roi_parle"},
	]


## Won: it lands, bows its neck to the grass; under the old harness, the Sceau des Cieux; its
## second cry and every piton's answer; Chloé's flyer impatient: the Vol, and how (page 31's
## words, never a key); it looks at the Monts and flies that way. Also played by the old harness
## prop, if the scene was cut short after the battle.
static func _gives_seal(who: Node) -> void:
	if Game.flag(&"sceau_cieux"):
		return
	S.lock(true)
	var chloe := Stage.chloe()
	var at: Vector2 = _old_harness_px(who)
	var lands := func() -> void:
		if who:
			var sprite := Stage.sprite_of(who)
			if sprite:
				sprite.position = Stage._rest(sprite)
			Stage.turn_to(who, chloe.global_position)
			await Stage.bow(who, 1.8)
	var seal := func() -> void:
		Stage.look_at(at, 1.0)
		await CS.chloe_walk(at + Vector2(-30.0, 30.0), 100.0, 2.0)
		Stage.turn_to(chloe, at)
		await CS.reach(chloe, at, 12.0, 1.0)
		CS.sparkle(at, 0.6, 16, 0.3)
		if ItemsDB.ITEMS.has(SEAL):
			CS.Act.pop(chloe.global_position, SEAL, 0.9)
	var cries := func() -> void:
		Stage.look_back(0.8)
		if who:
			Stage.rear(who, 1.4)
			Stage.cry(who, &"attaque")
		Stage.shake(2.0, 0.8)
		await S.wait(1.0)
		for i in 3:
			CS.far_cry("pteranodon", "neutre", -12.0 + 2.0 * i, 0.8 + 0.15 * i)
			await S.wait(0.5)
	await S.say([
		CS.cue({"text": "Le Roi se pose. La roche tremble à peine. Il incline son long cou devant Chloé, jusqu'à toucher l'herbe du nid."}, lands),
		CS.cue({"text": "Sous le vieux harnais d'Hélène, dans le tressage du nid, quelque chose luit : un disque d'ambre blanc doré, gravé d'une aile ouverte et d'une petite fougère. Le Sceau des Cieux."}, seal),
		CS.cue({"text": "Le Roi redresse la tête, et crie. Une seule fois, très fort. Et de chaque piton, de chaque nid, de partout dans les nuages, des voix lui répondent."}, cries),
		{"who": CHLOE, "text": "(Ils ont tous entendu. … Qu'est-ce qu'il leur a dit ?)"},
	])
	await S.say(_the_flight(who))
	var w = S.world()
	if ItemsDB.ITEMS.has(SEAL):
		Game.give_item(SEAL)
	Toast.say(w.get_tree(), "Objet obtenu : le Sceau des Cieux. Nouvelle capacité : le Vol !")
	Stage.look_back()
	Game.award_team_xp(XP_SCEAU)
	Save.save_game()
	S.lock(false)


## Chloé's flyer spreads its wings, impatient: the great pterosaurs of the island will carry her
## wherever she wants now. How (Hélène's words); the Roi looks at the Monts and flies there.
static func _the_flight(who: Node) -> Array:
	var chloe := Stage.chloe()
	var flying := C.flyer()
	var name: String = flying.nickname if flying else "ton ptérosaure"
	var impatient := func() -> void:
		var dino := CS.lead()
		if dino and flying and Game.lead_dino() == flying:
			Stage.rear(dino, 1.2)
			Stage.hop(dino, 2, 8.0)
		else:
			Stage.companion_joy()
		Stage.emote(chloe, "!")
	var goes := func() -> void:
		if who == null:
			return
		var monts: Vector2 = (who as Node2D).global_position + Vector2(0.0, 300.0)
		Stage.turn_to(who, monts)
		await S.wait(0.8)
		var ghost := C.stand_in(ROI, (who as Node2D).global_position, "RoiEnvol", 0, ROI_SIZE)
		if ghost:
			ghost.modulate.a = 1.0
			if who is CanvasItem:
				(who as CanvasItem).modulate.a = 0.0
			await CS.fly(ghost, (who as Node2D).global_position + Vector2(120.0, 520.0), 3.2, HOVER + 120.0)
			Stage.fade_out(ghost, 0.8, true)
			if is_instance_valid(who) and who is CanvasItem:
				(who as CanvasItem).modulate.a = 1.0   # (back on his nest when Chloé comes again)
	var lines: Array = [
		CS.cue({"text": "%s déplie ses ailes d'un coup, et piétine. Il a compris avant Chloé : désormais, les grands ptérosaures de l'île la porteront où elle veut. En plein ciel." % name.capitalize()}, impatient),
		{"who": CHLOE, "text": "(Voler. Pour de vrai. … « On se penche. On ne ferme pas les yeux. »)" if Game.flag(&"found_journal_31")
			else "(Voler. Pour de vrai. … Hélène volait. Elle a bien dû écrire comment, quelque part.)"},
		{"text": C.vol_howto()},
		{"flag": &"quetzal_roi_confiance"},
		{"flag": &"sceau_cieux"},
		{"flag": &"vol_obtenu"},
		CS.cue({"text": "Le Roi regarde encore une fois en bas, vers les Monts. Puis il se laisse tomber du nid, ouvre les ailes, et plonge dans cette direction."}, goes),
		{"who": CHLOE, "text": "(Où va-t-il ? … Les Monts. Le col.)"},
	]
	# (The Arche: on foot by the needle, whose wind lets her by now, or in flight.)
	if Game.flag(&"suie_indice"):
		lines.append({"who": CHLOE, "text": "(« Tous les Cœurs d'un coup, au même endroit. » L'Arche du Vent, là-haut. Le vent de l'aiguille me laissera passer, maintenant. Ou alors, je vole.)"})
	else:
		lines.append({"who": CHLOE, "text": "(L'Arche du Vent, là-haut, où le vent chante. Le vent de l'aiguille me laissera passer, maintenant. Ou alors, je vole.)"})
	return lines


## A line when Chloé comes back (the next one each time), with what it shows.
static func _again(who: Node) -> Dictionary:
	var k := int(Game.flag(&"roi_n"))
	Game.set_flag(&"roi_n", k + 1)
	var line := {"text": ROI_AGAIN[k % ROI_AGAIN.size()]}
	var chloe := Stage.chloe()
	match k % ROI_AGAIN.size():
		0:
			return CS.cue(line, func() -> void:
				Stage.turn_to(who, chloe.global_position)
				MS.breath(who, 10))
		1:
			return CS.cue(line, func() -> void:
				Stage.turn_to(who, (who as Node2D).global_position + Vector2(0.0, 300.0))
				await S.wait(1.0)
				Stage.turn_to(who, chloe.global_position))
	return CS.cue(line, func() -> void: CS.Act.lean(who, _old_harness_px(who), 14.0, 1.6))


## The old harness prop (event « vieux_harnais », optional): its lines; the Sceau if the scene was
## cut short after the battle.
static func vieux_harnais(who: Node) -> void:
	if Game.flag(&"quetzal_roi_battu") and not Game.flag(&"sceau_cieux"):
		await _gives_seal(_actor(ROI_NODES))
		return
	if Game.flag(&"sceau_cieux"):
		await S.say([{"text": "Le vieux harnais d'Hélène, et à côté, la place vide du Sceau. Le Roi le garde toujours. Chloé n'y touche pas."}])
		return
	await S.say([CS.cue({"text": "Une lanière de cuir usée, prise dans le tressage du nid, avec une petite fougère frappée dedans. Elle est là depuis très longtemps."},
		func() -> void: CS.sparkle((who as Node2D).global_position, 0.3, 6, 0.2))])


## Where the old harness lies (px): the zone's prop when it is there, else by the Roi.
static func _old_harness_px(roi: Node) -> Vector2:
	var prop = _actor(OLD_HARNESS_NODES)
	if prop is Node2D:
		return (prop as Node2D).global_position
	if roi is Node2D:
		return (roi as Node2D).global_position + Vector2(-90.0, 24.0)
	return C.px("VIEUX_HARNAIS")


## The first of `names` that is a node of the zone (null when none is).
static func _actor(names: Array):
	for n: String in names:
		var a = S.actor(n)
		if a != null:
			return a
	return null
