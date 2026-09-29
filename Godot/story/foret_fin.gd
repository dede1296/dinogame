class_name ForetFin
## Chapter 2, the Forêt Jurassique, the end of step 2 (docs/histoire.md, ch. 2, points 5 and 6),
## after the camp (story/foret_camp.gd): the Obsidian Mask on a walkway of the Haute futaie
## (it does not fight; it knew Hélène); Maïa's second challenge at the bridge to the Marais,
## whose ropes were cut (she ties it back up and goes first); back at the Cabinet, Roc and the
## lost hatchling, then black amber in his « broken » drawer (false lead 2).
## Staged (story/stage.gd, story/foret_gestes.gd): each description bubble is acted out as it
## shows — the camera goes up to the Masque, his compass lights his hands, the mist takes him;
## Maïa points at the cut span, ties it up and goes first; Roc wipes his glasses and sinks into
## his armchair; the little one peeks, then curls up by the incubator; the lead sniffs the
## drawer; the black amber glows violet until Roc slams it shut.
## Flags: masque_en_vue, masque_vu, maia_pont_vue, maia_defi_2, roc_oeuf_retrouve,
## roc_sceau_foret, tiroir_flaire, ambre_noir_tiroir; tiroir_n (lines).

const S := preload("res://story/story.gd")
const GESTES := preload("res://story/foret_gestes.gd")
const CHLOE := "Chloé"
const MAIA := "Maïa"
const ROC := "Prof. Roc"
const MASQUE := "Le Masque"
const OMBRE_MUSIC := "res://assets/audio/music/ombre.ogg"
const MASQUE_SHEET := "res://assets/art/characters/masque.png"
const LATCH := preload("res://assets/audio/sfx/latch.wav")
const LEAVES := preload("res://assets/audio/sfx/feuillage.mp3")
## By the bridge to the Marais: after a lost challenge, Maïa is right there.
const BRIDGE_SPAWN := &"DepuisMarais"
## The Forêt: the walkway between two giant trees on the Haute futaie (tools/zones/foret.gd
## MASQUE_AT: where the Masque stands when the zone has no Npc for it),
## which way it leaves (tiles), and where Maïa goes (across the bridge, west).
const MASQUE_SPOT := Vector2(56.5, 74.75)
const MASQUE_AWAY := Vector2(-6.0, -1.5)
const MAIA_AWAY := Vector2(0.4, 12.0)
## Where the camera looks while the Masque is there: from him towards Chloé (0: on him), so
## that both are in the picture.
const MASQUE_FRAME := 0.35
## His compass (Isaure's, docs/histoire.md): the warm light it gives when he opens it.
const COMPASS_LIGHT := Color(1.0, 0.72, 0.32)
## The mist of the futaie that takes him away: a veil over the screen, at its thickest.
const MIST := Color(0.84, 0.88, 0.86, 0.85)
## Far off towards the north-west, where the branches crack (px from Chloé).
const NORTH_WEST := Vector2(-160.0, -120.0)
## The bridge to the Marais (tools/zones/foret.gd MARAIS_BRIDGE: x 1-6, y 11-13): its last
## span, the one whose ropes were cut, where Maïa kneels to tie it up (tiles).
const BRIDGE_END := Vector2(1.9, 12.0)
## The Cabinet (tools/zones/cabinet.gd): the drawer at the desk's left end, where Roc sits
## (just in front of his armchair), where the little one curls up (in front of the incubator)
## and the way to it between the pedestals (tiles).
const DRAWER_AT := Vector2(4.35, 3.4)
const ARMCHAIR_SEAT := Vector2(9.4, 3.65)
const INCUBATOR_FRONT := Vector2(13.8, 4.15)
const INCUBATOR_WAY := Vector2(13.05, 7.6)
## Black amber: its violet veins.
const BLACK_AMBER := Color(0.62, 0.3, 1.0)
## Roc's cheeks, all red.
const BLUSH := Color(1.3, 0.8, 0.76)
## Maïa's second challenge: Caillou, Moustique the Dimorphodon, then her own hatchling.
const MAIA_LEVELS := {"caillou": 15, "moustique": 15, "starter": 16}
const XP_MASQUE := 30
const XP_MAIA := 70
const XP_TIROIR := 20
const DRAWER_BEFORE := [
	"Le bureau de Roc. Le tiroir de gauche est fermé. « Cassé », dit Roc.",
	"Chloé effleure la poignée du tiroir. Derrière elle, Roc toussote très fort.",
	"Le tiroir de gauche. Roc a collé dessus une étiquette : « CASSÉ. NE PAS TOUCHER. MERCI. »",
]
const DRAWER_AFTER := [
	"Le tiroir de gauche. Sa serrure brille, toute neuve. Roc l'a changée.",
	"Le tiroir ne bouge pas d'un millimètre. Roc fait semblant de lire, le livre à l'envers.",
	"(Pourquoi les garde-t-il, ces pierres noires ?)",
]


# ------------------------------------------------------------------ the Masque

