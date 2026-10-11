class_name Cieux
## Chapter 7, the Cieux Éternels (docs/histoire.md, ch. 7), the way up and the first zone: Joss's
## flying harness at the Havre (a fern stamped in the strap, « comme sur les boussoles d'Hélène »);
## the way out of the Monts (a grown pterosaur with the harness glides Chloé up to the first piton:
## a scripted glide, not the Vol, which the Roi gives later); the arrival (the sea of clouds, the
## silence, the lead dino meets the sky); the first liana bridge. The nests and the Roi are in
## story/cieux_nids.gd, the Arche and the mask in story/cieux_arche.gd.
## What the chapter's files share: the places by name (place: read from story/cieux_places.gd,
## the CARTE agent's, with fallbacks so a scene never breaks), the species or their stand-ins,
## what Chloé still needs to go up (fly_step), how one flies (vol_howto: never a key in the text).
## Flags: harnais_vol, maia_cieux_plan, cieux_ouverts, cieux_arrivee, pont_lianes_vu;
## joss_cieux_n, maia_cieux_n (lines).

const S := preload("res://story/story.gd")
const CS := preload("res://story/cote_stage.gd")
const MS := preload("res://story/monts_stage.gd")
const CHLOE := "Chloé"
const MAIA := "Maïa"
const JOSS := "Joss"
## The flying harness (ItemsDB « harnais_vol », the MÉCANIQUES agent's) and its flag.
const HARNESS := "harnais_vol"
const HARNESS_FLAG := &"harnais_vol"
const FLY := &"vol"
## The places' script (the CARTE agent's) and the spawns' names of the contract.
const PLACES_SCRIPT := "res://story/cieux_places.gd"
const SPAWN_MONTS := &"DepuisMonts"
const SPAWN_CIEUX := &"DepuisCieux"
const SPAWN_NIDS := &"DepuisNids"
## Where things are when CieuxPlaces does not say yet (tiles): only so the scenes play.
const FALLBACK_PLACES := {
	"ENTREE_MONTS": Vector2(40.0, 70.0), "PITON_ARRIVEE": Vector2(40.0, 66.0), "PREMIER_PONT": Vector2(48.0, 58.0),
	"BELVEDERE": Vector2(60.0, 30.0), "MER_DE_NUAGES": Vector2(30.0, 40.0), "ILOT_NUAGES": Vector2(24.0, 44.0),
	"SORTIE_NIDS": Vector2(70.0, 6.0), "SORTIE_MONTS": Vector2(40.0, 74.0),
	"NIDS_ENTREE": Vector2(20.0, 34.0), "NIDS": Vector2(20.0, 22.0), "GRAND_NID": Vector2(20.0, 8.0),
	"VIEUX_HARNAIS": Vector2(18.0, 7.0), "PAGE_32": Vector2(26.0, 20.0), "AIGUILLE": Vector2(34.0, 6.0),
	"ARCHE_ENTREE": Vector2(16.0, 28.0), "ARCHE": Vector2(16.0, 14.0), "BORD_ROI": Vector2(24.0, 18.0),
	"DESCENTE_CENDRE": Vector2(6.0, 8.0), "CAIRN": Vector2(24.0, 12.0),
}
## The chapter's species and what stands in for them while their sheets are not in SpeciesDB.
const STAND_INS := {
	&"quetzalcoatlus": &"pteranodon", &"hatzegopteryx": &"pteranodon", &"tupandactylus": &"dimorphodon",
	&"tapejara": &"dimorphodon", &"rhamphorhynchus": &"dimorphodon",
}
const XP_ARRIVEE := 30
const XP_PONT := 20
const XP_HARNAIS := 20
## The glide up: how long the pterosaur circles before it lands (s), its height over the piton (px).
const LANDING_CIRCLE := 3.2
const LANDING_HEIGHT := CS.FLY_HEIGHT + 90.0
## How long a flyer takes to set down once over its spot (s).
const LAND_S := 0.5
## How far from Chloé the pterosaur folds its wings (px), the small flyers' wheel (px).
const LANDS_AT := Vector2(70.0, 10.0)
const RHAMPHO_RADIUS := 150.0
const JOSS_CIEUX := [
	"Les coutures ont tenu ? … Elles ont tenu. Je le savais. Je ne dormais plus, mais je le savais.",
	"Maïa dit que le Roi des Cieux a reniflé mon harnais. Un roi. Mon harnais. Je vais le marquer sur l'enseigne.",
	"Un harnais de vol, un gilet de nage, un masque de plongée… Il ne me manque plus qu'un truc pour aller sous la terre. Non. Oublie. Je n'ai rien dit.",
]
const MAIA_COL_BEFORE := [
	"Je t'attends ici. J'ai un plan. Un plan stylé. … Non, je ne te le dis pas : sinon ce n'est plus un plan, c'est un programme.",
	"Caillou a voulu monter par la falaise. Il a fait trois pas. Il réfléchit, maintenant.",
	"Moustique a vu l'ombre là-haut, l'immense. Il est rentré dans ma capuche et il n'en sort plus.",
]
## Joss once Maïa has gone down with her mother (masque_tombe).
const JOSS_APRES := [
	"Maïa est descendue avec sa mère ? … Elle a mon manteau. Au moins, elle aura chaud. C'est idiot, ce que je dis. Je le sais.",
	"Moustique est avec toi ? Montre-le-moi. … Il a maigri. Non. Il a la même tête. C'est moi qui ai maigri.",
	"Quand elles remonteront, je leur couds à toutes les deux ce qu'elles voudront. Même un harnais. Même deux.",
]


