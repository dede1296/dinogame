class_name MaraisSuite
## Chapter 3, the Marais Brumeux, its second half (docs/histoire.md, ch. 3; the first half is
## in story/marais.gd): Dame Suie picking roots on her islet (she « improves » dinos with black
## amber and does not like Brac; her corrupted Dilophosaurus is calmed, then Chloé may keep it);
## Roc's lantern in the evening mist after page 14, or Roc at the Cabinet (three keys; he goes
## out at night and will not say where, he begs her to trust him); Roc and the first Heart;
## Maïa's third challenge in the northern reeds, before the road to the Désert.
## Flags: dame_suie_parle, dame_suie_battue, roc_marais_en_vue, roc_marais_vu, roc_sceau_marais,
## maia_roseliere_vue, maia_defi_3.

const S := preload("res://story/story.gd")
const Act := preload("res://story/marais_stage.gd")
const CHLOE := "Chloé"
const MAIA := "Maïa"
const ROC := "Prof. Roc"
const SUIE := "Dame Suie"
const OMBRE_MUSIC := "res://assets/audio/music/ombre.ogg"
## Where a lost battle takes Chloé back to: the way in from the Forêt; near Maïa, the road north.
const MARAIS_SPAWN := &"DepuisForet"
const NORTH_SPAWN := &"DepuisDesert"
## Dame Suie: her gardener, her « swimmer », then her corrupted champion (calmed, not beaten).
## Levels checked by simulation (scratchpad/sim_marais.gd): see docs/histoire.md.
const SUIE_TEAM := [[&"therizinosaurus", 19, "Mandragore"], [&"koolasuchus", 19, "Ciguë"]]
const SUIE_CHAMPION := [&"dilophosaurus", 20, "Belladone"]
## The name Chloé gives the calmed Dilophosaurus (« Belladone » is a poison).
const CALMED_NAME := "Braise"
## Maïa's third challenge: Pouce the Iguanodon, Moustique, Caillou, then her own hatchling.
const MAIA_LEVELS := {"pouce": 20, "moustique": 20, "caillou": 21, "starter": 22}
## The night scene waits for Chloé to be free (a second each time), this many times at most.
const NIGHT_TRIES := 15
## Dame Suie walks to the nearest boat this close to her (px), when she leaves.
const BOAT_REACH := 14.0 * 48.0
## Maïa suggests a rest first when a dino of the party is under this share of its PV.
const TIRED := 0.6
const XP_SUIE := 70
const XP_ROC := 30
const XP_MAIA := 80
## Belladone out of its velvet crate for the battle (a DinoNpc of the scene): its node's name,
## the crate (tiles, tools/zones/marais.gd), where it stands to fight (from Dame Suie, px).
const BELLADONE_NODE := "BelladoneScene"
const CRATE := Vector2(28.8, 37.8)
const BELLADONE_AT := Vector2(66.0, 44.0)
## Roc's lantern in the mist: how far he appears from Chloé and walks off (tiles), and how far
## behind him she stands once she has followed him (px).
const ROC_WAY := [4.5, 7.0]
const ROC_FROM := 0.4
const FOLLOW_GAP := 100.0
const FOLLOW_SIDE := 28.0

## Roc's night scene is waiting to play (night): never twice at once.
static var _roc_walking := false


# ------------------------------------------------------------------ Dame Suie

## Dame Suie on the islet of roots (Npc « DameSuie », reached swimming): she makes black amber
## and believes she « improves » dinos; she does not like Brac. A battle (her corrupted
## Dilophosaurus is calmed, then Chloé may keep it), and she leaves in her boat.
static func dame_suie(who: Node) -> void:
	if Game.flag(&"dame_suie_battue"):
		return
	if not Game.flag(&"dame_suie_parle"):
		S.lock(true)
		await S.say(_suie_hello(who))
		Game.set_flag(&"dame_suie_parle")
		S.lock(false)
	else:
		await S.say([{"who": SUIE, "text": "Vous revoilà, mademoiselle Varenne. Parfait : il me faut une seconde mesure."}])
	var rules := {"lose_spawn": MARAIS_SPAWN}
	var theme: AudioStream = ForetCamp.music_at(OMBRE_MUSIC)
	if theme:
		rules["music"] = theme
	if not await S.duel(SUIE, _suie_team(who), rules):
		var crated = S.actor(BELLADONE_NODE)   # (lost: back in its crate)
		if crated:
			crated.queue_free()
		return
	await _suie_beaten(who)


