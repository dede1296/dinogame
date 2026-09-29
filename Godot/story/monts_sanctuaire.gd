class_name MontsSanctuaire
## Chapter 6, the Monts Gelés, the sanctuary of Givre (zone sanctuaire_givre; docs/histoire.md,
## ch. 6, point 4): a round hall cut in the ice, blue light falling through the vault, a high
## wall of ice, two statues by the altar. Heavy steps up there make a puddle tremble (a wink:
## docs/histoire.md « Clins d'œil »), then silence; down the wall of ice climbs the
## Cryolophosaure Titan, silent (a crest across its head like a Sunday hairdo: Anselme called it
## « Toupet », page 27). It smells the Sceaux and the three Cœurs, then roars: a battle of honour.
## Won, it bows, breathes on the altar until the ice opens: the Sceau des Monts and the fourth
## Cœur, cold as a snowball, beating like someone asleep. The four Cœurs light up together; the
## volcano rumbles louder than ever; the Titan does not look at the volcano: it looks up, at the
## sky. Flags: sanctuaire_givre_arrivee, titan_parle, titan_battu, sceau_monts, coeur_4; titan_n.
## (Page 27: a Pickup, DialogueMonts page_27.)

const S := preload("res://story/story.gd")
const P := preload("res://story/monts_places.gd")
const MS := preload("res://story/monts_stage.gd")
const CS := preload("res://story/cote_stage.gd")
const CHLOE := "Chloé"
## The guardian: a battle of honour (checked by simulation: scratchpad ch6/sim_monts.gd,
## docs/histoire.md § 6); its size in the world and in battle.
const TITAN := &"cryolophosaure_titan"
const TITAN_NAME := "Cryolophosaure Titan"
## Its node and the altar's in the zone (tools/zones/sanctuaire_givre.gd), under either name.
const TITAN_NODES := ["Titan", "CryolophosaureTitan"]
const ALTAR_NODES := ["Autel", "AutelGivre"]
const TITAN_LEVEL := 40
const TITAN_SIZE := 1.1
## How high up the wall of ice it starts its climb down (px of its picture's lift).
const CLIMB_FROM := 170.0
const XP_ARRIVEE := 20
## Its heavy steps up there before it climbs down: the puddle of melted ice by the way in
## (tools/zones/sanctuaire_givre.gd), a dull thud (low), every so often (s).
const PUDDLE_NODE := "FlaqueRonde"
const PUDDLE_MIDDLE_PX := 8.0
const STEP_DB := -5.0
const STEP_PITCH := 0.55
const STEP_EVERY := 1.25
const XP_COEUR := 110
const TITAN_AGAIN := [
	"Le Titan souffle doucement sur les mains de Chloé. De petites fleurs de givre poussent sur ses manches.",
	"Le Titan lève la tête vers la voûte, vers le ciel, et gronde tout bas. Il écoute quelque chose, très haut.",
	"Le Titan renifle les moufles de Chloé, longtemps. Puis il éternue. Un nuage de neige retombe sur elle.",
]


# ------------------------------------------------------------------ arriving

