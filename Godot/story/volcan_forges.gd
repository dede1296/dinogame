class_name VolcanForges
## Chapter 8, the Plaine Volcanique, the forges of the Ombre Noire (zone forges_ombre;
## docs/chapitre-8-scenes.md, scenes 3 to 5): a camp nearly empty, the bone masks sitting on the
## ground; Léonce, an old fisherman of the port (« Rentre, Léonce. »); three small forges, each
## kept by a corrupted dino with a numbered iron plate (7 the Saichania, 11 the Allosaurus, 12 the
## Majungasaurus): calmed, each one puts out its own forge (shown, not told); the three out, 3 and 7
## push the barricade down together (« MA BARRICADE ! »); Brac, the last time: no orders since this
## morning, his visiting cards, Fournaise (the only one he named), the battle, the one bitter
## moment, the bone mask thrown in the ash, « voir la mer. De LOIN. »; Fournaise chooses. Dame Suie
## is in story/volcan_suie.gd.
## Flags: forges_arrivee, leonce_vu, forge_1_eteinte to forge_3_eteinte, petites_forges_eteintes,
## barricade_tombee, brac_volcan_vu, brac_vaincu, brac_parti, fournaise_garde, masque_brac_vu;
## leonce_n (lines).

const S := preload("res://story/story.gd")
const CS := preload("res://story/cote_stage.gd")
const MS := preload("res://story/monts_stage.gd")
const Act := preload("res://story/marais_stage.gd")
const V := preload("res://story/volcan.gd")
const CHLOE := "Chloé"
const BRAC := "Brac"
const LEONCE := "Léonce"
## The three small forges: their guard (node, species, level of the bestiary), the forge's prop,
## its fuel barrel (forge 3), the plate's number.
const GUARDS := {
	1: {"nodes": ["Numero7"], "species": &"saichania", "level": 43, "forge": ["Forge1"], "plate": 7,
		"seen": "Un Saichania aux veines violettes tourne autour de la première forge, sans s'arrêter, comme s'il cherchait la porte. Plaque au cou : « 7 »."},
	2: {"nodes": ["Numero11"], "species": &"allosaurus", "level": 43, "forge": ["Forge2"], "plate": 11,
		"seen": "Un Allosaurus, veines violettes, grogne devant la deuxième forge et claque des dents dans le vide. Plaque : « 11 »."},
	3: {"nodes": ["Numero12"], "species": &"majungasaurus", "level": 44, "forge": ["Forge3"], "plate": 12,
		"seen": "Un Majungasaurus, veines violettes, gratte le sol devant la troisième forge, et regarde ailleurs. Plaque : « 12 »."},
}
## A small forge once out (its prop's examination: the scenes' own words).
const FORGE_OUT := {
	1: "La forge penche dans la cendre. Les braises se sont éteintes une à une, en sifflant.",
	2: "La forge, sans soufflet. Sans air, elle a rougi, pâli, et s'est éteinte.",
	3: "La forge, froide. L'ambre noir brûle très mal, en fin de compte.",
}
const FORGE_KIND_OUT := "forge_eteinte"
const BARRICADE_KIND_OUT := "barricade_tombee"
## Brac's team (levels of the scenes: 44 to 46; simulated by the MÉCANIQUES agent).
const TEAM := [
	[&"stygimoloch", 44, "Cabosse", "Cabosse, cette fois tu te relèves !"],
	[&"majungasaurus", 44, "Grognon", "Grognon ! Et ne boude pas : c'est la dernière fois que je te le demande."],
	[&"allosaurus", 45, "Mastoc", "Mastoc ! Il a encore du sable entre les dents. Depuis le Désert. Il ne veut pas qu'on le brosse."],
]
const FOURNAISE := &"daspletosaurus"
const FOURNAISE_LEVEL := 46
## Where Brac's three lie round him (px from him), Fournaise's cage (px from him, when the zone
## has none), how far he walks off before the ash hides him (tiles).
const AROUND := [Vector2(-70.0, 30.0), Vector2(70.0, 34.0), Vector2(-10.0, 60.0)]
const CAGE_FROM_BRAC := Vector2(120.0, -24.0)
const BRAC_WALK := 10.0
const BRAC_LEAVES := 7.0
const LEONCE_AGAIN := [
	"La petite Kerval m'a dit bonjour. Avec mon masque sur la figure. Elle m'a reconnu aux chaussettes.",
	"Le rouquin, il est pas méchant. Il est bruyant. C'est pas pareil. Enfin, c'est un peu pareil, quand on dort à côté.",
]
const XP_ARRIVEE := 20
const XP_FORGE := 30
const XP_BARRICADE := 20
const XP_BRAC := 150


# ------------------------------------------------------------------ arriving

## Scene 3, the first time at the forges: three small ones, a great black tower spitting violet
## smoke, cages, barrels, anvils, nearly nobody; the bone masks sitting idle, one asleep;
## Moustique cries once towards the great forge; Brac's voice, behind the barricade.
static func arrival() -> void:
	if Game.flag(&"forges_arrivee"):
		return
	var w = S.world()
	if w == null:
		return
	S.lock(true)
	await S.wait(0.4)
	var chloe := Stage.chloe()
	var great := V.at_node(["GrandeForge"], V.spot("GRANDE_FORGE", Vector2(0.0, -9.0 * S.CELL)))
	var sitting = V.actor_of(["Leonce"])
	var forges := func() -> void:
		for n in [1, 2, 3]:
			var at := _forge_px(n, chloe.global_position + Vector2((n - 2) * 4.0 * S.CELL, -4.0 * S.CELL))
			Stage.look_at(at, 0.7)
			CS.pulse(at, V.FIRE_RED, 2, 1.0, 2.4, 3.5)
			await S.wait(0.8)
		await Stage.look_at(great + Vector2(0.0, -2.0 * S.CELL), 1.0)
		CS.pulse(great, MS.VIOLET, 3, 1.4, 3.0, 6.0)
	var idle := func() -> void:
		if sitting is Node2D:
			Stage.look_at((sitting as Node2D).global_position, 1.0)
			await S.wait(1.2)
			Stage.emote(sitting, "…")
		else:
			Stage.look_back(1.0)
	var voice := func() -> void:
		Stage.look_back(0.6)
		CS.far_cry("pteranodon", "neutre", -10.0, 1.6)   # (Moustique, once, towards the great forge)
		Stage.turn_to(chloe, great)
		await S.wait(0.5)
		Stage.shake(1.2, 0.4)
		Stage.emote(chloe, "!")
	await S.say([
		CS.cue({"text": "Les forges. Trois petites, qui rougissent sous des auvents, et au fond, sur la roche, une grande : une tour noire qui crache une fumée violette. Des cages. Des fûts. Des enclumes. Et presque personne."}, forges),
		CS.cue({"text": "Les masques d'os qui restent sont assis par terre. Ils ne font rien. L'un d'eux dort."}, idle),
		{"who": CHLOE, "text": "(Ça devrait grouiller. Ça ne grouille pas. … Ils attendent quelque chose. Ou quelqu'un qui ne reviendra pas.)"},
		CS.cue({"who": BRAC, "text": "QUI A LAISSÉ SORTIR LE TROIS ?!"}, voice),
		{"who": CHLOE, "text": "(Brac. … Lui au moins, il est là.)"},
		{"flag": &"forges_arrivee"},
	])
	Stage.look_back()
	Game.award_team_xp(XP_ARRIVEE)
	Save.save_game()
	S.lock(false)


