class_name Story
## The story's scenes: what plays when entering a zone (on_zone_entered), and the scenes
## characters start when Chloé talks to them (run, from Npc.event / DinoNpc.event).
## Each scene checks the story flags, so it resumes correctly after a reload.
## Lines are in DialogueDB when they are plain; here, the choreography around them.

const CELL := 48.0
## Ground someone can stand on (the tiles' "terrain"; see ZoneBuilder.WALKABLE).
const OPEN_GROUND := ["grass", "path", "tall_grass", "sand", "mud", "rock"]
const VOICES := "res://assets/audio/voices/%s.mp3"
const TRAINER_MUSIC := preload("res://assets/audio/music/rivale.ogg")
## The Cabinet's reserve shows at most this many dinos (the latest), so the choice fits on screen.
const RESERVE_SHOWN := 6


## Scenes being played right now (entering a zone, a character, a trigger…): the live demo
## (tools/capture.gd) waits until it is back to 0.
static var playing := 0


static func on_zone_entered(zone: StringName) -> void:
	playing += 1
	await _on_zone_entered(zone)
	playing -= 1


static func _on_zone_entered(zone: StringName) -> void:
	Monts.update_access()   # (the way up to the Monts: end of chapter 5 and a warm coat; old saves too)
	match zone:
		&"port_ambre":
			if not Game.flag(&"prologue_arrived") and not Game.flag(&"prologue_done"):
				await Prologue.arrival()
			else:
				await Plaines.back_to_port()
		&"cabinet":
			await Prologue.cabinet()
			await Plaines.empty_cabinet()
			await ForetFin.cabinet()
			await MaraisSuite.cabinet()
		&"havre_dore":
			await Havre.arrival()
		&"grotte_echos":
			await Grotte.arrival()
		&"foret":
			await Foret.arrival()
		&"camp_ombre":
			await ForetCamp.arrival()
		&"marais":
			await Marais.arrival()
		&"temple_englouti":
			await MaraisTemple.arrival()
		&"desert":
			await Desert.arrival()
		&"sanctuaire_vents":
			await DesertSanctuaire.arrival()
		# Chapter 5, the Côte Préhistorique (story/cote*.gd)
		&"cote":
			await Cote.arrival()
		&"grottes_marines":
			await CoteGrottes.arrival()
		&"recif_sanctuaire":
			await CoteRecif.arrival()
		# Chapter 6, the Monts Gelés (story/monts*.gd)
		&"monts":
			await Monts.arrival()
		&"grottes_glace":
			await MontsGrottes.arrival()
		&"sanctuaire_givre":
			await MontsSanctuaire.arrival()


## The time of day changed while in zone `zone` (a scene that only happens at night…).
static func on_phase_changed(zone: StringName) -> void:
	playing += 1
	await _on_phase_changed(zone)
	playing -= 1


static func _on_phase_changed(zone: StringName) -> void:
	Plaines.morning()
	if zone == &"havre_dore":
		await Havre.night()
	elif zone == &"marais":
		await MaraisSuite.night()   # Roc's lantern in the evening mist (after page 14)
	elif zone == &"desert":
		await Desert.on_phase(zone)   # the dusk scene towards the Côte, if it is still to play
	elif zone == &"cote":
		await Cote.on_phase(zone)   # the first night: the boat without a lantern
	elif zone == &"monts":
		await Monts.on_phase(zone)   # the first night: the forges' red lights (page 30)


## A scene started by talking to someone (`who` = the Npc or DinoNpc).
static func run(event: StringName, who: Node) -> void:
	playing += 1
	await _run(event, who)
	playing -= 1


