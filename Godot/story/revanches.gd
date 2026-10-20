class_name Revanches
## Le post-game, les revanches (docs/post-game-plan.md § 3, docs/post-game-scenes.md R1 à R4 ; décisions de Greg du
## 20/10) : Maïa au Grand Crâne (le défi n° 6, une fois par jour) ; les sept Alphas chez eux, « pour voir », une fois par
## jour chacun (la première victoire éveille son Sceau : il répond ensuite dans tous les combats, ApexEngine.Libres) ;
## le pari d'Isaure à sa barque, une fois par jour (la première victoire donne la page de la mer : `isaure_pari_gagne`,
## `carnet_mer`, que lit le lot des fossiles) ; Hélène et les Sceaux, une fois. Le Roi des Cieux ne combat pas ; le
## Souverain, jamais : ni l'un ni l'autre n'est ici. Les répliques : data/dialogue_revanches.gd ; les combats :
## battle/revanche_battles.gd, ApexBattles.maia_team.
## Branché par le correctif du lot C (scratchpad postgame/patch_C.md) : l'événement de chaque Alpha (story/plaines.gd,
## foret.gd, marais_temple.gd, desert_sanctuaire.gd, cote_recif.gd, monts_sanctuaire.gd, volcan_sanctuaire.gd), dès
## `post_game` → alpha(id, who) ; ApexAutour (maia, isaure, helene) → maia(), isaure(), helene().
## Répliques corrigées (elles ne collaient pas au jeu) : Maïa « tous les trois » (Moustique est à 50 lui aussi) et le
## tableau du Relais, qui porte déjà « pour l'instant » (elle le repasse) ; un Alpha « reprend sa garde » (debout : il ne
## se recouche pas) ; Cheminée dort après le chapitre 8 (il se lève, il ne sort pas de la faille) ; la porte des Vents a
## disparu (Piment se gratte contre l'entrée) ; Isaure ne cite Sirocco que si elle a déjà donné la terre (`carnet_terre`).
## Drapeaux : alpha_<id>_jour (= Game.day), alpha_<id>_reconnu, <sceau>_eveille (ApexEngine), maia_defi_6_jour,
## maia_defi_6, isaure_pari_jour, isaure_pari_offert, isaure_pari_gagne, carnet_mer, helene_sceaux.

const S := preload("res://story/story.gd")
const CS := preload("res://story/cote_stage.gd")
const A := preload("res://story/apex.gd")
const COINS_SFX := preload("res://assets/audio/sfx/coins.wav")
const MAIA := "Maïa"
const ISAURE := "Isaure"
const HELENE := "Hélène"
## L'Alpha qu'il faut faire venir (le Tricératops dans son antre, le Chef de Meute dans les fougères).
const STAND_IN := "RevancheAlpha"
## Son salut à l'arrivée, par région (Stage) : « bow » il baisse la tête, « rear » il se dresse, « roar » il rugit.
const GREETS := {&"plaines": "bow", &"foret": "cry", &"marais": "rear", &"desert": "roar", &"cote": "cry", &"monts": "cry",
	&"volcan": "rear"}
## La barque lavée : Chloé frotte le pont (trois coups).
const SCRUBS := 3
## Les Alphas qui ne sont plus chez eux après leur chapitre (le Spinosaure quitte son temple : hide_flag sceau_marais) :
## après la fin, ils y reviennent, à leur place (« spot »), et l'événement de leur chapitre les fait parler (on_zone).
const RESIDENTS := {&"temple_englouti": [&"marais", &"spinosaure_ancestral"]}
const RESIDENT := "AlphaRevanche"


# ------------------------------------------------------------------ l'état (sans fenêtre)

## Le post-game a commencé (l'épilogue est fini).
static func open() -> bool:
	return Game.flag(&"post_game") == true


static func day_flag(id: StringName) -> StringName:
	return StringName("alpha_%s_jour" % id)