## On the walkway of the Haute futaie (a StoryTrigger, once the Sceau is Chloé's): the
## Obsidian Mask. It does not fight; it knew Hélène. Then it is gone, towards the north-west.
static func masque(_trigger: Node) -> void:
	if Game.flag(&"masque_vu") or not Game.flag(&"sceau_foret"):
		return
	var w = S.world()
	if w == null:
		return
	S.lock(true)
	Game.set_flag(&"masque_en_vue")
	var theme: AudioStream = ForetCamp.music_at(OMBRE_MUSIC)
	if theme:
		Audio.push_music(theme, 1.2)
	Audio.play_sfx(LEAVES, -8.0)
	var mask = _masque_npc()
	var chloe: Player = w.player
	var frame: Vector2 = (mask as Node2D).global_position.lerp(chloe.global_position, MASQUE_FRAME)
	await S.say([GESTES.cue("Crac. Juste au-dessus du sentier, une planche de la passerelle a grincé. Puis plus rien. Même les oiseaux se sont tus.",
		func() -> void: _creak(chloe, mask, frame))])
	Stage.look_at(frame, 0.0)
	chloe.face_towards(mask.global_position)
	await Stage.fade_in(mask, 0.9)
	var lines: Array = [{"text": "Sur la passerelle, entre les deux arbres géants, quelqu'un la regarde. Une longue cape sombre qui tombe jusqu'aux planches. Et à la place du visage, un masque noir, lisse et brillant comme du verre."}]
	var lead := Game.lead_dino()
	if lead:
		lines.append(GESTES.cue("%s gronde tout bas, sans quitter la silhouette des yeux." % lead.nickname,
			func() -> void: _growl_at(mask)))
	lines.append_array([
		{"who": CHLOE, "text": "(Un masque d'obsidienne… Le Masque.)"},
		{"who": MASQUE, "text": "Alors c'est toi."},
		{"text": "La voix est grave, étouffée par le masque. Impossible de dire à qui elle appartient."},
		{"who": MASQUE, "text": "En une seule journée, tu as pris à Brac son Alpha, son champion et ses clés. Il ne s'en remettra pas. Brac ne s'est jamais remis de rien."},
		{"who": CHLOE, "text": "C'est vous qui avez volé le troisième petit ! Au Cabinet, la nuit où je suis arrivée."},
		GESTES.cue("Le Masque ne répond pas. Il sort de sa cape un petit boîtier rond qui brille, l'ouvre, le regarde, et le referme d'un coup sec.",
			func() -> void: _compass(mask)),
		{"who": CHLOE, "text": "Où est ma grand-mère ?"},
		GESTES.cue("Un long silence. Le vent fait claquer la cape.", func() -> void: _cape_flaps(mask)),
		{"who": MASQUE, "text": "Personne ne le sait. … Pas même moi."},
		{"who": MASQUE, "text": "Tu as les yeux de ta grand-mère. Ne fais pas les mêmes erreurs qu'elle."},
		{"who": CHLOE, "text": "Quelles erreurs ?! Vous la connaissiez ?"},
		{"who": MASQUE, "text": "Rentre chez toi, Chloé. Il y a des barques pour le continent. Tu as une barque trop petite et un courage trop grand : ça finit toujours mal."},
	])
	await S.say(lines)
	var after: Array = [
		GESTES.cue("La brume de la futaie monte autour de la passerelle… et quand elle retombe, il n'y a plus personne. Juste, au loin, un craquement de branches, vers le nord-ouest.",
			func() -> void: _masque_leaves(mask, chloe)),
	]
	var thoughts: Array = []
	if Game.flag(&"found_journal_3"):
		thoughts.append("(« Une barque trop petite et un courage trop grand »… Où est-ce que j'ai déjà lu ça ?)")
	thoughts.append_array([
		"(« Ne fais pas les mêmes erreurs qu'elle »… Il la connaissait. Assez pour savoir lesquelles.)",
		"(Le nord-ouest… Le vieux pont du Marais.)",
	])
	after.append(GESTES.cue(thoughts[0], func() -> void: GESTES.look_back(), CHLOE))
	for thought: String in thoughts.slice(1):
		after.append({"who": CHLOE, "text": thought})
	after.append({"flag": &"masque_vu"})
	await S.say(after)
	if is_instance_valid(mask):   # (the lines went by before the mist took him)
		mask.queue_free()
	if theme:
		Audio.pop_music(1.5)
	Game.award_team_xp(XP_MASQUE)
	Save.save_game()
	S.lock(false)


## The Masque on the walkway: the zone's own Npc when it is there, else one made here (a
## henchman's sheet, darkened, when its own is missing). Starts invisible: the scene fades it in.
static func _masque_npc():
	var mask = S.actor("Masque")
	if mask == null:
		var own := ResourceLoader.exists(MASQUE_SHEET)
		mask = S.stranger("Masque", "masque" if own else "sbire", S.at(MASQUE_SPOT.x, MASQUE_SPOT.y), "down", MASQUE)
		if not own:
			mask.sprite.modulate = Color(0.3, 0.26, 0.4)
	mask.remove_from_group(&"interactable")
	mask.modulate.a = 0.0
	return mask


## A plank creaks over the trail: Chloé starts and looks up at the walkway, and the camera
## goes up with her eyes (the walkway still empty).
static func _creak(chloe: Player, mask, frame: Vector2) -> void:
	if is_instance_valid(mask):
		Stage.turn_to(chloe, (mask as Node2D).global_position)
	Stage.emote(chloe, "!")
	await S.wait(0.9)
	if GESTES.in_scene():
		Stage.look_at(frame, 0.0)


## Chloé's dino growls low at the silhouette: it turns to it, its snout forward.
static func _growl_at(mask) -> void:
	var w = S.world()
	var companion = w.get("companion") if w else null
	if companion == null or not is_instance_valid(mask):
		return
	Stage.turn_to(companion, (mask as Node2D).global_position)
	Stage.cry(companion)
	await GESTES.lean(companion, (mask as Node2D).global_position, 6.0, 1.4)


## He takes out a small round box that shines (the compass), opens it — its warm light on his
## hands —, bends over it, and snaps it shut.
static func _compass(mask) -> void:
	await S.wait(0.7)
	if not is_instance_valid(mask):
		return
	var light := Stage.light_at((mask as Node2D).global_position + Vector2(0.0, 8.0), COMPASS_LIGHT, 2.4)
	if light == null:
		return
	var t := light.create_tween()
	t.tween_property(light, "light_energy", 3.2, 0.35).set_trans(Tween.TRANS_SINE)
	Stage.bow(mask, 2.2)
	await S.wait(2.4)
	Audio.play_sfx(LATCH, -6.0)
	if is_instance_valid(light):
		light.queue_free()


## The wind makes the cape flap: its picture billows out and back, with a gust in the leaves.
static func _cape_flaps(mask) -> void:
	var sprite := Stage.sprite_of(mask)
	if sprite == null:
		return
	if not sprite.has_meta(&"stage_scale"):
		sprite.set_meta(&"stage_scale", sprite.scale)
	var full: Vector2 = sprite.get_meta(&"stage_scale")
	Audio.play_sfx(LEAVES, -9.0)
	var t := sprite.create_tween()
	for i in 4:
		t.tween_property(sprite, "scale", full * Vector2(1.08, 0.99), 0.13).set_trans(Tween.TRANS_SINE)
		t.tween_property(sprite, "scale", full * Vector2(0.97, 1.0), 0.17).set_trans(Tween.TRANS_SINE)
	t.tween_property(sprite, "scale", full, 0.25)


