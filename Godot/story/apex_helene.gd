class_name ApexHelene
## Chapter 9, scene 3, after the battle (zone coeur_apex; docs/chapitre-9-scenes.md § 3 g to 3 j):
## the veins go out from the eyes to the tail; he lies down, a long breath; he blows on the rock where
## Maïa holds Isaure and Isaure holds Hélène: the amber left on her cracks « comme une noix » (no
## music from here to the end of the scene); Hélène wakes and knows the little one (« Tu as grandi. »),
## funny within the minute (« Tu as attaché tes cheveux. »); he lowers his head to her hands; Moustique
## and the cardboard mask go back to Maïa, the mask to Isaure, « Pas encore »; the Roi, who never
## left, comes down for Hélène (« Je vais les fermer, Chloé. Juste cette fois. »). Fade; « Trois jours
## plus tard »: the Cabinet (story/epilogue.gd).
## Flags: helene_liberee, helene_reveillee, moustique_rendu, masque_carton_rendu, masque_carton_pris,
## apex_fini.

const S := preload("res://story/story.gd")
const CS := preload("res://story/cote_stage.gd")
const MS := preload("res://story/monts_stage.gd")
const Act := preload("res://story/marais_stage.gd")
const V := preload("res://story/volcan.gd")
const C := preload("res://story/cieux.gd")
const A := preload("res://story/apex.gd")
const CHLOE := "Chloé"
const MAIA := "Maïa"
const ISAURE := "Isaure"
const HELENE := "Hélène"
const MASK := "masque_carton"
## How Hélène knows the little one (by its species).
const KNOWS := {
	&"velociraptor": "… Le petit de Griffe-Grise. Il a ses yeux. Et deux dents de plus.",
	&"ankylosaurus": "… Le petit du Vieux Rempart. On s'est assis dessus, je parie. Tout le monde s'assoit dessus.",
	&"parasaurolophus": "… Le petit de la Voix. Il a chanté ; j'ai entendu, de là-dedans. Il chante faux. Ça ne fait rien.",
}
const WARM_BITS: Array[Color] = [Color(1.0, 0.86, 0.6), Color(1.0, 0.95, 0.8), Color(0.95, 0.75, 0.45)]
## The Roi comes down from high above (px), its size.
const ROI_FROM := Vector2(80.0, -560.0)
const ROI_SIZE := 1.3
const XP_HELENE := 80


## 3 g to 3 j, then the Cabinet three days later.
static func after_battle(cast: Dictionary) -> void:
	S.lock(true)
	Audio.push_music(null, 1.0)   # (no music: Hélène wakes)
	if not Game.flag(&"helene_liberee"):
		await _amber_cracks(cast)
	await S.say(she_wakes(cast))
	await _his_muzzle(cast)
	await S.say(moustique_and_mask(cast))
	await _roi_comes(cast)
	await S.say(the_roi(cast))
	Game.award_team_xp(XP_HELENE)
	Save.save_game()
	await three_days_later(cast)


# ------------------------------------------------------------------ 3 g, the amber cracks (watched)

## The veins go out from the eyes to the tail; he lies down slowly; a long breath that moves the
## ash; the crater stops shaking; the floor's veins turn from white to gold; he turns his head to the
## rock and blows: a warm wind; the amber left on Hélène cracks like a nut and falls in golden bits.
## Her hand moves.
static func _amber_cracks(cast: Dictionary) -> void:
	var him = cast.get("souverain")
	if not him is Node2D:
		him = V.actor_of(["Souverain"])
	var rock: Vector2 = cast.get("rock", A.spot_or("ROCHER_ABRI", A.chloe_px() + Vector2(-4.0 * S.CELL, -1.0 * S.CELL)))
	if him is DinoNpc:
		Stage.look_at((him as Node2D).global_position, 1.0)
		await (him as DinoNpc).cleanse()
		await CS.crouch(him, 0.22, 1.6)
		Act.burst((him as Node2D).global_position + Vector2(0.0, 10.0), V.ASH_BITS, 18, 0.2, 1.0)
	await S.wait(1.0)
	for i in 3:   # (the floor's veins: white, then gold)
		CS.pulse(A.chloe_px() + Vector2(randf_range(-6.0, 6.0), randf_range(-5.0, 3.0)) * S.CELL, Color(1.0, 0.95, 0.85) if i == 0 else A.AMBER, 1, 1.0, 2.5, 6.0)
		await S.wait(0.5)
	if him is Node2D:
		Stage.turn_to(him, rock)
		await S.wait(0.6)
		Stage.lunge(him, rock, 0.3, false)
	Stage.look_at(rock, 1.0)
	for i in 3:
		Act.burst(rock + Vector2(20.0 + 10.0 * i, -10.0), WARM_BITS, 10, 0.6, 0.6)
		await S.wait(0.3)
	CS.sfx("res://assets/audio/sfx/glass.wav", -8.0)
	CS.sparkle(rock + Vector2(40.0, -10.0), 0.6, 18, 0.3)
	Act.burst(rock + Vector2(40.0, 0.0), A.AMBER_BITS, 14, 0.4, 0.5)
	await S.wait(0.8)
	var h = cast.get("helene")
	if h:
		Stage.hop(h, 1, 3.0)
	await S.wait(0.8)
	Game.set_flag(&"helene_liberee")


