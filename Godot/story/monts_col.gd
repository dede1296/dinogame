class_name MontsCol
## Chapter 6, the Monts Gelés, the Col des Tempêtes (docs/histoire.md, ch. 6, point 3): on the
## way up, the blizzard rises (Game.set_weather(&"blizzard")); a lantern stumbles in the white:
## Roc, worn out, lost, come to check the seal « as usual ». Sheltered behind Chloé's lead dino,
## he tells everything: two years ago, here, Hélène made him promise to watch the seal every night
## if she disappeared, and to tell nobody; his nights out were that; the black amber in his drawer,
## he confiscated it. « Ne fais confiance qu'aux dinos », she had written: he wanted Chloé to
## doubt everyone, him too. They make up (roc_innocente); the wind drops, a blue glow shows the
## frost door at the top of the col. Then the frost door (point 4): four round hollows; the three
## Cœurs beat, three hollows light up, the fourth waits for its own Cœur; the ice melts.
## Flags: roc_col_vu, roc_innocente, porte_givre_vue, sanctuaire_givre_ouvert.

const S := preload("res://story/story.gd")
const P := preload("res://story/monts_places.gd")
const MS := preload("res://story/monts_stage.gd")
const CS := preload("res://story/cote_stage.gd")
const CHLOE := "Chloé"
const ROC := "Prof. Roc"
const XP_ROC := 60
const XP_PORTE := 40
## Seconds for the blizzard to close in (the view blends the weather) before its first line.
const BLIZZARD_CLOSES := 2.5
## The camera shows the frost door from this far south of its foot (tiles): the door up on screen.
const DOOR_VIEW := 2.2
## Where Roc's lantern first shows in the white (from Chloé, px), and where he stumbles (px).
const LANTERN_FROM := Vector2(-260.0, 60.0)
const ROC_STOPS := Vector2(-80.0, 20.0)
## His seat when he collapses (his sitting picture is drawn for a chair: never on nothing): a snowy
## boulder about 0.5 m high (rocher_neige is 1.67 m at its own scale), this far north of him (px):
## drawn behind him.
const SEAT := "rocher_neige"
const SEAT_SCALE := 0.3
const SEAT_BEHIND := 3.0
## The wind blows from the west (the blizzard's flakes fly west to east): the lead dino stands on
## that side of them, facing it (px from Chloé).
const WINDBREAK := Vector2(-70.0, -10.0)
## The frost door's four hollows: [x from its middle, height] (m): top left, top right, bottom left
## (the three Cœurs, in that order: its pictures porte_givre_1…3), bottom right (the fourth, empty).
const HOLLOWS := [Vector2(-0.49, 2.15), Vector2(0.49, 2.15), Vector2(-0.49, 1.14), Vector2(0.49, 1.14)]
const MELT: Array[Color] = [Color(0.8, 0.93, 1.0), Color(1.0, 1.0, 1.0), Color(0.65, 0.85, 1.0)]


# ------------------------------------------------------------------ Roc in the blizzard

## The col (StoryTrigger « RocCol », event « roc_col », once Dame Suie is gone; or the frost
## door, if Chloé got there another way): the blizzard, Roc, the truth, the wind drops.
static func roc_col(_trigger: Node) -> void:
	if Game.flag(&"roc_col_vu"):
		Game.set_flag(&"blizzard_col")   # (the col's trigger, once its scene has played elsewhere)
		return
	var w = S.world()
	if w == null:
		return
	S.lock(true)
	await S.wait(0.3)
	var chloe := Stage.chloe()
	var cast := {"lantern": {"on": true}}
	Game.set_weather(&"blizzard")   # (it closes in over a couple of seconds, before the first line)
	Game.set_flag(&"blizzard_col")
	Stage.shake(1.5, 0.6)
	await S.wait(BLIZZARD_CLOSES)
	await S.say(_blizzard(cast))
	var roc = cast.get("roc")
	await S.say(_the_promise(roc, cast.get("stop", Stage.chloe().global_position + ROC_STOPS)))
	await S.say(_makes_up(roc))
	await S.say(_the_way_up(roc, cast.get("seat")))
	cast["lantern"]["on"] = false
	if is_instance_valid(roc) and roc is Node:
		roc.queue_free()
	CS.lead_back()
	Stage.look_back()
	Game.award_team_xp(XP_ROC)
	Save.save_game()
	S.lock(false)
	if chloe:
		Stage.turn_to(chloe, S.at(P.PORTE_GIVRE.x, P.PORTE_GIVRE.y))


