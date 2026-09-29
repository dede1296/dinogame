class_name ForetCamp
## Chapter 2, the Forêt Jurassique, step 2 (docs/histoire.md, ch. 2, points 3 to 6). Behind the
## cracked wall (Coup de crâne), the Ombre Noire's camp: cages, black amber, the smell of cold
## ash. Brac's two henchmen, then Brac and his champion: the third hatchling stolen from the
## Cabinet, raised on black amber — the first great calming, and it joins Chloé. The pack's
## leader, the Utahraptor, freed and calmed at length with her own hatchling: the Sceau de la
## Forêt, the pack back. Brac's papers: Hélène's notes, page 11, a note from « M. ». What comes
## next (the Masque, Maïa at the bridge, the Cabinet) is in story/foret_fin.gd.
## Flags: camp_arrive, sbire_camp_1_vu / _2_vu, sbire_camp_1_battu / _2_battu, brac_parle,
## brac_battu, oeuf_vole_apaise, cage_ouverte, utah_lecon, sceau_foret, cages_ouvertes,
## found_journal_11 (DialogueDB page_11), papiers_brac_lus; papiers_n.

const S := preload("res://story/story.gd")
const GESTES := preload("res://story/foret_gestes.gd")
const CHLOE := "Chloé"
const BRAC := "Brac"
const FIRMIN := "Firmin"
const LANTERNE := "Sbire à la lanterne"
const OMBRE_MUSIC := "res://assets/audio/music/ombre.ogg"
const ALPHA_MUSIC := "res://assets/audio/music/alpha.ogg"
const LATCH := preload("res://assets/audio/sfx/latch.wav")
## Where a lost battle in the camp takes Chloé back to (its way in, east).
const CAMP_SPAWN := &"DepuisForet"
## The camp (camp_ombre, tiles): its way out (east), Brac's escape (over the rocks of the north),
## the Utahraptor's cage.
const CAMP_EXIT := Vector2(38.0, 14.0)
const BRAC_FLIGHT := Vector2(20.0, 1.5)
const UTAH_SPOT := Vector2(31.0, 8.0)
## What the arrival shows (tiles): the clearing, the tents' side, the decor's two cages (the
## Deinonychus, the Dilophosaurus), a crate of black amber, Brac by the fire, the henchmen's
## beat; the pile of crates Chloé hides behind (tools/zones/camp_ombre.gd places them).
const VIEW_CLEARING := Vector2(26.0, 11.0)
const VIEW_TENTS := Vector2(15.5, 9.0)
const VIEW_DEINO := Vector2(25.5, 7.0)
const VIEW_DILO := Vector2(7.5, 11.5)
const VIEW_CRATE := Vector2(9.4, 10.8)
const VIEW_BRAC := Vector2(20.3, 12.6)
const VIEW_BRAC_UTAH := Vector2(25.5, 10.0)
const VIEW_BRAC_FIRMIN := Vector2(18.0, 13.5)
const VIEW_GUARDS := Vector2(21.0, 16.0)
const HIDING_SPOT := Vector2(34.9, 16.8)
## Brac's henchmen: where they stand, and which way they face (the zone places them there);
## the beat they pace « devant les tentes » (tiles, either side of their post).
const GUARD_POSTS := {"SbireCamp1": [Vector2(15.0, 17.0), "down"], "SbireCamp2": [Vector2(27.0, 17.0), "right"]}
const GUARD_BEAT := 1.8
## How far the caged Deinonychus goes each way, inside its cage (px).
const CAGE_STEPS := 12.0
const PACE_SPEED := 50.0
## Brac's way up the rocks of the north (tiles), round his tent.
const BRAC_CLIMB := [Vector2(21.8, 9.6), Vector2(21.8, 4.6)]
const BRAC_CLIMB_SPEED := 140.0
## Brac's champion: the little cage it backs out of, and where it stops (px, from Brac, on his
## side away from Chloé: x is mirrored when she stands on his right).
const CHAMPION_CAGE := Vector2(92.0, -40.0)
const CHAMPION_OUT := Vector2(58.0, 14.0)
## The pack on the rise and the rock block around the camp, when it comes back (tiles).
const PACK_SPOTS := [Vector2(19.5, 2.4), Vector2(23.2, 2.3), Vector2(26.8, 2.4), Vector2(29.6, 2.3), Vector2(34.3, 4.6), Vector2(34.1, 7.4)]
## Where the camera looks for the pack (their heads over the palisade), and for the leader
## leaving by the way out (a little south of them: above the dialogue box).
const VIEW_PACK := Vector2(26.5, 4.8)
const VIEW_EXIT := Vector2(34.5, 15.6)
const AMBER := Color(1.0, 0.85, 0.45, 0.45)
## Brac beaten: pale, red, then a little violet.
const BRAC_TINTS := [Color(1.35, 1.35, 1.3), Color(1.45, 0.62, 0.55), Color(0.95, 0.7, 1.35)]
## Brac's henchmen: [species, level] each.
const SBIRE_TEAMS := {
	1: [[&"dilophosaurus", 14], [&"microraptor", 14]],
	2: [[&"stegosaurus", 14], [&"deinonychus", 15]],
}
const BRAC_TEAM := [[&"deinonychus", 16, "Tenaille"], [&"allosaurus", 17, "Mastoc"]]
const CHAMPION_LEVEL := 16
## The stolen hatchling's own level (Game.STARTER_LEVEL): fed on black amber far from everything,
## it never grew — « un bébé qui a peur ». It fights like a grown one (CHAMPION_LEVEL, the black
## amber), but it looks, and joins Chloé, as the little one it is (DinoSize.growth).
const STOLEN_LEVEL := 5
# Tallest starter (m) that still reads as "a little one" next to the stolen hatchling.
const SMALL_BUDDY_M := 1.3
const UTAH_LEVEL := 18
## Its size, share of an adult Utahraptor (its DinoNpc in the camp: tools/zones/camp_ombre.gd).
const UTAH_SIZE := 1.2
const XP_SBIRE := 40
const XP_BRAC := 70
const XP_UTAH := 80
const XP_PAPERS := 30
## Said in the Utahraptor's battle the first time.
const LONG_LESSON := [
	"L'ambre noir le tient bien plus fort que les autres : sa jauge de Calme est deux fois plus longue.",
	"Ton dino de départ est lié à toi depuis le premier jour : s'il est en tête, il se met entre vous deux, et chaque tentative compte davantage. Chaque cœur de Lien aide aussi.",
]
const PAPERS_AGAIN := [
	"La table de Brac. Des cartes piquées de croix rouges, un trognon de pomme, et le mot de « M. » : « depuis la passerelle des deux arbres géants ».",
	"Chloé relit la liste de Brac : « Le Carnotaurus Rouge, dans le Désert : LE PROCHAIN. » Elle la plie et la range dans sa sacoche.",
	"Les notes d'Hélène sur la meute. Chloé les emporte : elles n'ont rien à faire chez un braconnier.",
]


# ------------------------------------------------------------------ arriving at the camp