# ------------------------------------------------------------------ 3 h, Hélène

## 3 h (10 lines): she looks at him, at Chloé, at the little one; she knows it; « Tu as grandi. »;
## « Tu ne m'as pas cherchée tout de suite. »; Isaure, « Mal »; « Tu as attaché tes cheveux. »
static func she_wakes(cast: Dictionary) -> Array:
	var h = cast.get("helene")
	var isaure = cast.get("isaure")
	var looks := func() -> void:
		var him = cast.get("souverain")
		if h and him is Node2D:
			Stage.look_at((h as Node2D).global_position, 0.8)
			Stage.turn_to(h, (him as Node2D).global_position)
			await S.wait(1.6)
		if h:
			Stage.turn_to(h, A.chloe_px())
		var dino := CS.lead()
		if dino:
			await S.wait(0.8)
			Stage.turn_to(dino, h.global_position if h is Node2D else A.chloe_px())
			Stage.emote(dino, "♥")
	var hand := func() -> void:
		if h and isaure:
			await CS.reach(h, (isaure as Node2D).global_position, 6.0, 0.8)
			await CS.reach(isaure, (h as Node2D).global_position, 6.0, 0.8)
	var a_while := func() -> void:
		if h:
			Stage.emote(h, "…")
	return [
		CS.cue({"text": "Hélène ouvre les yeux. Elle regarde le Souverain, d'abord. Longtemps. Puis Chloé. Puis, à côté de Chloé, le dino."}, looks),
		{"who": HELENE, "text": KNOWS.get(A.starter_species(), KNOWS[&"parasaurolophus"])},
		{"who": HELENE, "text": "Tu as grandi."},
		{"who": CHLOE, "text": "(Elle parle au dino. … Non. Elle me regarde.)"},
		{"who": HELENE, "text": "Tu ne m'as pas cherchée tout de suite."},
		{"who": CHLOE, "text": "Non. Je les ai trouvés d'abord. Les trois. Maïa en a un, et l'autre est avec moi."},
		CS.cue({"who": HELENE, "text": "Bien. … Alors c'est tout de suite. Isaure."}, hand),
		{"who": ISAURE, "text": "Je t'ai sortie de là. Mal."},
		CS.cue({"who": HELENE, "text": "Tu m'as toujours sortie de partout. Mal. Et je suis toujours sortie. Tu as attaché tes cheveux."}, a_while),
		{"who": ISAURE, "text": "… Tu as un an de retard pour le remarquer."},
		{"flag": &"helene_reveillee"},
	]


## Watched, no line: he lowers his head to Hélène; she puts her damaged hand on his muzzle; he blows,
## warm, not burning. Maïa, who still holds her mother by the collar, lets go at last.
static func _his_muzzle(cast: Dictionary) -> void:
	var him = cast.get("souverain")
	var h = cast.get("helene")
	var to: Vector2 = (h as Node2D).global_position if h is Node2D else A.chloe_px() + Vector2(-3.0 * S.CELL, 0.0)
	if him is DinoNpc:
		CS.get_up(him, 0.6)
		Stage.look_at(to.lerp((him as Node2D).global_position, 0.4), 1.0)
		await (him as DinoNpc).walk_to(S.ground_near(to + Vector2(2.2 * S.CELL, -1.4 * S.CELL), 3), 50.0)
		Stage.turn_to(him, to)
		await Stage.bow(him, 1.4)
	if h:
		await CS.reach(h, to + Vector2(2.0 * S.CELL, -1.0 * S.CELL), 10.0, 1.0)
	Act.burst(to + Vector2(30.0, -20.0), WARM_BITS, 12, 0.6, 0.5)
	await S.wait(1.0)
	var maia = cast.get("maia")
	if maia is Npc:
		await Stage.recoil(maia, to, 14.0)
		Stage.emote(maia, "…")
	await S.wait(0.6)