## The blizzard rises; a lantern in the white; it stops, falls: Roc.
static func _blizzard(cast: Dictionary) -> Array:
	var chloe := Stage.chloe()
	var rises := func() -> void:
		Stage.shake(2.0, 0.8)
		await S.wait(0.4)
		Stage.tremble(chloe, 1.4, 1.8)
		MS.snow_puff(chloe.global_position + Vector2(-30.0, 0.0), 18, 0.8, 0.6)
	var stop := S.ground_near(chloe.global_position + ROC_STOPS, 2)
	cast["stop"] = stop
	var lantern := func() -> void:
		var from := S.ground_near(chloe.global_position + LANTERN_FROM, 3)
		var roc := S.stranger("RocCol", "roc", from, "right")
		# (the dialogue box turns speakers towards each other by playing their standing picture:
		# out of its reach, he keeps his seat on the boulder while he talks)
		roc.remove_from_group(&"npc")
		roc.modulate.a = 0.0
		cast["roc"] = roc
		MS.lantern_on(roc, cast["lantern"])
		# A snowy boulder where he will stop, fading in out of the white (his seat: Roc's sitting
		# picture is drawn for a chair, never sitting on nothing), a little north: drawn behind him.
		var seat := Stage.show_thing(SEAT, stop + Vector2(0.0, -SEAT_BEHIND), "SiegeRoc")
		if seat:
			seat.scale = Vector2.ONE * SEAT_SCALE
			cast["seat"] = seat
		Stage.look_at(from, 1.0)
		Stage.fade_in(roc, 1.4)
		await roc.walk_to(stop.lerp(from, 0.45), "right", 45.0)
	var falls := func() -> void:
		var roc = cast.get("roc")
		if roc == null:
			return
		await roc.walk_to(stop, "right", 40.0)
		if not is_instance_valid(roc):
			return
		Stage.tremble(roc, 0.5, 2.0)
		await Stage.sit(roc)   # (his sitting picture, on the boulder)
		MS.snow_puff(stop, 14, 0.3, 0.3)
		Stage.shake(1.2, 0.3)
	return [
		CS.cue({"text": "Le vent se lève d'un coup. La neige ne tombe plus : elle vole, de côté, et efface tout. Le blizzard."}, rises),
		{"who": CHLOE, "text": "(Je ne vois plus rien… Même plus mes pieds.)"},
		CS.cue({"text": "Et puis, dans le blanc, une petite lumière. Une lanterne. Elle avance, s'arrête, repart…"}, lantern),
		CS.cue({"text": "… vacille, et se laisse tomber sur un rocher, à bout de souffle."}, falls),
	]