## The first time in the camp: palisades, cages, black amber, the pack's leader behind bars,
## and Brac, seen from afar. Chloé hides behind crates; two henchmen guard the way.
## The camera shows what the lines speak of (the camp, the cages, the leader throwing itself at
## its bars, Brac by the fire, the henchmen pacing up and down), then comes back to Chloé.
static func arrival() -> void:
	_quiet_cages()
	_restless_cage()
	if Game.flag(&"camp_arrive"):
		return
	var w = S.world()
	if w == null:
		return
	S.lock(true)
	var chloe: Player = w.player
	var pacing := {}   # henchman -> his pacing up and down (Stage.pace)
	var lantern = S.actor("SbireCamp2")
	if lantern:
		pacing[lantern] = _pace_beat(lantern)
	await S.wait(0.7)
	await S.say([
		GESTES.cue("Derrière le mur, un boyau étroit monte dans la roche, en pente raide. Au bout, sur les hauteurs, une clairière de boue, fermée par une palissade de pieux taillés en pointe.",
			func() -> void: GESTES.look([_px(VIEW_CLEARING)])),
		GESTES.cue("Des tentes rapiécées. Des caisses marquées d'un masque d'os. Un feu qui fume sans flamme. Et des cages. Beaucoup de cages.",
			func() -> void: GESTES.look([_px(VIEW_TENTS)])),
		GESTES.cue("Ça sent la cendre froide, si fort que Chloé en a la gorge qui pique.",
			func() -> void: GESTES.look_back(); Stage.bow(chloe, 0.5)),
	])
	var lead := Game.lead_dino()
	if lead:
		await S.say([GESTES.cue("%s se colle contre Chloé et gronde tout bas, sans quitter les cages des yeux." % lead.nickname,
			func() -> void: _growl_at(w.companion, _px(VIEW_DEINO)))])
	var dilo = S.actor("CageDilophosaurus")
	var loops := {}   # the looping moves of the scene, stopped further on
	await S.say([
		GESTES.cue("Dans les cages, des dinos aux veines violettes. Un Deinonychus tourne en rond sans jamais s'arrêter. Un Dilophosaurus mord ses barreaux, encore et encore. Aucun ne voit Chloé.",
			func() -> void: loops["dilo"] = _bite_bars(dilo); GESTES.look([_px(VIEW_DEINO), _px(VIEW_DILO)], 2.8)),
		GESTES.cue("Dans une caisse ouverte, des pierres noires comme du charbon, veinées de violet, qui luisent faiblement.",
			func() -> void: GESTES.look([_px(VIEW_CRATE)])),
		GESTES.cue("(De l'ambre… noir. C'est ça qu'ils leur font avaler.)",
			func() -> void: GESTES.look_back(); Stage.stop(dilo, loops.get("dilo")), CHLOE),
	])
	var utah = S.actor("Utahraptor")
	await S.say([
		GESTES.cue("BLANG ! Au fond du camp, la plus grande cage tremble sur ses pieux. Un raptor immense se jette contre les barreaux : deux fois la taille d'un Deinonychus, les plumes hérissées, une griffe grande comme une faucille.",
			func() -> void: _blang(utah, chloe, loops)),
		{"who": CHLOE, "text": "(Le chef de la meute… Il est vivant.)"},
	])
	var boss = S.actor("Brac")
	var firmin = S.actor("SbireCamp1")
	await S.say([
		GESTES.cue("Près du feu, un colosse se lève de sa caisse. Une barbe rousse pleine de cendre, un masque d'os relevé sur le front comme une casquette, et une voix à faire trembler les casseroles.",
			func() -> void: _brac_stands(boss)),
		GESTES.cue("HURLE, mon gros ! Hurle tant que tu veux ! Dans trois jours, l'ambre noir aura fait son travail, et tu mangeras dans ma main. Comme les autres.",
			func() -> void: _brac_shouts(boss, utah), BRAC),
		GESTES.cue("Chef ? Et s'il ne veut pas manger dans votre main ?",
			func() -> void: _firmin_comes(firmin, boss), "Un sbire"),
		GESTES.cue("Alors c'est TOI qui iras le nourrir, Firmin. Retourne monter la garde !",
			func() -> void: _firmin_goes(firmin, boss, pacing), BRAC),
		GESTES.cue("Chloé s'accroupit derrière une pile de caisses. Brac ne l'a pas vue. Pas encore.",
			func() -> void: GESTES.look_back(); Stage.stop(utah, loops.get("utah")); _hide(chloe)),
		GESTES.cue("Entre elle et lui, deux sbires font les cent pas devant les tentes.",
			func() -> void: GESTES.look([_px(VIEW_GUARDS)])),
		GESTES.cue("(Brac. C'est lui qui a pris le chef de la meute. Pour l'atteindre, il faudra passer par ses sbires.)",
			func() -> void: GESTES.look_back(), CHLOE),
		GESTES.cue("(Tiens bon, le grand. J'arrive.)",
			func() -> void: Stage.turn_to(chloe, _px(UTAH_SPOT)), CHLOE),
		{"flag": &"camp_arrive"},
	])
	for guard: Node in pacing:
		_back_to_post(guard, pacing[guard])
	Save.save_game()
	S.lock(false)


## A spot of the camp (tiles) in world pixels.
static func _px(tiles: Vector2) -> Vector2:
	return S.at(tiles.x, tiles.y)


## The Deinonychus of the decor's cage goes round and round in it, never stopping (its line says
## so), for as long as it is there (see _free_the_caged): a few steps each way, between its bars.
static func _restless_cage() -> void:
	var deino = S.actor("CageDeinonychus")
	if deino == null or deino.is_queued_for_deletion() or deino.has_meta(&"pacing"):
		return
	var home: Vector2 = deino.global_position
	deino.set_meta(&"pacing", Stage.pace(deino, home + Vector2(-CAGE_STEPS, 0.0), home + Vector2(CAGE_STEPS, 0.0), 24.0))


## The Dilophosaurus bites its bars (in front of it), again and again, until Stage.stop.
static func _bite_bars(dilo: Node) -> Tween:
	if dilo == null or not is_instance_valid(dilo):
		return null
	var bars: Vector2 = (dilo as Node2D).global_position + Vector2(-40.0 if dilo.sprite.flip_h else 40.0, 30.0)
	Stage.cry(dilo)
	return Stage.rage(dilo, bars, 0.35)


## Chloé's dino growls low at something, pressed against her.
static func _growl_at(companion: Node, at_px: Vector2) -> void:
	Stage.turn_to(companion, at_px)
	Stage.cry(companion)
	Stage.tremble(companion, 1.0, 1.2)


## BLANG: the leader throws itself at its bars, and goes on (a loop, stopped when Chloé hides).
static func _blang(utah: Node, chloe: Player, loops: Dictionary) -> void:
	GESTES.look([_px(UTAH_SPOT) + Vector2(-20.0, 50.0)])
	Stage.shake(6.0, 0.4)
	if utah:
		Stage.lunge(utah, chloe.global_position, 1.5)
		loops["utah"] = Stage.rage(utah, chloe.global_position, 0.7)


## Brac gets up from his crate by the fire, his eyes on the big cage.
static func _brac_stands(boss: Node) -> void:
	GESTES.look([_px(VIEW_BRAC)])
	if boss:
		boss.face(_px(UTAH_SPOT))
		Stage.rear(boss, 1.1)


## « HURLE, mon gros ! »: Brac leans at the cage, the leader cries back.
static func _brac_shouts(boss: Node, utah: Node) -> void:
	GESTES.look([_px(VIEW_BRAC_UTAH)])
	if boss:
		Stage.lunge(boss, _px(UTAH_SPOT), 0.5, false)
	Stage.cry(utah)


## Firmin leaves his post to ask his chief.
static func _firmin_comes(firmin: Node, boss: Node) -> void:
	GESTES.look([_px(VIEW_BRAC_FIRMIN)])
	if firmin == null or boss == null:
		return
	await firmin.walk_to(boss.global_position + Vector2(-66.0, 58.0), "", 150.0)
	if is_instance_valid(firmin) and is_instance_valid(boss):
		firmin.face(boss.global_position)
		boss.face(firmin.global_position)


## « Retourne monter la garde ! »: Brac shoos him; Firmin hurries back and paces again.
static func _firmin_goes(firmin: Node, boss: Node, pacing: Dictionary) -> void:
	if firmin == null or boss == null:
		return
	boss.face(firmin.global_position)
	Stage.lunge(boss, firmin.global_position, 0.4, false)
	await GESTES.halt(firmin)
	await S.wait(1.2)
	if not is_instance_valid(firmin):
		return
	await firmin.walk_to(_px(GUARD_POSTS["SbireCamp1"][0]), "", 190.0)
	if is_instance_valid(firmin) and GESTES.in_scene():
		pacing[firmin] = _pace_beat(firmin)


## Chloé slips behind the pile of crates and crouches, facing the camp.
static func _hide(chloe: Player) -> void:
	await GESTES.chloe_walk(_px(HIDING_SPOT))
	chloe.face_towards(_px(VIEW_BRAC))
	if not Stage.pose(chloe, &"accroupi", 1.8):   # crouching behind the crates (Outfits)
		Stage.bow(chloe, 1.8)


## A henchman paces up and down his beat, either side of his post.
static func _pace_beat(guard: Node2D) -> Dictionary:
	var post: Vector2 = _px(GUARD_POSTS[String(guard.name)][0])
	var beat := Vector2(GUARD_BEAT * S.CELL, 0.0)
	return Stage.pace(guard, post - beat, post + beat, PACE_SPEED)


## The scene over, a henchman stops pacing and goes back to his post (where Chloé finds him).
static func _back_to_post(guard: Node, pacing: Dictionary) -> void:
	await GESTES.halt(guard, pacing)
	if is_instance_valid(guard):
		var post: Array = GUARD_POSTS[String(guard.name)]
		await guard.walk_to(_px(post[0]), post[1], 120.0)