## The first time in the sanctuary: the round hall of ice, the high wall of ice, the statues; down
## the wall comes the guardian, and lands without a sound.
static func arrival() -> void:
	if Game.flag(&"sanctuaire_givre_arrivee"):
		return
	S.lock(true)
	await S.wait(0.5)
	var chloe := Stage.chloe()
	var guardian = _actor(TITAN_NODES)
	var rest := S.at(P.TITAN.x, P.TITAN.y)
	if guardian is CanvasItem:
		(guardian as CanvasItem).modulate.a = 0.0   # (not seen before it climbs down)
	var hall := func() -> void:
		Stage.look_at(chloe.global_position + Vector2(0.0, -4.0 * S.CELL), 1.4)
		CS.pulse(chloe.global_position + Vector2(0.0, -4.0 * S.CELL), MS.ICE_BLUE, 2, 2.0, 2.0, 6.0)
	var far_wall := func() -> void:
		await CS.pan(rest + Vector2(0.0, -1.0 * S.CELL), 1.8)
		MS.drips(rest + Vector2(40.0, -60.0), 3, 0.6, 3.0)
	var climbs := func() -> void:
		if not guardian is DinoNpc:
			return
		var sprite := Stage.sprite_of(guardian)
		if sprite:
			var rest_px := Stage._rest(sprite)
			sprite.position = rest_px + Vector2(0.0, -CLIMB_FROM)
			Stage.fade_in(guardian, 1.0)
			for i in 4:   # down the ice, claw after claw, a few flakes falling each time
				var t := sprite.create_tween()
				t.tween_property(sprite, "position:y", rest_px.y - CLIMB_FROM * (3 - i) / 4.0, 0.55).set_trans(Tween.TRANS_SINE)
				MS.snow_puff(rest + Vector2(randf_range(-20.0, 20.0), 0.0), 6, 2.0 - 0.4 * i, 0.2)
				await t.finished
	var lands := func() -> void:
		if guardian is DinoNpc:
			Stage.turn_to(guardian, chloe.global_position)
			MS.breath(guardian, 14)
		Stage.emote(chloe, "!")
	# (Clin d'œil, docs/histoire.md « Clins d'œil »: the water that trembles before a giant comes.)
	var steps := {"on": true}
	var puddle_px: Vector2 = _puddle_px(chloe)
	var trembles := func() -> void:
		Stage.look_at(puddle_px + Vector2(0.0, -12.0), 1.0)
		await S.wait(0.7)
		while steps["on"]:
			Audio.play_sfx(load(MS.RUMBLE), STEP_DB, 0.03, STEP_PITCH)
			Stage.shake(1.6, 0.18)
			Stage.ripples(puddle_px, 3, 0.42, 1.0)
			await S.wait(STEP_EVERY)
	var silence := func() -> void:
		steps["on"] = false
		Stage.emote(chloe, "!")
		await S.wait(0.6)
		CS.pan(rest + Vector2(0.0, -1.0 * S.CELL), 1.4)
	var lines: Array = [
		CS.cue({"text": "Derrière la porte, une salle ronde, taillée dans la glace. La lumière tombe d'en haut, à travers la voûte, bleue et tremblante."}, hall),
		CS.cue({"text": "Au fond, une haute paroi de glace, et deux statues de Cryolophosaure qui montent la garde de chaque côté d'un autel."}, far_wall),
		CS.cue({"text": "Aux pieds de Chloé, dans une petite flaque de fonte, l'eau se met à trembler. Des cercles, bien ronds. Boum. … Boum."}, trembles),
		CS.cue({"who": CHLOE, "text": "(Quelque chose de très lourd marche, là-haut… Et puis, plus rien.)"}, silence),
		CS.cue({"text": "Du haut de la paroi, quelque chose descend. Les griffes plantées dans la glace, sans un bruit."}, climbs),
		CS.cue({"text": "Il se pose devant l'autel, et la glace ne se fend même pas. Un Cryolophosaure, grand comme un arbre, avec une crête toute droite en travers de la tête."}, lands),
		{"who": CHLOE, "text": "(On dirait qu'il s'est coiffé pour me recevoir.)"},
		{"who": CHLOE, "text": "(Le gardien du quatrième Cœur…)"},
		{"flag": &"sanctuaire_givre_arrivee"},
	]
	await S.say(lines)
	if is_instance_valid(guardian) and guardian is CanvasItem:
		(guardian as CanvasItem).modulate.a = 1.0
		var sprite := Stage.sprite_of(guardian)
		if sprite:
			sprite.position = Stage._rest(sprite)
	Stage.look_back()
	Game.award_team_xp(XP_ARRIVEE)
	Save.save_game()
	S.lock(false)


## The middle of the puddle by the way in (its node, else just north of Chloé's feet).
static func _puddle_px(chloe: Player) -> Vector2:
	var puddle = S.actor(PUDDLE_NODE)
	if puddle is Node2D:   # (its picture stands up from its foot: its middle is seen a little further north)
		return (puddle as Node2D).global_position + Vector2(0.0, -PUDDLE_MIDDLE_PX)
	return chloe.global_position + Vector2(-20.0, -60.0)


# ------------------------------------------------------------------ the Titan