static func known_flag(id: StringName) -> StringName:
	return StringName("alpha_%s_reconnu" % id)


## La revanche de l'Alpha `id` est-elle possible aujourd'hui ?
static func can_challenge(id: StringName) -> bool:
	return open() and RevancheBattles.ALPHAS.has(id) and int(Game.flag(day_flag(id))) != Game.day


## Une revanche gagnée : la première fois, l'Alpha a « reconnu » Chloé et son Sceau s'éveille ; les pièces à chaque
## fois. {"first": la première fois, "coins": les pièces}.
static func record_win(id: StringName) -> Dictionary:
	var a: Dictionary = RevancheBattles.ALPHAS[id]
	var first: bool = Game.flag(known_flag(id)) != true
	Game.set_flag(known_flag(id))
	Game.set_flag(ApexEngine.woken_flag(a["sceau"]))
	Game.give_item("piece", a["coins"])
	return {"first": first, "coins": a["coins"]}


## Combien de Sceaux se sont éveillés (sur sept).
static func woken_count() -> int:
	return RevancheBattles.ALPHAS.values().filter(func(a: Dictionary) -> bool: return ApexEngine.woken(a["sceau"])).size()


## L'objectif « Les revanches » (ApexObjectives.side).
static func objective_text() -> String:
	return DialogueRevanches.objective(woken_count(), RevancheBattles.ALPHAS.size())


static func maia_can() -> bool:
	return open() and int(Game.flag(&"maia_defi_6_jour")) != Game.day


static func isaure_can() -> bool:
	return open() and int(Game.flag(&"isaure_pari_jour")) != Game.day


## Un pari joué : gagné la première fois, la page de la mer ; gagné ensuite, ISAURE_COINS pièces ; perdu, rien (la
## barque). {"first": la première victoire, "coins": les pièces données}.
static func isaure_record(won: bool) -> Dictionary:
	if not won:
		return {"first": false, "coins": 0}
	if Game.flag(&"isaure_pari_gagne") != true:
		Game.set_flag(&"isaure_pari_gagne")
		Game.set_flag(&"carnet_mer")
		return {"first": true, "coins": 0}
	Game.give_item("piece", RevancheBattles.ISAURE_COINS)
	return {"first": false, "coins": RevancheBattles.ISAURE_COINS}


## Ce qu'Hélène dit des Sceaux, une fois, dès le premier éveillé ("" sinon : elle l'a dit, ou rien n'est éveillé).
static func helene_line() -> String:
	if Game.flag(&"helene_sceaux") == true or woken_count() == 0:
		return ""
	Game.set_flag(&"helene_sceaux")
	return DialogueRevanches.HELENE_SCEAUX


# ------------------------------------------------------------------ R2 : un Alpha, « pour voir »

## En entrant dans une zone (Story) : l'Alpha qui n'y est plus depuis son chapitre y revient, après la fin.
static func on_zone(zone: StringName) -> void:
	var w = S.world()
	if not open() or not RESIDENTS.has(zone) or w == null or w.get("region") == null or S.actor(RESIDENT) != null:
		return
	var id: StringName = RESIDENTS[zone][0]
	var a: Dictionary = RevancheBattles.ALPHAS[id]
	var spot: Vector2 = a["spot"]
	var d := DinoNpc.new()
	d.name = RESIDENT
	d.species_id = a["species"]
	d.event = RESIDENTS[zone][1]
	d.size_scale = a["size"]
	d.position = S.at(spot.x, spot.y)
	w.region.entities.add_child(d)