## The mist of the futaie rises round the walkway (a veil over the screen) and takes the Masque;
## it falls again on an empty walkway; far off, branches crack towards the north-west, where
## Chloé and her dino turn.
static func _masque_leaves(mask, chloe: Player) -> void:
	var veil := _veil(MIST)
	if veil == null:
		return
	var rise := veil.create_tween()
	rise.tween_property(veil, "color:a", MIST.a, 1.5).set_trans(Tween.TRANS_SINE)
	if is_instance_valid(mask):
		mask.walk_to((mask as Node2D).global_position + MASQUE_AWAY * S.CELL * 0.3, "left", 80.0)
		Stage.fade_out(mask, 1.3, true)
	await S.wait(2.1)
	if is_instance_valid(veil):
		var fall := veil.create_tween()
		fall.tween_property(veil, "color:a", 0.0, 1.8).set_trans(Tween.TRANS_SINE)
		fall.tween_callback(veil.get_parent().queue_free)
	await S.wait(2.0)
	Audio.play_sfx(LEAVES, -13.0)
	if is_instance_valid(chloe):
		Stage.turn_to(chloe, chloe.global_position + NORTH_WEST)
		var w = S.world()
		var companion = w.get("companion") if w else null
		if companion:
			Stage.turn_to(companion, chloe.global_position + NORTH_WEST)


## A coloured veil over the whole screen, clear (alpha 0) to begin with, under the dialogue
## box, gone with the exploration screen. Null without it.
static func _veil(colour: Color) -> ColorRect:
	var w = S.world()
	if w == null:
		return null
	var layer := CanvasLayer.new()
	layer.layer = 40
	var rect := ColorRect.new()
	rect.color = Color(colour, 0.0)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(rect)
	(w as Node).add_child(layer)
	return rect


# ------------------------------------------------------------------ Maïa at the bridge

## Maïa at the bridge to the Marais (its last span's ropes cut): she saw the Masque too,
## « trop stylé »; her second challenge; then she ties the bridge back up and goes first.
static func maia_bridge(who: Node) -> void:
	if Game.flag(&"maia_defi_2"):
		return
	var first: bool = not Game.flag(&"maia_pont_vue")
	if first:
		S.lock(true)
		var cast := {"maia": who}
		await S.say(_maia_hello(cast))
		await _little_back(cast)
		Game.set_flag(&"maia_pont_vue")
		S.lock(false)
	var prompt := "Trois dinos chacune, cette fois. Et je te préviens : Moustique pique." if first \
		else "Alors, ce défi ? Moustique s'impatiente. Et quand il s'impatiente, il pique."
	var pick := await Dialogue.choose(MAIA, prompt, ["Relever le défi", "Plus tard"])
	if pick != 0:
		await S.say([{"who": MAIA, "text": "Je t'attends ici. De toute façon, sans moi, personne ne répare ce pont."}])
		return
	if not await S.duel(MAIA, _maia_team(), {"lose_spawn": BRIDGE_SPAWN}):
		await S.say([GESTES.cue("HA ! Qui c'est, la championne ? … Soigne ton équipe et reviens : je garde le pont.",
			func() -> void: Stage.hop(S.actor("MaiaPont"), 3, 10.0), MAIA)])
		return
	await _maia_beaten(who)


## `cast`: who plays in it (« maia »; « little », the hatchling shown to her, to give back).
static func _maia_hello(cast: Dictionary) -> Array:
	var maia = cast.get("maia")
	var span := S.at(BRIDGE_END.x, BRIDGE_END.y)
	var lines: Array = []
	if Game.flag(&"masque_vu"):
		lines = [
			GESTES.cue("CHLOÉ ! Tu l'as vu ? Dis-moi que tu l'as vu !", func() -> void: Stage.hop(maia, 3, 10.0), MAIA),
			{"who": CHLOE, "text": "Le Masque ? Sur la passerelle de la haute futaie…"},
			GESTES.cue("Il est passé ICI ! Juste là, au bout du pont ! Il a sauté par-dessus l'eau, là où les planches manquent, comme si de rien n'était. La cape qui claque, le masque tout noir qui brille comme du verre…",
				func() -> void: _points_at(maia, span), MAIA),
			GESTES.cue("TROP STYLÉ.", func() -> void: _cheers(maia), MAIA),
			{"who": CHLOE, "text": "Maïa. C'est lui qui a fait enfermer le chef de la meute. Et c'est lui qui a volé le troisième petit du Cabinet."},
			{"who": MAIA, "text": "Oui, bon, c'est un méchant. Mais un méchant STYLÉ. Ce n'est pas pareil."},
			{"who": MAIA, "text": "… Il m'a regardée, tu sais. Une seconde. Il s'est arrêté, comme s'il allait me dire quelque chose. Et puis non."},
		]
	else:
		lines = [
			GESTES.cue("Chloé ! Tu as vu, là-haut, sur la passerelle entre les deux arbres géants, au bord de la haute futaie ? Quelqu'un avec une grande cape et un masque tout noir !",
				func() -> void: Stage.hop(maia, 2, 10.0), MAIA),
			{"who": MAIA, "text": "Je l'ai vu de loin, mais je te jure : TROP STYLÉ. Tu crois que c'est LE Masque ?"},
			{"who": CHLOE, "text": "Le chef de l'Ombre Noire ? Sur une passerelle de la futaie ?"},
			{"who": MAIA, "text": "Va voir, si tu veux. Moi, je ne bouge pas d'ici : j'ai un pont à garder. Et une revanche à prendre."},
		]
	var little: Dino = ForetCamp.recovered()
	if little and Game.party.has(little):
		lines.append_array([
			GESTES.cue("Attends… Attends, attends, attends. C'est… le troisième petit ?! Celui qu'on a volé au Cabinet ?!",
				func() -> void: _maia_sees_little(maia, little, cast), MAIA),
			{"who": CHLOE, "text": "%s. Brac l'avait nourri à l'ambre noir. Je l'ai apaisé." % little.nickname},
			{"who": MAIA, "text": "Tu l'as… Bon. D'accord. Ça, c'est encore plus stylé que le Masque. Mais je ne te le dirai qu'une fois."},
		])
	lines.append_array([
		GESTES.cue("Bref ! Tu as vu le pont ? Quelqu'un a tranché les cordes de la dernière travée. Pour que personne n'aille au Marais… ou n'en revienne.",
			func() -> void: _points_at(maia, span), MAIA),
		{"who": MAIA, "text": "Moi, je peux le réparer : maman m'a appris tous les nœuds de marin. Mais d'abord…"},
		GESTES.cue("MON DÉFI. Le numéro deux. Caillou, %s, et mon petit nouveau : Moustique, un Dimorphodon." % _maia_starter_name(),
			func() -> void: _challenges(maia), MAIA),
	])
	return lines