static func _run(event: StringName, who: Node) -> void:
	match event:
		&"choose_starter":
			await Prologue.choose_starter(who)
		&"roc":
			if await Plaines.roc_denies():
				return
			var healed: bool = await Prologue.talk_roc()
			var said: bool = await PlainesAnnexes.roc()
			said = await ForetFin.roc() or said
			said = await MaraisSuite.roc() or said
			said = await Desert.roc() or said
			said = await Cote.roc() or said
			said = await MontsFin.roc() or said
			said = await _dex_rewards() or said
			if not said and not healed and Game.flag(&"prologue_done"):
				await _roc_chat()
		&"maia":
			await PlainesAnnexes.maia(who)
		&"nid_chipie":
			await PlainesAnnexes.nest(who)
		&"dormeur":
			await PlainesAnnexes.sleeper()
		&"grand_crane":
			await Plaines.grand_crane()
		&"alpha_plaines":
			await Plaines.alpha(who)
		&"maia_defi":
			await Plaines.maia_duel(who)
		&"shop_herboristerie":
			await Havre.shop(&"herboristerie", who)
		&"shop_mercerie":
			await MontsFin.rosalie(who)   # (her warm coat in the window, chapter 6)
			await Havre.shop(&"mercerie", who)
			Monts.update_access()
		&"ferreol":
			await Havre.ferreol()
		&"joss":
			if Game.flag(&"monts_arrivee"):   # chapter 6: Maïa at his place, then the flying harness
				await MontsFin.joss_havre()
			elif Game.flag(&"cote_arrivee"):   # chapter 5: he goes back and forth to the Côte
				await CoteLagon.joss_havre()
			elif Game.flag(&"maia_defi_2"):   # chapter 3: he also has his cabin in the Marais
				await Marais.joss_havre()
			else:
				await Havre.joss()
		&"relais":
			await Havre.relais()
		&"dresseur_gaspard":
			await Havre.trainer(&"gaspard", who)
		&"dresseur_lilou":
			await Havre.trainer(&"lilou", who)
		&"maia_havre":
			if Game.flag(&"maia_alliee"):   # chapter 6: they are a team now
				await MontsFin.maia_havre(who)
				return
			if Game.flag(&"maia_enfuie"):   # chapter 5: she ran away from the lookout
				await CoteFin.maia_havre(who)
				return
			var topics: Array = [&"pieces", &"monter"] if Game.flag(&"selle") else [&"pieces", &"selle", &"monter"]
			await Ask.menu(&"maia", "Maïa", DialogueDB.chatter(&"maia_havre")[0]["text"], topics + Ask.story_topics())
		&"marchande":
			await Ask.menu(&"marchande", "La marchande", DialogueDB.lines(&"marchande")[0]["text"], [&"pieces", &"selle"])
		&"sbire_grotte_1":
			await Grotte.gustave(who)
		&"sbire_grotte_2":
			await Grotte.chef(who)
		&"proto_corrompu":
			await Grotte.proto(who)
		&"entrepot":
			if not await CoteFin.entrepot(who):   # chapter 5: Ferréol, once the cache's crates are read
				await Dialogue.run(DialogueDB.lines(&"entrepot"))
		&"griffe_grise":
			await Foret.griffe_grise(who)
		&"clairiere_vide":
			await Foret.clairiere_vide(who)
		&"sbire_camp_1":
			await ForetCamp.sbire(1, who)
		&"sbire_camp_2":
			await ForetCamp.sbire(2, who)
		&"brac":
			await ForetCamp.brac(who)
		&"utahraptor_cage":
			await ForetCamp.utahraptor(who)
		&"papiers_brac":
			await ForetCamp.papers(who)
		&"masque_passerelle":
			await ForetFin.masque(who)
		&"maia_defi_2":
			await ForetFin.maia_bridge(who)
		&"tiroir_roc":
			await ForetFin.drawer(who)
		# Chapter 3, the Marais Brumeux (story/marais.gd, marais_suite.gd, marais_temple.gd)
		&"joss_marais":
			await Marais.joss(who)
		&"baryonyx_gilet":
			await Marais.baryonyx(who)
		&"voix_du_marais":
			await Marais.voix(who)
		&"dame_suie":
			await MaraisSuite.dame_suie(who)
		&"roc_marais":
			await MaraisSuite.roc_marais(who)
		&"maia_defi_3":
			await MaraisSuite.maia(who)
		&"vanne_1", &"vanne_2", &"vanne_3":
			await MaraisTemple.vanne(int(String(event).right(1)), who)
		&"fresque_1", &"fresque_2", &"fresque_3":
			await MaraisTemple.fresque(int(String(event).right(1)), who)
		&"spinosaure_ancestral":
			await MaraisTemple.spinosaure(who)
		# Chapter 4, the Désert Aride (story/desert.gd, desert_sanctuaire.gd)
		&"sirocco":
			await Desert.sirocco(who)
		&"vieux_rempart":
			await Desert.vieux_rempart(who)
		&"maia_defi_4":
			await Desert.maia(who)
		&"brac_sanctuaire":
			await DesertSanctuaire.brac_sanctuaire(who)
		&"poursuite_1", &"poursuite_2", &"poursuite_3":
			await DesertSanctuaire.poursuite(int(String(event).right(1)), who)
		&"brac_desert":
			await DesertSanctuaire.brac(who)
		&"chariot_brac":
			await DesertSanctuaire.chariot(who)
		&"carnotaurus_rouge":
			await DesertSanctuaire.carnotaurus(who)
		&"porte_vents":
			await DesertSanctuaire.porte_vents(who)
		&"coeur_vents":
			await DesertSanctuaire.coeur(who)
		&"carno_gardien":   # optional: the Carnotaurus by the open door (CARTE-C, see § 7)
			await DesertSanctuaire.gardien(who)
		# Chapter 5, the Côte Préhistorique (story/cote.gd, cote_lagon.gd, cote_grottes.gd, cote_recif.gd, cote_fin.gd)
		&"pecheurs_cote":
			await Cote.pecheurs(who)
		&"maia_falaises":
			await Cote.maia_falaises(who)
		&"joss_cote":
			if not await MontsFin.joss_coat(who):   # (chapter 6: the warm coats Rosalie gave him to sell)
				await CoteLagon.joss(who)
		&"nid_tortues":
			await CoteLagon.tortues(who)
		&"cache_arrivee":
			await CoteGrottes.cache_arrivee(who)
		&"passeur":
			await CoteGrottes.passeur(who)
		&"cache_contrebande":
			await CoteGrottes.caisses(who)
		&"barque_isaure":
			await CoteGrottes.barque(who)
		&"mosasaure_abyssal":
			await CoteRecif.mosasaure(who)
		&"coeur_recif":
			await CoteRecif.coeur(who)
		&"maia_guet":
			await CoteFin.maia(who)
		&"boite_helene":
			await CoteFin.boite(who)
		# Chapter 6, the Monts Gelés (story/monts.gd, monts_grottes.gd, monts_col.gd, monts_sanctuaire.gd, monts_fin.gd)
		&"bertille":
			await Monts.bertille(who)
		&"grelot":
			await Monts.grelot(who)
		&"glacier_arrivee":
			await Monts.glacier(who)
		&"grottes_glace_reserve":
			await MontsGrottes.reserve_seen(who)
		&"dame_suie_monts", &"suie_monts":
			await MontsGrottes.dame_suie(who)
		&"dormeurs":
			await MontsGrottes.dormeurs(who)
		&"oeufs_glace":
			await MontsGrottes.oeufs(who)
		&"traineau_suie":
			await MontsGrottes.traineau(who)
		&"roc_col", &"blizzard_col":
			await MontsCol.roc_col(who)
		&"porte_givre":
			await MontsCol.porte_givre(who)
		&"cryolophosaure_titan", &"titan_givre":
			await MontsSanctuaire.titan(who)
		&"coeur_givre":
			await MontsSanctuaire.coeur(who)
		&"maia_monts":
			await MontsFin.maia(who)
		_:
			push_error("Scène inconnue : %s" % event)