## L'événement d'un Alpha après la fin (son chapitre l'appelle dès `post_game`) : sa ligne d'arrivée, la pensée de
## Chloé, le choix ; le combat ; gagné, sa ligne d'après (la première fois : la pensée, le toast du Sceau) et les
## pièces ; perdu, une bulle. Déjà fait aujourd'hui : une bulle.
static func alpha(id: StringName, who: Node) -> void:
	if not RevancheBattles.ALPHAS.has(id) or Game.party.is_empty() or S.world() == null:
		return
	var title: String = DialogueRevanches.ALPHAS[id]["who"]
	if not can_challenge(id):
		await S.say([{"text": DialogueRevanches.ALPHA_TODAY % title}])
		return
	var actor: Node = await _alpha_actor(id, who)
	var cast := {"alpha": actor, "spawned": not who is DinoNpc}
	S.lock(true)
	var lines: Array = DialogueRevanches.arrival(id, _lead_name())
	lines[0] = CS.cue(lines[0], func() -> void: _greets(cast["alpha"], GREETS.get(id, "cry")))
	await S.say(lines)
	S.lock(false)
	if await Dialogue.choose("", DialogueRevanches.ALPHA_PROMPT % title, DialogueRevanches.ALPHA_OPTIONS) != 0:
		await _dismiss(cast)
		return
	Game.set_flag(day_flag(id), Game.day)
	var result: String = await S.world().call(&"_battle", RevancheBattles.alpha(id), RevancheBattles.alpha_rules(id))
	if result == "win":
		await _alpha_won(id, cast)
	elif result == "lose":
		await S.say([{"text": DialogueRevanches.ALPHA_LOST % title}])
	await _dismiss(cast)
	Save.save_game()


## Gagné : sa ligne d'après ; la première fois, la pensée de Chloé et le toast du Sceau ; les pièces.
static func _alpha_won(id: StringName, cast: Dictionary) -> void:
	var won := record_win(id)
	var lines: Array = [CS.cue({"text": DialogueRevanches.alpha_line(id, "after", _lead_name())},
		func() -> void: _greets(cast["alpha"], "bow"))]
	if won["first"]:
		lines.append({"who": DialogueRevanches.CHLOE, "text": DialogueRevanches.ALPHA_WON_THOUGHT})
	await S.say(lines)
	if won["first"] and S.world():
		Toast.say(S.world().get_tree(), DialogueRevanches.woken_toast(id))
	Audio.play_sfx(COINS_SFX)
	await S.say([{"text": DialogueRevanches.ALPHA_COINS % won["coins"]}])


## L'Alpha de la scène : celui à qui Chloé parle (un DinoNpc), sinon on le fait venir (son « spot », ou à côté de ce
## que Chloé regarde), en fondu. Tourné vers Chloé.
static func _alpha_actor(id: StringName, who: Node) -> Node:
	var actor: Node = who if who is DinoNpc else null
	if actor == null:
		var a: Dictionary = RevancheBattles.ALPHAS[id]
		var spot: Vector2 = a.get("spot", Vector2.INF)
		var at: Vector2 = S.at(spot.x, spot.y) if spot != Vector2.INF else S.ground_near(A.px_of(who) + Vector2(70.0, 0.0), 3)
		actor = A.stand_in(a["species"], at, STAND_IN, a["level"], a["size"])
		if actor:
			await Stage.fade_in(actor, 0.6)
	if actor and Stage.chloe():
		Stage.turn_to(actor, Stage.chloe().global_position)
	return actor


## Son salut : il baisse la tête, se dresse, rugit (le sol tremble un peu), ou crie.
static func _greets(actor, how: String) -> void:
	if actor == null or not is_instance_valid(actor):
		return
	match how:
		"bow":
			Stage.bow(actor, 1.2)
		"rear":
			Stage.rear(actor, 0.9)
		"roar":
			Stage.cry(actor, &"attaque")
			Stage.shake(3.0, 0.5)
			return
	Stage.cry(actor)


## Celui qu'on a fait venir repart (fondu) ; celui qui était là reste.
static func _dismiss(cast: Dictionary) -> void:
	if cast.get("spawned", false):
		await Stage.fade_out(cast.get("alpha"), 0.8, true)


static func _lead_name() -> String:
	var lead := Game.lead_dino()
	return lead.nickname if lead else ""