## « Juste là, au bout du pont » : she turns to the far end of the bridge and points at it with
## her chin; the camera takes in the bridge and Chloé.
static func _points_at(maia, span: Vector2) -> void:
	if not is_instance_valid(maia):
		return
	Stage.turn_to(maia, span)
	var chloe := Stage.chloe()
	if chloe:
		Stage.look_at(span.lerp(chloe.global_position, 0.5), 0.0)
	await GESTES.lean(maia, span, 8.0, 1.0)


## « TROP STYLÉ » : she jumps for joy (the camera back on Chloé).
static func _cheers(maia) -> void:
	GESTES.look_back()
	await Stage.hop(maia, 2, 12.0)


## « MON DÉFI » : back to Chloé, she draws herself up.
static func _challenges(maia) -> void:
	GESTES.look_back()
	await Stage.rear(maia, 0.8)


## She sees the third hatchling: Chloé's own dino, or (another of her party) brought out next
## to her for it (cast « little »: given back after the lines). Maïa turns to it, amazed.
static func _maia_sees_little(maia, little: Dino, cast: Dictionary) -> void:
	var w = S.world()
	var seen: Node2D = null
	if little == Game.lead_dino() and w and w.get("companion") and w.companion.visible:
		seen = w.companion
	else:
		seen = GESTES.stand_in(little)
		if seen:
			cast["little"] = seen
	if is_instance_valid(maia) and seen:
		Stage.turn_to(maia, seen.global_position)
		Stage.emote(maia, "!")
		await Stage.hop(maia, 1, 8.0)


## The hatchling a scene brought out (cast « little », GESTES.stand_in) goes back to Chloé.
static func _little_back(cast: Dictionary) -> void:
	var little = cast.get("little")
	cast.erase("little")
	if is_instance_valid(little):
		await GESTES.stand_in_back(little)


static func _maia_team() -> Array:
	var team := [[&"protoceratops", MAIA_LEVELS["caillou"], "Caillou"], [&"dimorphodon", MAIA_LEVELS["moustique"], "Moustique"]]
	var mine := StringName(str(Game.flag(&"maia_starter")))
	if SpeciesDB.PATHS.has(mine):
		team.append([mine, MAIA_LEVELS["starter"], _maia_starter_name()])
	return team


static func _maia_starter_name() -> String:
	return Prologue.MAIA_NAMES.get(StringName(str(Game.flag(&"maia_starter"))), "Flèche")


static func _maia_beaten(who: Node) -> void:
	S.lock(true)
	var span := S.at(BRIDGE_END.x, BRIDGE_END.y)
	await S.say([
		GESTES.cue("Non… Pas ENCORE ! Deux fois ! DEUX FOIS !", func() -> void: Stage.hop(who, 4, 5.0), MAIA),
		GESTES.cue("… Bon. Tu es forte. Vraiment forte. Ça m'énerve, mais c'est vrai.", func() -> void: Stage.bow(who, 1.4), MAIA),
		{"who": MAIA, "text": "Allez, une promesse est une promesse. Regarde bien : c'est de la haute technique."},
	])
	await _to_the_cut_span(who, span)
	await S.fade_through(func() -> void:
		Audio.play_sfx(LATCH, -6.0)
		await S.wait(0.45)
		Audio.play_sfx(LATCH, -8.0)
		await S.wait(0.45))
	var lines: Array = [
		GESTES.cue("Nœud de chaise, nœud de cabestan, un tour mort et deux demi-clés. En un clin d'œil, la dernière travée du pont remonte de l'eau et se tend de nouveau vers l'autre rive.",
			func() -> void: _span_tight(who, span)),
		{"who": MAIA, "text": "Maman dit qu'une marin qui ne sait pas faire ses nœuds, c'est une marin qui nage."},
		{"who": MAIA, "text": "De l'autre côté, c'est le Marais Brumeux. De la brume, des roseaux, et des trucs qui nagent sous l'eau. Maman m'a interdit d'y aller. Donc évidemment, j'y vais."},
	]
	lines.append_array(_maia_marais())
	lines.append_array([
		{"who": MAIA, "text": "Là-bas, il te faudra un dino qui nage. Et un gilet de Joss : il paraît qu'il en coud un. Moi, je pars devant."},
		GESTES.cue("Rendez-vous dans les roseaux, championne. Et la prochaine fois, c'est MOI qui gagne.",
			func() -> void: Stage.hop(who, 2, 10.0), MAIA),
		{"flag": &"maia_defi_2"},
	])
	await S.say(lines)
	Game.award_team_xp(XP_MAIA)
	await _maia_goes_first(who)
	Save.save_game()
	S.lock(false)


## « Regarde bien » : she walks out to the end of the bridge, where the ropes were cut, and
## kneels by them; the camera takes in the bridge and Chloé.
static func _to_the_cut_span(maia, span: Vector2) -> void:
	if not is_instance_valid(maia):
		return
	var chloe := Stage.chloe()
	if chloe:
		Stage.look_at(span.lerp(chloe.global_position, 0.5), 0.0)
	await maia.walk_to(span + Vector2(10.0, 0.0), "left", 130.0)
	if not Stage.pose(maia, &"accroupi"):   # (kneeling, when drawn; GESTES.stand_up ends it)
		await GESTES.lie_down(maia, 0.35, 0.86)


## The knots are tied: she stands, gives the rope a last pull (the span tightens) and is proud of it.
static func _span_tight(maia, span: Vector2) -> void:
	await S.wait(0.5)
	if not is_instance_valid(maia):
		return
	await GESTES.stand_up(maia, 0.4)
	Audio.play_sfx(LATCH, -4.0)
	await GESTES.lean(maia, span + Vector2(S.CELL * 4.0, 0.0), 9.0, 0.7)
	Stage.shake(2.0, 0.25)
	await Stage.hop(maia, 1, 9.0)