# ------------------------------------------------------------------ Léonce

## 3 bis, Léonce (Npc « Leonce », hide_flag grande_forge_eteinte: he goes home), a bone mask on
## his knee like a hat he no longer wants to wear: twelve years; the captain said « Rentre ».
static func leonce(who: Node) -> void:
	if Game.flag(&"grande_forge_eteinte"):
		await S.say([{"who": LEONCE, "text": "La grande s'est éteinte ? Alors j'y vais. Si tu passes au port : je raccommode les filets, et je ne pose pas de questions. Les deux, c'est gratuit."}])
		return
	if Game.flag(&"leonce_vu"):
		await S.say([{"who": LEONCE, "text": ForetCamp.next_line(&"leonce_n", LEONCE_AGAIN)}])
		return
	S.lock(true)
	if who is Node2D:
		Stage.sit(who)
	var points := func() -> void:
		var brac_npc := V.at_node(["BracVolcan", "Barricade"], V.spot("BRAC", Vector2(0.0, -6.0 * S.CELL)))
		if who is Npc:
			CS.reach(who, brac_npc, 8.0, 1.0)
		Stage.look_at(brac_npc, 1.0)
	await S.say([
		{"who": LEONCE, "text": "Tu cherches la sortie, petite ? Moi aussi. Ça fait douze ans."},
		{"who": LEONCE, "text": "Léonce. Du port. Je raccommodais les filets, avant. Puis il n'y a plus eu de poisson, et il y a eu ça. Il paie. Enfin, il payait."},
		{"who": CHLOE, "text": "Qui ?"},
		CS.cue({"who": LEONCE, "text": "Le grand rouquin, là-bas, derrière les cages. Il crie beaucoup pour un homme qu'on ne paie plus. La capitaine est passée ce matin, avec la petite. Elle m'a dit : « Rentre, Léonce. »"}, points),
		CS.cue({"who": LEONCE, "text": "Vingt ans qu'elle me dit quoi faire, alors je rentre. Dès que mes jambes auront compris."}, func() -> void: Stage.look_back(0.8)),
		{"flag": &"leonce_vu"},
	])
	Save.save_game()
	S.lock(false)


# ------------------------------------------------------------------ the three small forges

## Scene 4, a small forge and its guard (DinoNpc « Numero7 », « Numero11 », « Numero12 », or the
## forge's prop « Forge1 »…, which leads to its guard): the question, the battle (calmed), then
## the guard puts out its own forge. The three out: the barricade.
static func forge(n: int, who: Node) -> void:
	var out := StringName("forge_%d_eteinte" % n)
	if Game.flag(out):
		await S.say([{"text": FORGE_OUT[n]}])
		if Game.flag(&"petites_forges_eteintes") and not Game.flag(&"barricade_tombee"):
			await _barricade_falls()
		return
	var g: Dictionary = GUARDS[n]
	var guard = V.actor_of(g["nodes"])
	if guard == null and who is DinoNpc:
		guard = who
	if await Dialogue.choose("", g["seen"], ["L'approcher doucement", "Pas maintenant"]) != 0:
		return
	if not await V.calm(guard, g["plate"], g["species"], g["level"]):
		return
	S.lock(true)
	match n:
		1:
			await S.say(_seven(guard))
		2:
			await S.say(_eleven(guard))
		3:
			await S.say(_twelve(guard))
	Game.set_flag(out)
	_trots_off(guard)
	CS.lead_back()
	Stage.look_back()
	Game.award_team_xp(XP_FORGE)
	Save.save_game()
	S.lock(false)
	if Game.flag(&"forge_1_eteinte") and Game.flag(&"forge_2_eteinte") and Game.flag(&"forge_3_eteinte"):
		Game.set_flag(&"petites_forges_eteintes")
		await _barricade_falls()


## Forge 1, Numéro 7: three steps back « comme Grelot devant un mur de glace »; BONG, BONG; the
## forge tips over, the embers die in the ash; it sits down, very pleased with itself.
static func _seven(guard) -> Array:
	var chloe := Stage.chloe()
	var forge_px := _forge_px(1, _px_of(guard) + Vector2(60.0, -20.0))
	var back := func() -> void:
		Stage.turn_to(guard, forge_px)
		Stage.look_at(forge_px.lerp(chloe.global_position, 0.3), 1.0)
		if guard is DinoNpc:
			var from: Vector2 = (guard as Node2D).global_position
			await (guard as DinoNpc).walk_to(from + (from - forge_px).normalized() * 1.6 * S.CELL, 40.0)
			Stage.turn_to(guard, forge_px)
	var bongs := func() -> void:
		for i in 2:
			await Stage.lunge(guard, forge_px, 2.0)
			CS.sfx(V.BLOW, -6.0)
			_forge_shakes(1)
			await S.wait(0.7)
		_forge_out(1, forge_px)
	var pleased := func() -> void:
		Stage.bow(guard, 1.0)
		await S.wait(1.0)
		Stage.hop(guard, 2, 5.0)
		Stage.emote(guard, "♥")
	return [
		CS.cue({"text": "Numéro 7 s'arrête. Il regarde la forge. Il recule de trois pas, lentement, comme Grelot devant un mur de glace…"}, back),
		{"who": CHLOE, "text": "Oh non. Oh si."},
		CS.cue({"text": "Il prend son élan. BONG. La forge penche. Il recommence. BONG. La forge bascule, et les braises s'éparpillent dans la cendre, où elles s'éteignent une à une, en sifflant."}, bongs),
		CS.cue({"text": "Numéro 7 s'assoit dans la cendre, très content de lui. Puis il part, au trot, vers les champs."}, pleased),
		{"who": CHLOE, "text": "(C'est pour ça qu'il tournait autour. Il cherchait par où la pousser.)"},
	]