## « Chloé ? … Je te suivais. Enfin, je me suis perdu. » The lead dino shelters them; the
## promise; the nights; the drawer.
static func _the_promise(roc, stop: Vector2) -> Array:
	var chloe := Stage.chloe()
	var at := stop   # (where he sits, on his boulder)
	var runs := func() -> void:
		Stage.emote(chloe, "!")
		await CS.chloe_walk(at + Vector2(52.0, 8.0), 170.0, 1.6)
		Stage.turn_to(chloe, at)
		MS.kneel()
	var sits := func() -> void:   # (seated on his boulder since the fall: only his breath in the cold)
		if is_instance_valid(roc):
			MS.breath(roc, 8)
			Stage.emote(roc, "…")
	var shelter := func() -> void:
		var dino := CS.lead()
		if dino == null:
			return
		var mid: Vector2 = at.lerp(chloe.global_position, 0.5)
		await CS.lead_walk(mid + WINDBREAK, 90.0)
		Stage.turn_to(dino, mid + WINDBREAK * 3.0)
		Stage.rear(dino, 1.2)
		MS.snow_puff(dino.global_position + Vector2(-30.0, 0.0), 20, 0.9, 0.5)
	var wipes := func() -> void:
		if roc:
			for i in 3:
				await CS.reach(roc, (roc as Node2D).global_position + Vector2(0.0, -30.0), 5.0, 0.4)
			Stage.bow(roc, 1.2)
	var lead := Game.lead_dino()
	var lines: Array = [
		CS.cue({"who": CHLOE, "text": "Professeur ?!"}, runs),
		CS.cue({"text": "C'est Roc. De la neige jusqu'aux genoux, les lunettes couvertes de givre, une écharpe enroulée trois fois autour du cou."}, sits),
		{"who": ROC, "text": "Chloé ? … Ah. Tant mieux. Je te cherchais. Enfin… je te suivais. Enfin, je me suis perdu. Voilà."},
		CS.cue({"text": "Le vent souffle si fort que Chloé chancelle. %s se plante à côté d'eux, face au vent, comme un mur." % lead.nickname if lead
			else "Le vent souffle si fort que Chloé chancelle. Elle se serre contre Roc, dos au vent."}, shelter),
		{"who": CHLOE, "text": "Qu'est-ce que vous faites ici, par ce temps ?"},
		{"who": ROC, "text": "Le volcan. Depuis ton troisième Cœur, il gronde toutes les nuits. Les flacons tombent des étagères. Alors je suis venu voir le sceau. Comme d'habitude."},
		{"who": CHLOE, "text": "Comme… d'habitude ?"},
		CS.cue({"text": "Roc enlève ses lunettes. Il les essuie avec son écharpe. Il ne les remet pas."}, wipes),
		{"who": ROC, "text": "Il faut que je te dise. Tout. Maintenant, avant de geler pour de bon."},
		{"who": ROC, "text": "Il y a deux ans, Hélène m'a emmené ici, dans ce col. Elle m'a montré le volcan, et elle m'a demandé une chose : « Si je disparais, Anselme, surveille le sceau. Chaque nuit. Et ne le dis à personne. »"},
		{"who": ROC, "text": "Mes sorties de nuit, c'était ça. Le volcan, les sanctuaires, les Cœurs. Je vérifiais que tout dormait. Avec ma lanterne. Et de la cendre plein les chaussures."},
	]
	var seen: Array[String] = []
	if Game.flag(&"roc_parti_vu"):
		seen.append("sa lanterne vers le volcan, la première nuit")
	if Game.flag(&"roc_marais_vu"):
		seen.append("sa lanterne dans la brume du Marais")
	if Game.flag(&"pecheurs_vus"):
		seen.append("sa lanterne au bord du récif")
	if not seen.is_empty():
		var said := ", ".join(seen.slice(0, -1)) + " et " + seen[-1] if seen.size() > 1 else seen[0]
		lines.append({"who": CHLOE, "text": "(%s… Tout ce temps, il veillait.)" % (said.substr(0, 1).to_upper() + said.substr(1))})
	if Game.flag(&"ambre_noir_tiroir"):
		lines.append_array([
			{"who": CHLOE, "text": "Et l'ambre noir, dans votre tiroir ?"},
			{"who": ROC, "text": "Je le confisquais. Aux sbires, aux marchands du Havre, sur les plages… partout où j'en trouvais. Je ne savais pas quoi en faire, alors je le rangeais. Dans un tiroir fermé à clé. Comme un vieil idiot."},
		])
	lines.append_array([
		{"who": CHLOE, "text": "Pourquoi vous ne m'avez rien dit ?"},
		{"who": ROC, "text": "J'avais promis. Et puis… je voulais que tu te méfies. De tout le monde. Même de moi. C'est ce qu'elle t'avait écrit, non ? « Ne fais confiance qu'aux dinos. »"},
	])
	if Game.flag(&"found_journal_28"):
		lines.append_array([
			{"who": CHLOE, "text": "Je sais. J'ai trouvé une page, sous une pierre, dans le col. Elle y a tout écrit. « Il ment très mal : c'est pour ça qu'il se tait. »"},
			{"who": ROC, "text": "… Elle a écrit ça ? Elle écrivait tout. Même ce qu'elle me faisait promettre de taire. C'est tout elle."},
		])
	else:
		lines.append({"who": ROC, "text": "Elle l'a sûrement écrit quelque part. Elle écrivait tout. Même les secrets. Surtout les secrets."})
	return lines


