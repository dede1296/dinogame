class_name Voyage
## Fast travel (docs/histoire.md « Le Grand Voyageur »): old Brachiosaures walk the island's
## oldest paths, one waiting at each stop (STOPS: a « GrandVoyageur » DinoNpc, event
## &"grand_voyageur", and a « Voyageur » spawn point in every region). Chloé talks to one, the
## stop is noted for good, and she picks another stop she has already found: the dino carries
## her there on its back (the region's own arrival scene plays as usual on the way in).
## The very first one she meets sneezes on her (docs/histoire.md « Clins d'œil »).
## Flags: voyageur_rencontre, escale_<region> (see STOPS), roc_voyageur.

const S := preload("res://story/story.gd")
const CHLOE := "Chloé"
const ROC := "Prof. Roc"
## The sneeze and the heavy steps (the cries' families, see assets/audio/cries).
const CRY := "res://assets/audio/cries/sauropode-%s.mp3"
const RUMBLE := "res://assets/audio/sfx/rock_heavy.wav"
## How long the ride lasts, in game minutes: enough to see the light change on a long trip.
const RIDE_MINUTES := 90.0
const XP_FIRST := 20

## Every stop, in the island's order: its zone, the flag set once Chloé has found it, the
## region's name (AtlasDB) and what one sees from its stop (shown in the list, VoyageScreen).
const STOPS := [
	{"zone": &"port_ambre", "flag": &"escale_port", "region": "Port-Ambre", "sight": "Les toits du village et la mer."},
	{"zone": &"plaines", "flag": &"escale_plaines", "region": "Prairie du Grand Crâne", "sight": "Les hautes herbes, et le crâne au loin."},
	{"zone": &"havre_dore", "flag": &"escale_havre", "region": "Havre-Doré", "sight": "Le marché, le port, les lanternes."},
	{"zone": &"foret", "flag": &"escale_foret", "region": "Forêt Jurassique", "sight": "Les troncs immenses et la prairie des siens."},
	{"zone": &"marais", "flag": &"escale_marais", "region": "Marais Brumeux", "sight": "Les roseaux, les pontons, la brume."},
	{"zone": &"desert", "flag": &"escale_desert", "region": "Désert Aride", "sight": "Les canyons rouges et l'oasis."},
	{"zone": &"cote", "flag": &"escale_cote", "region": "Côte Préhistorique", "sight": "Les plages, le lagon, les falaises."},
	{"zone": &"monts", "flag": &"escale_monts", "region": "Monts Gelés", "sight": "La neige, et le glacier au-dessus."},
]


## Talking to a Grand Voyageur: its stop is noted, then Chloé picks where to go.
static func talk(who: Node) -> void:
	var stop := stop_of(zone_now())
	if stop.is_empty():
		return
	S.lock(true)
	if not Game.flag(&"voyageur_rencontre"):
		await _first_meeting(who)
		Game.set_flag(&"voyageur_rencontre")
		Game.award_team_xp(XP_FIRST)
	if not Game.flag(stop["flag"]):
		Game.set_flag(stop["flag"])
		await S.say([{"text": "Chloé note l'escale sur sa carte : le Grand Voyageur passe par ici."}])
	var found := _found()
	if found.size() < 2:
		await S.say([
			{"who": CHLOE, "text": "(Il attend. Il attendrait des jours, je crois.)"},
			{"who": CHLOE, "text": "(Quand je connaîtrai une autre escale, il m'y emmènera.)"},
		])
		S.lock(false)
		return
	var rows := []
	for s: Dictionary in found:
		rows.append([s["zone"], s["region"], s["sight"]])
	var goes: StringName = await VoyageScreen.ask(S.world(), rows, zone_now())
	if goes == &"":
		await S.say([{"text": "Le Grand Voyageur repose son cou dans l'herbe. Il a tout son temps."}])
		S.lock(false)
		return
	await _ride(who, goes)