## Forge 2, Numéro 11: it tears the bellows off and shakes it like a rag; without air, the forge
## goes out; it drops the leather at Chloé's feet, like a present.
static func _eleven(guard) -> Array:
	var chloe := Stage.chloe()
	var forge_px := _forge_px(2, _px_of(guard) + Vector2(50.0, -20.0))
	var tears := func() -> void:
		Stage.turn_to(guard, forge_px)
		Stage.look_at(forge_px.lerp(chloe.global_position, 0.3), 1.0)
		await S.wait(1.4)
		await CS.Act.lean(guard, forge_px, 18.0, 0.6)
		var bellows = V.actor_of(["Soufflet"])   # (the zone's bellows, gone from it once forge_2_eteinte)
		if bellows:
			Stage.fade_out(bellows, 0.4, true)
		Stage.tremble(guard, 1.6, 6.0)
		Stage.cry(guard, &"attaque")
		await S.wait(1.6)
		_forge_out(2, forge_px)
	var gift := func() -> void:
		if guard is DinoNpc:
			await (guard as DinoNpc).walk_to(S.ground_near(chloe.global_position + Vector2(56.0, -16.0), 2), 80.0)
		Stage.turn_to(guard, chloe.global_position)
		await Stage.bow(guard, 0.8)
		var leather := Stage.show_thing("soufflet", chloe.global_position + Vector2(24.0, 10.0), "SouffletArrache")
		if leather:
			leather.set_meta(&"scene_thing", true)
		Stage.emote(chloe, "?")
	return [
		CS.cue({"text": "Numéro 11 se tait. Il regarde la forge longtemps. Puis il attrape le soufflet dans sa gueule, l'arrache d'un coup de cou, et le secoue comme un chiffon jusqu'à ce qu'il n'en reste que du cuir. Sans air, la forge rougit, pâlit, et s'éteint."}, tears),
		CS.cue({"text": "Il laisse tomber le cuir aux pieds de Chloé. Comme un cadeau."}, gift),
		{"who": CHLOE, "text": "… Merci. Je crois."},
	]


## Forge 3, Numéro 12: it thinks (one sees it think), pushes the barrel of black amber into the
## forge with its snout; violet smoke, then white, then nothing.
static func _twelve(guard) -> Array:
	var chloe := Stage.chloe()
	var forge_px := _forge_px(3, _px_of(guard) + Vector2(50.0, -20.0))
	var barrel = V.actor_of(["FutForge3", "FutAmbreNoir"])
	var barrel_px: Vector2 = (barrel as Node2D).global_position if barrel is Node2D else forge_px + Vector2(-40.0, 20.0)
	var thinks := func() -> void:
		Stage.look_at(forge_px.lerp(chloe.global_position, 0.3), 1.0)
		Stage.turn_to(guard, forge_px)
		await S.wait(0.9)
		Stage.turn_to(guard, barrel_px)
		await S.wait(0.9)
		Stage.turn_to(guard, chloe.global_position)
		Stage.emote(guard, "?")
		await S.wait(1.2)
		Stage.emote(guard, "!")
	var pushes := func() -> void:
		Stage.turn_to(guard, barrel_px)
		await CS.Act.lean(guard, barrel_px, 14.0, 1.4)
		if barrel is Node2D:
			var t: Tween = (barrel as Node2D).create_tween()
			t.tween_property(barrel, "global_position", forge_px + Vector2(0.0, 6.0), 1.2).set_trans(Tween.TRANS_SINE)
			await t.finished
			Stage.fade_out(barrel, 0.4, true)
	var smoke := func() -> void:
		CS.pulse(forge_px, MS.VIOLET, 2, 1.0, 3.0, 4.0)
		for i in 3:
			Act.burst(forge_px + Vector2(0.0, -20.0), MS.BREATH_BITS, 12, 1.6, 0.25)
			await S.wait(0.5)
		_forge_out(3, forge_px)
	return [
		CS.cue({"text": "Numéro 12 regarde la forge, puis le gros fût d'ambre noir à côté, puis Chloé. Il réfléchit. On le voit réfléchir."}, thinks),
		CS.cue({"text": "Il pousse le fût du museau, doucement, jusqu'à ce qu'il tombe dans la forge."}, pushes),
		CS.cue({"text": "La fumée devient violette, puis blanche, puis plus rien. L'ambre noir brûle très mal, en fin de compte."}, smoke),
		{"who": CHLOE, "text": "(Dame Suie dirait : « Un problème de dosage. »)"},
	]


## The calmed guard trots off towards the fields (a wild dino there now, without its plate).
static func _trots_off(guard) -> void:
	if not guard is DinoNpc or not is_instance_valid(guard):
		return
	var at: Vector2 = (guard as Node2D).global_position
	var away := V.spot_or("ENTREE_FORGES", at + Vector2(0.0, 6.0 * S.CELL))
	var dir: Vector2 = (away - at).normalized() if away.distance_to(at) > 1.0 else Vector2(0.0, 1.0)
	Stage.fade_out(guard, 2.4, true)
	(guard as DinoNpc).walk_to(at + dir * 6.0 * S.CELL, 140.0)


## A small forge's prop shakes (a blow).
static func _forge_shakes(n: int) -> void:
	var prop = V.actor_of(GUARDS[n]["forge"])
	if prop:
		Stage.tremble(prop, 0.4, 4.0)
	Stage.shake(2.0, 0.3)


## A small forge goes out: its picture (forge_eteinte when drawn), the embers dying in the ash.
static func _forge_out(n: int, forge_px: Vector2) -> void:
	var prop = V.actor_of(GUARDS[n]["forge"])
	if prop:
		Stage.repaint(prop, FORGE_KIND_OUT)
	for i in 4:
		Act.burst(forge_px + Vector2(randf_range(-30.0, 30.0), 6.0), V.EMBER_BITS, 6, 0.2, 0.5)
		await S.wait(0.3)
	Act.burst(forge_px + Vector2(0.0, -10.0), V.ASH_BITS, 12, 0.8, 0.3)