# ------------------------------------------------------------------ the henchmen

## Talking to henchman `n` (1: Firmin, Gustave's cousin; 2: the one with the lantern, who
## knows things about the Masque): a few words, then a battle.
static func sbire(n: int, who: Node) -> void:
	var beaten := StringName("sbire_camp_%d_battu" % n)
	if Game.flag(beaten):
		return
	var seen := StringName("sbire_camp_%d_vu" % n)
	var speaker := FIRMIN if n == 1 else LANTERNE
	await GESTES.halt(who)   # (still on his way back to his post)
	if not Game.flag(seen):
		await S.say(_sbire_hello(n, who))
		Game.set_flag(seen)
	else:
		await S.say([{"who": speaker, "text": "Encore toi ?! Tu ne veux pas plutôt aller pêcher des sardines avec Gustave ?" if n == 1
			else "Toujours là ? Ma soupe, elle, n'est plus chaude. Finissons-en."}])
	if not await S.duel(speaker, SBIRE_TEAMS[n], {"lose_spawn": CAMP_SPAWN}):
		return
	S.lock(true)
	await S.say(_sbire_beaten(n, who) + [{"flag": beaten}])
	if n == 1:
		await S.say([GESTES.cue("Firmin file vers la sortie du camp, sans vérifier la moindre cage.",
			func() -> void: _leave(who, CAMP_EXIT, 200.0))])
		await GESTES.until_gone(who)
	else:
		await _leave(who, CAMP_EXIT, 200.0)
	if _next_guard() == 0:
		await S.say([{"who": CHLOE, "text": "(Plus personne entre Brac et moi.)"}])
	if _party_worn():
		await S.say([{"who": CHLOE, "text": "(Mon équipe est fatiguée… Le feu des sbires est encore chaud : on pourrait s'y reposer un peu avant la suite.)"}])
	Game.award_team_xp(XP_SBIRE)
	Save.save_game()
	S.lock(false)


static func _sbire_hello(n: int, who: Node) -> Array:
	if n == 1:
		return [
			{"who": FIRMIN, "text": "Halte-là ! On ne passe pas ! … Enfin, si, on passe. Mais après, on reste. Dans une cage."},
			{"who": FIRMIN, "text": "Attends… T'es pas la gamine de la grotte ? Celle qui a fait démissionner Gustave ?"},
			{"who": CHLOE, "text": "Il avait l'air content de retourner pêcher."},
			{"who": FIRMIN, "text": "Content ?! C'est mon cousin ! Il m'envoie des cartes postales : « Soleil, sardines, bisous. » Moi, j'ai de la boue jusqu'aux genoux, et un Dilophosaurus qui me crache dessus tous les matins !"},
			{"who": FIRMIN, "text": "Tu vas me le payer. Pour Gustave. Et pour les sardines."},
		]
	return [
		GESTES.cue("Le sbire à la lanterne ne crie pas. Il astique sa lanterne, sans même lever les yeux.",
			func() -> void: _polishes(who)),
		GESTES.cue("Tu es venue pour le grand raptor. Ils viennent tous pour lui. Personne ne repart avec.",
			func() -> void: _looks_up(who), LANTERNE),
		{"who": LANTERNE, "text": "Brac dit que dans trois jours, il obéira. Brac dit beaucoup de choses."},
		{"who": LANTERNE, "text": "Bon. Finissons-en, petite. Il fait froid, et ma soupe refroidit."},
	]


## The henchman with the lantern polishes it, his eyes down, not looking at Chloé.
static func _polishes(who: Node) -> void:
	if who == null or not is_instance_valid(who):
		return
	who.face((who as Node2D).global_position + Vector2(0.0, 60.0))
	await Stage.bow(who, 0.5)
	Stage.tremble(who, 2.4, 1.2)


static func _looks_up(who: Node) -> void:
	var chloe := Stage.chloe()
	if who and is_instance_valid(who) and chloe:
		who.face(chloe.global_position)


static func _sbire_beaten(n: int, who: Node) -> Array:
	if n == 1:
		return [
			{"who": FIRMIN, "text": "Bon. Bon, bon, bon. Très bien. Je vais… vérifier les cages. Celles du fond. Très au fond."},
			{"who": FIRMIN, "text": "Et si tu croises Gustave, dis-lui que je le déteste. Et qu'il m'envoie une sardine."},
		]
	var lines: Array = [
		{"who": LANTERNE, "text": "… Tu es forte, pour une petite. Alors écoute un conseil gratuit : rentre chez toi."},
		{"who": CHLOE, "text": "Pas sans le chef de la meute."},
		{"who": LANTERNE, "text": "Brac, ça va encore. Brac crie. Mais le Masque… Lui, il ne crie jamais."},
		{"who": LANTERNE, "text": "Il arrive la nuit, par la mer, sans lanterne. Personne n'a jamais vu son visage. Et il sait tout : où tu dors, ce que tu cherches… qui t'a amenée sur l'île."},
		{"who": CHLOE, "text": "Et vous travaillez pour lui quand même ?"},
		{"who": LANTERNE, "text": "Il paie. Au port, plus personne ne paie."},
		{"who": LANTERNE, "text": "Et ses bottes sont toujours pleines de cendre. Il revient des forges, là-haut, sur le volcan. C'est là qu'on fabrique… ça."},
		GESTES.cue("Du menton, il montre une caisse ouverte. Les pierres noires luisent dans la boue.",
			func() -> void: _points_at_crate(who)),
	]
	if Game.flag(&"maia_defi_1") and Game.flag(&"roc_nuit_niee"):
		lines.append_array([
			GESTES.cue("(Des bottes pleines de cendre… La mère de Maïa rentre comme ça, le soir. Et Roc avait de la cendre sur ses chaussures, le matin où il a tout nié.)",
				func() -> void: GESTES.look_back(), CHLOE),
			{"who": CHLOE, "text": "(Non. Plein de gens marchent dans la cendre, sur cette île… Non ?)"},
		])
	else:
		lines.append(GESTES.cue("(La cendre… Elle vient des forges du volcan.)", func() -> void: GESTES.look_back(), CHLOE))
	lines.append({"who": LANTERNE, "text": "Je vais me chercher un autre travail. Un travail où personne ne porte de masque."})
	return lines


## « Du menton, il montre une caisse ouverte »: he turns to the nearest crate of black amber
## and juts his chin at it; the camera goes to see it.
static func _points_at_crate(who: Node) -> void:
	if who == null or not is_instance_valid(who):
		return
	var crate := _nearest_crate((who as Node2D).global_position)
	if crate == Vector2.INF:
		return
	who.face(crate)
	GESTES.lean(who, crate, 8.0, 0.7)
	GESTES.look([(who as Node2D).global_position.lerp(crate, 0.2)])   # (him low, the crate high)


## Where the nearest crate of black amber is (world px), Vector2.INF when there is none.
static func _nearest_crate(from_px: Vector2) -> Vector2:
	var best := Vector2.INF
	var w = S.world()
	if w == null or w.get("region") == null:
		return best
	for n in w.region.entities.get_children():
		if n is Prop and String(n.get("kind")) in ["caisse_ambre_noir", "caisses"]:
			var at: Vector2 = (n as Node2D).global_position
			if best == Vector2.INF or at.distance_to(from_px) < best.distance_to(from_px):
				best = at
	return best


## Half the party's strength or less is left: time to rest by the fire.
static func _party_worn() -> bool:
	var hp := 0
	var full := 0
	for d: Dino in Game.party:
		hp += d.hp
		full += d.max_hp()
	return full > 0 and hp * 2 <= full


## The first henchman still standing (0: none).
static func _next_guard() -> int:
	for n: int in [1, 2]:
		if not Game.flag(StringName("sbire_camp_%d_battu" % n)):
			return n
	return 0


# ------------------------------------------------------------------ Brac