# ------------------------------------------------------------------ places and species

## Where `name` is (tiles): CieuxPlaces when the CARTE agent has written it, else the fallback.
static func place(name: String) -> Vector2:
	if ResourceLoader.exists(PLACES_SCRIPT):
		var places: Dictionary = (load(PLACES_SCRIPT) as Script).get_script_constant_map()
		if places.has(name) and places[name] is Vector2:
			return places[name]
	return FALLBACK_PLACES.get(name, Vector2.ZERO)


## The same, in world pixels.
static func px(name: String) -> Vector2:
	var tile := place(name)
	return S.at(tile.x, tile.y)


## `id` when SpeciesDB has it, else its stand-in (a scene never breaks for a missing sheet).
static func species_or(id: StringName) -> StringName:
	if SpeciesDB.PATHS.has(id):
		return id
	return STAND_INS.get(id, MS.species_or(id))


## A dino only a scene needs (CS.stand_in), its species or its stand-in; invisible at first. `size`
## is meant for the species itself: a stand-in (already a big one) keeps its own size.
static func stand_in(id: StringName, at_px: Vector2, node_name: String, level := 0, size := 1.0) -> DinoNpc:
	return CS.stand_in(species_or(id), at_px, node_name, level, size_or(id, size))


## Remembers where `actor`'s picture rests on the ground, before a flight lifts it: Stage._rest
## keeps the first position it reads, and read after the lift, the landing put it back in the air.
static func keep_rest(actor) -> void:
	var sprite := Stage.sprite_of(actor)
	if sprite:
		Stage._rest(sprite)


## A stand-in that flew (CS.fly, CS.circle: its flight sheet, wingbeats in a loop) sets down: its
## picture back on the ground where it rests, and its waiting pose (« idle »: wings folded, a slow
## breath). Without it, a landed flyer went on beating its wings for the whole scene (Greg, 11/10).
static func land(actor, secs := LAND_S) -> void:
	var sprite := Stage.sprite_of(actor) as AnimatedSprite2D
	if sprite == null:
		return
	var t := sprite.create_tween()
	t.tween_property(sprite, "position:y", Stage._rest(sprite).y, secs).set_trans(Tween.TRANS_SINE)
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(&"idle"):
		sprite.play(&"idle")


## `size` when SpeciesDB has `id`, else 1.0 (its stand-in is drawn at its own size).
static func size_or(id: StringName, size: float) -> float:
	return size if SpeciesDB.PATHS.has(id) else 1.0


# ------------------------------------------------------------------ going up

## Joss's flying harness (the item, or the story flag of the same name).
static func has_harness() -> bool:
	return Game.item_count(HARNESS) > 0 or bool(Game.flag(HARNESS_FLAG))


## The grown pterosaur of the party that can carry Chloé (with the harness), or null.
static func flyer() -> Dino:
	return Game.ability_user(FLY) if has_harness() else null