## She goes first: over the mended span and into the Marais (she fades on the far bank).
static func _maia_goes_first(maia) -> void:
	if is_instance_valid(maia):
		GESTES.stand_up(maia, 0.2)
		var fade: Tween = maia.create_tween()
		fade.tween_interval(0.5)
		fade.tween_property(maia, "modulate:a", 0.0, 0.6)
		await maia.walk_to(S.at(MAIA_AWAY.x, MAIA_AWAY.y), "left", 110.0)
		if is_instance_valid(maia):
			maia.queue_free()
	await Stage.look_back(0.5)


## What Maïa knows of the Marais (from her mother): the Voix du Marais, Écho's mother.
static func _maia_marais() -> Array:
	var mine: Dino = Foret.starter()
	if str(Game.flag(&"starter")) == "parasaurolophus" and mine:
		return [
			{"who": MAIA, "text": "Et il paraît qu'au cœur des roseaux chante une vieille Parasaurolophus qu'Hélène avait réveillée. La Voix du Marais."},
			{"who": MAIA, "text": "… Attends. C'est pas la maman %s, ça ?" % French.de(mine.nickname)},
			{"who": CHLOE, "text": "Si. Hélène me l'a écrit : elle chante encore dans les roseaux."},
			{"who": MAIA, "text": "Alors on sait où tu vas."},
		]
	var little: Dino = ForetCamp.recovered()
	if little and str(Game.flag(&"stolen_starter")) == "parasaurolophus":
		return [
			{"who": MAIA, "text": "Maman dit qu'au cœur des roseaux chante une vieille Parasaurolophus qu'Hélène avait réveillée : la Voix du Marais."},
			{"who": MAIA, "text": "Ton %s a la même crête qu'elle, non ? … Tu crois que… ?" % little.nickname},
		]
	return [{"who": MAIA, "text": "Maman dit qu'au cœur des roseaux chante une vieille Parasaurolophus, une amie d'Hélène : la Voix du Marais. On l'entend de très loin, les soirs de brume."}]


# ------------------------------------------------------------------ back at the Cabinet

## Entering the Cabinet: Roc sees the lost hatchling back; after the Sceau, the lead dino smells
## something in Roc's drawer (cold ash: black amber).
static func cabinet() -> void:
	if not Game.flag(&"prologue_done"):
		return
	await _hatchling_home()
	await _drawer_scent()


## Roc and the third hatchling, home at last (he blames himself: page 8).
static func _hatchling_home() -> void:
	var prof = S.actor("Roc")
	var little: Dino = ForetCamp.recovered()
	if prof == null or little == null or Game.flag(&"roc_oeuf_retrouve"):
		return
	var w = S.world()
	S.lock(true)
	await S.wait(0.4)
	prof.face(w.player.global_position)
	var cast := {}
	var lines: Array = []
	if Game.party.has(little):
		lines.append_array([
			GESTES.cue("Chloé ! Te voilà. Tu as une mine de… Qu'est-ce que…", func() -> void: _little_hides(little, prof, cast), ROC),
			GESTES.cue("%s passe prudemment la tête derrière la jambe de Chloé." % little.nickname, func() -> void: _little_peeks(cast, prof)),
			GESTES.cue("Roc enlève ses lunettes. Il les essuie. Il les remet.", func() -> void: _wipes_glasses(prof)),
			{"who": ROC, "text": "Le troisième petit… C'est %s. C'est lui." % little.nickname},
		])
	else:
		var sleeper := _sleeper(little)
		lines.append_array([
			{"who": ROC, "text": "Chloé ! Tu ne devineras jamais qui dort contre la couveuse depuis ce matin…"},
			GESTES.cue("Contre la vitre tiède, roulé en boule, %s ouvre un œil, reconnaît Chloé, et le referme." % little.nickname,
				func() -> void: _opens_an_eye(sleeper)),
		])
	lines.append_array([
		GESTES.cue("C'est Brac qui l'avait. Un braconnier de l'Ombre Noire. Il l'a nourri à l'ambre noir, depuis la nuit du vol.",
			func() -> void: GESTES.look_back(), CHLOE),
		GESTES.cue("Roc s'assoit lourdement dans son fauteuil. Pendant un long moment, il ne dit rien.", func() -> void: _sits_down(prof)),
		{"who": ROC, "text": "À l'ambre noir. Un bébé…"},
		{"who": ROC, "text": "J'avais fermé cette porte à clé, Chloé. J'en suis sûr. … J'aurais dû dormir devant."},
	])
	if Game.flag(&"found_journal_8"):
		lines.append_array([
			{"who": CHLOE, "text": "(« S'il se sent coupable un jour, dis-lui que non. »)"},
			{"who": CHLOE, "text": "Ce n'est pas votre faute, professeur."},
			{"who": ROC, "text": "… Tu parles exactement comme elle. C'est très agaçant."},
			GESTES.cue("Mais il sourit, pour la première fois depuis longtemps.", func() -> void: Stage.emote(prof, "~")),
		])
	else:
		lines.append({"who": CHLOE, "text": "Il va bien, maintenant. Regardez-le."})
	if Game.party.has(little):
		lines.append(GESTES.cue("%s trottine jusqu'à la couveuse, la renifle, et se roule en boule contre la vitre tiède." % little.nickname,
			func() -> void: _little_to_incubator(cast)))
	lines.append_array([
		GESTES.cue("Il se souvient… Bienvenue à la maison, petit.", func() -> void: GESTES.stand_up(prof, 0.6), ROC),
		{"flag": &"roc_oeuf_retrouve"},
	])
	if Game.flag(&"sceau_foret"):
		lines.append_array(_sceau_lines())
	await S.say(lines)
	if is_instance_valid(prof):
		GESTES.stand_up(prof, 0.3)   # (on his feet, even when the lines went by fast)
	await _little_back(cast)
	Save.save_game()
	S.lock(false)