## Talking to Brac: he sends his henchmen first; then the battle (Tenaille, Mastoc, and his
## champion: the stolen hatchling, which Chloé calms). He flees, swearing, towards the Désert.
static func brac(who: Node) -> void:
	if Game.flag(&"brac_battu"):
		return
	var guard := _next_guard()
	if guard != 0:
		await _call_guard(guard, who)
		return
	if not Game.flag(&"brac_parle"):
		S.lock(true)
		await S.say(_brac_hello(who))
		Game.set_flag(&"brac_parle")
		S.lock(false)
	else:
		await S.say([{"who": BRAC, "text": "Encore toi, moucheron ? T'as pas eu ton compte ? Viens donc, que je te montre encore une fois."}])
	var rules := {"lose_spawn": CAMP_SPAWN}
	var theme: AudioStream = music_at(OMBRE_MUSIC)
	if theme:
		rules["music"] = theme
	if not await S.duel(BRAC, _brac_team(), rules):
		var champion = S.actor("Champion")   # (brought out for the battle: back in its cage)
		if champion:
			champion.queue_free()
		return
	await _brac_beaten(who)


## Brac shouts for the next henchman, who comes to Chloé and fights.
static func _call_guard(guard: int, boss: Node) -> void:
	var w = S.world()
	var g = S.actor("SbireCamp%d" % guard)
	await S.say([GESTES.cue("HÉ ! Qui a laissé entrer une gamine dans mon camp ?! FIRMIN ! Occupe-toi d'elle !" if guard == 1
		else "LA LANTERNE ! Au travail ! Et pose ta soupe !", func() -> void: _shouts_at(boss, g), BRAC)])
	if g == null or w == null:
		return
	await GESTES.halt(g)
	await g.walk_to(w.player.global_position + Vector2(-70.0, 10.0), "right", 190.0)
	await sbire(guard, g)


## Brac bellows at his henchman: he turns to him and leans his whole bulk his way.
static func _shouts_at(boss: Node, guard: Node) -> void:
	if boss == null or guard == null or not is_instance_valid(guard):
		return
	boss.face((guard as Node2D).global_position)
	Stage.rear(boss, 0.7)
	Stage.lunge(boss, (guard as Node2D).global_position, 0.5, false)


static func _brac_hello(who: Node) -> Array:
	var lines: Array = [
		GESTES.cue("Brac se retourne. Il regarde Chloé de haut en bas. Ça prend un moment : il y a beaucoup de haut.",
			func() -> void: _sizes_her_up(who)),
		{"who": BRAC, "text": "Tiens, tiens. Une gamine dans mon camp. Et mes deux andouilles qui détalent comme des lapins."},
		{"who": BRAC, "text": "Tu sais qui je suis, moucheron ? Brac. Chasseur d'Alphas. Le Tricératops des Plaines, j'aurais dû m'en occuper avant toi. Pas grave : j'ai eu mieux."},
		{"who": CHLOE, "text": "Relâchez le chef de la meute. Et tous les autres."},
		{"who": BRAC, "text": "Le relâcher ? Il m'a coûté trois pièges, deux filets et un sbire, qui court encore. Sans compter le vieux raptor gris du ravin, qui m'a arraché mon meilleur piège."},
	]
	if Game.flag(&"griffe_grise_vu"):
		lines.append({"who": CHLOE, "text": "(Le piège de Griffe-Grise… C'était lui.)"})
	lines.append_array([
		{"who": BRAC, "text": "Non, non. Dans trois jours, il obéira. L'ambre noir, ça dresse n'importe quoi."},
		{"who": CHLOE, "text": "Il n'obéira pas. Il aura juste peur de vous."},
		{"who": BRAC, "text": "C'est pareil, gamine. C'est exactement pareil."},
		GESTES.cue("Il rabat son masque d'os sur son visage, d'un coup de pouce.",
			func() -> void: Stage.bow(who, 0.45)),
		{"who": BRAC, "text": "Allez. Je vais te montrer ce que valent les dinos de Brac."},
	])
	return lines


## Brac turns round, and looks Chloé over from his full height down to her boots.
static func _sizes_her_up(who: Node) -> void:
	var chloe := Stage.chloe()
	if who == null or not is_instance_valid(who) or chloe == null:
		return
	who.face((who as Node2D).global_position + Vector2(0.0, -60.0))
	await S.wait(0.35)
	who.face(chloe.global_position)
	await Stage.rear(who, 0.9)
	Stage.bow(who, 1.3)


## Tenaille, Mastoc, then the champion: the stolen hatchling, corrupted (it is calmed, not beaten).
static func _brac_team() -> Array:
	var id := stolen_species()
	var name := stolen_name()
	var champion := [id, CHAMPION_LEVEL, name, {
		"corrupted": true, "size": DinoSize.growth(SpeciesDB.get_species(id), STOLEN_LEVEL),
		"before": _champion_before(),
		"intro": "Brac envoie son champion : %s, fou de peur !" % name,
		"lesson": [
			"%s est corrompu : il ne tombera pas, et on ne capture pas un dino qui a peur." % name,
			"Choisis « Apaiser ». Il a grandi dans la peur : il lui faudra du temps pour t'écouter, et chaque coup l'en éloigne.",
		],
	}]
	return BRAC_TEAM + [champion]


## Before the champion comes out (in the world, between two battles): it backs out of a little
## cage by Brac, shaking all over.
static func _champion_before() -> Array:
	var name := stolen_name()
	var species: String = SpeciesDB.get_species(stolen_species()).display_name
	return [
		{"who": BRAC, "text": "Pas mal, moucheron. Pas mal du tout. Mais tu n'as pas encore vu mon champion."},
		GESTES.cue("Brac siffle entre ses doigts. Au fond d'une petite cage, quelque chose gémit, puis sort à reculons, en tremblant de toutes ses pattes.",
			func() -> void: _champion_comes_out()),
		GESTES.cue("Un jeune %s. Sous sa peau, des veines violettes. Et dans ses yeux, rien. Rien que de la peur." % species,
			func() -> void: Stage.tremble(S.actor("Champion"), 3.0, 1.6)),
		GESTES.cue("(Ce petit… Je le connais. C'est %s ! Le troisième petit du Cabinet !)" % name,
			func() -> void: Stage.emote(Stage.chloe(), "!"), CHLOE),
		{"who": BRAC, "text": "Un cadeau du Masque. Pris dans ton propre Cabinet, la nuit même où il est sorti de sa coquille. Nourri à l'ambre noir depuis le premier jour."},
		{"who": BRAC, "text": "Il n'a jamais rien connu d'autre. Le parfait petit soldat."},
		{"who": CHLOE, "text": "Ce n'est pas un soldat. C'est un bébé qui a peur."},
		{"who": CHLOE, "text": "(« Rester plus longtemps que leur peur. » D'accord, Hélène.)" if Game.flag(&"found_journal_10")
			else "(Je ne vais pas le combattre. Je vais l'apaiser.)"},
	]


## Brac whistles; the champion whimpers, then backs out of its little cage behind him, trembling.
static func _champion_comes_out() -> void:
	var boss = S.actor("Brac")
	if boss == null or S.actor("Champion"):
		return
	var at: Vector2 = boss.global_position
	var chloe := Stage.chloe()
	var side := Vector2(-1.0, 1.0) if chloe and chloe.global_position.x > at.x + 8.0 else Vector2.ONE
	var little: DinoNpc = _spawn_little(stolen_species(), at + CHAMPION_CAGE * side, true)
	if little == null:
		return
	little.modulate.a = 0.0
	await S.wait(0.5)
	if not is_instance_valid(little):
		return
	little.cry(&"degat")
	Stage.fade_in(little, 0.5)
	await GESTES.back_away(little, at + CHAMPION_OUT * side, 1.8)
	Stage.tremble(little, 2.0, 1.6)