## Chloé says sorry; Roc: she was right to doubt (Hélène doubted everyone, except those she
## loved: that was her mistake). A hug he does not know what to do with; then he does.
static func _makes_up(roc) -> Array:
	var chloe := Stage.chloe()
	var hugs := func() -> void:
		if roc is Node2D:
			MS.stand_up(chloe)
			await CS.chloe_walk((roc as Node2D).global_position + Vector2(26.0, 6.0), 90.0, 1.0)
			CS.Act.lean(chloe, (roc as Node2D).global_position, 8.0, 2.4)
			await S.wait(0.8)
			CS.Act.lean(roc, chloe.global_position, 6.0, 1.8)
			Stage.emote(chloe, "♥")
			await S.wait(0.6)
			Stage.emote(roc, "♥")
	return [
		CS.cue({"who": CHLOE, "text": "Professeur… J'ai douté de vous. Au Cabinet, au Marais… Pardon."}, func() -> void: Stage.bow(chloe, 1.0)),
		{"who": ROC, "text": "Tu as bien fait. À ta place, j'aurais douté aussi. Hélène aussi : elle doutait de tout le monde… sauf des gens qu'elle aimait."},
		{"who": ROC, "text": "Et c'est là qu'elle se trompait."},
		{"who": ROC, "text": "Pas avec toi, en tout cas. Ni avec moi. Enfin… j'espère."},
		CS.cue({"text": "Chloé le serre dans ses bras. Roc ne sait pas quoi faire des siens. Puis il trouve."}, hugs),
		{"flag": &"roc_innocente"},
	]


## The wind drops; a blue glow at the top of the col: the frost door. Roc goes back down (to
## Bertille's soup), relights his lantern, grumbling in Latin.
static func _the_way_up(roc, seat) -> Array:
	var door := S.at(P.PORTE_GIVRE.x, P.PORTE_GIVRE.y)
	var calms := func() -> void:
		Game.set_weather(&"snow")
		await CS.pan(door + Vector2(0.0, DOOR_VIEW * S.CELL), 2.2)
		CS.pulse(door + Vector2(0.0, -30.0), MS.ICE_BLUE, 3, 1.4, 2.6, 5.0)
	var goes := func() -> void:
		Stage.look_back(0.8)
		if is_instance_valid(roc) and roc is Npc:
			await CS.get_up(roc, 0.5)
			var at: Vector2 = (roc as Node2D).global_position
			var down := S.at(P.BERTILLE.x, P.BERTILLE.y)
			(roc as Npc).walk_to(at + (down - at).normalized() * 6.0 * S.CELL, "", 60.0)
			Stage.fade_out(roc, 3.0, false)
		if is_instance_valid(seat) and seat is Node2D:   # (his boulder goes back into the white)
			Stage.fade_out(seat, 2.4, true)
	var soup := "Moi, je redescends. Bertille me doit un bol de soupe depuis vingt ans." if Game.flag(&"bertille_vue") \
		else "Moi, je redescends. Il y a de la fumée, dans la vallée : quelqu'un aura bien un bol de soupe pour un vieux professeur gelé."
	return [
		CS.cue({"text": "Le vent tombe un peu. Dans le blanc, tout en haut du col, une lueur bleue apparaît. Une porte."}, calms),
		{"who": ROC, "text": "Le sanctuaire de Givre. Hélène y montait seule. Moi, j'attendais ici, avec du thé. Il était toujours froid quand elle redescendait."},
		{"who": ROC, "text": "La porte a quatre creux. Tes Cœurs sauront quoi faire. " + soup},
		CS.cue({"text": "Roc remet ses lunettes, secoue sa lanterne, et redescend dans la neige en marmonnant quelque chose en latin."}, goes),
		{"who": CHLOE, "text": "(Merci, professeur. Pour tout ce temps.)"},
		{"flag": &"roc_col_vu"},
	]