## What still keeps Chloé from going up to the Cieux ("" when she can): the harness, a grown flyer
## (in the party, too young, or waiting at the Cabinet), or where to find one.
static func fly_step() -> String:
	if not has_harness():
		if Game.flag(&"maia_alliee"):
			return "Il te faut le harnais de vol de Joss : il le coud au Havre. « Trois jours », a dit Maïa. Donc une semaine."
		return "Il te faut un harnais de vol. Joss, au Havre, saurait en coudre un."
	if Game.ability_user(FLY):
		return ""
	for d: Dino in Game.party:
		if Abilities.has(d, FLY):
			return "Ton %s est encore trop jeune pour te porter : il doit être adulte (niveau %d)." % [d.nickname, Abilities.ADULT_LEVEL]
	for d: Dino in Game.box:
		if Abilities.usable(d, FLY):
			return "Ton %s attend au Cabinet : lui saurait te porter. Fais-le venir depuis ton Dinodex, ou demande au Pr Roc." % d.nickname
	return "Avec le harnais, il te faut un grand ptérosaure adulte : un Ptéranodon des falaises de la Côte, de jour."


## The way from the Monts up to the Cieux (the Monts' exit, cieux_ouverts) opens once Maïa and
## Chloé are a team, with the harness and a grown flyer. Called on entering a zone, after Joss.
static func update_access() -> void:
	if Game.flag(&"maia_alliee") and flyer() != null and not Game.flag(&"cieux_ouverts"):
		Game.set_flag(&"cieux_ouverts")


## How one flies, in words (never a key: the Vol's own help shows them, story/vol.gd).
static func vol_howto() -> String:
	return "Monte sur son dos comme en selle : il fera le reste. Penche-toi du côté où tu veux aller. Pour te poser, cherche un sol où tes pieds tiendraient."


# ------------------------------------------------------------------ Joss, at the Havre

## Joss at the Havre once Maïa and Chloé are a team (Story.run « joss »): the harness is done. Then
## his lines of the chapter. True if he said something of the chapter's.
static func joss_harnais() -> bool:
	if not Game.flag(&"maia_alliee"):
		return false
	var joss = S.actor("Joss")
	if Game.flag(HARNESS_FLAG):
		if not Game.flag(&"vol_obtenu"):
			return false   # (chapter 6's lines, MontsFin.joss_havre: he waits for news)
		var pool: Array = JOSS_APRES if Game.flag(&"masque_tombe") else JOSS_CIEUX
		await S.say([{"who": JOSS, "text": ForetCamp.next_line(&"joss_cieux_n", pool)}])
		return true
	S.lock(true)
	await S.say(_the_harness(joss))
	if ItemsDB.ITEMS.has(HARNESS):
		Game.give_item(HARNESS)
	Game.set_flag(HARNESS_FLAG)
	update_access()
	var step := fly_step()
	if step != "":
		await S.say([{"who": JOSS, "text": "Il te faut aussi quelqu'un pour le porter. " + step}])
	Toast.say(S.world().get_tree(), "Objet obtenu : le harnais de vol")
	Game.award_team_xp(XP_HARNAIS)
	Save.save_game()
	S.lock(false)
	return true


## He pulls it from under the bench, still warm from the lamp; sewn twice; Moustique flew upside
## down; the fern stamped in the strap, « c'est Maïa qui m'a demandé ça ».
static func _the_harness(joss) -> Array:
	var chloe := Stage.chloe()
	var pulls := func() -> void:
		if joss:
			await Stage.bow(joss, 0.9)
			Stage.hop(joss, 1, 6.0)
	var shows := func() -> void:
		if joss:
			CS.reach(joss, chloe.global_position, 12.0, 1.6)
		if ItemsDB.ITEMS.has(HARNESS):
			CS.Act.pop(chloe.global_position + Vector2(-10.0, 0.0), HARNESS, 1.0)
	var fern := func() -> void:
		if joss:
			await CS.reach(joss, (joss as Node2D).global_position + Vector2(0.0, 20.0), 6.0, 0.7)
		CS.sparkle(chloe.global_position + Vector2(-10.0, 0.0), 0.5, 8, 0.1)
	return [
		CS.cue({"who": JOSS, "text": "Chloé ! Il est fini. Trois jours. Enfin, une semaine. Enfin, je n'ai pas compté les nuits."}, pulls),
		CS.cue({"text": "Joss sort de sous l'établi un harnais de cuir clair, encore chaud de la lampe : des sangles larges, des boucles d'ambre, et des coutures. Beaucoup de coutures."}, shows),
		{"who": JOSS, "text": "J'ai tout cousu deux fois. Regarde ces coutures. Non, vraiment : regarde-les. Celles-là, c'est ta vie qui tient dessus. Je l'ai dit à Maïa, elle a dit « parfait » et elle l'a essayé sur Moustique."},
		{"who": JOSS, "text": "Moustique a volé à l'envers. Mais il a volé. Et rien n'a craqué."},
		CS.cue({"who": JOSS, "text": "Et là, dans la sangle de poitrine… une petite fougère. Frappée au fer. « Comme sur les boussoles d'Hélène. » C'est Maïa qui m'a demandé ça. Elle n'a pas dit pourquoi."}, fern),
		{"who": CHLOE, "text": "(Comme sur les Sceaux. Comme sur la boussole d'Isaure.)"},
		{"who": JOSS, "text": "Il se met comme une selle, mais sur un ptérosaure. Un GRAND. Et après… après, je ne sais pas. Personne ne sait. Tu me raconteras."},
		{"flag": HARNESS_FLAG},
	]