## « Qu'est-ce que… » : the little one of Chloé's party is brought out, half hidden behind her
## (cast « little »); Roc has seen something.
static func _little_hides(little: Dino, prof, cast: Dictionary) -> void:
	var chloe := Stage.chloe()
	var actor := GESTES.stand_in(little)
	if actor == null or chloe == null:
		return
	cast["little"] = actor
	var hide: Vector2 = chloe.global_position + Vector2(16.0, 10.0)
	if actor.get_meta(&"for_companion", false):
		await actor.walk_to(hide, 90.0)
	else:
		actor.global_position = hide
	if is_instance_valid(prof):
		Stage.turn_to(actor, (prof as Node2D).global_position)
		await S.wait(0.6)
		Stage.emote(prof, "?")


## It puts its head out from behind Chloé's leg, carefully, towards Roc.
static func _little_peeks(cast: Dictionary, prof) -> void:
	var actor = cast.get("little")
	if not is_instance_valid(actor) or not is_instance_valid(prof):
		return
	Stage.turn_to(actor, (prof as Node2D).global_position)
	await S.wait(0.4)
	await GESTES.lean(actor, (prof as Node2D).global_position, 14.0, 2.2)


## Roc takes his glasses off, wipes them (head bent, rubbing), puts them back on.
static func _wipes_glasses(prof) -> void:
	if not is_instance_valid(prof):
		return
	Stage.bow(prof, 2.0)
	await S.wait(0.5)
	await Stage.tremble(prof, 0.9, 1.2)


## Roc crosses to his armchair and sinks into it, heavily (he sits: GESTES.stand_up later).
static func _sits_down(prof) -> void:
	if not is_instance_valid(prof):
		return
	await prof.walk_to(S.at(ARMCHAIR_SEAT.x, ARMCHAIR_SEAT.y), "down", 90.0)
	if not is_instance_valid(prof):
		return
	if not await Stage.sit(prof):
		await GESTES.lie_down(prof, 0.3, 0.86)
	Stage.shake(1.2, 0.15)


## The little one trots to the incubator (between the pedestals), sniffs it and curls up
## against its warm glass; the camera goes with it.
static func _little_to_incubator(cast: Dictionary) -> void:
	var actor = cast.get("little")
	if not is_instance_valid(actor):
		return
	var front := S.at(INCUBATOR_FRONT.x, INCUBATOR_FRONT.y)
	Stage.look_at(front.lerp(Stage.chloe().global_position, 0.3), 0.0)
	await GESTES.walk(actor, [S.at(INCUBATOR_WAY.x, INCUBATOR_WAY.y), front], 110.0)
	if not is_instance_valid(actor):
		return
	await GESTES.lean(actor, front + Vector2(0.0, -40.0), 6.0, 0.8)
	GESTES.stand_in_cry(actor, &"neutre")
	await GESTES.lie_down(actor, 0.8)


## The little one waiting at the Cabinet (not in the party): asleep against the incubator,
## there for as long as Chloé stays in the Cabinet.
static func _sleeper(little: Dino) -> DinoNpc:
	var w = S.world()
	if w == null or w.get("region") == null:
		return null
	var actor := DinoNpc.new()
	actor.name = "PetitCouveuse"
	actor.species_id = little.species().id
	actor.level = little.level
	actor.flip = true
	actor.position = S.at(INCUBATOR_FRONT.x, INCUBATOR_FRONT.y)
	w.region.entities.add_child(actor)
	actor.collision_layer = 0
	GESTES.lie_down(actor, 0.0)
	return actor


## It opens an eye (its head comes up a little, a small sound), knows Chloé, and sleeps again.
static func _opens_an_eye(sleeper) -> void:
	if not is_instance_valid(sleeper):
		return
	var chloe := Stage.chloe()
	if chloe:
		Stage.look_at((sleeper as Node2D).global_position.lerp(chloe.global_position, 0.3), 0.0)
	await S.wait(1.2)
	if not is_instance_valid(sleeper):
		return
	await GESTES.lie_down(sleeper, 0.4, 0.86)
	sleeper.cry(&"neutre")
	await S.wait(1.2)
	await GESTES.lie_down(sleeper, 0.6)


## After the Sceau: the lead dino smells cold ash in Roc's drawer (a hint towards it).
static func _drawer_scent() -> void:
	if not Game.flag(&"sceau_foret") or Game.flag(&"ambre_noir_tiroir") or Game.flag(&"tiroir_flaire"):
		return
	var lead := Game.lead_dino()
	var w = S.world()
	# (a dino too tall for the Cabinet's door waits outside: another time, then)
	if lead == null or w == null or not w.companion.visible:
		return
	S.lock(true)
	await S.wait(0.3)
	var drawer_px := S.at(DRAWER_AT.x, DRAWER_AT.y)
	var cast := {}
	var little: Dino = ForetCamp.recovered()
	var lines: Array = []
	if little and lead == little:
		lines.append(GESTES.cue("%s se fige au milieu du Cabinet. Il fixe le bureau de Roc… et se met à trembler." % lead.nickname,
			func() -> void: _freezes(drawer_px)))
	else:
		lines.append(GESTES.cue("%s file droit vers le bureau de Roc et gronde, le nez collé au tiroir de gauche." % lead.nickname,
			func() -> void: _sniffs_drawer(drawer_px, cast)))
	lines.append({"who": CHLOE, "text": "(Cette odeur… De la cendre froide. Comme au camp de Brac.)"})
	if S.actor("Roc"):
		lines.append({"who": ROC, "text": "Hmm ? Qu'est-ce qu'il a, ton dino ? … Ah, les dinos. Toujours à renifler partout."})
	lines.append({"flag": &"tiroir_flaire"})
	await S.say(lines)
	await _little_back(cast)
	S.lock(false)


## The little one (Chloé's lead) freezes, stares at the desk, and shakes.
static func _freezes(drawer_px: Vector2) -> void:
	var w = S.world()
	var companion = w.get("companion") if w else null
	if companion == null:
		return
	Stage.turn_to(companion, drawer_px)
	Stage.emote(companion, "!")
	await S.wait(1.0)
	await Stage.tremble(companion, 2.4, 2.0)


## Chloé's lead runs straight to the desk (as a stand-in, cast « little ») and growls, its
## nose against the left drawer; the camera takes in the desk and Chloé.
static func _sniffs_drawer(drawer_px: Vector2, cast: Dictionary) -> void:
	var actor := GESTES.stand_in()
	var chloe := Stage.chloe()
	if actor == null or chloe == null:
		return
	cast["little"] = actor
	Stage.look_at(drawer_px.lerp(chloe.global_position, 0.5), 0.0)
	await actor.walk_to(drawer_px + Vector2(6.0, 30.0), 200.0)
	if not is_instance_valid(actor):
		return
	GESTES.stand_in_cry(actor, &"attaque")
	await GESTES.lean(actor, drawer_px, 7.0, 0.8)
	await GESTES.lean(actor, drawer_px, 7.0, 0.8)