## Where a small forge stands (px): its prop, else `fallback`.
static func _forge_px(n: int, fallback: Vector2) -> Vector2:
	var name := "FORGE_%d" % n
	return V.at_node(GUARDS[n]["forge"], V.spot_or(name, fallback))


static func _px_of(actor) -> Vector2:
	if actor is Node2D and is_instance_valid(actor):
		return (actor as Node2D).global_position
	var chloe := Stage.chloe()
	return chloe.global_position + Vector2(0.0, -90.0) if chloe else Vector2.ZERO


# ------------------------------------------------------------------ the barricade

## The barricade's prop (StoryProp « Barricade »): before, the way to the great forge is shut;
## once the three forges are out, it falls (if the scene was cut short).
static func barricade(_who: Node) -> void:
	if Game.flag(&"petites_forges_eteintes") and not Game.flag(&"barricade_tombee"):
		await _barricade_falls()
		return
	if Game.flag(&"barricade_tombee"):
		await S.say([{"text": "La barricade de cages, par terre. Des cages qui ont roulé partout."}])
		return
	await S.say([{"text": "Une barricade de cages empilées ferme le passage vers la grande forge."}])


## The three forges out: Numéro 3 trots in between the cages, goes for the barricade head down
## and pushes; Numéro 7, back from nobody knows where, pushes beside him; it falls with a great
## noise of rolling iron. Behind it, a very tall, very red-haired man jumps up.
static func _barricade_falls() -> void:
	if Game.flag(&"barricade_tombee"):
		return
	S.lock(true)
	var chloe := Stage.chloe()
	var wall = V.actor_of(["Barricade"])
	var at := V.at_node(["Barricade"], V.spot("BARRICADE", Vector2(0.0, -5.0 * S.CELL)))
	var cast := {}
	var push := func() -> void:
		await Stage.look_at(at.lerp(chloe.global_position, 0.3), 1.0)
		var three := V.stand_in(&"styracosaurus", at + Vector2(-5.0 * S.CELL, 2.0 * S.CELL), "Numero3Retour")
		var seven := V.stand_in(&"saichania", at + Vector2(5.0 * S.CELL, 2.0 * S.CELL), "Numero7Retour")
		cast["three"] = three
		cast["seven"] = seven
		for d in [three, seven]:
			if d:
				Stage.fade_in(d, 0.4)
				(d as DinoNpc).walk_to(at + Vector2(-0.8 * S.CELL if d == three else 0.8 * S.CELL, 0.9 * S.CELL), 150.0)
		await S.wait(2.2)
		for i in 3:
			for d in [three, seven]:
				if d:
					Stage.lunge(d, at, 1.4, i == 0)
			if wall:
				Stage.tremble(wall, 0.4, 3.0 + i)
			Stage.shake(1.5 + i, 0.3)
			await S.wait(0.8)
		CS.sfx(V.BLOW, -2.0)
		Stage.shake(4.0, 0.8)
		Act.burst(at, V.ASH_BITS, 24, 0.4, 0.8)
		if wall:
			if Prop.KINDS.has(BARRICADE_KIND_OUT):
				await Stage.repaint(wall, BARRICADE_KIND_OUT)
				(wall as CollisionObject2D).collision_layer = 0
			else:
				await Stage.fade_out(wall, 0.5, true)
	var up := func() -> void:
		var brac_npc = V.actor_of(["BracVolcan"])
		if brac_npc:
			Stage.look_at((brac_npc as Node2D).global_position, 0.8)
			Stage.pose(brac_npc, &"")   # (up from his cage: he sits on it in the zone)
			Stage.hop(brac_npc, 1, 14.0)
			Stage.turn_to(brac_npc, chloe.global_position)
	await S.say([
		CS.cue({"who": CHLOE, "text": "(Ils se sont donné rendez-vous. Je ne sais pas comment. Ils se sont donné rendez-vous.)"}, push),
		CS.cue({"text": "Derrière la barricade, un homme très grand, très roux, assis sur une cage retournée, se lève d'un bond."}, up),
		{"who": BRAC, "text": "MA BARRICADE !"},
		{"flag": &"barricade_tombee"},
	])
	for k in cast:
		var d = cast[k]
		if is_instance_valid(d):
			Stage.fade_out(d, 2.0, true)
			(d as DinoNpc).walk_to((d as Node2D).global_position + Vector2(0.0, 5.0 * S.CELL), 120.0)
	Stage.look_back()
	Game.award_team_xp(XP_BARRICADE)
	Save.save_game()
	S.lock(false)


# ------------------------------------------------------------------ Brac

## Scene 5, Brac (Npc « BracVolcan », event « brac_volcan », hide_flag brac_parti): before the
## battle (no orders, « Tu peux rentrer, Brac. », the visiting cards, Fournaise); the battle;
## the bitter moment and his going. Behind the barricade until it falls. Short moments (Greg,
## 18/10): ~9 lines in a row at most, cut by things watched (he jumps up; Mastoc's head on his
## knee; he walks off) and two choices (« Vous voulez qu'on arrête ? »; where he goes).
static func brac(who: Node) -> void:
	if Game.flag(&"brac_parti") or not Game.flag(&"barricade_tombee"):
		return
	var cast := _his_three(who)
	if not Game.flag(&"brac_vaincu"):
		if not Game.flag(&"brac_volcan_vu"):
			await _meets(who, cast)
		elif await Dialogue.choose(BRAC, _waits(),
			["Le défier", "Pas encore"]) != 0:
			return
		var rules: Dictionary = {"lose_spawn": V.spawn("SPAWN_CHAMPS")}
		rules.merge(V.battles_const("BRAC_RULES", {}), true)   # (the MÉCANIQUES agent's rules win)
		if not await S.duel(BRAC, _team(), rules):
			await S.say([{"who": BRAC, "text": _waits()}])
			return
		Game.set_flag(&"brac_vaincu")
		Save.save_game()
	await _after(who, cast)


## What he says when she comes back before the fight (a line each time, `brac_n`).
const BRAC_WAITS := [
	"Reviens quand tu voudras, moucheron ! Je ne vais nulle part. C'est bien le problème.",
	"Encore toi ? Mes bêtes font la sieste. Reviens quand tu veux !",
	"Deux cent quatre-vingt-dix-neuf cartes. La trois-centième, une petite l'a gardée. Elle a dit merci.",
]


