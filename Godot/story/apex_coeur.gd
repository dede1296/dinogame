class_name ApexCoeur
## Chapter 9, scene 3, the Cœur des Apex (zone coeur_apex; docs/chapitre-9-scenes.md § 3 a to 3 f):
## the round hall open to the sky, the block that beats; inside, the Souverain lying down, his eyes
## OPEN (he has been afraid for twenty-five years), and Hélène against his flank, in the amber up to
## her neck, a hand flat on him; Isaure puts her hand on hers, through the amber. Three tries to get
## her out (claws, charge, song: a choice each, watched, one line); the drop of black amber on
## Hélène's amber, not on him (« La même erreur qu'elle. »); the waking, watched, no line (the black
## vein like ink in water, Hélène slides into Isaure's arms, he rises violet to the eyes and cries
## with fear, his tail sweeps, Caillou charges and holds, Maïa pulls the two behind a rock); « Je te
## tiens »; Chloé's hatchling steps forward (Lien 5); the last battle: calming him (the Sceaux, Caillou,
## the clear amber at two thirds, the last gesture: the MÉCANIQUES agent's battle). Hélène then:
## story/apex_helene.gd.
## Flags: coeur_apex_arrivee, helene_vue, essai_griffes, essai_charge, essai_chant, essais_finis,
## goutte_noire, souverain_eveille, helene_sortie, caillou_rempart, starter_lien_5, souverain_apaise.

const S := preload("res://story/story.gd")
const CS := preload("res://story/cote_stage.gd")
const MS := preload("res://story/monts_stage.gd")
const Act := preload("res://story/marais_stage.gd")
const V := preload("res://story/volcan.gd")
const A := preload("res://story/apex.gd")
const CHLOE := "Chloé"
const MAIA := "Maïa"
const ISAURE := "Isaure"
## The three tries: [ability, its name, the option, its line after it is watched, its flag].
const TRIALS := [
	[&"tranche", "griffes", "Les griffes", "L'ambre ne prend pas une rayure. Pas une. Hélène l'a voulu solide.", &"essai_griffes"],
	[&"charge", "charge", "La charge", "Le bloc ne bouge pas. C'est le dino qui recule, et il s'assoit, et il se demande ce qui s'est passé.", &"essai_charge"],
	[&"resonance", "chant", "Le chant", "L'ambre chante avec lui, tout le bloc, longtemps… et c'est tout. Hélène n'a pas fait une porte : elle a fait un abri.", &"essai_chant"],
]
const TRIAL_PROMPT := "Comment la sortir de là ?"
const NOBODY := " (personne ne sait faire ça ici)"
const DONT_KNOW := "Je ne sais pas"
## The Souverain: his size in the scenes (« trop grand pour l'écran »), his level, the amber's tint
## on what is still inside the block.
const SOUVERAIN := &"souverain"
const SOUVERAIN_SIZE := 1.5
const SOUVERAIN_LEVEL := 50
const IN_AMBER := Color(1.0, 0.82, 0.5, 0.92)
const INK: Array[Color] = [Color(0.18, 0.08, 0.24), Color(0.3, 0.12, 0.4), Color(0.1, 0.05, 0.12)]
const ALPHA_MUSIC := "res://assets/audio/music/alpha.ogg"
const SOUVERAIN_MUSIC := "res://assets/audio/music/souverain.ogg"   # (his own; absent: the Alphas')
const XP_ARRIVEE := 40
const XP_SOUVERAIN := 300


# ------------------------------------------------------------------ arriving

## The bottom of the crater, as the story stands: the first time, scenes 3 a to 3 f; a game
## reloaded midway picks up where it was (the tries; him awake, waiting: talk to him; calmed:
## Hélène, story/apex_helene.gd); afterwards he lies there, calm (the zone's node, else a stand-in).
static func arrival() -> void:
	if not Game.flag(&"apex_ouvert") or S.world() == null:
		return
	if Game.flag(&"apex_fini"):
		_lying_there()
		return
	S.lock(true)
	await S.wait(0.4)
	var cast := stage()
	if Game.flag(&"souverain_apaise"):
		await ApexHelene.after_battle(cast)
		return
	if Game.flag(&"souverain_eveille"):
		S.lock(false)   # (he waits against the wall: talk to him, « Encore »)
		return
	if not Game.flag(&"coeur_apex_arrivee"):
		await S.say(the_block(cast))
		await _moustique_taps(cast)
		Game.award_team_xp(XP_ARRIVEE)
		Save.save_game()
	if Game.flag(&"goutte_noire"):   # (a game reloaded after the drop, before he woke)
		await _after_the_drop(cast)
	else:
		await _from_the_tries(cast)