## Roc when he has nothing new to say: a line (the objective as advice, sometimes), then the
## questions of the moment (Ask.story_topics) and the Cabinet's reserve, when there is one.
static func _roc_chat() -> void:
	var line: Array = DialogueDB.chatter(&"roc")
	var topics: Array = Ask.story_topics()
	var action := "La réserve du Cabinet" if not Game.box.is_empty() else ""
	if topics.is_empty() and action == "":
		await Dialogue.run(line)
		return
	if await Ask.menu(&"roc", "Prof. Roc", line[0]["text"], topics, action):
		await reserve()


## Roc looks at the Dinodex: its rewards not given yet (DexDB.pending_rewards). True if any.
static func _dex_rewards() -> bool:
	if not Game.flag(&"prologue_done"):
		return false
	var rewards := DexDB.pending_rewards()
	for r in rewards:
		for id: String in r["items"]:
			Game.give_item(id, r["items"][id])
		Game.set_flag(r["flag"])
		await say([{"who": "Prof. Roc", "text": r["text"]}, {"text": "Tu reçois : %s." % r["gift"]}])
	if not rewards.is_empty():
		Save.save_game()
	return not rewards.is_empty()


## The Cabinet's reserve (Game.box, the dinos caught while the party was full): one of them
## joins the party; when it is full, one of the party waits at the Cabinet in its place.
static func reserve() -> void:
	var shown: Array = Game.box.slice(maxi(0, Game.box.size() - RESERVE_SHOWN))
	var names: Array = shown.map(func(d: Dino) -> String: return "%s (niv. %d)" % [d.nickname, d.level])
	names.append("Personne")
	var pick := await Dialogue.choose("Prof. Roc", "Qui veux-tu emmener ? Les autres m'aident à ranger. Enfin, à déranger.", names)
	if pick < 0 or pick >= shown.size():
		return
	var incoming: Dino = shown[pick]
	var leaving: Dino = null
	if Game.party.size() >= Game.PARTY_MAX:
		var party_names: Array = Game.party.map(func(d: Dino) -> String: return "%s (niv. %d)" % [d.nickname, d.level])
		party_names.append("Personne")
		var out := await Dialogue.choose("Prof. Roc", "Ton équipe est pleine. Qui reste au Cabinet à sa place ?", party_names)
		if out < 0 or out >= Game.party.size():
			return
		leaving = Game.party[out]
		Game.party[out] = incoming
		Game.box[Game.box.find(incoming)] = leaving
	else:
		Game.box.erase(incoming)
		Game.party.append(incoming)
	Game.party_changed.emit()
	var text := "%s rejoint ton équipe !" % incoming.nickname
	if leaving:
		text += " %s reste au Cabinet, avec Roc." % leaving.nickname
	await say([{"text": text}])
	Save.save_game()