# ------------------------------------------------------------------ the frost door

## The frost door at the top of the col (StoryProp « PorteGivre », event « porte_givre »): not
## before the sleepers are safe (a violet glow down by the glacier); Roc's scene first if it has
## not played; then the three Cœurs light three hollows, the fourth waits, the ice melts.
static func porte_givre(who: Node) -> void:
	if Game.flag(&"sanctuaire_givre_ouvert"):
		return
	var at: Vector2 = (who as Node2D).global_position if who is Node2D else S.at(P.PORTE_GIVRE.x, P.PORTE_GIVRE.y)
	if not Game.flag(&"suie_monts_battue"):
		var glacier := S.at(P.ENTREE_GROTTES.x, P.ENTREE_GROTTES.y)
		await S.say([
			CS.cue({"text": "Une grande porte de glace, fermée, avec quatre creux ronds. Les Cœurs battent dans la sacoche… mais au loin, vers le glacier, une lueur violette clignote entre les rochers."},
				func() -> void:
					MS.hearts(1, 1.0)
					Stage.look_at(glacier, 1.4)
					CS.pulse(glacier, MS.VIOLET, 3, 1.0, 2.0, 4.0)),
			{"who": CHLOE, "text": "(De l'ambre noir, là-bas, près des grottes de glace… D'abord, voir ce qui s'y passe. La porte attendra.)"},
		])
		Stage.look_back()
		return
	if not Game.flag(&"roc_col_vu"):
		await roc_col(null)
	S.lock(true)
	var door = who
	var chloe := Stage.chloe()
	var looks := func() -> void:
		if is_instance_valid(door) and door is Node2D:
			await CS.chloe_walk(at + Vector2(-30.0, 46.0), 90.0, 2.0)   # (in front of it, a little aside)
			Stage.turn_to(chloe, at)
		Stage.look_at(at + Vector2(0.0, DOOR_VIEW * S.CELL), 1.2)
		Game.set_flag(&"porte_givre_vue")
	var beat := func() -> void:
		await MS.hearts(2, 0.8)
	var lines: Array = [
		CS.cue({"text": "Une porte de glace, haute comme deux maisons, prise dans la roche du col. Au milieu, quatre creux ronds, grands comme un poing."}, looks),
		CS.cue({"text": "Dans la sacoche, les Cœurs se mettent à battre, fort, tous ensemble."}, beat),
	]
	# One Cœur after another in its hollow (the door's picture with 1, 2, 3 Cœurs set in it).
	var said := [
		"Chloé sort le premier Cœur, celui du Marais, et le pose dans le creux d'en haut, à gauche. Il s'y loge tout seul, et s'allume.",
		"Puis celui du Désert, encore chaud comme le sable à midi : en haut, à droite.",
		"Puis celui de la Côte, frais comme un galet mouillé : en bas, à gauche.",
	]
	for i in mini(MS.hearts_count(), HOLLOWS.size() - 1):
		lines.append(CS.cue({"text": said[i]}, _sets_heart.bind(door, at, i)))
	var fourth := func() -> void:
		_hollow_light(at, HOLLOWS.size() - 1, MS.ICE_BLUE, 2, 1.6, 1.0)
	var together := func() -> void:
		for i in HOLLOWS.size() - 1:
			_hollow_light(at, i, MS.HEART_GLOW, 3, 0.9, 2.4)
		MS.hearts(3, 0.9)
	var melts := func() -> void:
		MS.crack(2.0)
		for i in 5:
			CS.Act.burst(at + Vector2(randf_range(-50.0, 50.0), 0.0), MELT, 10, randf_range(0.4, 2.8), 0.3)
			await S.wait(0.3)
		if is_instance_valid(door) and door is CanvasItem:
			Stage.glow(door, Color(1.2, 1.35, 1.6), 2, 0.8)
			Stage.tremble(door, 1.2, 2.0)
			await S.wait(1.0)
			CS.Act.burst(at, MELT, 40, 1.2, 1.2)
			Stage.shake(3.0, 0.8)
			CS.sfx(MS.RUMBLE, -8.0)
			if is_instance_valid(door):
				await Stage.fade_out(door, 1.0, false)
	var back := func() -> void:
		for i in 3:
			CS.sparkle(at + Vector2(randf_range(-30.0, 30.0), 10.0), 0.3, 8, 0.1)
		await CS.reach(chloe, at, 12.0, 1.0)
		MS.hearts(1, 1.0)
	lines.append_array([
		CS.cue({"text": "Le quatrième creux, en bas à droite, reste sombre. Il attend son Cœur : celui qui dort derrière la porte."}, fourth),
		CS.cue({"text": "Les trois Cœurs battent ensemble, dans la glace, de plus en plus fort."}, together),
		CS.cue({"text": "La glace se met à fondre. D'abord des gouttes, puis des ruisseaux. La porte devient transparente comme une vitre… et s'effondre en neige fondue."}, melts),
		CS.cue({"text": "Dans la neige fondue, les trois Cœurs roulent jusqu'aux pieds de Chloé, tièdes. Elle les ramasse et les remet dans sa sacoche."}, back),
		{"who": CHLOE, "text": "(Le sanctuaire de Givre…)"},
		{"flag": &"sanctuaire_givre_ouvert"},
	])
	await S.say(lines)
	if is_instance_valid(door) and door is Node:
		door.queue_free()
	Stage.look_back()
	Game.award_team_xp(XP_PORTE)
	Save.save_game()
	S.lock(false)