## The Cryolophosaure Titan (DinoNpc « CryolophosaureTitan », event « cryolophosaure_titan »): it
## smells the Sceaux and the Cœurs, then roars (the first time); a battle of honour; won, it opens
## the altar. Afterwards, a line at each visit.
static func titan(who: Node) -> void:
	if Game.flag(&"coeur_4"):
		await S.say([_again(who)])
		return
	if not Game.flag(&"titan_battu"):
		if not Game.flag(&"titan_parle"):
			S.lock(true)
			await S.say(_sniffs(who))
			S.lock(false)
		var pick := await Dialogue.choose("", "Le Cryolophosaure Titan attend, immobile, la crête dressée. Il veut savoir ce que vaut l'héritière d'Hélène.",
			["Relever le défi", "Pas encore"])
		if pick != 0:
			return
		await MS.rested("Le Titan attend pendant que tes dinos croquent la neige fraîche du sanctuaire. Elle a un goût de menthe, et elle les remet d'aplomb. Un combat d'honneur se livre reposé.",
			func() -> void:
				var dino := CS.lead()
				if dino:
					Stage.bow(dino, 0.8)
					MS.snow_puff(CS.D._head_of(dino), 8, 0.2, 0.2))
		var species := MS.species_or(TITAN)
		var foe := Dino.create(species, TITAN_LEVEL, TITAN_NAME)
		var rules := {"catch": false, "run": false, "lose_spawn": P.SPAWN_SANCTUAIRE_DEPUIS_MONTS, "size": TITAN_SIZE,
			"intro": "Le Cryolophosaure Titan dresse sa crête et rugit ! (Combat d'honneur : pas de collier, pas de fuite.)",
			"lesson": _lesson(foe)}
		var theme: AudioStream = MS.music(MS.ALPHA_MUSIC)
		if theme:
			rules["music"] = theme
		var result: String = await S.world().call(&"_battle", foe, rules)
		if result != "win":
			return
		Game.set_flag(&"titan_battu")
		Save.save_game()
	await _opens_altar(who)


## What the battle's first lines teach: what hits it hard, what its blows hurt (from its type).
static func _lesson(foe: Dino) -> Array:
	var type := foe.type()
	var weak := MS.weak_to(type)
	var hurts := MS.hurts(type, MS.TYPE_OF)
	var lines: Array = []
	if weak != "":
		lines.append("Le Titan est un dino %s : %s le touche%s fort." % [MS.TYPE_OF.get(type, type), weak, "nt" if " et " in weak else ""])
	if hurts != "":
		lines.append("Ses coups font très mal aux dinos %s. Tu peux changer de dino pendant le combat." % hurts)
	return lines


## It lowers its head to Chloé; frost flowers on her sleeves; it smells the Sceaux and the Cœurs;
## then it rears and roars: needles of ice fall from the vault.
static func _sniffs(who: Node) -> Array:
	var chloe := Stage.chloe()
	var at: Vector2 = (who as Node2D).global_position
	var bends := func() -> void:
		await CS.step_aside(who, 90.0)
		Stage.turn_to(who, chloe.global_position)
		await CS.Act.lean(who, chloe.global_position, 16.0, 2.2)
		MS.breath(who, 12)
		MS.snow_puff(chloe.global_position, 10, 1.0, 0.2)
	var smells := func() -> void:
		for i in 2:
			await CS.Act.lean(who, chloe.global_position, 12.0, 1.0)
		MS.hearts(3, 0.7)
	var lines: Array = [
		CS.cue({"text": "Le Cryolophosaure Titan baisse la tête jusqu'à Chloé. Son souffle fait pousser de petites fleurs de givre sur ses manches."}, bends),
		CS.cue({"text": "Il renifle les Sceaux, un à un. Il renifle les Cœurs, longtemps. Ils battent sous son nez."}, smells),
	]
	if Game.flag(&"sceau_cote"):
		lines.append(CS.cue({"text": "Au Sceau de la Côte, il fronce les naseaux. Ça sent le poisson."},
			func() -> void: CS.D._snort(who)))
	var roars := func() -> void:
		Stage.cry(who, &"attaque")
		Stage.rear(who, 1.4)
		Stage.shake(4.0, 0.9)
		for i in 5:
			MS.snow_puff(at + Vector2(randf_range(-160.0, 160.0), randf_range(-60.0, 40.0)), 8, 3.0, 0.3)
			await S.wait(0.15)
		Stage.recoil(chloe, at, 10.0)
	lines.append_array([
		CS.cue({"text": "Puis il se redresse, dresse sa crête… et rugit. Tout le sanctuaire tremble ; des aiguilles de glace tombent de la voûte."}, roars),
		{"who": CHLOE, "text": "(Il veut voir ce que je vaux. Comme il l'a fait avec Hélène.)"},
		{"flag": &"titan_parle"},
	])
	return lines