static func _waits() -> String:
	return ForetCamp.next_line(&"brac_n", BRAC_WAITS)


## His three, lying round him (the zone's DinoNpc « Mastoc », « Cabosse », « Grognon » when there,
## else stand-ins), and Fournaise in the great cage (shown when it opens).
static func _his_three(who: Node) -> Dictionary:
	var cast := {}
	var at: Vector2 = (who as Node2D).global_position if who is Node2D else Stage.chloe().global_position + Vector2(0.0, -120.0)
	for i in TEAM.size():
		var name: String = TEAM[i][2]
		var d = V.actor_of([name])
		if d == null:
			d = V.stand_in(TEAM[i][0], V.spot_or(name.to_upper(), S.ground_near(at + AROUND[i], 2)), name)
			if d:
				Stage.fade_in(d, 0.6)
				CS.crouch(d, 0.22, 0.4)
		cast[name] = d
	cast["fournaise"] = V.actor_of(["Fournaise"])
	return cast


## 5 a, before the battle: no orders (9 lines); he looks at the fire, then jumps up (watched); his
## visiting cards (3 lines); a choice (« Vous voulez qu'on arrête ? », or nothing); Fournaise (6 or
## 5 lines). Also the test's entry (static_brac).
static func _meets(who: Node, cast: Dictionary) -> void:
	S.lock(true)
	await S.say(_before(who, cast))
	await _jumps_up(who)
	await S.say(_cards(who))
	var pick := await Dialogue.choose("", "Brac attend. Que dit Chloé ?", ["« Vous voulez qu'on arrête ? »", "Ne rien dire"])
	await S.say(_fournaise(who, cast, pick == 0))
	S.lock(false)


## Moment 1 (9 lines): « MON volcan »; the Trois; no orders since this morning; « Tu peux rentrer ».
static func _before(who: Node, cast: Dictionary) -> Array:
	var chloe := Stage.chloe()
	var at: Vector2 = (who as Node2D).global_position
	var mastoc = cast.get("Mastoc")
	var stands := func() -> void:
		Stage.pose(who, &"")   # (on his feet: back in the zone, he was sitting on his cage again)
		Stage.look_at(at.lerp(chloe.global_position, 0.4), 0.8)
		await CS.chloe_walk(at + Vector2(-20.0, 120.0), 90.0, 2.0)
		Stage.turn_to(chloe, at)
		if who is Npc:
			(who as Npc).face(chloe.global_position)
		Stage.hop(who, 1, 8.0)
	var looks := func() -> void:   # (at his forges out, the barricade down, Numéro 3 trotting off)
		Stage.turn_to(who, at + Vector2(0.0, 300.0))
		var three := V.stand_in(&"styracosaurus", at + Vector2(-4.0 * S.CELL, 4.0 * S.CELL), "Numero3Loin")
		if three:
			Stage.fade_in(three, 0.4)
			Stage.fade_out(three, 3.0, true)
			three.walk_to(three.global_position + Vector2(-5.0 * S.CELL, 3.0 * S.CELL), 110.0)
		await S.wait(1.2)
		if who is Npc:
			(who as Npc).face(chloe.global_position)
	var sits := func() -> void:
		Stage.sit(who)
		if mastoc:
			Stage.rear(mastoc, 0.8)
			CS.reach(who, (mastoc as Node2D).global_position, 8.0, 1.2)
	return [
		CS.cue({"who": BRAC, "text": "Le moucheron. ÉVIDEMMENT, le moucheron. La Forêt, le Désert, et maintenant MON volcan."}, stands),
		{"who": CHLOE, "text": "Ce n'est pas votre volcan."},
		CS.cue({"who": BRAC, "text": "C'est le volcan où je suis. Donc c'est mon volcan. C'est comme ça que ça marche, les volcans."}, looks),
		{"who": BRAC, "text": "Trois forges. Douze ans de forges. Et le Trois qui me regarde comme si c'était MOI qui l'avais mis dans une cage."},
		{"who": CHLOE, "text": "C'est vous qui l'avez mis dans une cage."},
		CS.cue({"who": BRAC, "text": "… Techniquement."}, sits),
		{"who": BRAC, "text": "Tu veux savoir quoi, moucheron ? Je n'ai plus d'ordres. Elle est passée là, juste là, avec les quatre Cœurs sous le bras, la petite Kerval à côté, et un Tricératops qui a éternué sur ma marmite."},
		{"who": CHLOE, "text": "(Caillou.)"},
		{"who": BRAC, "text": "Et tu sais ce qu'elle m'a dit, après douze ans ? « Tu peux rentrer, Brac. » RENTRER. Comme on dit à un chien."},
	]


## Watched, no line: a silence; he looks at the fire; then he jumps up, and is Brac again.
static func _jumps_up(who: Node) -> void:
	var at: Vector2 = (who as Node2D).global_position
	Stage.turn_to(who, at + Vector2(-60.0, 40.0))
	await S.wait(1.6)
	Stage.pose(who, &"")
	Stage.hop(who, 1, 12.0)
	Stage.turn_to(who, Stage.chloe().global_position)
	await S.wait(0.6)


## Moment 2 (3 lines): his visiting cards, three hundred; the only one he gave, to Maïa, who said
## thank you (then the choice).
static func _cards(who: Node) -> Array:
	var chloe := Stage.chloe()
	var at: Vector2 = (who as Node2D).global_position
	var card := func() -> void:   # (a dirty card held out: nothing to read, ash on it)
		CS.reach(who, chloe.global_position, 14.0, 1.4)
		Act.burst(at + Vector2(10.0, -40.0), V.ASH_BITS, 8, 1.2, 0.15)
	return [
		{"who": BRAC, "text": "Bon ! Ça ne change rien ! Je suis Brac, chasseur d'Alphas, et c'est écrit sur mes cartes de visite ! J'en ai, maintenant ! Trois cents ! Regarde !"},
		CS.cue({"text": "Il sort une carte sale de sa poche et la brandit. On ne lit rien : il y a de la cendre dessus."}, card),
		{"who": BRAC, "text": "J'en ai donné une. Une seule. À la petite Kerval, ce matin. Elle a dit « merci ». MERCI. Tu sais depuis combien de temps personne ne m'avait dit merci ?"},
	]