static func _suie_hello(who: Node) -> Array:
	var chloe_at: Vector2 = Stage.chloe().global_position
	var roots: Vector2 = (who as Node2D).global_position + Vector2(0.0, -120.0)   # her roots, north of her
	var lines: Array = [
		Act.cue({"text": "Au milieu des racines tordues, une dame en gris coupe des racines noires avec de petits ciseaux d'argent. Elle les range une à une dans des fioles, étiquetées d'une écriture fine."},
			func() -> void: _snips(who, roots)),
		{"text": "Un long manteau couleur de cendre, des gants gris perle, un chapeau à voilette, et des lunettes aux verres fumés qui ne laissent rien voir de ses yeux."},
		Act.cue({"who": SUIE, "text": "Ne marchez pas sur les racines de brume, je vous prie. Elles sont timides."},
			func() -> void: Stage.turn_to(who, roots)),   # (not turned yet: see the next line)
		Act.cue({"text": "Elle se retourne enfin, et regarde Chloé de la tête aux pieds."},
			func() -> void:
				Stage.turn_to(who, chloe_at)
				Stage.bow(who, 1.2)),
		{"who": SUIE, "text": "Oh. Une enfant. Trempée, avec ça. Mademoiselle Varenne, je présume ? La petite-fille. Brac ne parle que de vous. Enfin, il hurle. Brac hurle tout."},
		{"who": CHLOE, "text": "Vous êtes avec Brac ?"},
		{"who": SUIE, "text": "Avec Brac ? Grands dieux, non. Brac est un rustre. Il donne l'ambre noir à la pelle, sans rien mesurer, et il s'étonne ensuite que ses bêtes aient peur de leur ombre."},
		{"who": SUIE, "text": "Moi, je mesure. Je dose. Je note. On m'appelle Dame Suie. Je suis chimiste."},
		{"who": CHLOE, "text": "C'est vous qui fabriquez l'ambre noir !"},
		{"who": SUIE, "text": "Je le perfectionne. Mal dosé, il rend fou, c'est vrai. Bien dosé, il rend plus fort, plus rapide, plus obéissant. J'améliore les dinos, mademoiselle."},
		{"who": SUIE, "text": "Votre grand-mère les réveillait. Moi, je les termine."},
		{"who": CHLOE, "text": "Ils ont peur ! Des veines violettes partout, et peur de tout !"},
		{"who": SUIE, "text": "La peur n'est qu'un problème de dosage. Ces racines devraient justement l'adoucir. Je suis une scientifique, pas une brute."},
		{"who": SUIE, "text": "On dit que vous les calmez. Sans rien. Juste en leur parlant. … Fascinant. Montrez-moi."},
		Act.cue({"text": "Elle retire ses gants, un doigt après l'autre, et sort un petit carnet noir."},
			func() -> void: Stage.bow(who, 1.6)),
		{"who": SUIE, "text": "Pour la science."},
	]
	return lines


## Her back to Chloé, cutting roots and filing them in vials: small bows over her work.
static func _snips(who: Node, roots: Vector2) -> void:
	if not is_instance_valid(who):
		return
	Stage.turn_to(who, roots)
	for i in 3:
		if not is_instance_valid(who):
			return
		await Stage.bow(who, 0.8)
		await S.wait(0.35)


## Her gardener, her swimmer, then Belladone: corrupted, calmed (not beaten). It comes out of
## its velvet crate as she speaks of it, trembling, and stays there while the battle lasts.
static func _suie_team(who: Node) -> Array:
	var champion: Array = SUIE_CHAMPION + [{
		"corrupted": true,
		"before": [
			Act.cue({"who": SUIE, "text": "Et voici Belladone. Mon plus bel essai : trois gouttes le matin, deux le soir."},
				func() -> void: Stage.turn_to(who, S.at(CRATE.x, CRATE.y))),
			Act.cue({"text": "D'une caisse capitonnée de velours sort un Dilophosaurus aux veines violettes. Sa collerette tremble sans arrêt. Il ne regarde personne."},
				func() -> void: _belladone_out(who)),
			{"who": CHLOE, "text": "Il n'est pas « amélioré ». Il est terrifié."},
			{"who": SUIE, "text": "Nous allons voir cela. Prenez des notes, si vous voulez. Moi, j'en prends."},
		],
		"intro": "Dame Suie envoie Belladone, le Dilophosaurus corrompu !",
		"lesson": [
			"Belladone est corrompu : il ne tombera pas. Choisis « Apaiser ».",
			"Plus il est fatigué, plus il t'écoute. Mais chaque coup l'affole un peu.",
		],
	}]
	return SUIE_TEAM + [champion]


## Belladone steps out of its crate (by the crate, between Dame Suie and Chloé), its collar
## shaking; it keeps trembling, its eyes on nobody.
static func _belladone_out(who: Node) -> void:
	if S.actor(BELLADONE_NODE) or not is_instance_valid(who):
		return
	var at := S.ground_near((who as Node2D).global_position + BELLADONE_AT, 2)
	var crate := S.at(CRATE.x, CRATE.y)
	var start := crate if Act.clear_way(crate, at) else at
	var dilo := Act.stand_in(SUIE_CHAMPION[0], start, BELLADONE_NODE, true)
	if dilo == null:
		return
	Stage.fade_in(dilo, 0.5)
	if start != at:
		await dilo.walk_to(at, 70.0)
	if not is_instance_valid(dilo):
		return
	Stage.turn_to(dilo, Stage.chloe().global_position)
	Stage.tremble(dilo, 4.0, 1.6)