## From the three tries to the battle (also after a game reloaded before the drop).
static func _from_the_tries(cast: Dictionary) -> void:
	await tries(cast)
	await S.say(the_drop(cast))
	var pick := await Dialogue.choose("", "La fiole est débouchée.", ["Attendez.", "Pas comme ça."])
	await S.say(drop_answer(pick))
	await _after_the_drop(cast)


## The waking, « Je te tiens », the battle.
static func _after_the_drop(cast: Dictionary) -> void:
	await _waking(cast)
	await S.say(holding(cast))
	Save.save_game()
	await _battle(cast)


## Who and what is there, as the story stands (the zone's nodes when CARTE placed them, else
## brought on round the block): Isaure, Maïa, Caillou, the block, Hélène in the amber, him.
static func stage() -> Dictionary:
	var base := A.chloe_px()
	var block := V.at_node(["BlocSouverain"], A.spot_or("BLOC", S.ground_near(base + Vector2(0.0, -5.0 * S.CELL), 3)))
	var cast := {"block_px": block}
	cast["block"] = S.actor("BlocSouverain")
	var awake: bool = Game.flag(&"souverain_eveille")
	if awake:
		var rock := A.spot_or("ROCHER_ABRI", S.ground_near(block + Vector2(-4.5 * S.CELL, 3.0 * S.CELL), 3))
		cast["rock"] = rock
		_two_behind_the_rock(cast, rock)
		cast["maia"] = A.person(["MaiaBloc"], A.MAIA_SHEETS, A.spot_or("MAIA_ABRI", S.ground_near(rock + Vector2(-50.0, 6.0), 2)), "right", MAIA)
	else:
		cast["isaure"] = A.person(["IsaureBloc"], A.ISAURE_SHEETS, A.spot_or("ISAURE", S.ground_near(block + Vector2(1.6 * S.CELL, 3.0 * S.CELL), 3)), "up", ISAURE)
		cast["maia"] = A.person(["MaiaBloc"], A.MAIA_SHEETS, A.spot_or("MAIA", S.ground_near(block + Vector2(-2.0 * S.CELL, 3.4 * S.CELL), 3)), "up", MAIA)
		cast["helene"] = _helene_in_amber(block)
	cast["caillou"] = A.dino(["CaillouBloc"], &"triceratops", A.spot_or("CAILLOU", S.ground_near(block + Vector2(3.4 * S.CELL, 3.6 * S.CELL), 3)))
	cast["souverain"] = _him(block, awake)
	return cast


## Hélène in the block (Npc « HeleneAmbre » of the zone), else, when the block's picture is not drawn
## yet, someone sitting against him, tinted by the amber.
static func _helene_in_amber(block: Vector2):
	var there = V.actor_of(["HeleneAmbre"])
	if there != null or S.actor("BlocSouverain") != null:
		return there
	var h := S.stranger("HeleneAmbre", V.sheet(A.HELENE_SHEETS), A.spot_or("HELENE_AMBRE", S.ground_near(block + Vector2(1.6 * S.CELL, 1.2 * S.CELL), 2)), "down", A.HELENE)
	if h:
		h.modulate = IN_AMBER
		Stage.sit(h)
	return h


## Him: inside the block (lying, amber-tinted: a stand-in when the block's picture is not drawn), or
## awake (the zone's DinoNpc « Souverain », corrupted, else a stand-in), against the wall.
static func _him(block: Vector2, awake: bool):
	var there = V.actor_of(["Souverain"])
	if there != null:
		if awake and there is DinoNpc and not (there as DinoNpc).corrupted:
			(there as DinoNpc).corrupted = true   # (seen as he wakes: the scene's own violet)
		return there
	if not awake:
		if S.actor("BlocSouverain") != null:
			return null
		var d := A.stand_in(SOUVERAIN, block, "SouverainBloc", 0, SOUVERAIN_SIZE)
		if d:
			d.modulate = IN_AMBER
			CS.crouch(d, 0.22, 0.1)
		return d
	var wall := A.spot_or("SOUVERAIN_PAROI", block + Vector2(0.0, -1.5 * S.CELL))
	return _awake_one(wall)


## Him awake, corrupted, against the wall: to be talked to (« souverain »: the battle again).
static func _awake_one(at_px: Vector2) -> DinoNpc:
	var d := A.stand_in(SOUVERAIN, at_px, "Souverain", SOUVERAIN_LEVEL, SOUVERAIN_SIZE, true)
	if d == null:
		return null
	d.modulate.a = 1.0
	d.event = &"souverain"
	d.add_to_group(&"interactable")
	return d