# ------------------------------------------------------------------ Maïa, at the col

## Maïa at the col of the Monts during the chapter (MontsFin.maia, once they are a team): before
## the climb, her plan (« stylé »); after the mask, what she keeps. True if she said something.
static func maia_monts(_who: Node) -> bool:
	if not Game.flag(&"maia_alliee") or not Game.flag(HARNESS_FLAG):
		return false
	if Game.flag(&"masque_tombe"):
		return false   # (she went down with her mother: her Npc at the col is hidden, hide_flag masque_tombe)
	if not Game.flag(&"maia_cieux_plan"):
		Game.set_flag(&"maia_cieux_plan")
		await S.say([
			{"who": MAIA, "text": "Tu as le harnais de Joss ? Avec la fougère ? … C'est moi qui lui ai demandé. Pour que là-haut, on sache de quel côté tu es."},
			{"who": MAIA, "text": "Moi, je ne peux pas monter : Moustique est trop petit, et Caillou… Caillou est Caillou."},
			{"who": MAIA, "text": "Alors je t'attends ici. J'ai un plan. Un plan stylé. Je ne te dis pas lequel."},
			{"who": CHLOE, "text": "Maïa…"},
			{"who": MAIA, "text": "Va. Et si tu vois ma mère là-haut… ne lui dis rien. C'est moi qui lui dirai."},
		])
		return true
	await S.say([{"who": MAIA, "text": ForetCamp.next_line(&"maia_cieux_n", MAIA_COL_BEFORE)}])
	return true


# ------------------------------------------------------------------ arriving

## The first time in the Cieux (up from the Monts): the pterosaur circles once and lands, folds its
## wings; the silence; the sea of clouds; the lead dino meets the sky; the small flyers; the arch,
## far up, and a huge shadow wheeling.
static func arrival() -> void:
	if Game.flag(&"cieux_arrivee"):
		return
	var w = S.world()
	if w == null:
		return
	S.lock(true)
	await S.wait(0.4)
	var chloe := Stage.chloe()
	var cast := {}
	var up: Vector2 = chloe.global_position + Vector2(0.0, -6.0 * S.CELL)
	var lines: Array = _lands(cast)
	lines.append_array([
		{"who": CHLOE, "text": "(… Plus un bruit. Même le vent fait moins de bruit, ici. Il passe à côté.)"},
		CS.cue({"text": "Tout autour du piton, une mer de nuages, blanche, qui bouge très lentement. Les Monts sont dessous, quelque part. Tout petits."},
			func() -> void: Stage.look_at(chloe.global_position + Vector2(0.0, 4.0 * S.CELL), 1.6)),
		CS.cue({"text": "Le froid pique autrement, là-haut. Un froid qui vient d'en haut, pas d'en bas. Chloé remonte son col jusqu'aux yeux."},
			func() -> void:
				Stage.look_back(1.0)
				Stage.tremble(chloe, 1.0, 1.4)
				MS.breath(chloe, 7)),
	])
	var lead := Game.lead_dino()
	if lead:
		lines.append_array(_meets_the_sky(lead))
	lines.append_array([
		CS.cue({"text": "Des petits ptérosaures à longue queue filent dans le vent, en bande, et se laissent retomber comme des feuilles."},
			func() -> void: _rhamphos(cast, up)),
		CS.cue({"text": "Et tout en haut, au-dessus de tous les pitons, une arche de pierre. Le vent y chante, très loin. Au-dessus d'elle, une ombre immense tourne, les ailes ouvertes."},
			func() -> void: _the_arch_far(cast, up)),
		CS.cue({"text": "Dans la sacoche, les Cœurs battent plus fort qu'aux Monts. Comme s'ils avaient hâte, eux."},
			func() -> void:
				Stage.look_back(1.2)
				MS.hearts(2, 1.0)),
		{"who": CHLOE, "text": "(Le Sceau des Cieux. Et le Masque, quelque part là-haut, qui attend « tous les Cœurs d'un coup ».)" if Game.flag(&"suie_indice")
			else "(Le Sceau des Cieux est quelque part là-haut. Et quelque chose d'immense le garde.)"},
		{"flag": &"cieux_arrivee"},
	])
	await S.say(lines)
	for k in cast:
		var n = cast[k]
		if is_instance_valid(n):
			Stage.fade_out(n, 1.0, true)
	CS.lead_back()
	Stage.look_back()
	Game.award_team_xp(XP_ARRIVEE)
	Save.save_game()
	S.lock(false)


