class_name CoteRecif
## Chapter 5, the Côte Préhistorique, the reef's sanctuary under the sea (zone recif_sanctuaire;
## docs/histoire.md, ch. 5, points 12 and 13): the world's noise stops, columns of blue light,
## coral as high as a church, old stones carved with bone masks; an immense shadow. The
## Mosasaure Abyssal (Hélène's « Minuit ») rises: almost blind, it listens to the Cœurs beating
## in Chloé's bag, smells the Sceaux, strikes the sand with its tail — an invitation. A battle of
## honour under the water; won, it circles the altar, the coral opens like fingers, it taps a
## giant clam: the Sceau de la Côte and the third Cœur. The three Cœurs light up together; far
## below, the rumble is stronger than ever. Then it nudges Chloé up towards the light.
## Flags: recif_arrivee, mosasaure_parle, mosasaure_battu, sceau_cote, coeur_3; mosasaure_n.
## (Page 22: a Pickup, DialogueCote page_22.)

const S := preload("res://story/story.gd")
const P := preload("res://story/cote_places.gd")
const CS := preload("res://story/cote_stage.gd")
const CHLOE := "Chloé"
const ALPHA_MUSIC := "res://assets/audio/music/alpha.ogg"
const RUMBLE := "res://assets/audio/sfx/rock_heavy.wav"
## The Mosasaure Abyssal: a battle of honour (to check by simulation with the chapter's levels);
## its size in the world and in its battle; the species used while SpeciesDB has not got it.
const MOSA := &"mosasaure_abyssal"
const MOSA_STAND_IN := &"plesiosaurus"
const MOSA_NAME := "Mosasaure Abyssal"
const MOSA_LEVEL := 34
const MOSA_SIZE := 1.2
const XP_RECIF := 20
## Its shadow passing over Chloé as she arrives: from this far on one side to the other (px),
## this high above her (px of its picture), dark against the light from above.
const SHADOW_PASS := 520.0
const SHADOW_HEIGHT := 0.0   # (at swim height: higher, the camera looking down on her would not see it)
## …and a little ahead of her, over the arena (just over her, the rock of the pass hides it) (px).
const SHADOW_AHEAD := 170.0
const SHADOW_TINT := Color(0.42, 0.5, 0.64, 1.0)
const XP_COEUR := 90
## Sand thrown up by its tail, the deep's light.
const SAND: Array[Color] = [Color(0.9, 0.86, 0.72), Color(0.76, 0.7, 0.56), Color(0.62, 0.66, 0.6)]
const MOSA_AGAIN := [
	"Le Mosasaure tourne lentement autour de l'autel ouvert. Quand Chloé passe, il frôle son épaule du bout du museau.",
	"Le Mosasaure écoute les Cœurs dans la sacoche de Chloé. Il souffle un long filet de bulles : ils battent bien.",
	"Un banc de poissons argentés passe entre les dents du Mosasaure. Il ne les mange pas. Il a l'air de trouver ça drôle.",
]


# ------------------------------------------------------------------ arriving under the sea