# ------------------------------------------------------------------ helpers for scenes

## The exploration screen (world.gd), untyped for its player, companion, region.
static func world():
	return Engine.get_main_loop().current_scene


## A character or dino of the current zone, by node name (null when absent). Untyped, so
## scenes can call its own methods (walk_to, face, cry…).
static func actor(node_name: String):
	var w = world()
	if w == null or w.get("region") == null:
		return null
	return w.region.entities.get_node_or_null(node_name)


static func at(x: float, y: float) -> Vector2:
	return Vector2(x, y) * CELL


## Takes control away from the player during a scene (or gives it back).
static func lock(on: bool) -> void:
	var w = world()
	if w and w.get("player"):
		if on:
			w.dismount()   # a scene plays: Chloé on her feet
		w.player.busy = on
		w.player.velocity = Vector2.ZERO
		if not on:   # the scene is over: the camera comes back to her (Stage.look_at)
			var view: Node = w.get_tree().get_first_node_in_group(&"world_view")
			if view:
				view.set("focus_px", Vector2.INF)


static func say(steps: Array) -> void:
	await Dialogue.run(steps)


static func voice(id: String) -> Dictionary:
	return {"voice": VOICES % id}


static func wait(seconds: float) -> void:
	await Engine.get_main_loop().create_timer(seconds).timeout