## The pterosaur that carried her circles once over the piton and lands beside her, folds its
## wings « comme un parapluie »; Chloé slides down.
static func _lands(cast: Dictionary) -> Array:
	var chloe := Stage.chloe()
	var at: Vector2 = chloe.global_position
	var flying := flyer()
	var species: StringName = flying.species().id if flying else &"pteranodon"
	var name: String = flying.nickname if flying else "Le Ptéranodon"
	var circles := func() -> void:
		var bird := stand_in(species, at + Vector2(-120.0, -80.0), "PorteurCieux", 0, 1.1)
		cast["bird"] = bird
		if bird == null:
			return
		keep_rest(bird)
		Stage.fade_in(bird, 0.5)
		await CS.circle(bird, at, 110.0, LANDING_CIRCLE, LANDING_HEIGHT)
		await CS.fly(bird, at + LANDS_AT, 0.9, LANDING_HEIGHT * 0.5)
		land(bird)
		MS.snow_puff(at + LANDS_AT, 8, 0.1, 0.4)
	var folds := func() -> void:
		var bird = cast.get("bird")
		if bird:
			Stage.turn_to(bird, at)
			Stage.bow(bird, 1.2)
		Stage.hop(chloe, 1, 8.0)
		Stage.emote(chloe, "!")
	return [
		CS.cue({"text": "%s tourne une fois au-dessus du piton, les ailes immobiles, et se pose. Il n'a pas battu des ailes une seule fois : c'est le vent qui montait." % name}, circles),
		CS.cue({"text": "Il replie ses ailes comme un parapluie. Chloé se laisse glisser de son dos, les jambes en coton."}, folds),
	]


## How the lead dino takes the sky, acted out at Chloé's side (the raptor looks down and sits very
## fast; the armoured one keeps far from the edge; the duck-bill calls, and nothing answers).
static func _meets_the_sky(lead: Dino) -> Array:
	var dino := CS.lead()
	var chloe := Stage.chloe()
	var edge: Vector2 = chloe.global_position + Vector2(0.0, 2.5 * S.CELL)
	var sees := func() -> void:
		if dino:
			await CS.lead_walk(edge + Vector2(30.0, -20.0), 120.0)
			Stage.turn_to(dino, edge)
			await S.wait(0.5)
			Stage.recoil(dino, edge, 18.0)
			CS.crouch(dino, 0.2, 0.6)
	var stays := func() -> void:
		if dino:
			await CS.lead_walk(chloe.global_position + Vector2(-20.0, -40.0), 60.0)
			Stage.turn_to(dino, edge)
			Stage.tremble(dino, 0.8, 1.0)
	var calls := func() -> void:
		if dino:
			Stage.cry(dino, &"neutre")
			Stage.rear(dino, 1.0)
			await S.wait(1.6)
			Stage.emote(dino, "?")
	match lead.species().family:
		&"raptor":
			return [CS.cue({"text": "%s trotte jusqu'au bord, regarde en bas… et s'assoit. Très vite. Très loin du bord, tout d'un coup." % lead.nickname}, sees)]
		&"armored":
			return [CS.cue({"text": "%s ne va pas voir le bord. %s reste au milieu du piton, les pattes bien écartées, et regarde le vide de loin. De très loin." % [lead.nickname, lead.nickname]}, stays)]
		&"hadrosaur":
			return [CS.cue({"text": "%s lance un appel vers les nuages. Et rien ne répond. Pas d'écho, ici : le son part, et ne revient pas." % lead.nickname}, calls),
				{"who": CHLOE, "text": "(Ici, personne ne répond. C'est ça, le silence des Cieux.)"}]
	return [CS.cue({"text": "%s regarde le vide, puis Chloé, puis le vide. Et se colle contre sa jambe." % lead.nickname}, stays)]