## Calmed: Dame Suie cannot believe it (it is not in her tables); she speaks of Hélène's burnt
## notes (« presque toutes »), of the temple and of the Masque; she leaves in her boat.
static func _suie_beaten(who: Node) -> void:
	var w = S.world()
	if w == null:
		return
	S.lock(true)
	var dilo = S.actor(BELLADONE_NODE)
	await S.say([
		Act.cue({"text": "Le Dilophosaurus cligne des yeux. Les veines violettes pâlissent, puis s'effacent. Il replie sa collerette, tout doucement, et vient renifler la main de Chloé."},
			func() -> void: _belladone_calmed(dilo)),
		Act.cue({"text": "Dame Suie a arrêté d'écrire. Son stylo est resté en l'air."},
			func() -> void:
				if is_instance_valid(who):
					Stage.turn_to(who, w.player.global_position)
					Stage.emote(who, "!")),
		{"who": SUIE, "text": "… Remarquable. Vous l'avez calmé. Sans une goutte. Juste en restant là."},
		{"who": SUIE, "text": "Ce n'est pas dans mes tables."},
		{"who": CHLOE, "text": "Ce n'est pas de la chimie. C'est de la confiance. Hélène appelait ça le Lien."},
		{"who": SUIE, "text": "Votre grand-mère… Savez-vous qu'elle avait brûlé ses notes ? Toutes ses pages sur l'ambre forcé."},
		{"who": SUIE, "text": "Presque toutes. « Presque. » C'est un mot merveilleux, mademoiselle. Toute ma science tient dedans."},
	])
	if Game.flag(&"found_journal_4"):
		await S.say([{"who": CHLOE, "text": "(« J'ai brûlé mes notes… presque toutes. » La page de la grotte. Quelqu'un a trouvé les autres.)"}])
	await _keep_calmed(dilo)
	var about_temple: Array = []
	if Game.flag(&"temple_ouvert"):
		about_temple = [
			{"who": SUIE, "text": "Quelqu'un a chanté, l'autre jour. La vieille porte du temple s'est ouverte. Le Masque sera ravi de l'apprendre : il cherche ce qui dort là-dessous depuis des années."},
			{"who": CHLOE, "text": "Vous ne l'aurez pas."},
			{"who": SUIE, "text": "Moi ? Je ne veux rien, mademoiselle. Je mesure."},
		]
	else:
		about_temple = [
			{"who": SUIE, "text": "On dit qu'une vieille Parasaurolophus chante dans la roselière, et que son chant ouvre le temple englouti. Le Masque aimerait beaucoup l'entendre."},
			{"who": CHLOE, "text": "Laissez-la tranquille !"},
			{"who": SUIE, "text": "Moi ? Je ne touche à rien. Je mesure."},
		]
	await S.say(about_temple + [
		{"who": SUIE, "text": "Le Masque paie mes flacons et ne pose jamais de question. C'est très reposant. Et si vous croisez Brac, dites-lui que ses dinos méritent mieux que lui. Il ne comprendra pas, mais cela me fera plaisir."},
		Act.cue({"text": "Elle remet ses gants, un doigt après l'autre, et ramasse son panier de fioles."},
			func() -> void: Stage.bow(who, 1.6)),
		{"who": SUIE, "text": "Au revoir, mademoiselle Varenne. Nous nous reverrons, j'en suis sûre. Là où il fait plus froid, peut-être."},
	])
	if is_instance_valid(who):   # to her boat, into the mist
		await ForetCamp._leave(who, _boat_near(who) / S.CELL, 90.0)
	var lines: Array = [{"text": "Sa barque glisse dans la brume, sans un bruit de rame. Il ne reste qu'une odeur de cheminée froide."}]
	var page_at := S.at(29.3, 33.8)   # page 13, in the moss between her roots (it shows with the flag)
	if not Game.flag(&"found_journal_13"):
		lines.append(Act.cue({"text": "Entre les racines qu'elle cueillait, quelque chose de pâle dépasse de la mousse. Un coin de papier ?"},
			func() -> void: Stage.look_at(page_at)))
	lines.append_array([
		{"who": CHLOE, "text": "(Elle croit vraiment qu'elle les aide…)"},
		{"flag": &"dame_suie_battue"},
	])
	await S.say(lines)
	if not Game.flag(&"found_journal_13"):
		await S.wait(1.0)   # (the page shows up, there)
	Game.award_team_xp(XP_SUIE)
	Save.save_game()
	S.lock(false)


## Belladone calmed: the black amber lets go of it (its own colours back, the violet light
## gone), it folds its frill and comes to sniff Chloé's hand.
static func _belladone_calmed(dilo: Node) -> void:
	if dilo == null or not is_instance_valid(dilo):
		return
	Stage.stop(dilo, null)
	await dilo.cleanse()
	if not is_instance_valid(dilo):
		return
	var chloe_at: Vector2 = Stage.chloe().global_position
	var to: Vector2 = chloe_at + ((dilo as Node2D).global_position - chloe_at).normalized() * 50.0
	if Act.clear_way((dilo as Node2D).global_position, to):
		await dilo.walk_to(to, 60.0)
	if is_instance_valid(dilo):
		Stage.turn_to(dilo, chloe_at)
		Act.lean(dilo, chloe_at, 10.0, 1.4)


## Where Dame Suie's boat waits (the nearest « barque » of the zone), else a few steps away.
static func _boat_near(who: Node2D) -> Vector2:
	var best := who.global_position + Vector2(0.0, 4.0 * S.CELL)
	var w = S.world()
	if w == null or w.get("region") == null:
		return best
	var best_d := BOAT_REACH
	for n in w.region.entities.get_children():
		if n is Prop and n.get("kind") == "barque" and (n as Node2D).global_position.distance_to(who.global_position) < best_d:
			best_d = (n as Node2D).global_position.distance_to(who.global_position)
			best = (n as Node2D).global_position + Vector2(0.0, -0.5 * S.CELL)
	return best