## The first time in the sanctuary: silence, blue light, the carved stones of the ancients; the
## Cœurs beat, a glow answers from the altar; an immense shadow passes over Chloé.
static func arrival() -> void:
	if Game.flag(&"recif_arrivee"):
		return
	S.lock(true)
	await S.wait(0.5)
	var chloe := Stage.chloe()
	var diver: Dino = CS.diver()
	var middle := S.at(P.MOSASAURE.x, P.MOSASAURE.y)
	var altar := _altar_px()
	# The guardian is not seen before it passes over Chloé (the shadow), then rests in the deep.
	var mosa = S.actor("MosasaureAbyssal")
	if mosa is CanvasItem:
		(mosa as CanvasItem).modulate.a = 0.0
	var silence := func() -> void:
		Audio.duck(-10.0, 1.2)
		for i in 3:
			CS.bubbles(chloe.global_position + Vector2(0.0, -10.0), 6, 1.0)
			await S.wait(0.7)
	var light := func() -> void:
		await CS.pan(middle, 1.8)
		CS.pulse(middle + Vector2(0.0, -2.0 * S.CELL), CS.DEEP_GLOW, 2, 2.0, 2.0, 6.0)
	var stones := func() -> void:
		CS.pan(middle.lerp(altar, 0.5) + Vector2(3.0 * S.CELL, 0.0), 1.6)
	var lines: Array = [
		CS.cue({"text": "Le bruit du monde s'arrête d'un coup. Plus de vagues, plus de vent : seulement le souffle de %s, et des bulles qui montent." % diver.nickname if diver
			else "Le bruit du monde s'arrête d'un coup. Plus de vagues, plus de vent : seulement des bulles qui montent."}, silence),
		CS.cue({"text": "Des colonnes de lumière bleue tombent de la surface, très haut. Le corail monte tout autour, haut comme une nef d'église."}, light),
		CS.cue({"text": "Pris dans le corail, de vieilles pierres sculptées : des masques d'os, tournés vers le fond. Les anciens veillaient ici aussi."}, stones),
	]
	if Game.flag(&"coeur_1") or Game.flag(&"coeur_2"):
		lines.append(CS.cue({"text": "Dans la sacoche, les Cœurs battent plus fort. Au fond, derrière le corail, une lueur dorée leur répond."},
			func() -> void:
				Stage.look_at(altar, 1.0)
				CS.hearts_beat(2, 1.0)
				CS.pulse(altar, CS.HEART_GLOW, 2, 1.0, 2.0, 3.0)))
	var shadow := func() -> void:
		Stage.look_at(chloe.global_position + Vector2(0.0, -SHADOW_AHEAD * 1.4), 0.8)   # (the camera rises to see it pass)
		CS.far_cry("marin", "neutre", -10.0, 0.55)
		Stage.flash(Color(0.0, 0.03, 0.12, 0.55), 2.2)
		if mosa is DinoNpc:   # its dark shape glides over the arena just ahead of her, then down to its place
			(mosa as Node2D).global_position = chloe.global_position + Vector2(-SHADOW_PASS, -SHADOW_AHEAD)
			(mosa as CanvasItem).modulate = SHADOW_TINT * Color(1, 1, 1, 0)
			(mosa as CanvasItem).create_tween().tween_property(mosa, "modulate:a", SHADOW_TINT.a, 0.6)
			CS.fly(mosa, chloe.global_position + Vector2(SHADOW_PASS, -SHADOW_AHEAD), 2.6, SHADOW_HEIGHT)
		for i in 4:
			CS.bubbles(chloe.global_position + Vector2(randf_range(-80.0, 80.0), -40.0), 8, 1.4)
			await S.wait(0.4)
		Stage.emote(chloe, "!")
		if mosa is DinoNpc:
			await S.wait(1.2)
			var rest_at := S.at(P.MOSASAURE.x, P.MOSASAURE.y)
			(mosa as CanvasItem).create_tween().tween_property(mosa, "modulate", Color.WHITE, 2.4)
			await CS.fly(mosa, rest_at, 2.4, 0.0)
		Stage.look_back(1.0)
	lines.append_array([
		CS.cue({"text": "Une ombre immense passe au-dessus de Chloé. Elle couvre tout, longtemps. Puis elle glisse vers le fond, et la lumière revient."}, shadow),
		{"who": CHLOE, "text": "(Le gardien du récif…)"},
		{"flag": &"recif_arrivee"},
	])
	await S.say(lines)
	Audio.duck(0.0, 1.5)
	Game.award_team_xp(XP_RECIF)
	Save.save_game()
	S.lock(false)


# ------------------------------------------------------------------ the Mosasaure Abyssal

## The Mosasaure Abyssal (DinoNpc « MosasaureAbyssal », event « mosasaure_abyssal »): it rises
## and listens (the first time); a battle of honour under the water; won, it opens the altar.
## Afterwards, a line at each visit.
static func mosasaure(who: Node) -> void:
	if Game.flag(&"coeur_3"):
		await S.say([_again(who)])
		return
	if not Game.flag(&"mosasaure_battu"):
		if not Game.flag(&"mosasaure_parle"):
			S.lock(true)
			await S.say(_rises(who))
			S.lock(false)
		var pick := await Dialogue.choose("", "Le Mosasaure Abyssal attend, immobile dans l'eau bleue. Il veut entendre ce que vaut le cœur de l'héritière d'Hélène.",
			["Relever le défi", "Pas encore"])
		if pick != 0:
			return
		await _catch_breath()
		var species := MOSA if SpeciesDB.PATHS.has(MOSA) else MOSA_STAND_IN
		var foe := Dino.create(species, MOSA_LEVEL, MOSA_NAME)
		var rules := {"catch": false, "run": false, "underwater": true, "abyss": true, "lose_spawn": P.LOSE_RECIF, "size": MOSA_SIZE,
			"intro": "Le Mosasaure Abyssal ouvre sa gueule immense ! (Combat d'honneur : pas de collier, pas de fuite.)",
			"lesson": ["Le Mosasaure est un dino de l'Eau : les attaques du Vent le touchent fort. Ses coups d'Eau, eux, font très mal aux dinos de Feu et de Terre.",
				"Quand il plonge dans le noir, tes attaques ne l'atteignent pas : protège-toi. Quand il jaillit, il reste à découvert : frappe à ce moment-là !"]}
		var theme: AudioStream = ForetCamp.music_at(ALPHA_MUSIC)
		if theme:
			rules["music"] = theme
		var result: String = await S.world().call(&"_battle", foe, rules)
		if result != "win":
			return
		Game.set_flag(&"mosasaure_battu")
		Save.save_game()
	await _opens_altar(who)