## After the choice (6 or 5 lines; `asked`: Chloé asked whether to stop): « gagner UNE fois »; his
## three wake; the great cage opens: Fournaise, a name, not a number.
static func _fournaise(who: Node, cast: Dictionary, asked: bool) -> Array:
	var at: Vector2 = (who as Node2D).global_position
	var cage := V.at_node(["EnclosFournaise", "Fournaise"], V.spot_or("FOURNAISE", at + CAGE_FROM_BRAC))
	var wakes := func() -> void:
		for k in ["Mastoc", "Cabosse", "Grognon"]:
			var d = cast.get(k)
			if d:
				CS.get_up(d, 0.4)
				Stage.rear(d, 0.8)
		Stage.look_at(cage, 1.0)
	var opens := func() -> void:
		CS.sfx(V.TINKLE, -4.0)
		Stage.shake(2.5, 0.6)
		var fence = V.actor_of(["EnclosFournaise"])   # (the pen's front, gone from the zone once brac_volcan_vu)
		if fence:
			Stage.fade_out(fence, 0.5, true)
		var big = cast.get("fournaise")
		if big == null:
			big = V.stand_in(FOURNAISE, S.ground_near(cage + Vector2(0.0, 30.0), 2), "Fournaise", 0, 1.1, true)
			cast["fournaise"] = big
		if big:
			Stage.fade_in(big, 0.6)
			Stage.rear(big, 1.2)
			Stage.cry(big, &"attaque")
	var lines: Array = []
	if asked:
		lines.append_array([
			{"who": CHLOE, "text": "… Vous voulez qu'on arrête ?"},
			CS.cue({"who": BRAC, "text": "ARRÊTER ?! Tu as éteint mes forges, renversé ma barricade, et tu me demandes si je veux ARRÊTER ?! Non, moucheron. Il me reste une chose à faire ici : gagner UNE fois."}, func() -> void: Stage.hop(who, 2, 8.0)),
		])
	else:
		lines.append(CS.cue({"who": BRAC, "text": "Et ne me regarde pas comme ça ! Tu as éteint mes forges, renversé ma barricade… Non, moucheron. Il me reste une chose à faire ici : gagner UNE fois."}, func() -> void: Stage.hop(who, 2, 8.0)))
	lines.append_array([
		CS.cue({"who": BRAC, "text": "Mastoc ! Cabosse ! Grognon ! Et toi, là-dedans : réveille-toi. On a de la visite."}, wakes),
		CS.cue({"text": "La grande cage s'ouvre : un Daspletosaurus corrompu, énorme, les veines violettes jusqu'au bout de la queue. Plaque : « FOURNAISE ». Un nom, pas un numéro."}, opens),
		{"who": BRAC, "text": "Fournaise. Mon chef-d'œuvre. Enfin, le chef-d'œuvre de la Suie : mais c'est MOI qui l'ai nourri. À la pelle."},
		{"who": CHLOE, "text": "(Un nom. Il lui a donné un nom. … Il l'aime bien, celui-là. Apaiser Fournaise : pas les autres, eux, ils sont à lui pour de vrai.)"},
		{"flag": &"brac_volcan_vu"},
	])
	return lines


## Cabosse, Grognon, Mastoc, then Fournaise (corrupted, a long calm); no healing between them.
## VolcanBattles.brac_team() when the MÉCANIQUES agent has it (its levels, balanced), else this.
static func _team() -> Array:
	var theirs: Array = V.from_battles(&"brac_team", [], [])
	if not theirs.is_empty():
		return theirs
	var team: Array = []
	for t: Array in TEAM:
		team.append([V.species_or(t[0]), t[1], t[2], {"before": [{"who": BRAC, "text": t[3]}]}])
	team.append([V.species_or(FOURNAISE), FOURNAISE_LEVEL, "Fournaise", {"corrupted": true, "long_calm": true,
		"before": [{"who": BRAC, "text": "Fournaise. Vas-y doucement, il est tout neuf. … Non, vas-y fort, qu'est-ce que je raconte."}],
		"intro": "Brac envoie Fournaise, et la cendre tremble !",
		"lesson": ["Fournaise ne tombe pas : il s'apaise. Les trois autres, oui."]}])
	return team


## 5 c, after the battle: Fournaise asleep, the bitter moment (4 lines); Mastoc's head on his knee
## (watched); the mask in the ash, the swearing, his three, Fournaise (9 lines); a choice (where
## he goes: the sea, or the Monts: the sea anyway, « de LOIN »); the biscuit (3 lines); he walks
## off (watched); the two masks (2 lines). Then Fournaise chooses.
static func _after(who: Node, cast: Dictionary) -> void:
	S.lock(true)
	var chloe := Stage.chloe()
	var at: Vector2 = (who as Node2D).global_position if who is Node2D else chloe.global_position + Vector2(0.0, -120.0)
	var big = cast.get("fournaise")
	if big == null:
		big = V.stand_in(FOURNAISE, S.ground_near(at + CAGE_FROM_BRAC + Vector2(0.0, 40.0), 2), "Fournaise", 0, 1.1, true)
		cast["fournaise"] = big
		if big:
			Stage.fade_in(big, 0.4)
	var mask := {}
	await S.say(_bitter(who, cast, big))
	await _knee(who, cast)
	await S.say(_the_bone_mask(who, mask))
	var pick := await Dialogue.choose(BRAC, "Quelque part où il n'y a pas de volcan. … Il y a des endroits sans volcan ?", ["« La mer. »", "« Les Monts Gelés. »"])
	await S.say(_the_sea(who, cast, pick == 0))
	await _walks_off(who, cast)
	await S.say(_two_masks(mask))
	await _fournaise_chooses(big)
	_clean_up(who, cast, mask)
	CS.lead_back()
	Stage.look_back()
	Game.award_team_xp(XP_BRAC)
	Save.save_game()
	S.lock(false)