## Roc's drawer (the one he says is « broken »): after the Sceau, black amber wrapped in a
## handkerchief. Roc, caught, cannot explain (false lead 2: he confiscates it, docs/lore.md).
static func drawer(who: Node) -> void:
	if Game.flag(&"ambre_noir_tiroir"):
		var line := ForetCamp.next_line(&"tiroir_n", DRAWER_AFTER)
		await S.say([GESTES.cue(line, func() -> void: _drawer_aside(line, who))])
		return
	if not Game.flag(&"sceau_foret"):
		var line := ForetCamp.next_line(&"tiroir_n", DRAWER_BEFORE)
		await S.say([GESTES.cue(line, func() -> void: _drawer_aside(line, who))])
		return
	var w = S.world()
	if w == null:
		return
	S.lock(true)
	var chloe: Player = w.player
	var drawer_px: Vector2 = (who as Node2D).global_position if who is Node2D else S.at(DRAWER_AT.x, DRAWER_AT.y)
	var glow := {}
	var lines: Array = [
		{"text": "Le tiroir de gauche. Celui que Roc dit « cassé »."},
		GESTES.cue("Chloé tire doucement sur la poignée. Clic : la serrure ne tient plus. Elle est vraiment cassée. Le tiroir glisse tout seul.",
			func() -> void: _tug(chloe, drawer_px, 6.0, true)),
		GESTES.cue("Dedans, enveloppées dans un vieux mouchoir, des pierres noires comme du charbon. Froides. Veinées de violet.",
			func() -> void: glow["light"] = _black_amber_glow(drawer_px)),
		{"who": CHLOE, "text": "(De l'ambre noir. Comme dans les caisses de Brac.)"},
	]
	var cast := {}
	var little: Dino = ForetCamp.recovered()
	if little and Game.party.has(little):
		lines.append(GESTES.cue("Derrière Chloé, %s recule en gémissant. Il connaît cette odeur mieux que personne." % little.nickname,
			func() -> void: _little_shies(little, drawer_px, cast)))
	var prof = S.actor("Roc")
	if prof:
		var beside: Vector2 = chloe.global_position + Vector2(56.0, 24.0)
		lines.append_array([
			GESTES.cue("Chloé ! Ne touche pas à… !", func() -> void: prof.walk_to(beside, "left", 220.0), ROC),
			GESTES.cue("Roc referme le tiroir d'un coup sec. Il a les joues toutes rouges.", func() -> void: _slams_drawer(prof, drawer_px, glow)),
			{"who": ROC, "text": "Ce n'est pas… Ce n'est pas ce que tu crois."},
			{"who": CHLOE, "text": "C'est de l'ambre noir, professeur. Au camp de Brac, il y en avait des caisses entières. Ils en font avaler aux dinos pour qu'ils aient peur !"},
			{"who": ROC, "text": "Je sais ce que c'est. Mieux que personne, crois-moi."},
			GESTES.cue("Il ouvre la bouche. La referme. Il tourne une petite clé dans la serrure cassée, qui ne sert plus à rien, et garde la main posée dessus.",
				func() -> void: _turns_the_key(prof, drawer_px)),
			{"who": ROC, "text": "Je ne peux pas t'expliquer. Pas maintenant. Fais-moi confiance, veux-tu ? Juste… fais-moi confiance."},
			{"who": ROC, "text": "Et n'en parle à personne. Même pas à Maïa. Surtout pas à…"},
			GESTES.cue("Il s'arrête net.", func() -> void: Stage.emote(prof, "…")),
			{"who": ROC, "text": "… À personne. Voilà."},
			{"who": CHLOE, "text": "(« Ne fais confiance qu'à ceux qui ne veulent rien de l'ambre », disait Hélène. Et lui, il en cache dans son tiroir…)"},
			{"flag": &"ambre_noir_tiroir"},
		])
	else:
		lines.append_array([
			GESTES.cue("Le fauteuil de Roc est vide. Sa vieille lanterne n'est plus au crochet.",
				func() -> void: Stage.look_at(S.at(ARMCHAIR_SEAT.x, ARMCHAIR_SEAT.y).lerp(chloe.global_position, 0.4), 0.0)),
			GESTES.cue("Chloé remet le mouchoir en place, et referme le tiroir sans bruit.", func() -> void: _closes_drawer(chloe, drawer_px, glow)),
			{"who": CHLOE, "text": "(Professeur… Qu'est-ce que vous faites avec ça ?)"},
			{"who": CHLOE, "text": "(« Ne fais confiance qu'à ceux qui ne veulent rien de l'ambre », disait Hélène…)"},
			{"flag": &"ambre_noir_tiroir"},
		])
	await S.say(lines)
	_light_out(glow.get("light"), 0.3)
	if is_instance_valid(prof):
		prof.modulate = Color.WHITE
	await _little_back(cast)
	Game.award_team_xp(XP_TIROIR)
	Save.save_game()
	S.lock(false)


## The drawer's single lines, acted out: Chloé brushes the handle and Roc coughs very loudly;
## the new lock shines; the drawer does not budge and Roc pretends to read (his back turned).
static func _drawer_aside(line: String, drawer_node: Node) -> void:
	var chloe := Stage.chloe()
	var prof = S.actor("Roc")
	var at: Vector2 = (drawer_node as Node2D).global_position if drawer_node is Node2D else S.at(DRAWER_AT.x, DRAWER_AT.y)
	if line == DRAWER_BEFORE[1]:
		await _tug(chloe, at, -4.0, false)
		if is_instance_valid(prof) and chloe:
			Stage.turn_to(prof, chloe.global_position)
			await Stage.bow(prof, 0.3)
			await Stage.bow(prof, 0.3)
	elif line == DRAWER_AFTER[0]:
		await Stage.glow(drawer_node as CanvasItem, Color(1.6, 1.5, 1.2), 2, 0.5, 2.0)
	elif line == DRAWER_AFTER[1]:
		await _tug(chloe, at, 5.0, false)
		if is_instance_valid(prof):
			prof.face((prof as Node2D).global_position + Vector2(0.0, -60.0))
			Stage.emote(prof, "…")