## Belladone, calmed: Dame Suie does not want a dino that no longer obeys. Chloé may keep it
## (named Braise), or let it go free in the Marais. (`dilo`: Belladone out of its crate, or null.)
static func _keep_calmed(dilo: Node) -> void:
	await S.say([{"who": SUIE, "text": "Gardez-le. Un sujet qui n'obéit plus ne m'est d'aucune utilité."}])
	_hides_behind(dilo)
	var pick := await Dialogue.choose("", "Le Dilophosaurus se cache derrière Chloé. Il ne veut plus retourner dans sa caisse de velours.",
		["Viens avec moi !", "Tu es libre, va"])
	if pick != 0:
		await S.say([Act.cue({"text": "Le Dilophosaurus pousse un petit cri, presque un merci, et file dans les roseaux. Loin des fioles. Ses veines finiront de pâlir au soleil."},
			func() -> void: _runs_free(dilo))])
		return
	var d := Dino.create(SUIE_CHAMPION[0], SUIE_CHAMPION[1], CALMED_NAME)
	var in_party: bool = await ForetCamp.make_room_for(d, "%s veut rester avec toi. Mais ton équipe est pleine : qui part attendre au Cabinet ?" % CALMED_NAME)
	await S.say([
		{"who": CHLOE, "text": "« Belladone », c'est le nom d'un poison. Toi, tu t'appelleras %s." % CALMED_NAME},
		Act.cue({"text": "%s rejoint ton équipe !" % CALMED_NAME if in_party else "%s part attendre au Cabinet, au chaud." % CALMED_NAME},
			func() -> void:
				if is_instance_valid(dilo):
					Stage.hop(dilo, 2, 8.0)
					Stage.fade_out(dilo, 1.2, true)),
	])
	if is_instance_valid(dilo):   # (the line hurried along: gone all the same)
		Stage.fade_out(dilo, 0.4, true)


## It slips behind Chloé (away from Dame Suie) and shakes.
static func _hides_behind(dilo: Node) -> void:
	if dilo == null or not is_instance_valid(dilo):
		return
	var chloe := Stage.chloe()
	var suie = S.actor("DameSuie")
	var away: Vector2 = Vector2.DOWN if suie == null else (chloe.global_position - (suie as Node2D).global_position).normalized()
	var to: Vector2 = chloe.global_position + away * 44.0 + away.orthogonal() * 20.0
	if Act.clear_way((dilo as Node2D).global_position, to):
		await dilo.walk_to(to, 90.0)
	if is_instance_valid(dilo):
		Stage.turn_to(dilo, chloe.global_position)
		Stage.tremble(dilo, 1.6, 1.6)


## Set free: a little cry, and off into the reeds (it fades on the way).
static func _runs_free(dilo: Node) -> void:
	if dilo == null or not is_instance_valid(dilo):
		return
	Stage.cry(dilo, &"neutre")
	var from: Vector2 = (dilo as Node2D).global_position
	var to := Act.way_from(from, Vector2(1.0, 0.6), 3.0, 5.0)
	if to == Vector2.INF:
		await Stage.fade_out(dilo, 0.8, true)
		return
	await ForetCamp._leave(dilo, to / S.CELL, 150.0)


# ------------------------------------------------------------------ Roc, at night

## Roc's lantern in the evening mist (after page 14): Chloé follows it and confronts him.
## Played when evening or night falls in the Marais, or when Chloé comes in by then (as soon as
## she is free: after a zone change, a rest by the fire…).
static func night() -> void:
	if _roc_walking:
		return
	_roc_walking = true
	for i in NIGHT_TRIES:
		if not _roc_may_walk():
			break
		var w = S.world()
		if w == null or w.get("region") == null or w.region.region_id != &"marais":
			break
		if not (w.player.busy or Dialogue.active or w.player.is_swimming() or w.get_tree().paused or Router.is_busy()):
			await _roc_walks(w)
			break
		await S.wait(1.0)
	_roc_walking = false


## A lantern in the mist: Roc walks off, stopping and going, along Chloé's own pontoon (or
## island: always on firm ground, never on the water); the camera shows him. She follows him
## (a fade: she is just behind him when the view comes back). With nowhere to walk to, he is
## simply there, out of the mist, a few steps from her.
static func _roc_walks(w) -> void:
	S.lock(true)
	var lantern = S.actor("RocMarais")
	if lantern == null:
		var chloe_at: Vector2 = w.player.global_position
		var far := Act.way_from(chloe_at, Vector2(1.0, -0.5), ROC_WAY[0], ROC_WAY[1])
		var walks := far != Vector2.INF
		var start: Vector2 = chloe_at.lerp(far, ROC_FROM) if walks else S.ground_near(chloe_at + Vector2(80.0, -30.0), 2)
		lantern = S.stranger("RocNuit", "roc", start, "down")
		Plaines._lantern(lantern)
		lantern.modulate.a = 0.0
		var going := {"on": walks}
		await S.say([
			Act.cue({"text": "Dans la brume du soir, une petite lumière avance au ras de l'eau. Elle s'arrête, repart, s'arrête encore. Une lanterne."},
				func() -> void:
					Stage.look_at(start.lerp(far, 0.5) if walks else start)
					Stage.fade_in(lantern, 1.4)
					if walks:
						_stop_and_go(lantern, start, far, going)),
			{"who": CHLOE, "text": "(Qui se promène dans le Marais à une heure pareille ?)"},
			{"text": "Chloé la suit sans bruit, de ponton en ponton…"},
			{"flag": &"roc_marais_en_vue"},
		])
		going["on"] = false
		if walks:
			await S.fade_through(func() -> void: _catch_up(w, lantern, chloe_at, far))
		else:
			Stage.look_back()
			w.player.face_towards(lantern.global_position)
	else:
		w.player.face_towards(lantern.global_position)
	await roc_confronts(lantern, true)
	S.lock(false)