## Isaure sitting, Hélène against her (the zone's prop « IsaureHelene », else the two of them).
static func _two_behind_the_rock(cast: Dictionary, rock: Vector2) -> void:
	var prop = S.actor("IsaureHelene")
	if prop != null:
		cast["pair"] = prop
		return
	var isaure := S.stranger("IsaureHelene", V.sheet(A.ISAURE_SHEETS), A.spot_or("ISAURE_ABRI", S.ground_near(rock + Vector2(10.0, 4.0), 2)), "right", ISAURE)
	cast["isaure"] = isaure
	if isaure:
		Stage.sit(isaure)
	var helene := S.stranger("HeleneSol", V.sheet(A.HELENE_SHEETS), A.spot_or("HELENE_ABRI", S.ground_near(rock + Vector2(40.0, 10.0), 2)), "left", A.HELENE)
	cast["helene"] = helene
	A.tint_helene(helene)
	if helene:
		Stage.sit(helene)


## After it all (apex_fini): he lies in the middle of the crater, his eyes open, without fear.
static func _lying_there() -> void:
	if V.actor_of(["Souverain", "SouverainCouche"]) != null:
		return
	var at := A.spot_or("SOUVERAIN_COUCHE", A.chloe_px() + Vector2(0.0, -5.0 * S.CELL))
	var d := A.stand_in(SOUVERAIN, at, "SouverainCouche", 0, SOUVERAIN_SIZE)
	if d:
		d.modulate.a = 1.0
		d.event = &"souverain"
		d.add_to_group(&"interactable")
		CS.crouch(d, 0.22, 0.1)


# ------------------------------------------------------------------ 3 a, the block

## 3 a, the block (9 lines): too big to look at at once; it beats; him lying, his eyes open; her
## against his flank, in the amber up to her neck; Isaure's hand on hers; « Et lui, il nous
## regarde. » « Il a peur. »
static func the_block(cast: Dictionary) -> Array:
	var block: Vector2 = cast.get("block_px", A.chloe_px() + Vector2(0.0, -5.0 * S.CELL))
	var looks_up := func() -> void:
		await Stage.look_at(block + Vector2(0.0, -2.0 * S.CELL), 1.6)
		CS.pulse(block, A.AMBER, 2, 1.6, 2.5, 7.0)
	var beats := func() -> void:
		for i in 2:
			CS.pulse(block, A.AMBER, 1, 1.2, 3.5, 8.0)
			Stage.shake(0.6, 0.2)
			await S.wait(1.4)
	var him := func() -> void:
		var d = cast.get("souverain")
		Stage.look_at(block + Vector2(-1.0 * S.CELL, -1.0 * S.CELL), 1.2)
		if d:
			Stage.glow(d, A.AMBER * 1.6, 1, 1.4)
	var her := func() -> void:
		var h = cast.get("helene")
		Stage.look_at(h.global_position if h is Node2D else block + Vector2(1.6 * S.CELL, S.CELL), 1.0)
	var hand := func() -> void:
		var isaure = cast.get("isaure")
		var h = cast.get("helene")
		if isaure is Npc:
			var to: Vector2 = h.global_position if h is Node2D else block + Vector2(1.6 * S.CELL, S.CELL)
			await (isaure as Npc).walk_to(S.ground_near(to + Vector2(0.0, 40.0), 2), "up", 60.0)
			await CS.reach(isaure, to, 10.0, 1.2)
	var eye := func() -> void:
		var d = cast.get("souverain")
		if d:
			Stage.turn_to(d, A.chloe_px())
			Stage.emote(d, "…")
		else:
			CS.pulse(block + Vector2(-1.2 * S.CELL, -0.8 * S.CELL), A.AMBER, 1, 0.8, 3.0, 2.5)
	return [
		CS.cue({"text": "Le bloc. De près, il est trop grand pour le regarder d'un coup : il faut lever la tête, puis la tourner."}, looks_up),
		CS.cue({"text": "Dedans, l'ambre est doré, presque clair. Et il bat. Lentement."}, beats),
		CS.cue({"text": "Le Souverain. Couché, immense, la peau veinée d'ambre comme la roche du cratère. Et ses yeux sont ouverts. Il ne dort pas. Il regarde dehors, et il attend."}, him),
		CS.cue({"text": "Contre son flanc, une femme assise, dans l'ambre jusqu'au cou. Les cheveux gris. Les yeux fermés, elle. Une main à plat sur lui, comme on calme un cheval. Les mains sont abîmées."}, her),
		{"who": CHLOE, "text": "(Hélène.)"},
		{"who": CHLOE, "text": "(Elle a l'air de lui dire quelque chose. Depuis un an.)"},
		CS.cue({"text": "Isaure s'approche. Elle pose sa main sur l'ambre, exactement sur la main d'Hélène, de l'autre côté."}, hand),
		{"who": ISAURE, "text": "Elle n'a jamais eu l'air de dormir. Même quand elle dormait. … Là non plus."},
		CS.cue({"who": MAIA, "text": "Et lui, il nous regarde."}, eye),
		{"who": CHLOE, "text": "Il a peur. Il a toujours eu peur. Elle est là pour ça."},
		{"flag": &"coeur_apex_arrivee"},
		{"flag": &"helene_vue"},
	]