## Brac beaten, his champion calmed: the little one remembers the Cabinet and comes to Chloé;
## Brac flees over the rocks (he will be back in the Désert), leaving his keys behind.
static func _brac_beaten(who: Node) -> void:
	var w = S.world()
	if w == null:
		return
	S.lock(true)
	var chloe: Player = w.player
	var name := stolen_name()
	var species: String = SpeciesDB.get_species(stolen_species()).display_name
	var little = S.actor("Champion")   # out of its cage for the battle
	if little == null:
		var from: Vector2 = chloe.global_position + Vector2(0.0, -70.0)
		if is_instance_valid(who):
			from = chloe.global_position.lerp(who.global_position, 0.5)
		little = _spawn_little(stolen_species(), from)
	await S.say([
		GESTES.cue("Non… Non, non, NON ! Qu'est-ce que tu lui as fait ?! Il avait peur de TOUT ! Il était PARFAIT !",
			func() -> void: Stage.hop(who, 2, 7.0), BRAC),
		GESTES.cue("Le jeune %s cligne des yeux, longtemps, comme s'il se réveillait d'un très mauvais rêve. Les veines violettes ont disparu." % species,
			func() -> void: _wakes_up(little)),
		GESTES.cue("Il regarde Brac, et recule d'un pas. Puis il se tourne vers Chloé et renifle l'air : ses mains, sa sacoche, ses chaussures…",
			func() -> void: _shies_then_sniffs(little, who, chloe)),
		{"text": "L'odeur de la couveuse tiède, de l'ambre et du vieux papier. L'odeur du Cabinet. Le seul endroit au monde où il n'a jamais eu peur."},
	])
	if is_instance_valid(little):
		await GESTES.halt(little)
		await little.walk_to(GESTES.beside_chloe(little, 1.0, 14.0, 40.0), 90.0)
	var lines: Array = []
	var mine: Dino = Foret.starter()
	var buddy: Node2D = null   # her own hatchling, sniffing the little one
	if mine and Game.party.has(mine):
		buddy = w.companion if Game.lead_dino() == mine else GESTES.stand_in(mine)
		# A grown starter towers over the stolen little one: it bends down to meet it.
		var small := DinoSize.height_m(mine.species(), DinoSize.world_scale(mine)) <= SMALL_BUDDY_M
		var meet := "%s s'avance, et les deux petits se reniflent le bout du museau." if small \
			else "%s s'avance et baisse la tête jusqu'au petit : ils se reniflent le bout du museau."
		lines.append(GESTES.cue((meet % mine.nickname) + " Le jour de leur éclosion, ils dormaient côte à côte, sur les socles du Cabinet. Ils s'en souviennent.",
			func() -> void: _noses(buddy, little)))
	lines.append({"who": CHLOE, "text": "%s. C'est ton nom, tu sais. Tu l'avais avant qu'on te prenne." % name})
	await S.say(lines)
	if is_instance_valid(who):
		who.face(chloe.global_position)
	await S.say([
		GESTES.cue("Brac devient blême. Puis tout rouge. Puis un peu violet, lui aussi.",
			func() -> void: GESTES.colours(who, BRAC_TINTS, 0.9)),
		GESTES.cue("Crotte de Stégosaure ! Nom d'un fossile moisi ! Le Masque va… Le Masque va me…",
			func() -> void: Stage.hop(who, 3, 6.0), BRAC),
		GESTES.cue("Il s'arrête, avale sa salive, et jette un coup d'œil par-dessus son épaule. Comme si quelqu'un pouvait l'entendre.",
			func() -> void: _over_his_shoulder(who, chloe)),
		{"who": BRAC, "text": "Ce n'est pas fini, moucheron ! Le Désert est grand, et là-bas, j'ai des amis. Des amis avec des DENTS !"},
	])
	await S.say([
		GESTES.cue("Il escalade les rochers du fond avec une agilité étonnante pour un homme de sa taille, et disparaît dans les fougères. On l'entend jurer longtemps, de plus en plus loin.",
			func() -> void: _brac_climbs(who)),
		GESTES.cue("Dans la boue, là où il se tenait, il a laissé tomber un gros trousseau de clés.",
			func() -> void: GESTES.look_back(); Audio.play_sfx(LATCH, -10.0); Stage.emote(chloe, "!")),
		{"who": CHLOE, "text": "(Les clés des cages.)"},
		{"flag": &"brac_battu"},
	])
	await GESTES.until_gone(who, 3.0)
	await _little_joins(little)
	if buddy is DinoNpc:
		await GESTES.stand_in_back(buddy)
	Game.award_team_xp(XP_BRAC)
	Save.save_game()
	S.lock(false)


## Brac climbs the rocks at the back of the camp and is gone in the ferns (the camera follows).
static func _brac_climbs(who: Node) -> void:
	GESTES.look([_px(Vector2(21.5, 9.0)), _px(Vector2(21.0, 5.2))], 1.4)
	_leave(who, BRAC_FLIGHT, BRAC_CLIMB_SPEED, BRAC_CLIMB)


## The champion wakes from the black amber (its veins go, a flash of its own colours).
static func _wakes_up(little: Node) -> void:
	if little == null or not is_instance_valid(little):
		return
	if (little as DinoNpc).corrupted:
		await little.cleanse()
	else:
		await Stage.glow(little, Color(2.2, 2.2, 2.2), 1, 0.8)
	Stage.emote(little, "…")


## It looks at Brac and steps back; then turns to Chloé and sniffs: her hands, her bag, her shoes.
static func _shies_then_sniffs(little: Node, boss: Node, chloe: Player) -> void:
	if little == null or not is_instance_valid(little):
		return
	if boss and is_instance_valid(boss):
		Stage.turn_to(little, boss.global_position)
		await S.wait(0.5)
		await Stage.recoil(little, boss.global_position, 18.0)
	await S.wait(0.7)
	if not is_instance_valid(little):
		return
	Stage.turn_to(little, chloe.global_position)
	for i in 3:
		await GESTES.lean(little, chloe.global_position, 7.0, 0.6)


## Two little ones sniffing each other's snouts.
static func _noses(a: Node2D, b: Node) -> void:
	if a == null or b == null or not is_instance_valid(a) or not is_instance_valid(b):
		return
	Stage.turn_to(a, (b as Node2D).global_position)
	Stage.turn_to(b, a.global_position)
	GESTES.lean(a, (b as Node2D).global_position, 10.0, 1.4)
	await GESTES.lean(b, a.global_position, 10.0, 1.4)
	Stage.emote(b as Node2D, "♥")


## He glances over his shoulder, as if someone could hear him (the Masque), then back at her.
static func _over_his_shoulder(who: Node, chloe: Player) -> void:
	if who == null or not is_instance_valid(who):
		return
	Stage.bow(who, 0.4)
	await S.wait(0.6)
	who.face((who as Node2D).global_position + Vector2(0.0, -60.0))
	await S.wait(1.2)
	if is_instance_valid(who):
		who.face(chloe.global_position)


## The first great calming: the stolen hatchling joins Chloé (a place is made in the party if
## she wants it; else it waits at the Cabinet, by the incubator).
static func _little_joins(little: Node) -> void:
	var id := stolen_species()
	var d := Dino.create(id, STOLEN_LEVEL, stolen_name())
	Game.set_flag(&"oeuf_vole_apaise")
	Toast.say(S.world().get_tree(), "Premier grand apaisement !")
	var in_party := await make_room_for(d, "%s veut rester avec toi. Mais ton équipe est pleine : qui part attendre au Cabinet ?" % d.nickname)
	Game.add_bond(d, 1)
	var lines: Array = [GESTES.cue("%s rejoint ton équipe ! Il tremble encore un peu. Mais plus de peur." % d.nickname if in_party
		else "%s part attendre au Cabinet, au chaud contre la couveuse." % d.nickname,
		func() -> void: _joins(little, in_party))]
	if id == &"velociraptor" and Game.flag(&"griffe_grise_vu"):
		lines.append({"who": CHLOE, "text": "(Un œuf de Velociraptor, laissé par Hélène… Griffe-Grise saura peut-être d'où il vient.)"})
	lines.append(GESTES.cue("(Et maintenant, le chef de la meute.)",
		func() -> void: Stage.turn_to(Stage.chloe(), _px(UTAH_SPOT)), CHLOE))
	await S.say(lines)


## The little one with Chloé now: it trembles a little, then goes to her side and its picture
## fades (it is in her party; to the Cabinet: it goes off towards the way out).
static func _joins(little: Node, in_party: bool) -> void:
	if little == null or not is_instance_valid(little):
		return
	var chloe := Stage.chloe()
	if in_party:
		await Stage.tremble(little, 1.0, 1.0)
		if is_instance_valid(little) and chloe:
			await little.walk_to(GESTES.beside_chloe(little, 1.0, 6.0), 80.0)
	else:
		little.walk_to(_px(CAMP_EXIT), 110.0)
	await Stage.fade_out(little, 0.6, true)


## Adds `d` to the party; when it is full, Chloé may pick who waits at the Cabinet instead
## (or let `d` go there). True if `d` is in the party.
static func make_room_for(d: Dino, question: String) -> bool:
	if Game.party.size() < Game.PARTY_MAX:
		return Game.add_caught(d)
	var options: Array = Game.party.map(func(p: Dino) -> String: return "%s (niv. %d)" % [p.nickname, p.level])
	options.append("Personne : %s ira au Cabinet" % d.nickname)
	var pick := await Dialogue.choose("", question, options)
	if pick < 0 or pick >= Game.party.size():
		return Game.add_caught(d)
	Game.mark_caught(d.species().id)
	var leaving: Dino = Game.party[pick]
	Game.party[pick] = d
	Game.box.append(leaving)
	Game.party_changed.emit()
	await S.say([{"text": "%s part attendre au Cabinet. Roc s'occupera de lui." % leaving.nickname}])
	return true