## Roc's lantern, stopping and going: three stretches from `from` to `to`, a pause between
## (until `going["on"]` is false).
static func _stop_and_go(prof: Node, from: Vector2, to: Vector2, going: Dictionary) -> void:
	for i in [1, 2, 3]:
		await S.wait(0.8)
		if not going["on"] or not is_instance_valid(prof):
			return
		await prof.walk_to(from.lerp(to, i / 3.0), "", 55.0)


## (Under the fade.) Roc has stopped, his back to her; Chloé stands a few steps behind him on
## the same way (so on firm ground), her dino at her side; the camera is hers again.
static func _catch_up(w, prof: Node, from: Vector2, to: Vector2) -> void:
	var back := (from - to).normalized()
	var roc_at: Vector2 = (prof as Node2D).global_position if is_instance_valid(prof) else to
	if is_instance_valid(prof):
		prof.face(roc_at - back * 100.0)
	# A little aside, not right behind him: the camera sees them both.
	var side := back.orthogonal() * FOLLOW_SIDE
	var her_at := from   # (where she was, if nothing better)
	for spot: Vector2 in [back * FOLLOW_GAP + side, back * FOLLOW_GAP - side, back * FOLLOW_GAP]:
		if Act.clear_way(roc_at, roc_at + spot):
			her_at = roc_at + spot
			break
	w.player.teleport(her_at)
	var dino_at := her_at + back * 40.0
	w.companion.teleport(dino_at if Act.clear_way(her_at, dino_at) else her_at)
	w.player.face_towards(roc_at)
	var view: Node = w.get_tree().get_first_node_in_group(&"world_view")
	if view:
		view.set("focus_px", Vector2.INF)


## Talking to Roc on the pontoons (Npc « RocMarais », there after a reload in the middle of
## the night scene): the confrontation, or a word before he goes.
static func roc_marais(who: Node) -> void:
	if Game.flag(&"roc_marais_vu"):
		await S.say([{"who": ROC, "text": "Rentre te mettre au chaud, Chloé. La brume, la nuit… ce n'est pas un endroit pour toi. Ni pour moi, d'ailleurs."}])
		return
	S.lock(true)
	await roc_confronts(who, true)
	S.lock(false)


static func _roc_may_walk() -> bool:
	return Game.flag(&"found_journal_14") and not Game.flag(&"roc_marais_vu") and Game.phase() in [&"dusk", &"night"]