## Watched, no line: Moustique flies onto the block, taps the amber twice with his beak, and comes
## back to Chloé's shoulder, vexed.
static func _moustique_taps(cast: Dictionary) -> void:
	var chloe := Stage.chloe()
	var block: Vector2 = cast.get("block_px", A.chloe_px() + Vector2(0.0, -5.0 * S.CELL))
	if chloe == null:
		return
	var bird := A.stand_in(&"dimorphodon", chloe.global_position + V.SHOULDER, "MoustiqueBloc", V.MOUSTIQUE_LEVEL, 0.8)
	if bird == null:
		await S.wait(1.0)
		return
	await Stage.fade_in(bird, 0.3)
	await CS.fly(bird, block + Vector2(0.0, 1.4 * S.CELL), 1.0, V.SHOULDER_UP + 30.0)
	for i in 2:
		Stage.lunge(bird, block, 0.4, false)
		CS.sfx("res://assets/audio/sfx/glass.wav", -14.0)
		await S.wait(0.45)
	Stage.emote(bird, "!")
	await CS.fly(bird, chloe.global_position + V.SHOULDER, 1.0, V.SHOULDER_UP)
	Stage.emote(bird, "…")
	await S.wait(0.6)
	Stage.fade_out(bird, 0.4, true)


# ------------------------------------------------------------------ 3 b, the three tries

## 3 b: a choice each time (the abilities of the party; the others greyed, « personne ne sait faire
## ça ici »; « Je ne sais pas »), the try watched, its line; after three, or « Je ne sais pas »:
## Chloé's « Il doit y avoir un autre moyen ».
static func tries(cast: Dictionary) -> void:
	var done: Array = []
	while done.size() < TRIALS.size():
		var shown := trial_options(done)
		var pick := await Dialogue.choose("", TRIAL_PROMPT, shown["labels"])
		var rows: Array = shown["rows"]
		if pick < 0 or pick >= rows.size():
			break
		var row: Array = rows[pick]
		var user: Dino = Game.ability_user(row[0])
		if user == null:
			continue   # (greyed: nobody here knows how)
		await _try(row, user, cast)
		await S.say([{"text": row[3]}, {"flag": row[4]}])
		done.append(row[1])
	await S.say(tries_over())


## The choice's options now (those not tried yet; greyed without the ability) and their rows.
static func trial_options(done: Array) -> Dictionary:
	var labels: Array = []
	var rows: Array = []
	for row: Array in TRIALS:
		if row[1] in done:
			continue
		labels.append(row[2] if Game.ability_user(row[0]) else String(row[2]) + NOBODY)
		rows.append(row)
	labels.append(DONT_KNOW)
	return {"labels": labels, "rows": rows}


## After the tries (1 line).
static func tries_over() -> Array:
	return [
		{"who": CHLOE, "text": "(Il doit y avoir un autre moyen. Il y en a toujours un. Elle l'écrivait à chaque page.)"},
		{"flag": &"essais_finis"},
	]