# ------------------------------------------------------------------ the pack's leader

## The Utahraptor in its cage: Brac first; then Chloé opens it, and calms the leader at length,
## with her own hatchling's help (a "long_calm" battle). He gives her the Sceau de la Forêt.
static func utahraptor(who: Node) -> void:
	if Game.flag(&"sceau_foret"):
		return
	var chloe := Stage.chloe()
	var at_chloe: Vector2 = chloe.global_position if chloe else _px(UTAH_SPOT) + Vector2(0.0, 60.0)
	if not Game.flag(&"brac_battu"):
		Stage.lunge(who, at_chloe, 1.0)
		await S.say([
			{"text": "Le grand raptor se jette contre les barreaux. Ses yeux ne voient rien : ils sont troubles, violets, pleins de peur."},
			{"who": BRAC, "text": "HÉ ! Pas touche à mon Alpha, moucheron !"},
		])
		var boss = S.actor("Brac")
		if boss:
			await brac(boss)
		return
	var opened: bool = Game.flag(&"cage_ouverte")
	var rage := Stage.rage(who, at_chloe)   # it throws itself at the stakes, again and again, all along
	GESTES.companion_to_side(Vector2(-48.0, 4.0))   # her dino at her side, before the giant's head
	if not opened:
		S.lock(true)
		Stage.lunge(who, at_chloe, 1.0)
		await Stage.recoil(chloe, (who as Node2D).global_position)   # Chloé, startled, steps back
		await S.say([
			{"text": "Le chef de la meute. De près, il est encore plus grand. Ses plumes gris-bleu sont ébouriffées, pleines de boue, et sous sa peau, des veines violettes pulsent comme un second cœur."},
			{"text": "Il ne voit plus Chloé. Il ne voit plus rien. Il se jette contre les barreaux, recule, recommence."},
			{"who": CHLOE, "text": "On ne peut pas le combattre. Il faut rester plus longtemps que sa peur." if Game.flag(&"found_journal_10")
				else "Pas de collier, pas de force. Il faut le calmer… même si ça prend longtemps."},
		])
		S.lock(false)
	var prompt := "La cage est fermée par un gros cadenas. Une des clés de Brac devrait l'ouvrir." if not opened \
		else "La cage est ouverte, mais le Chef de Meute tourne en rond à l'intérieur, fou de peur."
	var pick := await Dialogue.choose("", prompt, ["Ouvrir la cage" if not opened else "L'approcher doucement", "Pas encore"])
	if pick != 0:
		Stage.stop(who, rage)
		return
	await _starter_first(who)   # her hatchling steps up to the stakes, faces the giant
	if not opened:
		S.lock(true)
		await S.say([GESTES.cue("Chloé essaie les clés une à une. La cinquième tourne. La chaîne tombe dans la boue, et la porte s'ouvre en grinçant…",
			func() -> void: _tries_the_keys(chloe, who))])
		Game.set_flag(&"cage_ouverte")
		S.lock(false)
	Stage.stop(who, rage)
	await Stage.lunge(who, at_chloe, 2.2)   # out of the cage, at them
	Stage.shake(7.0, 0.5)
	var foe := Dino.create(&"utahraptor", UTAH_LEVEL, "Chef de Meute")
	foe.corrupted = true
	var rules := {"catch": false, "run": false, "long_calm": true, "lose_spawn": CAMP_SPAWN, "size": UTAH_SIZE,
		"intro": "Le Chef de Meute jaillit de sa cage, fou de rage et de peur !"}
	if not Game.flag(&"utah_lecon"):
		rules["lesson"] = LONG_LESSON
	var theme: AudioStream = music_at(ALPHA_MUSIC)
	if theme:
		rules["music"] = theme
	var result: String = await S.world().call(&"_battle", foe, rules)
	Game.set_flag(&"utah_lecon")
	if result != "calmed":
		return
	await _leader_calmed(who)


## Chloé tries Brac's keys at the padlock, one after the other, until the fifth turns.
static func _tries_the_keys(chloe: Player, cage: Node) -> void:
	if chloe == null or cage == null:
		return
	for i in 3:
		GESTES.lean(chloe, (cage as Node2D).global_position, 5.0, 0.5)
		await S.wait(0.55)
	Audio.play_sfx(LATCH, -2.0)


## Before the long calming: her own hatchling at the front (if it is not already); it steps up
## to the stakes and faces the giant (with its line, when it is her hatchling).
static func _starter_first(cage: Node) -> void:
	var at: Vector2 = (cage as Node2D).global_position if is_instance_valid(cage) else _px(UTAH_SPOT)
	var mine: Dino = Foret.starter()
	if mine and not Game.party.has(mine):
		await S.say([{"who": CHLOE, "text": "(Si seulement %s était là… Hélène disait que c'est le Lien qui calme les plus grandes peurs.)" % mine.nickname}])
	elif mine and Game.party[0] != mine:
		var pick := await Dialogue.choose("", "%s est lié à toi depuis le premier jour. Avec lui en tête, le Chef de Meute l'écoutera peut-être." % mine.nickname,
			["%s, avec moi !" % mine.nickname, "Garder mon équipe"])
		if pick == 0:
			Game.set_lead(Game.party.find(mine))
	if mine and Game.lead_dino() == mine:
		await S.say([GESTES.cue("%s passe devant Chloé. Tout petit, face au géant. Il ne recule pas." % mine.nickname,
			func() -> void: Stage.companion_to(at))])
		return
	await Stage.companion_to(at)


## Calmed: the veins fade, the Sceau de la Forêt, the pack comes back for its leader, the
## other cages are opened; he growls towards the high forest before leaving (the Masque).
static func _leader_calmed(who: Node) -> void:
	var w = S.world()
	if w == null:
		return
	S.lock(true)
	var chloe: Player = w.player
	if is_instance_valid(who):
		await who.cleanse()
	await S.say([
		GESTES.cue("Les veines violettes pâlissent, puis s'effacent, une à une. Le grand raptor chancelle et se couche dans la boue, épuisé.",
			func() -> void: await Stage.tremble(who, 0.8, 2.2); GESTES.lie_down(who, 0.9)),
		GESTES.cue("Quand il rouvre les yeux, ils sont dorés. Il regarde les cages, les caisses, le feu éteint, comme s'il sortait d'un très long cauchemar.",
			func() -> void: GESTES.look_around(who, [_px(VIEW_DEINO), _px(Vector2(34.0, 12.0)), _px(Vector2(21.0, 14.8))], 1.2)),
	])
	await S.say(_helper_lines(who, chloe))
	await S.say([
		GESTES.cue("Il se relève de toute sa hauteur. Sous les plumes de son cou pend un collier de lianes tressées, et au bout, un disque d'ambre gravé d'une petite fougère.",
			func() -> void: Stage.turn_to(who, chloe.global_position); Stage.rear(who, 1.4)),
		{"who": CHLOE, "text": "La fougère d'Hélène…"},
		GESTES.cue("Brac ne l'avait même pas remarqué. Le Chef de Meute baisse la tête jusqu'à Chloé, et attend.",
			func() -> void: Stage.bow(who, 2.6)),
		GESTES.cue("Chloé dénoue les lianes. Le disque est tiède, comme une pierre restée au soleil.",
			func() -> void: GESTES.lean(chloe, (who as Node2D).global_position, 6.0, 1.4)),
		GESTES.cue("Chloé reçoit le Sceau de la Forêt !",
			func() -> void: Stage.glow(chloe, Color(1.8, 1.45, 0.8), 2); Stage.flash(AMBER, 0.9)),
		{"flag": &"sceau_foret"},
	])
	if ItemsDB.ITEMS.has("sceau_foret"):
		Game.give_item("sceau_foret")
	Toast.say(w.get_tree(), "Objet obtenu : le Sceau de la Forêt")
	var pack := _the_pack()
	await _pack_cries()
	Stage.shake(3.0, 0.4)
	await S.say([
		GESTES.cue("Alors, tout autour du camp, des cris. Des dizaines. Au-dessus des palissades et des rochers, des têtes apparaissent : une, deux, dix… La meute !",
			func() -> void: _pack_appears(pack)),
		GESTES.cue("Le Chef de Meute lève le museau et pousse un cri immense, qui fait trembler les cages. Et cette fois, quelqu'un commande.",
			func() -> void: _leader_roars(who)),
	])
	if Game.flag(&"griffe_grise_vu"):
		await S.wait(0.5)
		Foret.raptor_cry("neutre", -12.0, Foret.OLD_PITCH)
		await S.say([GESTES.cue("Et très loin, tout au fond de la Forêt, un cri grave et lent leur répond. Griffe-Grise.",
			func() -> void: _all_turn(pack + [who], _px(Vector2(30.0, 30.0))))])
	await S.say([
		GESTES.cue("Avec le trousseau de Brac, Chloé ouvre les autres cages. Les dinos aux veines violettes sortent en titubant ; la meute les entoure, les renifle, et les pousse doucement vers la forêt.",
			func() -> void: _free_the_caged()),
		GESTES.cue("(Loin de l'ambre noir, leurs veines finiront par pâlir. Comme celles du Stegosaurus d'Hélène.)" if Game.flag(&"found_journal_9")
			else "(Loin de l'ambre noir, leurs veines finiront par pâlir. Il faudra du temps. Maintenant, ils en ont.)",
			func() -> void: GESTES.look_back(), CHLOE),
		{"flag": &"cages_ouvertes"},
	])
	if is_instance_valid(who):
		GESTES.look([_px(VIEW_EXIT)])
		await who.walk_to(S.at(CAMP_EXIT.x - 2.0, CAMP_EXIT.y), 170.0)
	await S.say([
		GESTES.cue("Au moment de quitter le camp, le Chef de Meute s'arrête. Il se retourne vers le sud-est, les plumes hérissées, et gronde longuement vers les arbres géants de la haute futaie.",
			func() -> void: _growls_south_east(who)),
		GESTES.cue("Puis il bondit dans le tunnel, et la meute le suit.",
			func() -> void: _leave(who, CAMP_EXIT + Vector2(3.0, 0.0), 260.0); _pack_follows(pack)),
	])
	await GESTES.until_gone(who, 4.0)
	_quiet_cages(false)
	await S.say([GESTES.cue("(« Depuis la passerelle des deux arbres géants », disait le mot de M. Là-bas, sur la haute futaie…)" if Game.flag(&"papiers_brac_lus")
		else "(Il a senti quelque chose, là-bas, vers la haute futaie. Ou quelqu'un.)", func() -> void: GESTES.look_back(), CHLOE)])
	Game.award_team_xp(XP_UTAH)
	Save.save_game()
	S.lock(false)