## Page 14 in hand: three keys to the Cabinet, and Roc's nights out. He admits going out, will
## not say where (a promise), begs her to trust him. `outside`: in the Marais, lantern in hand
## (he walks away into the mist); else at the Cabinet.
static func roc_confronts(prof, outside: bool) -> void:
	var lines: Array = []
	var chloe := Stage.chloe()
	if outside:
		lines.append_array([
			{"who": CHLOE, "text": "Professeur ?!"},
			Act.cue({"text": "Roc sursaute si fort que sa lanterne fait un tour complet."},
				func() -> void:
					Stage.hop(prof, 1, 16.0)
					Stage.emote(prof, "!")
					await S.wait(0.3)
					if is_instance_valid(prof):
						prof.face(chloe.global_position)),
			{"who": ROC, "text": "Chloé ?! Par tous les fossiles… Qu'est-ce que tu fais dehors à une heure pareille ?"},
			{"who": CHLOE, "text": "Et vous ?"},
			{"who": ROC, "text": "Moi ? Je… je cueille des champignons. Des champignons de nuit. Ça existe. C'est très rare."},
		])
		var lead := Game.lead_dino()
		if lead:
			lines.append(Act.cue({"text": "%s renifle les chaussures de Roc : de la vase… et, par-dessus, une fine poussière grise." % lead.nickname},
				func() -> void: _sniffs_shoes(prof)))
			lines.append(Act.cue({"who": CHLOE, "text": "(De la cendre. Encore.)"}, func() -> void: Act.lead_back()))
	else:
		lines.append_array([
			{"who": ROC, "text": "Ah, Chloé ! Tu tombes bien, je voulais te montrer un…"},
			Act.cue({"text": "Chloé pose une page du journal sur le bureau, bien à plat. Roc la reconnaît tout de suite. Il enlève ses lunettes, les essuie, les remet."},
				func() -> void: _page_on_desk(prof)),
		])
	lines.append_array([
		{"who": CHLOE, "text": "J'ai trouvé une page d'Hélène, dans le Marais. Ses notes sur l'ambre forcé ont été volées au Cabinet. Sans effraction."},
		{"who": CHLOE, "text": "Elle écrit que trois personnes seulement avaient la clé. Elle… vous… et « I. »."},
		Act.cue({"text": "Un long silence. Quelque part, une goutte tombe dans l'eau."},
			func() -> void:
				Stage.bow(prof, 2.4)
				if outside:
					Act.burst(Act.water_near((prof as Node2D).global_position, 4), Act.SPLASH, 4, Act.ON_WATER, 0.1)),
		{"who": ROC, "text": "Je sais. Elle me l'avait dit, à l'époque. Je n'ai jamais cessé d'y penser."},
		{"who": CHLOE, "text": "Le petit volé, la nuit où je suis arrivée : pas d'effraction non plus. Et vous sortez la nuit." + (" Et il y a de l'ambre noir dans votre tiroir." if Game.flag(&"ambre_noir_tiroir") else "")},
		{"who": ROC, "text": "Oui. Je sors la nuit. Souvent. Depuis qu'elle est partie."},
		{"who": CHLOE, "text": "Où allez-vous ?"},
		{"who": ROC, "text": "Je ne peux pas te le dire. Pas parce que j'ai honte. Parce que j'ai promis."},
		{"who": CHLOE, "text": "Promis à qui ?"},
		{"who": ROC, "text": "À quelqu'un qui n'est plus là pour me délier de ma promesse."},
		{"who": ROC, "text": "Ce n'est pas moi, Chloé. Je n'ai jamais touché à ses carnets. Et je n'aurais jamais fait de mal à ce petit. Jamais."},
		{"who": ROC, "text": "Je sais que je ne t'ai donné aucune raison de me croire. Je bougonne, je mens mal, je cache des choses dans des tiroirs… Mais je t'en supplie : fais-moi confiance. Encore un peu."},
		{"who": CHLOE, "text": "Et « I. » ? Qui est-ce ?"},
		{"who": ROC, "text": "Hélène avait beaucoup d'amis, autrefois. Certains le sont restés. D'autres…"},
		Act.cue({"text": "Il s'arrête net."}, func() -> void: Stage.emote(prof, "…")),
		{"who": ROC, "text": "Ce n'est pas à moi de le dire. Pas sans preuve."},
	])
	await S.say(lines)
	Act.lead_back()
	if outside:
		await S.say([{"who": ROC, "text": "Rentre te mettre au chaud. Et sois prudente : la brume cache des choses."}])
		await S.say([Act.cue({"text": "La lanterne s'éloigne dans la brume, de plus en plus petite, puis plus rien."},
			func() -> void: _lantern_goes(prof))])
	else:
		await S.say([Act.cue({"who": ROC, "text": "Et maintenant, si tu veux bien… j'ai des bocaux à étiqueter. Beaucoup de bocaux."},
			func() -> void:
				if is_instance_valid(prof):
					prof.face((prof as Node2D).global_position + Vector2(0.0, -100.0)))])
	await S.say([
		{"who": CHLOE, "text": "(Il n'a pas dit non. Il n'a pas dit oui. Il a juste supplié.)"},
		{"who": CHLOE, "text": "(Je veux le croire. Je crois que je le crois.)"},
		{"flag": &"roc_marais_vu"},
	])
	Game.award_team_xp(XP_ROC)
	Save.save_game()


## Chloé's lead dino goes to sniff Roc's shoes (it comes back on the next line: lead_back).
static func _sniffs_shoes(prof: Node) -> void:
	var c := Act.lead()
	if c == null or not is_instance_valid(prof):
		return
	var at: Vector2 = (prof as Node2D).global_position
	var to: Vector2 = at + (c.global_position - at).normalized() * 34.0
	if not Act.clear_way(c.global_position, to):
		to = c.global_position.lerp(to, 0.5)
	await Act.walk_lead(to, 90.0)
	Stage.turn_to(c, at)
	Stage.bow(c, 1.2)


## At the Cabinet: Chloé lays the page on the desk; Roc looks at it, takes his glasses off,
## wipes them, puts them back.
static func _page_on_desk(prof: Node) -> void:
	var chloe := Stage.chloe()
	if not is_instance_valid(prof):
		return
	Stage.lunge(chloe, (prof as Node2D).global_position, 0.6, false)
	await S.wait(0.7)
	if not is_instance_valid(prof):
		return
	await Stage.bow(prof, 0.9)
	if is_instance_valid(prof):
		Stage.tremble(prof, 0.9, 1.2)


## Roc walks off into the mist, his lantern with him (on firm ground, away from Chloé), and
## fades; the camera watches him go, then comes back.
static func _lantern_goes(prof: Node) -> void:
	if not is_instance_valid(prof):
		return
	var at: Vector2 = (prof as Node2D).global_position
	var away := Act.way_from(at, at - Stage.chloe().global_position, 3.0, 6.0)
	var fade: Tween = prof.create_tween()
	fade.tween_interval(0.6)
	fade.tween_property(prof, "modulate:a", 0.0, 2.4)
	if away != Vector2.INF:
		Stage.look_at(at.lerp(away, 0.5), 1.2)
		await prof.walk_to(away, "", 70.0)
	else:
		await S.wait(3.0)
	if is_instance_valid(prof):
		prof.queue_free()
	Stage.look_back()


# ------------------------------------------------------------------ at the Cabinet

## Entering the Cabinet: after page 14, if Chloé has not met Roc in the Marais at night, she
## confronts him here; with the Heart, Roc sees it at once.
static func cabinet() -> void:
	var prof = S.actor("Roc")
	if prof == null or not Game.flag(&"prologue_done"):
		return
	if Game.flag(&"found_journal_14") and not Game.flag(&"roc_marais_vu"):
		S.lock(true)
		await S.wait(0.4)
		prof.face(S.world().player.global_position)
		await roc_confronts(prof, false)
		S.lock(false)
		return
	if Game.flag(&"sceau_marais") and not Game.flag(&"roc_sceau_marais"):
		S.lock(true)
		await S.wait(0.4)
		prof.face(S.world().player.global_position)
		await S.say(_heart_lines(prof))
		Save.save_game()
		S.lock(false)