## A try, watched: the dino who knows how sets to it, its own way (claws on the amber, a charge
## that bounces back, a song the whole block sings back… and that is all).
static func _try(row: Array, user: Dino, cast: Dictionary) -> void:
	var block: Vector2 = cast.get("block_px", A.chloe_px() + Vector2(0.0, -5.0 * S.CELL))
	var dino := _trier(user)
	if dino == null:
		await S.wait(1.0)
		return
	var close := A.spot_or("ESSAIS", S.ground_near(block + Vector2(randf_range(-1.0, 1.0) * S.CELL, 2.4 * S.CELL), 2))
	Stage.look_at(block.lerp(close, 0.5), 0.8)
	if dino is Companion:
		await CS.lead_walk(close, 120.0)
	else:
		await (dino as DinoNpc).walk_to(close, 120.0)
	Stage.turn_to(dino, block)
	match String(row[1]):
		"griffes":
			for i in 3:
				Stage.lunge(dino, block, 0.8, i == 0)
				CS.sfx("res://assets/audio/sfx/slice.wav", -8.0)
				CS.sparkle(block + Vector2(0.0, 1.6 * S.CELL), 0.6, 6, 0.2)
				await S.wait(0.5)
		"charge":
			Stage.lunge(dino, block, 2.0, true)
			await S.wait(0.35)
			Stage.shake(1.5, 0.25)
			CS.sfx("res://assets/audio/sfx/rock_heavy.wav", -8.0)
			await Stage.recoil(dino, block, 30.0)
			await CS.crouch(dino, 0.2, 0.6)
			Stage.emote(dino, "?")
		_:
			Stage.rear(dino, 1.2)
			Stage.cry(dino, &"neutre")
			for i in 4:
				CS.pulse(block, A.AMBER, 1, 0.9, 2.5 + i, 8.0)
				await S.wait(0.7)
	await S.wait(0.8)
	if dino is DinoNpc and A.brought(dino):
		Stage.fade_out(dino, 0.5, true)


## Who tries: the lead dino when it is the one who knows how, else one brought next to Chloé.
static func _trier(user: Dino) -> Node2D:
	if Game.lead_dino() == user and CS.lead():
		return CS.lead()
	var d := A.stand_in(user.species().id, S.ground_near(A.chloe_px() + Vector2(60.0, -10.0), 2), "Essai", user.level)
	if d:
		Stage.fade_in(d, 0.3)
	return d


# ------------------------------------------------------------------ 3 c, the drop

## 3 c, the drop (6 lines): « Il n'y a pas d'autre moyen »; the vial, black, sealed with wax; he
## follows it with his eyes; « sur l'ambre, pas sur lui »; « tant qu'il y aura un autre moyen »; « Un
## an, c'est ce que j'avais. »
static func the_drop(cast: Dictionary) -> Array:
	var isaure = cast.get("isaure")
	var vial := func() -> void:
		if isaure:
			_faces(isaure, A.chloe_px())
			await CS.reach(isaure, A.chloe_px(), 6.0, 1.0)
			Stage.glow(isaure, A.VIOLET * 1.6, 1, 1.0)
		var d = cast.get("souverain")
		if d:
			Stage.turn_to(d, isaure.global_position if isaure is Node2D else A.chloe_px())
	var maia_asks := func() -> void:
		var maia = cast.get("maia")
		if maia and isaure:
			Stage.turn_to(maia, (isaure as Node2D).global_position)
	return [
		{"who": ISAURE, "text": "Il n'y a pas d'autre moyen, moussaillon. J'ai regardé pendant que tu essayais. J'ai regardé très fort."},
		CS.cue({"text": "Elle sort la fiole. Noire, petite, bouchée de cire. Dans l'ambre, le Souverain la suit des yeux."}, vial),
		{"who": ISAURE, "text": "Une goutte sur l'ambre. Pas sur lui. L'ambre noir mange l'ambre : la dame en gris l'a dit. Il se fend, elle sort, et lui ne sentira rien."},
		{"who": CHLOE, "text": "Il la regarde. La fiole. Il sait ce que c'est."},
		CS.cue({"who": MAIA, "text": "Maman. Tu as dit « tant qu'il y aura un autre moyen »."}, maia_asks),
		{"who": ISAURE, "text": "J'ai tenu parole aussi longtemps que j'ai pu, ma tornade. Il y a un an que je la regarde là-dedans. Un an, c'est ce que j'avais."},
	]


## Her answer to the choice (« Attendez. » 0 / « Pas comme ça. » 1), and Chloé's thought (2 lines).
static func drop_answer(pick: int) -> Array:
	var answer := "J'ai attendu vingt ans, moussaillon. J'ai arrêté d'être douée pour ça." if pick == 0 \
		else "Je ne connais pas d'autre « comme ». Elle les connaissait tous. C'est bien pour ça qu'elle est là-dedans, et moi dehors."
	return [
		{"who": ISAURE, "text": answer},
		{"who": CHLOE, "text": "(La même erreur qu'elle. Il y a vingt-cinq ans, Hélène a voulu le réveiller. « Ne fais pas les mêmes erreurs qu'elle » : c'est Isaure qui me l'a dit, sur la passerelle.)"},
		{"flag": &"goutte_noire"},
	]