## A battle against a trainer (a henchman, Maïa, a trainer of the Relais, Brac): their dinos one
## after the other, [species, level, name?, options?] each; no collar, no running away.
## `options`: "corrupted" (fed black amber: it cannot be beaten, only calmed with Apaiser, and
## "calmed" then counts as a win), "before" (lines said before it comes out), "intro" (the
## battle's first line), "lesson" (lines after it), "long_calm", "music", "size" (BattleScene.run).
## `rules`: added to every battle's rules ("music", "lose_spawn"…).
## True if Chloé beats them all (on a defeat, the world has already taken her back to the
## zone's entry, or to `rules["lose_spawn"]`).
static func duel(trainer: String, team: Array, rules := {}) -> bool:
	var w = world()
	if w == null or Game.party.is_empty():
		return false
	for member: Array in team:
		var options: Dictionary = member[3] if member.size() > 3 else {}
		var foe := Dino.create(member[0], member[1], member[2] if member.size() > 2 else "")
		var corrupted: bool = options.get("corrupted", false)
		foe.corrupted = corrupted
		if options.has("before"):
			await say(options["before"])
		var battle := {"catch": false, "run": false, "music": TRAINER_MUSIC, "trainer": trainer,
			"intro": "%s envoie %s !" % [trainer, foe.nickname]}
		battle.merge(rules, true)
		for key: String in ["intro", "lesson", "long_calm", "music", "size"]:
			if options.has(key):
				battle[key] = options[key]
		var result: String = await w.call(&"_battle", foe, battle)
		if result != "win" and not (corrupted and result == "calmed"):
			return false
	return true


## Where someone a scene brings next to Chloé can stand: the open ground nearest to `px`
## (not water, not woods), at the height of Chloé's tile (not on a cliff above her), within
## a few tiles; `px` itself when there is none.
static func ground_near(px: Vector2, max_tiles := 6) -> Vector2:
	var w = world()
	if w == null or w.get("region") == null:
		return px
	var region: Region = w.region
	var mine: float = region.tile_height(Vector2i((w.player.global_position / CELL).floor()))
	var start := Vector2i((px / CELL).floor())
	for r in max_tiles + 1:
		var best := Vector2.INF
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var c := start + Vector2i(dx, dy)
				var data := region.terrain.get_cell_tile_data(c)
				if data == null or not String(data.get_custom_data("terrain")) in OPEN_GROUND:
					continue
				if absf(region.tile_height(c) - mine) > 0.3:
					continue
				var p := (Vector2(c) + Vector2(0.5, 0.5)) * CELL
				if best == Vector2.INF or p.distance_to(px) < best.distance_to(px):
					best = p
		if best != Vector2.INF:
			return best
	return px


## The name each character's lines are signed with, by picture (so that a character a scene
## brings along faces whoever it talks to: the dialogue box finds it by that name).
const SPEAKERS := {"roc": "Prof. Roc", "maia": "Maïa", "isaure": "Isaure", "brac": "Brac", "joss": "Joss",
	"dame_suie": "Dame Suie", "masque": "Le Masque", "ferreol": "Maître Ferréol", "tante_sirocco": "Tante Sirocco",
	"bertille": "Bertille"}


## A character only a scene needs (a passer-by, someone at night): added to the zone, not
## to be talked to. `display`: the name its lines are signed with (else SPEAKERS).
static func stranger(node_name: String, sheet: String, at_px: Vector2, facing := "down", display := "") -> Npc:
	var w = world()
	var n: Npc = load("res://actors/npc.tscn").instantiate()
	n.name = node_name
	n.sheet = load("res://assets/art/characters/%s.png" % sheet)
	n.display_name = display if display != "" else SPEAKERS.get(sheet, "")
	n.facing = facing
	n.position = at_px
	w.region.entities.add_child(n)
	n.remove_from_group(&"interactable")
	return n


## Fades the screen out and back in around `between` (a Callable, may be a coroutine).
static func fade_through(between: Callable, time := 0.6) -> void:
	await Router.fade_out(time)
	await between.call()
	await Router.fade_in(time)