## Moment 1 (4 lines): « Quatre fois. » Fournaise asleep, the first time; twelve years; « Rentrer
## où ? J'ai deux cent quatre-vingt-dix-neuf cartes de visite, et pas d'adresse dessus. »
static func _bitter(who: Node, cast: Dictionary, big) -> Array:
	var chloe := Stage.chloe()
	var at: Vector2 = (who as Node2D).global_position
	var asleep := func() -> void:
		Stage.look_at(at.lerp(chloe.global_position, 0.35), 0.8)
		if big is DinoNpc:
			await (big as DinoNpc).cleanse()
			CS.crouch(big, 0.3, 1.2)
		for k in ["Mastoc", "Cabosse", "Grognon"]:
			var d = cast.get(k)
			if d is DinoNpc:
				Stage.bow(d, 0.8)
	var sits := func() -> void:
		Stage.sit(who)
		if big:
			Stage.turn_to(who, (big as Node2D).global_position)
	return [
		CS.cue({"who": BRAC, "text": "… Quatre fois. La Forêt. Le Désert. Et deux fois ici, si on compte la barricade. Je compte la barricade."}, asleep),
		CS.cue({"who": BRAC, "text": "Il dort. Trois mois, et je ne l'avais jamais vu dormir."}, sits),
		{"who": BRAC, "text": "Douze ans, moucheron. Douze ans que je lui ramène des bêtes, que je dors dans la cendre, que je crie pour que ça avance. Et ce matin elle passe devant moi, sans s'arrêter, et elle dit « Tu peux rentrer »."},
		{"who": BRAC, "text": "Rentrer où ? J'ai deux cent quatre-vingt-dix-neuf cartes de visite, et pas d'adresse dessus."},
	]


## Watched, no line: a long silence. Mastoc lays his big head on Brac's knee. Chloé says nothing.
## Moustique neither. The lead dino sits down.
static func _knee(who: Node, cast: Dictionary) -> void:
	var at: Vector2 = (who as Node2D).global_position
	await S.wait(1.2)
	var mastoc = cast.get("Mastoc")
	if mastoc is DinoNpc:
		await (mastoc as DinoNpc).walk_to(S.ground_near(at + Vector2(46.0, 16.0), 1), 50.0)
		CS.Act.lean(mastoc, at, 12.0, 2.0)
	var dino := CS.lead()
	if dino:
		CS.crouch(dino, 0.2, 0.8)
	await S.wait(1.6)


## Moment 2 (9 lines): « Elle n'est pas rentrée non plus »; the bone mask thrown in the ash; the
## swearing; his three (« ils regardent mon sandwich »); Fournaise will choose; « Où est-ce que vous
## allez ? » (then the choice).
static func _the_bone_mask(who: Node, mask: Dictionary) -> Array:
	var at: Vector2 = (who as Node2D).global_position
	var off := func() -> void:
		Stage.pose(who, &"")
		CS.reach(who, at + Vector2(0.0, -40.0), 6.0, 1.2)
	var throws := func() -> void:   # (in the ash, at his feet: the bone mask makes no noise)
		await CS.reach(who, at + Vector2(0.0, 30.0), 10.0, 0.6)
		var m := Stage.show_thing("masque_os_sol", at + Vector2(-24.0, 22.0), "MasqueBracScene")
		mask["thing"] = m
		Act.burst(at + Vector2(-24.0, 22.0), V.ASH_BITS, 10, 0.1, 0.3)
		await S.wait(0.6)
		Stage.hop(who, 2, 8.0)
		Stage.shake(1.0, 0.3)
	return [
		{"who": CHLOE, "text": "(Il n'a pas peur du Masque. Il n'a plus de Masque. C'est pire, pour lui.)"},
		{"who": CHLOE, "text": "Elle n'est pas rentrée non plus, vous savez. Elle est montée. Et Maïa aussi."},
		{"who": BRAC, "text": "… Je sais. Je les ai regardées partir. La petite m'a dit bonjour, merci, et une carte dans la poche. C'est la plus polie de toute l'Ombre Noire, et elle n'en fait même pas partie."},
		CS.cue({"who": BRAC, "text": "Il me serrait, de toute façon."}, off),
		CS.cue({"who": BRAC, "text": "Bon. CROTTE DE STÉGOSAURE. Nom d'un fossile moisi. Par les écailles de ma grand-mère, et par celles de son Stégosaure."}, throws),
		{"who": BRAC, "text": "Je garde Mastoc, Cabosse et Grognon. Eux, quand je parle, ils me regardent. Ils regardent mon sandwich, mais ils me regardent."},
		{"who": CHLOE, "text": "Et Fournaise ?"},
		{"who": BRAC, "text": "Fournaise dort. On ne réveille pas un dino qui dort : c'est écrit sur un panneau quelque part, ta grand-mère en a mis partout. Il est à toi, moucheron. Ou aux coulées. Ou à personne. Il choisira."},
		{"who": CHLOE, "text": "Où est-ce que vous allez ?"},
	]


## After the choice (3 lines; `sea`: Chloé said « La mer. », else the Monts, which he will not
## have): the sea, « de LOIN »; the biscuit; his first swearing on the way.
static func _the_sea(who: Node, cast: Dictionary, sea: bool) -> Array:
	var chloe := Stage.chloe()
	var at: Vector2 = (who as Node2D).global_position
	var away := V.spot_or("ENTREE_FORGES", at + Vector2(0.0, 12.0 * S.CELL))
	var steps := func() -> void:
		if who is Npc:
			var dir: Vector2 = (away - at).normalized() if away.distance_to(at) > 1.0 else Vector2(0.0, 1.0)
			(who as Npc).walk_to(S.ground_near(at + dir * 2.0 * S.CELL, 2), "", 60.0)
	var leaves := func() -> void:
		var walkers: Array = [who, cast.get("Mastoc"), cast.get("Cabosse"), cast.get("Grognon")]
		for wk in walkers:
			if not is_instance_valid(wk):
				continue
			var from: Vector2 = (wk as Node2D).global_position
			var dir: Vector2 = (away - from).normalized() if away.distance_to(from) > 1.0 else Vector2(0.0, 1.0)
			Stage.fade_out(wk, BRAC_LEAVES, false)
			if wk is Npc:
				(wk as Npc).walk_to(from + dir * BRAC_WALK * S.CELL, "", 70.0)
			elif wk is DinoNpc:
				(wk as DinoNpc).walk_to(from + dir * BRAC_WALK * S.CELL, 70.0)
		Stage.look_at(away.lerp(chloe.global_position, 0.5), 2.0)
	return [
		{"who": BRAC, "text": "La mer. Je vais aller voir la mer. De LOIN. Pas en barque. Je ne monte plus dans la barque de personne." if sea
			else "Les MONTS ? Avec Bertille qui compte mes feux ? … Non. La mer. Je vais aller voir la mer. De LOIN. Pas en barque. Je ne monte plus dans la barque de personne."},
		CS.cue({"who": BRAC, "text": "Moucheron. Si tu la revois… la petite… Dis-lui que la carte, c'est gratuit. Elle a voulu me payer. Avec un biscuit. … C'était un bon biscuit."}, steps),
		CS.cue({"who": BRAC, "text": "Par la crotte moisie d'un fossile de grand-mère !"}, leaves),
	]