# ------------------------------------------------------------------ 3 d, the waking (watched)

## 3 d, the waking (no line, about fifteen seconds): the drop on the amber above Hélène's hand; a
## black vein in the gold like ink in water; the amber cracks in a star; Hélène slides, Isaure
## catches her without trembling; the vein goes on, into his flank: violet to the eyes; the block
## bursts, he rises and cries (a cry of fear, not a roar), the ground shakes; his tail sweeps back
## towards their rock: Caillou charges, horns against the tail, slides a metre and holds; Maïa
## pulls the two behind the rock; Moustique cries in Chloé's collar; he backs against the wall,
## trembling, and looks at us.
static func _waking(cast: Dictionary) -> void:
	var block: Vector2 = cast.get("block_px", A.chloe_px() + Vector2(0.0, -5.0 * S.CELL))
	var h = cast.get("helene")
	var hand: Vector2 = h.global_position if h is Node2D else block + Vector2(1.6 * S.CELL, S.CELL)
	Stage.look_at(hand, 0.8)
	Act.burst(hand + Vector2(0.0, -20.0), INK, 6, 0.8, 0.1)
	await S.wait(0.8)
	for i in 4:   # (the black vein, like ink in water)
		CS.pulse(hand.lerp(block, i / 3.0), A.VIOLET, 1, 0.6, 2.5, 3.0)
		await S.wait(0.35)
	Stage.shake(2.0, 0.5)
	CS.sfx("res://assets/audio/sfx/glass.wav", -4.0)
	var block_node = cast.get("block")
	if block_node:
		Stage.repaint(block_node, "bloc_souverain_fendu", 0.6)
	await S.wait(0.6)
	await _helene_slides(cast, hand)
	Stage.look_at(block, 0.8)
	for i in 3:
		CS.pulse(block + Vector2(randf_range(-2.0, 2.0), randf_range(-1.0, 1.0)) * S.CELL, A.VIOLET, 1, 0.5, 3.0, 5.0)
		await S.wait(0.3)
	await _he_rises(cast, block)
	await _tail_and_caillou(cast, block)
	Stage.look_back(1.0)
	await S.wait(0.6)
	Game.set_flag(&"souverain_eveille")
	Game.set_flag(&"helene_sortie")
	Game.set_flag(&"caillou_rempart")


## Hélène slides out of the amber; Isaure catches her and holds her against her (sitting).
static func _helene_slides(cast: Dictionary, hand: Vector2) -> void:
	var isaure = cast.get("isaure")
	var h = cast.get("helene")
	if h is Node2D:
		await Stage.fade_out(h, 0.4, A.brought(h))
	var catch_at := A.spot_or("MAIN_HELENE", S.ground_near(hand + Vector2(10.0, 50.0), 2))
	if isaure is Npc:
		await (isaure as Npc).walk_to(catch_at, "up", 120.0)
		Stage.sit(isaure)
	var her := S.stranger("HeleneSol", V.sheet(A.HELENE_SHEETS), catch_at + Vector2(28.0, 6.0), "left", A.HELENE)
	cast["helene"] = her
	A.tint_helene(her)
	if her:
		her.modulate.a = 0.0
		Stage.sit(her)
		Stage.fade_in(her, 0.4)
	await S.wait(0.6)


## The block bursts; he rises (his head out of the picture), violet to the eyes, and cries with fear.
static func _he_rises(cast: Dictionary, block: Vector2) -> void:
	var inside = cast.get("souverain")
	if inside is Node2D and A.brought(inside):
		Stage.fade_out(inside, 0.3, true)
	var block_node = cast.get("block")
	if block_node:
		Stage.repaint(block_node, "bloc_souverain_eclate", 0.4)
	Stage.shake(4.0, 0.8)
	CS.sfx("res://assets/audio/sfx/rock_heavy.wav", 0.0)
	Act.burst(block, A.AMBER_BITS, 24, 1.2, 1.2)
	var awake = V.actor_of(["Souverain"])
	if awake == null:
		awake = _awake_one(block)
	cast["souverain"] = awake
	if awake == null:
		await S.wait(1.0)
		return
	Stage.fade_in(awake, 0.3)
	await Stage.rear(awake, 1.2)
	Stage.cry(awake, &"attaque")
	for i in 3:   # (the crater's veins flicker)
		CS.pulse(block + Vector2(randf_range(-6.0, 6.0), randf_range(-3.0, 4.0)) * S.CELL, A.AMBER, 1, 0.4, 3.0, 5.0)
		Stage.shake(2.0, 0.3)
		await S.wait(0.3)