## Chloé sets Cœur n° `i` (0: the Marais', 1: the Désert's, 2: the Côte's) in its hollow: she holds
## it out (its picture rising from her hands), the door's picture now has it (porte_givre_<i+1>),
## amber light and sparks on that hollow, a heartbeat.
static func _sets_heart(door, at: Vector2, i: int) -> void:
	var chloe := Stage.chloe()
	if chloe:
		Stage.turn_to(chloe, at)
		var item := "coeur_%d" % (i + 1)
		if ItemsDB.ITEMS.has(item):
			CS.Act.pop(chloe.global_position, item, 1.0)
		await CS.reach(chloe, at, 12.0, 0.8)
	var kind := "porte_givre_%d" % (i + 1)
	if is_instance_valid(door) and Prop.KINDS.has(kind):
		door.set("kind", kind)
	_hollow_light(at, i, MS.HEART_GLOW, 2, 1.0, 2.6)
	CS.sfx(MS.ICE_SOUND, -6.0)
	MS.hearts(1, 0.8)


## A light and amber sparks on hollow `i` of the door whose foot is at `at` (px), up at its height:
## `beats` pulses of `secs`, up to `energy`. Not awaited.
static func _hollow_light(at: Vector2, i: int, colour: Color, beats: int, secs: float, energy: float) -> void:
	var hollow: Vector2 = HOLLOWS[i]
	var px := at + Vector2(hollow.x * S.CELL, 0.0)
	CS.sparkle(px, hollow.y, 12, 0.06)
	var light := Stage.light_at(px, Color(colour / maxf(colour.r, maxf(colour.g, colour.b)), 1.0), 1.4)
	if light == null:
		return
	light.position.y += hollow.y - 1.1   # (light_at puts it 1.1 m up)
	var t := light.create_tween()
	for b in beats:
		t.tween_property(light, "light_energy", energy, secs * 0.5).set_trans(Tween.TRANS_SINE)
		t.tween_property(light, "light_energy", energy * 0.25, secs * 0.5).set_trans(Tween.TRANS_SINE)
	t.tween_property(light, "light_energy", 0.0, 0.5)
	t.tween_callback(light.queue_free)