# ------------------------------------------------------------------ R1 : le défi n° 6 de Maïa

## Après sa réplique au Grand Crâne (ApexAutour.maia) : le choix, ses trois bulles, son équipe, ses mots ; une fois par
## jour (même perdu : « Demain, même heure »).
static func maia(_who: Node) -> void:
	if not maia_can() or Game.party.is_empty() or S.world() == null:
		return
	if await Dialogue.choose("", DialogueRevanches.MAIA_PROMPT, DialogueRevanches.MAIA_OPTIONS) != 0:
		return
	Game.set_flag(&"maia_defi_6_jour", Game.day)
	await S.say(DialogueRevanches.maia_before())
	var won: bool = await S.duel(MAIA, ApexBattles.maia_team(), ApexBattles.MAIA_RULES)
	if won:
		Game.set_flag(&"maia_defi_6")
	await S.say(DialogueRevanches.maia_won() if won else DialogueRevanches.maia_lost())
	Save.save_game()


## Le tableau du Relais (Havre.relais), une fois le défi n° 6 gagné ; "" avant.
static func relais_line() -> String:
	return DialogueRevanches.RELAIS_CRAIE if Game.flag(&"maia_defi_6") == true else ""


# ------------------------------------------------------------------ R3 : le pari d'Isaure

## Après sa réplique à la barque (ApexAutour.isaure) : la première fois, ce qu'elle parie (2 bulles) ; le choix ; ses
## quatre dinos ; gagné, la page de la mer (puis des pièces) ; perdu, la barque à laver. Une fois par jour. True quand
## le pari a été joué (la barque ne part pas ensuite).
static func isaure(who: Node) -> bool:
	if not isaure_can() or Game.party.is_empty() or S.world() == null:
		return false
	if Game.flag(&"isaure_pari_offert") != true:
		Game.set_flag(&"isaure_pari_offert")
		await S.say(DialogueRevanches.isaure_offer())
	if await Dialogue.choose(ISAURE, DialogueRevanches.ISAURE_PROMPT, DialogueRevanches.ISAURE_OPTIONS) != 0:
		return false
	Game.set_flag(&"isaure_pari_jour", Game.day)
	var won: bool = await S.duel(ISAURE, RevancheBattles.isaure_team(), RevancheBattles.isaure_rules())
	var r := isaure_record(won)
	if not won:
		await S.say([{"who": ISAURE, "text": DialogueRevanches.ISAURE_LOST},
			CS.cue({"text": DialogueRevanches.ISAURE_SCRUB}, func() -> void: _scrubs(who)),
			{"who": ISAURE, "text": DialogueRevanches.ISAURE_TOMORROW}])
	elif r["first"]:
		await S.say(DialogueRevanches.isaure_won_first(Game.flag(&"carnet_terre") == true))
	else:
		Audio.play_sfx(COINS_SFX)
		await S.say([{"who": ISAURE, "text": DialogueRevanches.ISAURE_WON_AGAIN}, {"text": "Tu gagnes %d pièces." % r["coins"]}])
	Save.save_game()
	return true


## Chloé frotte le pont : elle se penche, trois fois ; Isaure la regarde faire.
static func _scrubs(isaure_npc) -> void:
	var chloe := Stage.chloe()
	if chloe == null:
		return
	if isaure_npc is Node2D and is_instance_valid(isaure_npc):
		Stage.turn_to(isaure_npc, chloe.global_position)
	for i in SCRUBS:
		await Stage.bow(chloe, 0.5)


# ------------------------------------------------------------------ R4 : Hélène, les Sceaux

## Dès le premier Sceau éveillé, une fois (ApexAutour.helene, avant son pool). True quand elle l'a dit.
static func helene(_who: Node) -> bool:
	var line := helene_line()
	if line == "":
		return false
	await S.say([{"who": HELENE, "text": line}])
	Save.save_game()
	return true