## Won: it bows its crest to the snow; breathes on the altar until the ice opens: the Sceau des
## Monts and the fourth Cœur; the four Cœurs together; the volcano rumbles; it looks up, at the
## sky. Also played by the altar, if the scene was cut short after the battle.
static func _opens_altar(who: Node) -> void:
	if Game.flag(&"coeur_4"):
		return
	S.lock(true)
	var chloe := Stage.chloe()
	var altar := _altar_px()
	var altar_node = _actor(ALTAR_NODES)
	var bows := func() -> void:
		if who:
			await Stage.bow(who, 1.6)
			MS.snow_puff(CS.D._head_of(who), 12, 0.1, 0.3)
	var breathes := func() -> void:
		Stage.look_at(altar, 1.0)
		if who is DinoNpc:
			await (who as DinoNpc).walk_to(altar + Vector2(130.0, 26.0), 70.0)
			await (who as DinoNpc).walk_to(altar + Vector2(96.0, 26.0), 40.0)   # (the last steps sideways: seen from the side, facing it)
			Stage.turn_to(who, altar)
		for i in 5:
			MS.breath(who, 12)
			CS.Act.burst(altar, MS.BREATH_BITS, 10, 0.8, 0.3)
			await S.wait(0.5)
	var melts := func() -> void:
		if altar_node:
			Stage.glow(altar_node, MS.HEART_GLOW, 2, 1.0)
			Stage.tremble(altar_node, 0.8, 1.5)
		MS.drips(altar + Vector2(0.0, -20.0), 5, 0.3, 1.0)
		CS.pulse(altar, MS.ICE_BLUE, 2, 1.2, 2.2, 3.0)
	var takes := func() -> void:
		await CS.chloe_walk(altar + Vector2(-40.0, 50.0), 110.0, 5.0)
		Stage.turn_to(chloe, altar)
		await CS.reach(chloe, altar, 12.0, 1.0)
		if ItemsDB.ITEMS.has("sceau_monts"):
			CS.Act.pop(chloe.global_position, "sceau_monts", 0.9)
	var beats := func() -> void:
		await Stage.bow(chloe, 0.8)
		MS.hearts(2, 1.1)
	var together := func() -> void:
		Stage.flash(Color(1.0, 0.85, 0.45, 0.5), 1.0)
		CS.sparkle(chloe.global_position, 0.8, 30, 0.4)
		Stage.glow(chloe, MS.HEART_GLOW, 2, 1.0)
		CS.pulse(chloe.global_position + Vector2(0.0, -2.0 * S.CELL), MS.HEART_GLOW, 2, 1.4, 3.0, 8.0)
	await S.say([
		CS.cue({"text": "Le Cryolophosaure Titan incline sa crête devant Chloé, jusqu'à toucher la neige."}, bows),
		CS.cue({"text": "Puis il va jusqu'à l'autel, une vasque de pierre pleine de glace claire, au fond de la salle, et souffle dessus. Longtemps."}, breathes),
		CS.cue({"text": "La glace fond sous son souffle, goutte à goutte. Dedans, deux choses apparaissent."}, melts),
		CS.cue({"text": "Un disque d'ambre bleu pâle, gravé d'un flocon et d'une petite fougère : le Sceau des Monts."}, takes),
		CS.cue({"text": "Et un cœur d'ambre gros comme un poing, froid comme une boule de neige. Il bat tout doucement, comme quelqu'un qui dort."}, beats),
		CS.cue({"text": "Les quatre Cœurs s'allument ensemble. Si fort que toute la glace du sanctuaire devient dorée."}, together),
	])
	CS.sfx(MS.RUMBLE, -6.0)
	Stage.shake(5.0, 1.6)
	var falls := func() -> void:
		var spot: Vector2 = chloe.global_position + Vector2(70.0, -20.0)
		await S.wait(0.4)
		MS.snow_puff(spot, 30, 2.6, 0.2)
		await S.wait(0.3)
		MS.snow_puff(spot, 24, 0.1, 0.6)
		CS.sfx(MS.ICE_SOUND, -4.0)
		Stage.recoil(chloe, spot, 16.0)
	var looks_up := func() -> void:
		if who:
			Stage.turn_to(who, (who as Node2D).global_position + Vector2(0.0, -300.0))
			Stage.rear(who, 1.4)
			Stage.cry(who, &"neutre")
		Stage.look_at(chloe.global_position + Vector2(0.0, -5.0 * S.CELL), 1.4)
	var lines: Array = [
		CS.cue({"text": "Loin, très loin dessous, le volcan gronde. Plus fort que jamais. La voûte craque ; une stalactite tombe et se brise à côté de Chloé."}, falls),
		CS.cue({"text": "Le Titan ne regarde pas vers le volcan. Il lève la tête, tout en haut, vers la voûte… vers le ciel. Et il gronde, tout bas."}, looks_up),
	]
	if Game.flag(&"suie_indice"):
		lines.append({"who": CHLOE, "text": "(Vers le ciel… « Le Masque veut tous les Cœurs d'un coup. Les Cieux. »)"})
	else:
		lines.append({"who": CHLOE, "text": "(Vers le ciel ? Qu'est-ce qu'il y a, là-haut ?)"})
	lines.append_array([
		CS.cue({"text": "Chloé reçoit le Sceau des Monts et le quatrième Cœur d'ambre !"}, func() -> void:
			Stage.look_back(0.8)
			Stage.companion_joy()),
		{"flag": &"sceau_monts"},
		{"flag": &"coeur_4"},
	])
	await S.say(lines)
	var w = S.world()
	for id: String in ["sceau_monts", "coeur_4"]:
		if ItemsDB.ITEMS.has(id):
			Game.give_item(id)
	Toast.say(w.get_tree(), "Objets obtenus : le Sceau des Monts et le quatrième Cœur d'ambre")
	Stage.look_back()
	Game.award_team_xp(XP_COEUR)
	Save.save_game()
	S.lock(false)