## His tail sweeps back towards the rock where Isaure holds Hélène: Caillou charges, plants himself,
## horns against the tail, slides a metre, and holds; Maïa grabs her mother by the collar and pulls
## the two behind the rock; Moustique cries; he backs against the wall, trembling, and looks at us.
static func _tail_and_caillou(cast: Dictionary, block: Vector2) -> void:
	var him = cast.get("souverain")
	var rock := A.spot_or("ROCHER_ABRI", S.ground_near(block + Vector2(-4.5 * S.CELL, 3.0 * S.CELL), 3))
	cast["rock"] = rock
	var isaure = cast.get("isaure")
	var target: Vector2 = isaure.global_position if isaure is Node2D else rock
	var caillou = cast.get("caillou")
	if him:
		Stage.lunge(him, target, 1.6, false)
	if caillou is DinoNpc:
		var between := A.spot_or("CAILLOU_REMPART", S.ground_near(target.lerp(block, 0.35), 2))
		await (caillou as DinoNpc).walk_to(between, 260.0)
		Stage.turn_to(caillou, block)
		Stage.lunge(caillou, block, 1.2, true)
		Stage.shake(2.0, 0.4)
		await Stage.recoil(caillou, block, 48.0)   # (a metre)
		Stage.tremble(caillou, 1.2, 2.0)
	var maia = cast.get("maia")
	if maia is Npc:
		(maia as Npc).walk_to(A.spot_or("MAIA_ABRI", S.ground_near(rock + Vector2(-50.0, 6.0), 2)), "right", 200.0)
	for k in ["isaure", "helene"]:
		var n = cast.get(k)
		if n is Npc:
			var to := A.spot_or("ISAURE_ABRI" if k == "isaure" else "HELENE_ABRI", S.ground_near(rock + (Vector2(10.0, 4.0) if k == "isaure" else Vector2(40.0, 10.0)), 2))
			(n as Npc).walk_to(to, "", 160.0)
	if Stage.chloe():
		V.shoulder_peek(Stage.chloe(), 1.2)
	await S.wait(1.4)
	if him is DinoNpc:
		var wall := A.spot_or("SOUVERAIN_PAROI", block + Vector2(0.0, -1.5 * S.CELL))
		await (him as DinoNpc).walk_to(wall, 90.0)
		Stage.turn_to(him, A.chloe_px())
		Stage.tremble(him, 2.0, 3.0)
	await S.wait(0.8)


# ------------------------------------------------------------------ 3 e, « Je te tiens »

## 3 e (5 lines): Maïa holds them both; « Va, moussaillon »; Caillou holds the line; Chloé's hatchling
## steps between her and him (+♥: Lien 5); « Il a peur. Moi aussi. J'y vais. »
static func holding(cast: Dictionary) -> Array:
	var steps := func() -> void:
		var d := A.starter()
		if d and Game.party.has(d):
			Game.set_lead(Game.party.find(d))
		await S.wait(0.3)
		var him = cast.get("souverain")
		var dino := CS.lead()
		if A.has_place("COMBAT_CHLOE"):
			await CS.chloe_walk(A.px("COMBAT_CHLOE"), 90.0, 2.0)
		if dino and him is Node2D:
			await CS.lead_walk(A.spot_or("COMBAT_DINO", A.chloe_px().lerp((him as Node2D).global_position, 0.3)), 90.0)
			Stage.turn_to(dino, (him as Node2D).global_position)
		raise_bond()
	return [
		{"who": MAIA, "text": "Je te tiens. Je t'ai dit que je te tiendrais."},
		{"who": ISAURE, "text": "… Va, moussaillon. Je ne peux pas. Je n'ai jamais pu : je faisais semblant, avec une fiole."},
		{"who": MAIA, "text": "Caillou tient la ligne. Il a dit qu'il tiendrait. Enfin, il a éternué. C'est pareil."},
		CS.cue({"who": CHLOE, "text": "Tu étais le plus petit, dans la couveuse. Tu te souviens ? … Moi non plus. On y va."}, steps),
		{"who": CHLOE, "text": "(Il a peur. Moi aussi. J'y vais.)"},
		{"flag": &"starter_lien_5"},
	]


## Chloé's hatchling at Lien 5 (« +♥ », ApexBag), if it was not yet.
static func raise_bond() -> void:
	ApexBag.starter_full_bond()
	Game.set_flag(&"starter_lien_5")


static func _faces(who, px: Vector2) -> void:
	if who is Npc:
		(who as Npc).face(px)
	elif who is Node2D:
		Stage.turn_to(who, px)