# ------------------------------------------------------------------ 3 i, Moustique, the mask

## 3 i (10 lines; 7 without the cardboard mask): « Il n'a plus peur. »; Page 10; the other way was
## him; Moustique on Maïa's shoulder, the mask held out (« Tu peux les reprendre »); « Aïe. Oui. Moi
## aussi. »; the mask to her mother, a second time: « Pas encore ».
static func moustique_and_mask(cast: Dictionary) -> Array:
	var mask := A.has_cardboard_mask()
	var maia = cast.get("maia")
	var isaure = cast.get("isaure")
	var to_maia := func() -> void:
		var chloe := Stage.chloe()
		if chloe == null:
			moustique_leaves()
			return
		if maia is Npc:
			await (maia as Npc).walk_to(S.ground_near(chloe.global_position + Vector2(-56.0, -6.0), 2), "", 90.0)
			(maia as Npc).face(chloe.global_position)
		var bird := A.stand_in(&"dimorphodon", chloe.global_position + V.SHOULDER, "MoustiqueRendu", V.MOUSTIQUE_LEVEL, 0.8)
		cast["moustique"] = bird
		if bird:
			await Stage.fade_in(bird, 0.3)
			await CS.reach(chloe, A.px_of(maia, Vector2(-56.0, 0.0)), 10.0, 0.6)
			await CS.fly(bird, A.px_of(maia, Vector2(-56.0, 0.0)) + V.SHOULDER, 0.9, V.SHOULDER_UP)
		moustique_leaves()
		if mask and ItemsDB.ITEMS.has(MASK):
			Act.pop(chloe.global_position, MASK, 0.9)
	var bites := func() -> void:
		var bird = cast.get("moustique")
		if bird:
			Stage.lunge(bird, A.px_of(maia), 0.3, false)
		if maia:
			Stage.hop(maia, 1, 4.0)
	var holds_out := func() -> void:
		if maia and isaure is Node2D:
			if ItemsDB.ITEMS.has(MASK):
				Act.pop((maia as Node2D).global_position, MASK, 0.9)
			await CS.reach(maia, (isaure as Node2D).global_position, 12.0, 1.4)
	var takes := func() -> void:
		mask_taken()
		if isaure:
			Stage.bow(isaure, 0.8)
	var out: Array = [
		{"who": HELENE, "text": "Il n'a plus peur. … Vingt-six ans que je le connais, et c'est la première fois que je le vois sans peur. C'est toi qui as fait ça. Avec lui. Je n'aurais pas su."},
		{"who": CHLOE, "text": "Tu avais écrit comment. Page 10."},
		{"who": HELENE, "text": "J'écris mieux que je fais. Tout le monde le sait. Anselme le dit à tout le monde."},
		{"who": CHLOE, "text": "(Il y avait un autre moyen. C'était lui. Il suffisait qu'il n'ait plus peur. … Personne ne pouvait le savoir. Elle, peut-être.)"},
		CS.cue({"text": "Moustique sort du col de Chloé, regarde Maïa, et ne bouge pas. Chloé le prend dans ses deux mains et le pose sur l'épaule de Maïa." + (" Puis elle sort le masque en carton." if mask else "")}, to_maia),
		{"who": CHLOE, "text": "Tiens. Je suis revenue. Tu peux les reprendre." if mask else "Tiens. Je suis revenue. Tu peux le reprendre."},
		CS.cue({"who": MAIA, "text": "Je savais que tu reviendrais. C'était juste pour être sûre. Aïe. Oui. Moi aussi."}, bites),
		{"flag": &"moustique_rendu"},
	]
	if mask:
		out.append_array([
			CS.cue({"text": "Maïa tend le masque en carton à sa mère. La deuxième fois."}, holds_out),
			CS.cue({"who": ISAURE, "text": "… Je le prends. Je ne le mets pas. Pas encore."}, takes),
			{"who": MAIA, "text": "« Pas encore », c'est mieux que « pas aujourd'hui ». On avance."},
			{"flag": &"masque_carton_rendu"},
			{"flag": &"masque_carton_pris"},
		])
	return out


## Moustique goes back to Maïa: he leaves Chloé's party, or the Cabinet's reserve (ApexBag).
static func moustique_leaves() -> void:
	ApexBag.moustique_leaves()
	Game.set_flag(&"moustique_rendu")
	Game.party_changed.emit()