## A band of small long-tailed flyers wheels round `up`, then drifts away (stand-ins, gone after).
static func _rhamphos(cast: Dictionary, up: Vector2) -> void:
	Stage.look_at(up, 1.2)
	for i in 3:
		var phase := TAU * i / 3.0
		var start := up + Vector2(cos(phase), sin(phase) * 0.55) * RHAMPHO_RADIUS
		var bird := stand_in(&"rhamphorhynchus", start, "Rhampho%d" % i, 0, 0.7)
		if bird == null:
			continue
		cast["rhampho_%d" % i] = bird
		Stage.fade_in(bird, 0.6)
		CS.circle(bird, up, RHAMPHO_RADIUS, 4.0, CS.FLY_HEIGHT + 40.0 * i, phase)


## Far up: the arch (the camera looks that way), and a huge shadow wheeling.
static func _the_arch_far(cast: Dictionary, up: Vector2) -> void:
	var sky := up + Vector2(0.0, -6.0 * S.CELL)
	await CS.pan(sky, 2.2)
	var big := stand_in(&"quetzalcoatlus", sky + Vector2(-140.0, 30.0), "OmbreDesCieux", 0, 1.7)
	if big == null:
		return
	cast["big"] = big
	big.modulate = Color(0.5, 0.52, 0.62, 0.0)
	big.create_tween().tween_property(big, "modulate:a", 0.8, 1.2)
	CS.circle(big, sky, 160.0, 6.0, CS.FLY_HEIGHT + 200.0)


# ------------------------------------------------------------------ the first bridge

## The first liana bridge (StoryTrigger « PremierPont », event « premier_pont »): it sways; Chloé
## holds the lianas; her lead dino crosses its own way. Once.
static func pont(_trigger: Node) -> void:
	if Game.flag(&"pont_lianes_vu"):
		return
	S.lock(true)
	var chloe := Stage.chloe()
	var dino := CS.lead()
	var lead := Game.lead_dino()
	var sways := func() -> void:
		Stage.shake(1.2, 1.4)
		Stage.tremble(chloe, 1.4, 2.0)
	var holds := func() -> void:
		Stage.bow(chloe, 1.0)
		CS.reach(chloe, chloe.global_position + Vector2(30.0, -10.0), 8.0, 1.2)
	var lines: Array = [
		CS.cue({"text": "Le pont de lianes est tressé serré, mais dès que Chloé pose le pied dessus, il se balance. Dessous, les nuages. Rien d'autre."}, sways),
		CS.cue({"who": CHLOE, "text": "(On ne regarde pas en bas. On regarde les lianes. On s'accroche aux lianes.)"}, holds),
	]
	if lead and dino:
		var ahead: Vector2 = chloe.global_position + Vector2(90.0, 0.0)
		match lead.species().family:
			&"raptor":
				lines.append(CS.cue({"text": "%s traverse en courant, en quatre bonds, et attend de l'autre côté. Il a l'air vexé qu'elle soit si lente." % lead.nickname},
					func() -> void:
						await CS.lead_walk(ahead, 200.0)
						Stage.turn_to(dino, chloe.global_position)
						Stage.hop(dino, 2, 6.0)))
			&"armored":
				lines.append(CS.cue({"text": "%s avance très lentement, une patte après l'autre. Le pont plie sous lui, et grince. Il passe. Le pont se souviendra de lui." % lead.nickname},
					func() -> void:
						CS.lead_walk(ahead, 30.0)
						Stage.shake(0.8, 2.0)))
			&"hadrosaur":
				lines.append(CS.cue({"text": "%s ferme les yeux et marche tout droit, le nez contre le dos de Chloé. Ça marche aussi." % lead.nickname},
					func() -> void: CS.lead_walk(chloe.global_position + Vector2(20.0, 12.0), 60.0)))
			_:
				lines.append(CS.cue({"text": "%s traverse derrière elle, sans un bruit, comme s'il ne voulait pas réveiller le pont." % lead.nickname},
					func() -> void: CS.lead_walk(chloe.global_position + Vector2(20.0, 12.0), 60.0)))
	lines.append_array([
		{"text": "Sur le piton d'en face, une planchette clouée à un poteau : « Un pont de lianes, ça se traverse. Ça ne se regarde pas. — H. »"},
		{"who": CHLOE, "text": "(Merci, Hélène. Pour le conseil. Un peu tard.)"},
		{"flag": &"pont_lianes_vu"},
	])
	await S.say(lines)
	CS.lead_back()
	Stage.look_back()
	Game.award_team_xp(XP_PONT)
	Save.save_game()
	S.lock(false)