## What the leader does with the dino that stood between them (her own hatchling, when it led):
## still lying in the mud, it sniffs it, and Chloé.
static func _helper_lines(leader: Node, chloe: Player) -> Array:
	var mine: Dino = Foret.starter()
	var lead := Game.lead_dino()
	var companion: Node2D = S.world().companion
	var lines: Array = []
	if mine and lead == mine:
		lines.append(GESTES.cue("%s ne l'a pas quitté des yeux une seule seconde. Le Chef de Meute baisse la tête jusqu'à lui et souffle doucement sur son museau." % mine.nickname,
			func() -> void: Stage.turn_to(companion, (leader as Node2D).global_position); GESTES.lean(leader, companion.global_position, 12.0, 1.8)))
		if Foret.vif_dino() == mine:
			lines.append(GESTES.cue("Il le renifle longuement. Il connaît cette odeur : celle du vieux raptor du ravin, que toute la meute respecte.",
				func() -> void: _sniffs(leader, companion.global_position, 2)))
			if Game.flag(&"griffe_grise_vu"):
				lines.append({"who": CHLOE, "text": "Oui. C'est le petit de Griffe-Grise. Ça se sent, hein ?"})
		Game.add_bond(mine, 1)
		lines.append(GESTES.cue("Entre Chloé et %s, quelque chose s'est resserré. Plus solide qu'avant." % mine.nickname,
			func() -> void: Stage.emote(companion, "♥"); Stage.companion_joy()))
	elif lead:
		lines.append(GESTES.cue("Le Chef de Meute renifle %s, puis Chloé. Il ne gronde plus." % lead.nickname,
			func() -> void: await GESTES.lean(leader, companion.global_position, 12.0, 1.2); GESTES.lean(leader, chloe.global_position, 12.0, 1.2)))
	else:
		lines.append(GESTES.cue("Le Chef de Meute renifle Chloé. Il ne gronde plus.",
			func() -> void: _sniffs(leader, chloe.global_position, 2)))
	return lines


## Sniffs at something, `times` times (a lean and back, each). Awaitable.
static func _sniffs(actor: Node, at_px: Vector2, times := 2) -> void:
	for i in times:
		await GESTES.lean(actor, at_px, 10.0, 0.9)


## « Un cri immense, qui fait trembler les cages »: the camera back on him, rearing, crying.
static func _leader_roars(leader: Node) -> void:
	GESTES.look_back()
	Stage.rear(leader, 1.4)
	Stage.cry(leader)
	Stage.shake(5.0, 0.6)


## Before leaving: he turns to the south-east, feathers up, and growls a long while.
static func _growls_south_east(leader: Node) -> void:
	if leader == null or not is_instance_valid(leader):
		return
	Stage.turn_to(leader, (leader as Node2D).global_position + Vector2(120.0, 80.0))
	Stage.rear(leader, 1.0)
	Stage.cry(leader)
	await S.wait(0.6)
	Stage.tremble(leader, 1.6, 1.5)


## The pack, come back for its leader: Deinonychus on the rise and the rock block around the
## camp, not seen yet (see _pack_appears).
static func _the_pack() -> Array:
	var w = S.world()
	var pack: Array = []
	if w == null or w.get("region") == null:
		return pack
	for i in PACK_SPOTS.size():
		var spot: Vector2 = PACK_SPOTS[i]
		var d := DinoNpc.new()
		d.name = "Meute%d" % i
		d.species_id = &"deinonychus"
		d.size_scale = 1.0
		d.flip = spot.x > UTAH_SPOT.x   # looking down into the camp
		d.position = _px(spot)
		d.modulate.a = 0.0
		w.region.entities.add_child(d)
		d.collision_layer = 0
		pack.append(d)
	return pack


## « Des têtes apparaissent : une, deux, dix… »: the camera on the rise, heads one by one.
static func _pack_appears(pack: Array) -> void:
	GESTES.look([_px(VIEW_PACK)])
	await S.wait(0.5)
	for d: DinoNpc in pack:
		if not is_instance_valid(d):
			continue
		Stage.fade_in(d, 0.5)
		if randf() < 0.5:
			d.cry(&"neutre")
		await S.wait(0.35)


## Everyone of `actors` turns towards `px`.
static func _all_turn(actors: Array, px: Vector2) -> void:
	for a: Node in actors:
		Stage.turn_to(a, px)


## « Et la meute le suit »: the pack goes off east along the rise, fading away.
static func _pack_follows(pack: Array) -> void:
	for d: DinoNpc in pack:
		if not is_instance_valid(d):
			continue
		var fade := d.create_tween()
		fade.tween_interval(randf_range(0.4, 1.0))
		fade.tween_property(d, "modulate:a", 0.0, 0.8)
		fade.tween_callback(d.queue_free)
		d.walk_to(d.global_position + Vector2(150.0, 0.0), 170.0)


## The pack calling all around the camp.
static func _pack_cries() -> void:
	for i in 6:
		Foret.raptor_cry("neutre" if i % 2 == 0 else "attaque", -18.0 + i, randf_range(0.95, 1.15))
		await S.wait(0.2)


## A cage with its dino still inside (the Utahraptor's, the others'): the dino answers, not the
## bars in front of it (their lines say the cage is empty and open, true once it is freed).
## `quiet` false: the cages quieted this way can be looked at again (the dinos are gone).
static func _quiet_cages(quiet := true) -> void:
	var w = S.world()
	if w == null or w.get("region") == null:
		return
	var dinos: Array = w.region.entities.get_children().filter(func(n: Node) -> bool:
		return n is DinoNpc and not n.is_queued_for_deletion())
	for n in w.region.entities.get_children():
		if not (n is Prop and n.get("kind") == "cage"):
			continue
		if not quiet:
			if n.has_meta(&"quieted"):
				n.add_to_group(&"interactable")
			continue
		for d: Node2D in dinos:
			if d.global_position.distance_to((n as Node2D).global_position) < S.CELL and n.is_in_group(&"interactable"):
				n.remove_from_group(&"interactable")
				n.set_meta(&"quieted", true)
				break