## The altar (StoryProp « AutelGivre », event « coeur_givre »): shut in clear ice until the
## guardian breathes on it; if the scene was cut short after the battle, it opens now.
static func coeur(who: Node) -> void:
	if Game.flag(&"coeur_4"):
		await S.say([{"text": "L'autel est ouvert, et vide. Sur la glace, la marque de deux mains qui ont fondu un peu. Les mains d'Hélène ? Les tiennes ?"}])
		return
	if Game.flag(&"titan_battu"):
		await _opens_altar(_actor(TITAN_NODES))
		return
	await S.say([CS.cue({"text": "Un bloc de glace claire, au fond de la salle. Dedans, quelque chose luit et bat, tout doucement. La glace est dure comme de la pierre : le gardien veille."},
		func() -> void: CS.pulse((who as Node2D).global_position if who is Node2D else _altar_px(), MS.HEART_GLOW, 1, 1.2, 1.8, 3.0))])


## A line when Chloé comes back (the next one each time), with what it shows.
static func _again(who: Node) -> Dictionary:
	var k := int(Game.flag(&"titan_n"))
	Game.set_flag(&"titan_n", k + 1)
	var line := {"text": TITAN_AGAIN[k % TITAN_AGAIN.size()]}
	var chloe := Stage.chloe()
	match k % TITAN_AGAIN.size():
		0:
			return CS.cue(line, func() -> void:
				MS.breath(who, 10)
				MS.snow_puff(chloe.global_position, 8, 1.0, 0.2))
		1:
			return CS.cue(line, func() -> void:
				Stage.turn_to(who, (who as Node2D).global_position + Vector2(0.0, -300.0))
				Stage.rear(who, 1.2))
	return CS.cue(line, func() -> void:
		CS.Act.lean(who, chloe.global_position, 12.0, 1.0)
		MS.snow_puff(chloe.global_position, 14, 1.2, 0.3))


## The altar (pixels): the zone's StoryProp « AutelGivre » when it is there.
static func _altar_px() -> Vector2:
	var altar = _actor(ALTAR_NODES)
	return (altar as Node2D).global_position if altar is Node2D else S.at(P.AUTEL.x, P.AUTEL.y)


## The first of `names` that is a node of the zone (null when none is).
static func _actor(names: Array):
	for n: String in names:
		var a = S.actor(n)
		if a != null:
			return a
	return null