## Talking to Roc (Story.run « roc »): the confrontation or the Heart, if not yet. True if said.
static func roc() -> bool:
	if Game.flag(&"found_journal_14") and not Game.flag(&"roc_marais_vu"):
		S.lock(true)
		await roc_confronts(S.actor("Roc"), false)
		S.lock(false)
		return true
	if Game.flag(&"sceau_marais") and not Game.flag(&"roc_sceau_marais"):
		await S.say(_heart_lines(S.actor("Roc")))
		return true
	return false


## (`prof`: Roc. The Heart beats in Chloé's bag, then in the light as she shows it; he leans in.)
static func _heart_lines(prof) -> Array:
	var chloe := Stage.chloe()
	var lines: Array = [
		Act.cue({"who": ROC, "text": "Chloé, ta sacoche… Elle bat. Qu'est-ce que… Montre-moi."},
			func() -> void:
				Act.heartbeat(chloe, 2)
				if prof:
					Stage.emote(prof, "!")),
		Act.cue({"text": "Chloé sort le Cœur d'ambre. Dans la lumière du Cabinet, il bat doucement, comme un cœur endormi."},
			func() -> void:
				Act.pop(chloe.global_position, "coeur_1", 1.0)
				Act.heartbeat(chloe, 3, 1.3)
				if prof:
					Act.lean(prof, chloe.global_position, 8.0, 2.4)),
		{"who": ROC, "text": "Le premier Cœur. Et le Sceau du Marais… Le Spinosaure te les a donnés. À toi."},
		{"who": ROC, "text": "Il n'avait jamais fait confiance qu'à elle. Elle disait qu'il lui avait fallu trois pleines lunes pour qu'il sorte la tête de l'eau."},
		{"who": ROC, "text": "Écoute-moi bien. Ce Cœur, ne le montre à personne. À PERSONNE. Pas même à ceux qui te sourient."},
	]
	if Game.flag(&"roc_marais_vu"):
		lines.append({"who": ROC, "text": "… Oui, même pas à moi, si tu préfères. Je comprendrais."})
	lines.append({"flag": &"roc_sceau_marais"})
	return lines


# ------------------------------------------------------------------ Maïa's third challenge

## Maïa in the northern reeds, before the road to the Désert (Npc « MaiaRoseliere », there
## once the Sceau is Chloé's): the Heart, Roc (« il est bizarre, pas méchant »), her challenge;
## beaten, she goes first towards the Désert.
static func maia(who: Node) -> void:
	if Game.flag(&"maia_defi_3"):
		return
	var first: bool = not Game.flag(&"maia_roseliere_vue")
	if first:
		S.lock(true)
		await S.say(_maia_hello(who))
		Game.set_flag(&"maia_roseliere_vue")
		S.lock(false)
	var prompt := "Quatre dinos chacune. Et Pouce a hâte de te dire bonjour. Avec son pouce." if first \
		else "Alors, ce défi numéro trois ? Pouce s'entraîne à dire bonjour sur les roseaux. Il en a déjà coupé douze."
	if Game.party.any(func(d: Dino) -> bool: return d.hp < d.max_hp() * TIRED):
		prompt = "Ton équipe a l'air crevée… Un feu de camp fume dans la roselière : repose-toi d'abord, si tu veux. Je veux une VRAIE victoire."
	var pick := await Dialogue.choose(MAIA, prompt, ["Relever le défi", "Plus tard"])
	if pick != 0:
		await S.say([{"who": MAIA, "text": "Je t'attends ici. La route du Désert ne va pas s'envoler. Enfin, avec le vent qu'il fait là-haut…"}])
		return
	if not await S.duel(MAIA, _maia_team(), {"lose_spawn": NORTH_SPAWN}):
		await S.say([{"who": MAIA, "text": "HA ! Qui c'est, la championne du Marais ? … Soigne ton équipe et reviens. Je ne bouge pas."}])
		return
	await _maia_beaten(who)


## (`who`: Maïa. She hops about; the Heart beats in Chloé's hands, she leans in to see it.)
static func _maia_hello(who: Node) -> Array:
	var chloe := Stage.chloe()
	var lines: Array = [
		Act.cue({"who": MAIA, "text": "CHLOÉ ! Enfin ! J'ai vu une lumière dorée sortir du temple, tout droit dans la brume ! C'était toi, hein ? C'était TOI !"},
			func() -> void: Stage.hop(who, 3, 10.0)),
		{"who": CHLOE, "text": "Le Spinosaure Ancestral m'a confié le Sceau du Marais. Et le premier Cœur d'ambre."},
		Act.cue({"who": MAIA, "text": "Un Cœur ?! Montre ! … Oh. Il bat. Il BAT, Chloé. C'est le truc le plus stylé que j'aie jamais vu. Plus que le Masque. Si, si."},
			func() -> void:
				Act.lean(who, chloe.global_position, 10.0, 2.2)
				Act.pop(chloe.global_position, "coeur_1", 1.0)
				Act.heartbeat(chloe, 3)),
	]
	if str(Game.flag(&"maia_starter")) == "parasaurolophus":
		lines.append({"who": MAIA, "text": "Et Clairon n'arrête pas de chanter depuis qu'on est dans le Marais. La vieille Voix lui répond, le soir. Je crois qu'ils se racontent des histoires de crêtes."})
	lines.append_array(_maia_about_roc())
	lines.append_array([
		{"who": MAIA, "text": "Bon. Assez parlé. Mon défi numéro TROIS. Et j'ai un petit nouveau : Pouce, un Iguanodon !"},
		{"who": MAIA, "text": "Il a un pouce en pointe. Il s'en sert pour dire bonjour. Et pour piquer. Surtout pour piquer."},
	])
	return lines