## Watched, no line: he goes off towards the fields, vexed, tall, not broken, his three behind him,
## Mastoc looking back at the pot; until the ash hides them.
static func _walks_off(_who: Node, _cast: Dictionary) -> void:
	await S.wait(BRAC_LEAVES * 0.5)


## Moment 3 (2 lines): « Il a surtout eu peur. »; the bone mask in the ash: two masks on the ground.
static func _two_masks(mask: Dictionary) -> Array:
	var chloe := Stage.chloe()
	var looks := func() -> void:
		var m = mask.get("thing")
		Stage.look_back(1.0)
		if is_instance_valid(m):
			Stage.turn_to(chloe, (m as Node2D).global_position)
	return [
		{"who": CHLOE, "text": "(Il va voir la mer. De loin. … Il n'a jamais fait peur à personne, en fait. Il a surtout eu peur.)"},
		CS.cue({"who": CHLOE, "text": "(Deux masques par terre. Un dans l'herbe, un dans la cendre. Personne ne les ramassera.)"}, looks),
		{"flag": &"brac_parti"},
	]


## Fournaise gets up, looks at Chloé, and chooses: Chloé's party when there is room (a fire dino:
## it crosses the lava), else the lava flows (found there, wild, at night). fournaise_garde says which.
static func _fournaise_chooses(big) -> void:
	var chloe := Stage.chloe()
	var room := Game.party.size() < Game.PARTY_MAX and SpeciesDB.PATHS.has(FOURNAISE)
	var gets_up := func() -> void:
		if big:
			await CS.get_up(big, 0.6)
			Stage.turn_to(big, chloe.global_position)
			Stage.emote(big, "…")
	var line := {"text": "Fournaise se lève, et regarde Chloé."}
	if room:
		await S.say([CS.cue(line, gets_up)])
		var d = V.from_battles(&"fournaise", [], null)
		if not d is Dino:
			d = Dino.create(FOURNAISE, FOURNAISE_LEVEL, "Fournaise")
		Game.add_caught(d)
		Game.set_flag(&"fournaise_garde")
		if big:
			Stage.fade_out(big, 0.6, true)
		Stage.companion_joy()
		Toast.say(S.world().get_tree(), "Fournaise rejoint ton équipe !")
		return
	var coulees := V.spot_or("SORTIE_COULEES", chloe.global_position + Vector2(8.0 * S.CELL, -4.0 * S.CELL))
	var goes := func() -> void:
		if big is DinoNpc:
			var from: Vector2 = (big as Node2D).global_position
			Stage.fade_out(big, 3.0, true)
			(big as DinoNpc).walk_to(from + (coulees - from).normalized() * 8.0 * S.CELL, 90.0)
	await S.say([CS.cue(line, gets_up), CS.cue({"text": "Puis il part, vers les coulées."}, goes)])
	Game.set_flag(&"fournaise_garde", false)


## The scene's actors gone (the zone's own nodes are hidden from now on: hide_flag brac_parti).
static func _clean_up(who: Node, cast: Dictionary, mask: Dictionary) -> void:
	for k in ["Mastoc", "Cabosse", "Grognon"]:
		var d = cast.get(k)
		if is_instance_valid(d):
			(d as Node).queue_free()
	if is_instance_valid(who):
		(who as Node).queue_free()
	var m = mask.get("thing")
	if is_instance_valid(m) and S.actor("MasqueBrac") != null:
		(m as Node).queue_free()


## The bone mask in the ash (StoryProp « MasqueBrac », show_flag brac_parti).
static func masque_brac(_who: Node) -> void:
	var lines: Array = [{"text": "Le masque d'os de Brac, dans la cendre. Il est fendu sur le côté : il le serrait vraiment."}]
	if not Game.flag(&"masque_brac_vu"):
		lines.append({"who": CHLOE, "text": "(Il ne reviendra pas le chercher. Il a dit : la mer.)"})
		lines.append({"flag": &"masque_brac_vu"})
	await S.say(lines)


# ------------------------------------------------------------------ for the tests

## For the tests (tools/capture.gd « static »): the forges on any zone, no battle: the arrival,
## Léonce (brought on), the three guards calmed (stand-ins) putting their forges out, the barricade.
static func static_forges() -> void:
	S.playing += 1
	var chloe := Stage.chloe()
	await arrival()
	var leonce_npc := S.stranger("Leonce", "sbire", S.ground_near(chloe.global_position + Vector2(-90.0, -60.0), 3), "down", LEONCE)
	if leonce_npc:
		leonce_npc.set_meta(Outfits.PERSON_META, &"leonce")   # (his sitting pose: leonce_assis, the zone's Npc's)
		await leonce(leonce_npc)
	for n in [1, 2, 3]:
		var g: Dictionary = GUARDS[n]
		var guard := V.stand_in(g["species"], S.ground_near(chloe.global_position + Vector2(-140.0 + 140.0 * (n - 1), -110.0), 3), (g["nodes"] as Array)[0], 0, 1.0)
		if guard:
			await Stage.fade_in(guard, 0.3)
		S.lock(true)
		match n:
			1:
				await S.say(_seven(guard))
			2:
				await S.say(_eleven(guard))
			3:
				await S.say(_twelve(guard))
		Game.set_flag(StringName("forge_%d_eteinte" % n))
		_trots_off(guard)
		S.lock(false)
	Game.set_flag(&"petites_forges_eteintes")
	await _barricade_falls()
	S.playing -= 1


## For the tests: Brac brought on beside Chloé (the barricade down), 5 a (the test picks the first
## answer of each choice), the battle skipped (brac_vaincu), 5 c and Fournaise's choice.
static func static_brac() -> void:
	S.playing += 1
	var chloe := Stage.chloe()
	Game.set_flag(&"barricade_tombee")
	var who := S.stranger("BracVolcan", V.sheet(["brac"]), S.ground_near(chloe.global_position + Vector2(0.0, -2.6 * S.CELL), 3), "down", BRAC)
	if who:
		var cast := _his_three(who)
		await _meets(who, cast)
		Game.set_flag(&"brac_vaincu")
		await _after(who, cast)
	S.playing -= 1