## It rises from the deep: pale eyes, a head longer than a boat; it circles Chloé, its eye comes
## right up to her mask; it listens to the Cœurs, smells the Sceaux; its tail strikes the sand.
static func _rises(who: Node) -> Array:
	var chloe := Stage.chloe()
	var at: Vector2 = (who as Node2D).global_position
	var rises := func() -> void:
		Stage.look_at(at, 1.0)
		var sprite := Stage.sprite_of(who)
		if sprite:
			var rest := Stage._rest(sprite)
			sprite.position = rest + Vector2(0.0, 90.0)
			who.modulate.a = 0.0
			var t := sprite.create_tween()
			t.tween_property(sprite, "position", rest, 2.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			Stage.fade_in(who, 1.6)
		for i in 3:
			CS.bubbles(at + Vector2(randf_range(-60.0, 60.0), 0.0), 10, 1.2)
			await S.wait(0.6)
	var circles := func() -> void:
		var centre := chloe.global_position
		for i in 9:
			var angle := TAU * i / 8.0   # (from her right, round, back to her right: never stopping in front of her)
			var p := centre + Vector2(cos(angle) * 170.0, sin(angle) * 90.0)
			await CS.fly(who, p, 0.45, 0.0)
			Stage.turn_to(chloe, p)
			CS.bubbles(p, 4, 0.8)
	var eye := func() -> void:
		Stage.turn_to(who, chloe.global_position)
		await CS.Act.lean(who, chloe.global_position, 22.0, 2.0)
		Stage.recoil(chloe, (who as Node2D).global_position, 8.0)
	var lines: Array = [
		CS.cue({"text": "Du fond, quelque chose remonte. D'abord deux yeux, pâles comme la lune. Puis une tête plus longue qu'une barque, des écailles bleu de nuit, des cicatrices partout."}, rises),
		CS.cue({"text": "Le Mosasaure Abyssal. Plus long que trois barques mises bout à bout."},
			func() -> void:
				(who as DinoNpc).cry(&"neutre")
				Stage.rear(who, 1.6)),
		CS.cue({"text": "Il tourne lentement autour de Chloé. Une fois. Deux fois. Le courant de son passage la fait tourner sur elle-même."}, circles),
		CS.cue({"text": "Son œil vient tout contre la vitre du masque. Un œil grand comme une assiette, laiteux. Il ne la voit pas."}, eye),
		CS.cue({"text": "Il écoute. Les Cœurs qui battent dans la sacoche. Et le cœur de Chloé, qui bat très, très vite."},
			func() -> void: CS.hearts_beat(3, 0.6)),
	]
	if Game.flag(&"sceau_marais"):
		lines.append(CS.cue({"text": "Il renifle les Sceaux, un à un. Au Sceau du Marais, il souffle un long filet de bulles, comme on salue un vieil ami."},
			func() -> void: CS.bubbles(CS.D._head_of(who), 14, 0.9)))
	var strikes := func() -> void:
		CS.Act.burst(at + Vector2(60.0, 20.0), SAND, 40, 0.3, 1.2)
		Stage.shake(3.0, 0.8)
		Stage.lunge(who, at + Vector2(100.0, 30.0), 0.8, false)
	lines.append_array([
		CS.cue({"text": "Puis il frappe le sable de la queue. Un nuage monte, lent, qui cache tout."}, strikes),
		{"who": CHLOE, "text": "(Une invitation… et un avertissement.)"},
		{"flag": &"mosasaure_parle"},
	])
	return lines


## A battle of honour is fought rested: it waits while Chloé's dinos go up to breathe in an air
## pocket under the coral vault (the party is healed, when it needs to be).
static func _catch_breath() -> void:
	var tired := Game.party.any(func(d: Dino) -> bool: return d.hp < d.max_hp())
	if not tired:
		return
	Game.heal_party()
	Game.party_changed.emit()
	var up := func() -> void:
		# (under the sea Chloé never leaves her diver's back: the pair swims up to the air and back)
		var chloe := Stage.chloe()
		var from := chloe.global_position
		await CS.chloe_walk(from + Vector2(20.0, -90.0), 90.0, 1.6)
		CS.bubbles(chloe.global_position, 14, 1.4)
		await S.wait(0.8)
		await CS.chloe_walk(from, 90.0, 1.6)
		Stage.turn_to(chloe, S.at(P.MOSASAURE.x, P.MOSASAURE.y))
	await S.say([CS.cue({"text": "Le Mosasaure attend pendant que tes dinos remontent respirer dans une poche d'air, sous la voûte de corail. Un combat d'honneur se livre reposé."}, up)])


## Won: it bows, circles the altar; the coral opens like fingers; it taps the giant clam: the
## Sceau de la Côte and the third Cœur. The three Cœurs together; the deep rumbles; it nudges
## Chloé up towards the light. Also played by the altar, if the scene was cut short.
static func _opens_altar(who: Node) -> void:
	if Game.flag(&"coeur_3"):
		return
	S.lock(true)
	var chloe := Stage.chloe()
	var altar := _altar_px()
	var altar_node = S.actor("Autel")
	var bows := func() -> void:
		if who:
			Stage.bow(who, 1.4)
	var round_it := func() -> void:
		Stage.look_at(altar, 1.0)
		CS.chloe_walk(altar + Vector2(-60.0, 110.0), 110.0, 6.0)   # she swims after it, up to the altar
		if who:
			for i in 7:
				var angle := TAU * i / 6.0
				await CS.fly(who, altar + Vector2(cos(angle) * 130.0, sin(angle) * 70.0 + 40.0), 0.45, 0.0)
	var opens := func() -> void:
		if altar_node:
			Stage.glow(altar_node, CS.HEART_GLOW, 2, 1.0)
		CS.pulse(altar, CS.DEEP_GLOW, 2, 1.2, 2.5, 4.0)
		CS.sparkle(altar, 0.5, 18, 0.5)
	var taps := func() -> void:
		if who:
			await CS.Act.lean(who, altar, 16.0, 1.2)
		CS.bubbles(altar, 12, 0.6)
		CS.sparkle(altar, 0.4, 12, 0.2)
	var takes := func() -> void:
		await CS.chloe_walk(altar + Vector2(-40.0, 50.0), 120.0, 6.0)
		Stage.turn_to(chloe, altar)
		await CS.reach(chloe, altar, 12.0, 1.0)
		if ItemsDB.ITEMS.has("sceau_cote"):
			CS.Act.pop(chloe.global_position, "sceau_cote", 0.9)
	var beats := func() -> void:
		await Stage.bow(chloe, 0.8)
		CS.hearts_beat(2, 0.9)
	var together := func() -> void:
		Stage.flash(Color(1.0, 0.85, 0.45, 0.5), 1.0)
		CS.sparkle(chloe.global_position, 0.8, 28, 0.4)
		Stage.glow(chloe, CS.HEART_GLOW, 2, 1.0)
		if altar_node:
			Stage.glow(altar_node, CS.HEART_GLOW, 2, 1.0)
	await S.say([
		CS.cue({"text": "Le Mosasaure incline sa tête immense devant Chloé. Puis il nage jusqu'à l'autel, et en fait le tour, lentement."},
			func() -> void:
				await bows.call()
				round_it.call()),
		CS.cue({"text": "Sur son passage, les branches de corail s'écartent, comme des doigts qui s'ouvrent."}, opens),
		CS.cue({"text": "Au centre, un bénitier géant, grand comme une baignoire. Le Mosasaure le touche du bout du museau. La coquille s'ouvre."}, taps),
		CS.cue({"text": "Dedans, deux choses brillent. Un disque d'ambre bleu de nuit, gravé d'une vague qui s'enroule et d'une petite fougère : le Sceau de la Côte."}, takes),
		CS.cue({"text": "Et un cœur d'ambre gros comme un poing, frais comme un galet mouillé. Il bat au rythme de la houle."}, beats),
		CS.cue({"text": "Les trois Cœurs s'allument ensemble, si fort que le corail se colore d'or."}, together),
	])
	var w = S.world()
	CS.sfx(RUMBLE, -6.0)
	w.player.get_node("Camera").call(&"shake", 5.0, 1.6)
	var flee := func() -> void:
		for i in 5:
			CS.bubbles(altar + Vector2(randf_range(-200.0, 200.0), randf_range(-80.0, 40.0)), 10, 1.4)
			await S.wait(0.25)
	var growls := func() -> void:
		if who:
			Stage.turn_to(who, (who as Node2D).global_position + Vector2(0.0, 300.0))
			(who as DinoNpc).cry(&"attaque")
			Stage.rear(who, 1.2)
	var nudges := func() -> void:
		if who:
			await CS.Act.lean(who, chloe.global_position, 18.0, 1.2)
		Stage.recoil(chloe, (who as Node2D).global_position if who else altar, 24.0)
		CS.bubbles(chloe.global_position, 14, 1.4)
	await S.say([
		CS.cue({"text": "Loin, très loin dessous, quelque chose gronde. Plus fort que les autres fois. Le récif tremble ; des nuées de poissons s'enfuient dans tous les sens."}, flee),
		CS.cue({"text": "Le Mosasaure tourne la tête vers le sud, vers le volcan. Et il gronde à son tour, tout bas."}, growls),
		{"who": CHLOE, "text": "(Il gronde plus fort à chaque Cœur… Qu'est-ce qui se réveille, là-dessous ?)"},
		CS.cue({"text": "Chloé reçoit le Sceau de la Côte et le troisième Cœur d'ambre !"}, func() -> void: Stage.companion_joy()),
		CS.cue({"text": "Puis, du bout du museau, le Mosasaure la pousse doucement vers le haut. Vers la lumière."}, nudges),
		{"flag": &"sceau_cote"},
		{"flag": &"coeur_3"},
	])
	for id: String in ["sceau_cote", "coeur_3"]:
		if ItemsDB.ITEMS.has(id):
			Game.give_item(id)
	Toast.say(w.get_tree(), "Objets obtenus : le Sceau de la Côte et le troisième Cœur d'ambre")
	Stage.look_back()
	Game.award_team_xp(XP_COEUR)
	Save.save_game()
	S.lock(false)


## The altar (StoryProp « Autel », event « coeur_recif »): closed by the coral until the guardian
## opens it; if the scene was cut short after the battle, it opens now; afterwards, empty.
static func coeur(who: Node) -> void:
	if Game.flag(&"coeur_3"):
		await S.say([{"text": "Le bénitier est ouvert, et vide. Le corail s'est refermé tout autour, doucement, comme une main qui a fini de donner."}])
		return
	if Game.flag(&"mosasaure_battu"):
		await _opens_altar(S.actor("MosasaureAbyssal"))
		return
	await S.say([CS.cue({"text": "Au fond, derrière des branches de corail serrées comme des doigts, quelque chose luit et bat. Le corail ne s'ouvre pas. Le gardien veille."},
		func() -> void: CS.pulse((who as Node2D).global_position, CS.HEART_GLOW, 1, 1.2, 1.8, 3.0))])


## A line when Chloé comes back (the next one each time), with what it shows.
static func _again(who: Node) -> Dictionary:
	var k := int(Game.flag(&"mosasaure_n"))
	Game.set_flag(&"mosasaure_n", k + 1)
	var line := {"text": MOSA_AGAIN[k % MOSA_AGAIN.size()]}
	var chloe := Stage.chloe()
	match k % MOSA_AGAIN.size():
		0:
			return CS.cue(line, func() -> void: CS.Act.lean(who, chloe.global_position, 12.0, 1.0))
		1:
			return CS.cue(line, func() -> void: CS.bubbles(CS.D._head_of(who), 16, 1.0))
	return CS.cue(line, func() -> void: Stage.hop(who, 1, 6.0))


## The altar (pixels): the zone's StoryProp « Autel » when it is there.
static func _altar_px() -> Vector2:
	var altar = S.actor("Autel")
	return (altar as Node2D).global_position if altar is Node2D else S.at(P.AUTEL.x, P.AUTEL.y)