## Someone pulls at something (Chloé at the drawer's handle): the picture leans back from
## `at_px` by `px` pixels (towards it when < 0) and comes back; `click`: the lock gives (Clic).
static func _tug(actor, at_px: Vector2, px: float, click: bool) -> void:
	var sprite := Stage.sprite_of(actor)
	if sprite == null:
		return
	if not sprite.has_meta(&"stage_rest"):
		sprite.set_meta(&"stage_rest", sprite.position)
	var rest: Vector2 = sprite.get_meta(&"stage_rest")
	var away: Vector2 = ((actor as Node2D).global_position - at_px).normalized() * px
	var t := sprite.create_tween()
	t.tween_interval(0.3)
	t.tween_property(sprite, "position", rest + away, 0.35).set_trans(Tween.TRANS_SINE)
	if click:
		t.tween_callback(func() -> void: Audio.play_sfx(LATCH, -8.0))
	t.tween_interval(0.2)
	t.tween_property(sprite, "position", rest, 0.3).set_trans(Tween.TRANS_SINE)
	await t.finished


## A faint violet light breathing over the open drawer (black amber) until _light_out.
static func _black_amber_glow(at_px: Vector2) -> OmniLight3D:
	var light := Stage.light_at(at_px, BLACK_AMBER, 1.8)
	if light == null:
		return null
	var t := light.create_tween().set_loops()
	t.tween_property(light, "light_energy", 2.2, 0.9).set_trans(Tween.TRANS_SINE)
	t.tween_property(light, "light_energy", 0.9, 0.9).set_trans(Tween.TRANS_SINE)
	light.set_meta(&"loop", t)
	return light


## The drawer's light goes out: at once (`secs` 0: shut with a bang) or softly.
static func _light_out(light, secs := 0.0) -> void:
	if light == null or not is_instance_valid(light):
		return
	var loop = light.get_meta(&"loop", null)
	if loop is Tween and (loop as Tween).is_valid():
		(loop as Tween).kill()
	if secs <= 0.0:
		light.queue_free()
		return
	var t: Tween = light.create_tween()
	t.tween_property(light, "light_energy", 0.0, secs)
	t.tween_callback(light.queue_free)


## Roc slams the drawer shut (a lunge at it, the bang, the violet light out), his cheeks red.
static func _slams_drawer(prof, drawer_px: Vector2, glow: Dictionary) -> void:
	if not is_instance_valid(prof):
		return
	if prof.walking:
		await GESTES.halt(prof)
	if not is_instance_valid(prof):
		return
	Stage.turn_to(prof, drawer_px)
	Stage.lunge(prof, drawer_px, 0.8, false)
	await S.wait(0.14)
	Audio.play_sfx(LATCH, -2.0)
	_light_out(glow.get("light"))
	await S.wait(0.5)
	await GESTES.colours(prof, [BLUSH], 2.6)


## He hesitates, then turns a little key in the broken lock (a tiny click) and keeps his hand on it.
static func _turns_the_key(prof, drawer_px: Vector2) -> void:
	if not is_instance_valid(prof):
		return
	await S.wait(1.4)
	if not is_instance_valid(prof):
		return
	Stage.turn_to(prof, drawer_px)
	await S.wait(0.5)
	Audio.play_sfx(LATCH, -14.0)
	await GESTES.lean(prof, drawer_px, 5.0, 2.0)


## Roc away: Chloé pushes the drawer back in, softly; the violet light fades; the camera comes back.
static func _closes_drawer(chloe: Player, drawer_px: Vector2, glow: Dictionary) -> void:
	GESTES.look_back()
	await _tug(chloe, drawer_px, -5.0, false)
	_light_out(glow.get("light"), 0.6)


## The little one (behind Chloé) backs away from the drawer, whimpering, and shakes.
static func _little_shies(little: Dino, drawer_px: Vector2, cast: Dictionary) -> void:
	var chloe := Stage.chloe()
	var actor := GESTES.stand_in(little)
	if actor == null or chloe == null:
		return
	cast["little"] = actor
	if not actor.get_meta(&"for_companion", false):
		actor.global_position = chloe.global_position + Vector2(22.0, 26.0)
	var away: Vector2 = (actor.global_position - drawer_px).normalized() * 30.0
	GESTES.stand_in_cry(actor, &"degat")
	await GESTES.back_away(actor, actor.global_position + away, 0.9)
	await Stage.tremble(actor, 1.6, 1.5)


## Talking to Roc once the Sceau de la Forêt is Chloé's (Story.run « roc »). True if he said it.
static func roc() -> bool:
	if not Game.flag(&"sceau_foret") or Game.flag(&"roc_sceau_foret"):
		return false
	await S.say(_sceau_lines())
	return true


static func _sceau_lines() -> Array:
	return [
		GESTES.cue("Et ça… Montre-moi ça. Le Sceau de la Forêt ? Le Chef de Meute te l'a donné. À toi.",
			func() -> void: _sceau_shines(), ROC),
		{"who": ROC, "text": "Hélène avait mis des semaines à gagner sa confiance. Il lui a volé son chapeau trois fois, pour voir si elle reviendrait le chercher. Elle revenait toujours."},
		{"who": ROC, "text": "Elle serait fière. Elle ne le dirait pas, bien sûr : elle dirait « c'est normal ». Mais elle le serait."},
		{"flag": &"roc_sceau_foret"},
	]


## « Montre-moi ça » : Chloé holds up the Sceau, its amber lights up in her hands (a warm light
## at her, not a tint on her).
static func _sceau_shines() -> void:
	var chloe := Stage.chloe()
	if chloe == null:
		return
	await S.wait(0.4)
	var light := Stage.light_at(chloe.global_position + Vector2(0.0, 6.0), Color(1.0, 0.78, 0.4), 2.0)
	if light == null:
		return
	var t := light.create_tween()
	t.tween_property(light, "light_energy", 2.4, 0.5).set_trans(Tween.TRANS_SINE)
	t.tween_interval(1.0)
	t.tween_property(light, "light_energy", 0.0, 0.8).set_trans(Tween.TRANS_SINE)
	t.tween_callback(light.queue_free)