## Maïa defends Roc (« il est bizarre, pas méchant »); « I. », she does not see who it could be.
static func _maia_about_roc() -> Array:
	var lines: Array = []
	if Game.flag(&"roc_marais_vu"):
		lines.append({"who": CHLOE, "text": "Maïa… J'ai parlé à Roc. Il sort la nuit, en cachette. Et il avait la clé du Cabinet, la nuit du vol."})
	elif Game.flag(&"found_journal_14"):
		lines.append({"who": CHLOE, "text": "Maïa… Hélène a écrit que trois personnes seulement avaient la clé du Cabinet. Roc en fait partie. Et il sort la nuit."})
	else:
		lines.append({"who": MAIA, "text": "Au fait : Joss a vu Roc passer une nuit sur les pontons, avec sa lanterne. Il est tombé dans la vase. Roc, pas Joss. Enfin, Joss aussi, mais après."})
	lines.append_array([
		{"who": MAIA, "text": "Roc ? Un voleur ? N'importe quoi. Il est bizarre, pas méchant."},
		{"who": MAIA, "text": "Quand j'avais six ans, il a passé une nuit entière à recoudre mon doudou. Il s'est piqué quarante fois. Il a juré en latin."},
		{"who": MAIA, "text": "Les méchants, ça ne recoud pas les doudous."},
	])
	if Game.flag(&"found_journal_14"):
		lines.append_array([
			{"who": CHLOE, "text": "Et la troisième clé ? Hélène l'appelle juste « I. »."},
			{"who": MAIA, "text": "« I. » ? Plein de gens commencent par I. Irène, la poissonnière. Ignace, l'ancien gardien du phare. Bref. Pas Roc, voilà."},
		])
	return lines


static func _maia_team() -> Array:
	var team := [[&"iguanodon", MAIA_LEVELS["pouce"], "Pouce"], [&"dimorphodon", MAIA_LEVELS["moustique"], "Moustique"],
		[&"protoceratops", MAIA_LEVELS["caillou"], "Caillou"]]
	var mine := StringName(str(Game.flag(&"maia_starter")))
	if SpeciesDB.PATHS.has(mine):
		team.append([mine, MAIA_LEVELS["starter"], Prologue.MAIA_NAMES.get(mine, "Flèche")])
	return team


static func _maia_beaten(who: Node) -> void:
	S.lock(true)
	var lines: Array = [
		Act.cue({"who": MAIA, "text": "TROIS FOIS ! Trois fois de suite ! C'est… c'est statistiquement impossible !"},
			func() -> void: Stage.hop(who, 2, 6.0)),
		{"who": MAIA, "text": "… Bon. Tu es la meilleure dresseuse que je connaisse. Après moi. Enfin, avant moi. Pour l'instant."},
		Act.cue({"who": MAIA, "text": "Au nord, c'est la route du Désert. Les roseaux s'arrêtent, la vase craque, et après, plus une goutte d'eau pendant des jours."},
			func() -> void:
				if is_instance_valid(who):
					who.face((who as Node2D).global_position + Vector2(0.0, -100.0))),
	]
	if Game.flag(&"papiers_brac_lus"):
		lines.append({"who": CHLOE, "text": "Brac y est parti. Il veut le Carnotaurus Rouge, l'Alpha du Désert. C'était écrit sur sa liste."})
	else:
		lines.append({"who": CHLOE, "text": "Brac y est parti, en jurant. Il disait qu'il avait là-bas « des amis avec des dents »."})
	lines.append(Act.cue({"who": MAIA, "text": "Alors on y va ! Enfin, TOI, tu y vas. Et moi, j'arrive avant toi."},
		func() -> void:
			if is_instance_valid(who):
				who.face(Stage.chloe().global_position)))
	if Game.flag(&"found_journal_14") or Game.flag(&"roc_marais_vu"):
		lines.append({"who": MAIA, "text": "Et Chloé… pour Roc. Fais-lui confiance. Moi, je lui fais confiance."})
	lines.append_array([
		{"who": MAIA, "text": "Rendez-vous au Désert, championne. Et la prochaine fois, Caillou aura une surprise pour toi. Une GROSSE surprise."},
		{"flag": &"maia_defi_3"},
	])
	await S.say(lines)
	Game.award_team_xp(XP_MAIA)
	if is_instance_valid(who):
		var fade: Tween = who.create_tween()
		fade.tween_interval(0.6)
		fade.tween_property(who, "modulate:a", 0.0, 0.6)
		var road: Vector2 = (who as Node2D).global_position + Vector2(0.0, -220.0)
		if Act.clear_way((who as Node2D).global_position, road):   # (the road north, never the water)
			await who.walk_to(road, "up", 200.0)
		else:
			await S.wait(1.2)
		if is_instance_valid(who):
			who.queue_free()
	Save.save_game()
	S.lock(false)