## The other caged dinos leave with the pack (the zone hides them once the Sceau is won): the
## camera on the Deinonychus' cage; each comes out staggering, then goes off and fades away.
static func _free_the_caged() -> void:
	var w = S.world()
	if w == null or w.get("region") == null:
		return
	GESTES.look([_px(VIEW_DEINO)])
	for n in w.region.entities.get_children():
		if n is StoryProp and String(n.name).begins_with("Barreaux"):
			Stage.fade_out(n, 0.5, true)   # the cage's front bars: open
		elif n is DinoNpc and (n as DinoNpc).corrupted and not n.is_queued_for_deletion():
			_staggers_out(n)


static func _staggers_out(caged: DinoNpc) -> void:
	await GESTES.halt(caged, caged.get_meta(&"pacing", {}))
	await S.wait(randf_range(0.3, 0.9))
	if not is_instance_valid(caged):
		return
	var out := caged.global_position + Vector2(0.0, 1.5 * S.CELL)   # through its open cage, south
	await caged.walk_to(caged.global_position.lerp(out, 0.5), 30.0)
	await Stage.tremble(caged, 0.8, 2.5)
	if not is_instance_valid(caged):
		return
	await caged.walk_to(out, 30.0)
	await Stage.tremble(caged, 0.5, 2.0)
	if not is_instance_valid(caged):
		return
	var fade := caged.create_tween()
	fade.tween_interval(2.0)
	fade.tween_property(caged, "modulate:a", 0.0, 1.0)
	fade.tween_callback(caged.queue_free)
	caged.walk_to(out + Vector2(3.0 * S.CELL, 0.8 * S.CELL), 50.0)


# ------------------------------------------------------------------ Brac's papers

## Brac's table: his list (the next Alpha: the Désert's), Hélène's notes on the pack, page 11
## torn from her notebook (someone got into her notebooks), and a note from « M. ».
static func papers(_who: Node) -> void:
	if Game.flag(&"found_journal_11"):
		var n := int(Game.flag(&"papiers_n"))
		Game.set_flag(&"papiers_n", n + 1)
		await S.say([GESTES.cue(PAPERS_AGAIN[n % PAPERS_AGAIN.size()], func() -> void: Stage.bow(Stage.chloe(), 1.0))])
		return
	if not Game.flag(&"brac_battu"):
		await S.say([{"text": "Une table bancale couverte de papiers, de cartes et de taches de café. Brac ne la quitte pas des yeux. Pas question d'aller fouiller sous son nez."}])
		return
	S.lock(true)
	var chloe := Stage.chloe()
	await S.say([
		GESTES.cue("La table de Brac. Des cartes de la Forêt piquées de croix rouges, des bouts de corde, un trognon de pomme, et une pile de papiers.",
			func() -> void: Stage.bow(chloe, 1.2)),
		{"text": "Tout en haut, une liste en grosses lettres maladroites : « À ATTRAPER. L'Alpha de la Forêt : FAIT. Le Carnotaurus Rouge, dans le Désert : LE PROCHAIN. »"},
		{"who": CHLOE, "text": "(Le Désert… C'est là qu'il est parti. Il veut un autre Alpha.)"},
		{"text": "Dessous, des feuilles couvertes d'une écriture penchée que Chloé connaît par cœur. Des notes sur la meute : « Le chef compte les siens à chaque ruisseau. Il dort dans la clairière aux fougères géantes, au nord-ouest. »"},
		GESTES.cue("L'écriture d'Hélène ! C'est avec ses notes qu'ils l'ont trouvé…", func() -> void: Stage.emote(chloe, "!"), CHLOE),
		{"text": "Et glissée entre deux notes, une page qui n'a rien à voir avec la Forêt. Une page de son journal."},
	])
	await Dialogue.run(DialogueDB.lines(&"page_11"))
	var lines: Array = []
	if Game.flag(&"found_journal_3"):
		lines.append({"who": CHLOE, "text": "(« I. »… L'amie de la barque, sur la page des falaises. Elles se sont fâchées ? À cause de l'ambre ?)"})
	lines.append_array([
		{"text": "Le bord de la page est déchiré net. Celle-ci n'a pas été cachée dans l'île, comme les autres : on l'a arrachée d'un carnet."},
		{"who": CHLOE, "text": "Ses carnets étaient au Cabinet… Quelqu'un y est entré, et les a pris."},
		{"who": CHLOE, "text": "(Comme la nuit du vol. Sans effraction. Avec une clé.)"},
		GESTES.cue("Tout au fond de la pile, un petit mot plié en quatre, sur un papier noir, à l'encre argentée, d'une écriture fine et droite :",
			func() -> void: Stage.bow(chloe, 1.0)),
		{"text": "« Brac. L'Alpha doit être prêt avant la pleine lune. Je viendrai juger ton travail moi-même, depuis la passerelle des deux arbres géants, sur la haute futaie. Ne me déçois pas. — M. »"},
	])
	if Game.flag(&"masque_vu"):
		lines.append({"who": CHLOE, "text": "(M… Le Masque. C'est pour ça qu'il était sur la passerelle.)"})
	elif Game.flag(&"sceau_foret"):
		lines.append({"who": CHLOE, "text": "(M… Le Masque ? La passerelle de la haute futaie… Le Chef de Meute grondait justement par là.)"})
	else:
		lines.append({"who": CHLOE, "text": "(M… Le Masque ? La passerelle de la haute futaie. Il viendra peut-être voir son « Alpha ».)"})
	lines.append({"flag": &"papiers_brac_lus"})
	await S.say(lines)
	Game.award_team_xp(XP_PAPERS)
	Save.save_game()
	S.lock(false)


# ------------------------------------------------------------------ helpers

## The third hatchling (the one the Ombre Noire stole), once calmed and with Chloé: in the
## party or the box, by its egg name; null before.
static func recovered() -> Dino:
	if not Game.flag(&"oeuf_vole_apaise"):
		return null
	var id := String(stolen_species())
	var fallback: Dino = null
	for d: Dino in Game.party + Game.box:
		if String(d.species().id) != id:
			continue
		if d.nickname == stolen_name():
			return d
		fallback = d
	return fallback


## The stolen hatchling's species (Game.flag « stolen_starter »), and the name of its egg.
static func stolen_species() -> StringName:
	var id := StringName(str(Game.flag(&"stolen_starter")))
	return id if Game.STARTERS.has(id) else &"parasaurolophus"


static func stolen_name() -> String:
	return Game.STARTERS.get(stolen_species(), "le petit")


## A little dino shown in the world for a scene (Brac's champion), not to be talked to;
## `corrupted`: still fed on black amber (its veins, its violet glow).
static func _spawn_little(id: StringName, at_px: Vector2, corrupted := false) -> DinoNpc:
	var w = S.world()
	if w == null:
		return null
	var little := DinoNpc.new()
	little.name = "Champion"
	little.species_id = id
	little.level = STOLEN_LEVEL   # (it never grew)
	little.corrupted = corrupted
	little.position = at_px
	w.region.entities.add_child(little)
	little.collision_layer = 0
	return little


## Someone leaves the scene: walks to `to` (tiles; by the tiles of `via` first) while fading,
## then is gone.
static func _leave(who, to: Vector2, speed: float, via: Array = []) -> void:
	if not is_instance_valid(who):
		return
	var points: Array = via.map(func(v: Vector2) -> Vector2: return _px(v)) + [_px(to)]
	var time := 0.0
	var from: Vector2 = (who as Node2D).global_position
	for p: Vector2 in points:
		time += from.distance_to(p) / speed
		from = p
	var fade: Tween = who.create_tween()
	fade.tween_interval(maxf(0.0, time - 0.6))
	fade.tween_property(who, "modulate:a", 0.0, 0.6)
	await GESTES.walk(who, points, speed)
	if is_instance_valid(who):
		who.queue_free()


## A music only when its file is there (it may not be imported yet).
static func music_at(path: String) -> AudioStream:
	return load(path) as AudioStream if ResourceLoader.exists(path) else null


## The next of `pool`, a different one each time (counter flag `counter`).
static func next_line(counter: StringName, pool: Array) -> String:
	var n := int(Game.flag(counter))
	Game.set_flag(counter, n + 1)
	return pool[n % pool.size()]