## The cardboard mask leaves Chloé's bag: Maïa gave it to her mother, who keeps it in her jacket.
static func mask_taken() -> void:
	ApexBag.take(MASK)
	Game.set_flag(&"masque_carton_rendu")
	Game.set_flag(&"masque_carton_pris")
	Game.party_changed.emit()


# ------------------------------------------------------------------ 3 j, the Roi

## Watched, no line: a cry high above; the Roi des Cieux comes down turning, lands at the edge of the
## hall and lowers his neck to Hélène. He never left.
static func _roi_comes(cast: Dictionary) -> void:
	var h = cast.get("helene")
	var edge := A.spot_or("ROI_POSE", S.ground_near(A.chloe_px() + Vector2(4.0 * S.CELL, -1.0 * S.CELL), 3))
	Stage.look_at(edge + Vector2(0.0, -3.0 * S.CELL), 1.0)
	CS.far_cry("pteranodon", "attaque", -4.0, 0.7)
	await S.wait(0.8)
	var roi := A.stand_in(&"quetzalcoatlus", edge + ROI_FROM, "RoiCoeur", 0, ROI_SIZE)
	cast["roi"] = roi
	if roi == null:
		await S.wait(1.0)
		return
	C.keep_rest(roi)
	roi.modulate.a = 1.0
	await CS.circle(roi, A.spot_or("ROI_CIEL_COEUR", edge + Vector2(0.0, -2.0 * S.CELL)), 90.0, 1.8, CS.FLY_HEIGHT + 160.0)
	await CS.fly(roi, edge, 2.2, CS.FLY_HEIGHT + 100.0)
	C.land(roi)
	Stage.shake(1.5, 0.5)
	if h is Node2D:
		await roi.walk_to(S.ground_near((h as Node2D).global_position + Vector2(2.4 * S.CELL, 0.4 * S.CELL), 3), 70.0)
		Stage.turn_to(roi, (h as Node2D).global_position)
		await Stage.bow(roi, 1.6)


## 3 j (3 lines): « Il n'est jamais reparti ? »; « Je vais les fermer, Chloé. Juste cette fois. »;
## Maïa and her mother go back up on foot.
static func the_roi(cast: Dictionary) -> Array:
	var maia = cast.get("maia")
	var asks := func() -> void:
		var isaure = cast.get("isaure")
		if maia and isaure is Node2D:
			Stage.turn_to(maia, (isaure as Node2D).global_position)
	return [
		{"who": HELENE, "text": "Le Roi. … Il n'est jamais reparti ? « On se penche. On ne ferme pas les yeux. » Je me souviens de l'avoir écrit."},
		{"who": HELENE, "text": "Je vais les fermer, Chloé. Juste cette fois. Ne le dis pas à Anselme."},
		CS.cue({"who": MAIA, "text": "Nous, on remonte à pied. Je n'ai pas d'ailes, moi, et c'est très bien comme ça. Tu viens ? Tu ne cours jamais. Moi non plus."}, asks),
		{"flag": &"apex_fini"},
	]


## Fade to black; he stays lying in the middle of the crater, his eyes open, without fear; « Trois
## jours plus tard »; the Cabinet (story/epilogue.gd plays there).
static func three_days_later(cast: Dictionary) -> void:
	await Router.fade_out(1.6)
	A.clean_up(cast)
	Game.day += 2
	Game.pass_time_until(10.0)
	await Epilogue.card("Trois jours plus tard")
	Audio.pop_music(0.5)
	S.lock(false)
	var w = S.world()
	if w and w.has_method(&"goto_zone"):
		w.call(&"goto_zone", A.CABINET, &"Depart")
	else:
		await Router.fade_in(0.6)


# ------------------------------------------------------------------ for the tests

## For the tests (tools/capture.gd « static »): after the battle on any zone (him, Isaure with
## Hélène, Maïa, Caillou brought on round Chloé): 3 g to 3 j, without going to the Cabinet.
static func static_helene() -> void:
	S.playing += 1
	Game.set_flag(&"apex_ouvert")
	Game.set_flag(&"goutte_noire")
	Game.set_flag(&"souverain_eveille")
	S.lock(true)
	var cast := ApexCoeur.stage()
	Audio.push_music(null, 0.5)
	await _amber_cracks(cast)
	await S.say(she_wakes(cast))
	await _his_muzzle(cast)
	await S.say(moustique_and_mask(cast))
	await _roi_comes(cast)
	await S.say(the_roi(cast))
	await Router.fade_out(1.0)
	await Epilogue.card("Trois jours plus tard")
	await Router.fade_in(0.6)
	Audio.pop_music(0.5)
	A.clean_up(cast)
	S.lock(false)
	S.playing -= 1