# ------------------------------------------------------------------ 3 f, the battle

## 3 f, calming him (the MÉCANIQUES agent's battle: ApexBattles.souverain_team, souverain_rules,
## ApexEngine: the Sceaux, Caillou, the clear amber at two thirds, the last gesture; « rally »: no
## defeat, the party gets up on the spot, « Encore. »). Won: souverain_apaise, then Hélène. Should it
## end otherwise, Chloé is free on the spot: talk to him to go again.
static func _battle(cast: Dictionary) -> void:
	S.lock(true)
	if await fight():
		await _calmed(cast)
		return
	S.lock(false)


## The battle itself (Story.duel: « calmed » is a win): true when he is calmed.
static func fight() -> bool:
	var team: Array = A.from_battles(&"souverain_team", [], [[A.species_or(SOUVERAIN), SOUVERAIN_LEVEL, "", {"corrupted": true, "long_calm": true, "size": SOUVERAIN_SIZE}]])
	var rules: Dictionary = A.from_battles(&"souverain_rules", [], battle_rules())
	return await S.duel("", team, rules)


## The last battle's rules from the document (docs/chapitre-9-scenes.md 3 f) if ApexBattles were gone
## (its words are ApexEngine's): no collar, no running away (« Sceaux » instead), a deep corruption
## three times as long, Caillou, the clear amber at two thirds, no defeat, his music (else the Alphas').
static func battle_rules() -> Dictionary:
	var rules := {"catch": false, "run": false, "long_calm": true, "calm_factor": 3, "sceaux": true, "caillou": true,
		"antidote": true, "antidote_min_calm": 0.66, "rally": true, "apex": true, "size": SOUVERAIN_SIZE}
	for path: String in [SOUVERAIN_MUSIC, ALPHA_MUSIC]:
		if ResourceLoader.exists(path):
			rules["music"] = load(path)
			break
	return rules


## Calmed: the clear amber is gone (poured), Hélène's scene (story/apex_helene.gd).
static func _calmed(cast: Dictionary) -> void:
	Game.set_flag(&"souverain_apaise")
	if Game.item_count("antidote_ambre") > 0:
		Game.use_item("antidote_ambre")
	Game.award_team_xp(XP_SOUVERAIN)
	Save.save_game()
	await ApexHelene.after_battle(cast)


# ------------------------------------------------------------------ talked to

## Him (DinoNpc « Souverain »): awake, the battle again (« Encore »); lying, at peace, a line.
static func souverain(who: Node) -> void:
	if Game.flag(&"apex_fini"):
		await S.say(DialogueApex.lines(&"souverain_couche"))
		return
	if not Game.flag(&"souverain_eveille") or Game.flag(&"souverain_apaise"):
		return
	S.lock(true)
	var cast := stage()
	if who is DinoNpc:
		cast["souverain"] = who
	if await fight():
		await _calmed(cast)
		return
	S.lock(false)


## The block (StoryProp « BlocSouverain »): before the drop, the tries again (a game reloaded); else
## it beats, or lies in pieces.
static func bloc(who: Node) -> void:
	if Game.flag(&"coeur_apex_arrivee") and not Game.flag(&"goutte_noire"):
		S.lock(true)
		await _from_the_tries(stage())
		return
	CS.pulse(A.px_of(who), A.AMBER, 2, 1.2, 2.5, 6.0)
	await S.wait(0.8)


## Hélène in the amber (Npc « HeleneAmbre »), or with Isaure behind the rock: a thought.
static func helene_ambre(_who: Node) -> void:
	if Game.flag(&"goutte_noire"):
		return
	await S.say([{"who": CHLOE, "text": "(Elle a l'air de lui dire quelque chose. Depuis un an.)"}])


# ------------------------------------------------------------------ for the tests

## For the tests (tools/capture.gd « static »): the block on any zone (the people, the block and him
## brought on before Chloé), the tries (the test picks), the drop (the test picks), the waking, « Je
## te tiens » (no battle).
static func static_coeur() -> void:
	S.playing += 1
	Game.set_flag(&"apex_ouvert")
	S.lock(true)
	var cast := stage()
	await S.say(the_block(cast))
	await _moustique_taps(cast)
	await tries(cast)
	await S.say(the_drop(cast))
	var pick := await Dialogue.choose("", "La fiole est débouchée.", ["Attendez.", "Pas comme ça."])
	await S.say(drop_answer(pick))
	await _waking(cast)
	await S.say(holding(cast))
	S.lock(false)
	S.playing -= 1