## The first one she ever meets: it leans down to smell her… and sneezes.
static func _first_meeting(who: Node) -> void:
	var chloe := Stage.chloe()
	var leans := func() -> void:
		if who and is_instance_valid(who):
			Stage.turn_to(who, chloe.global_position)
			Stage.close_up(who.global_position, 7.0, 1.2)
	var sniffs := func() -> void:
		if who and is_instance_valid(who):
			Stage.lunge(who, chloe.global_position, 0.5, false)
	var sneezes := func() -> void:
		Audio.play_sfx(load(CRY % "attaque"), -2.0, 0.04, 0.7)
		Stage.shake(5.0, 0.5)
		Stage.recoil(chloe, who.global_position if who and is_instance_valid(who) else chloe.global_position, 22.0)
	var kneels := func() -> void:
		Stage.wide()
		if who and is_instance_valid(who):
			Stage.bow(who, 1.2)
	await S.say([
		_cue({"text": "Une ombre passe sur Chloé. Très haut au-dessus d'elle, un cou descend, lentement, comme une branche qui plie."}, leans),
		_cue({"text": "Une tête plus grande que Chloé s'arrête à deux pas. Elle renifle son chapeau, son sac, ses cheveux."}, sniffs),
		{"who": CHLOE, "text": "(Bonjour, toi. Tu es… tu es vraiment très grand.)"},
		_cue({"text": "Le Brachiosaure prend une longue inspiration. Une TRÈS longue inspiration."}, func() -> void: Stage.emote(chloe, "!")),
		_cue({"text": "« ATCHOUM ! »"}, sneezes),
		{"who": CHLOE, "text": "(…)"},
		{"who": CHLOE, "text": "(Je suis trempée. De la tête aux pieds. Merci beaucoup.)"},
		_cue({"text": "Il a l'air très content de lui. Puis il plie les pattes avant et baisse son cou jusqu'au sol, comme une passerelle."}, kneels),
		{"who": CHLOE, "text": "(… Tu veux que je monte ? C'est une invitation, ça ?)"},
		{"text": "C'est un Grand Voyageur. Les vieux de l'île disent qu'ils suivent les mêmes chemins depuis toujours, d'une escale à l'autre, sans jamais se presser."},
		{"text": "Hélène le savait. Sur sa carte, chaque escale porte une petite fougère."},
	])


## Chloé climbs on its back and it walks her to the stop of `zone`.
static func _ride(who: Node, zone: StringName) -> void:
	var stop := stop_of(zone)
	var chloe := Stage.chloe()
	var climbs := func() -> void:
		if who and is_instance_valid(who):
			Stage.bow(who, 1.4)
		Stage.hop(chloe, 1, 14.0)
	await S.say([
		_cue({"text": "Le Grand Voyageur s'agenouille. Chloé grimpe le long de son cou et s'assied tout en haut, entre ses épaules."}, climbs),
		_cue({"text": "Il se relève. L'île entière tient d'un coup dans un seul regard."}, func() -> void:
			Audio.play_sfx(load(RUMBLE), -8.0, 0.05, 0.6)
			Stage.shake(2.5, 0.6)),
	])
	Game.pass_minutes(RIDE_MINUTES)
	var w = S.world()
	if w == null:
		S.lock(false)
		return
	await w.goto_zone(zone, &"Voyageur")
	await S.say([{"text": "Le Grand Voyageur s'arrête et baisse le cou. %s Chloé saute dans l'herbe." % stop.get("sight", "")}])
	Save.save_game()
	S.lock(false)


## Roc, once Chloé has met her first Grand Voyageur: what they are, and that Hélène rode them.
## True when he said it (Story._run &"roc" chains the scenes that have something to say).
static func roc() -> bool:
	if not Game.flag(&"voyageur_rencontre") or Game.flag(&"roc_voyageur"):
		return false
	var prof = S.actor("Roc")
	if prof is Node2D:
		Stage.turn_to(prof, Stage.chloe().global_position)
	await S.say([
		{"who": ROC, "text": "Tu sens le Brachiosaure, Chloé. Non, ce n'est pas un reproche. C'est une odeur d'herbe mâchée, très honnête."},
		{"who": CHLOE, "text": "Il m'a éternué dessus."},
		{"who": ROC, "text": "Ah ! Alors il t'a adoptée. Ce sont les Grands Voyageurs. De vieux Brachiosaures qui font le tour de l'île depuis… depuis plus longtemps que l'île n'a de nom, je crois."},
		{"who": ROC, "text": "Ils s'arrêtent toujours aux mêmes endroits. Les escales. Monte sur le dos de l'un d'eux, dis-lui une escale que tu as déjà vue, et il t'y portera. Sans se presser, remarque."},
		{"who": ROC, "text": "Ta grand-mère a fini par ne plus voyager autrement. Elle disait que c'était la seule façon de voir l'île en entier… et la seule où on ne peut pas se perdre."},
		{"who": CHLOE, "text": "(Les petites fougères gravées sur sa carte. C'était ça.)"},
		{"flag": &"roc_voyageur"},
	])
	return true


## The stops Chloé has found (in the island's order), Chloé's own included.
static func _found() -> Array:
	var out := []
	for stop: Dictionary in STOPS:
		if Game.flag(stop["flag"]):
			out.append(stop)
	return out


## The stop of a zone (empty when that zone has none).
static func stop_of(zone: StringName) -> Dictionary:
	for stop: Dictionary in STOPS:
		if stop["zone"] == zone:
			return stop
	return {}


static func zone_now() -> StringName:
	var w = S.world()
	return w.region.region_id if w and w.get("region") else &""


## A line whose move starts the moment it shows (see Desert._cue).
static func _cue(line: Dictionary, action: Callable) -> Dictionary:
	var text: String = line["text"]
	var cued := line.duplicate()
	cued.erase("text")
	cued["text_fn"] = func() -> String:
		action.call_deferred()
		return text
	return cued
