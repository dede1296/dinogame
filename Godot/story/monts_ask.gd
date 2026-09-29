class_name MontsAsk
## Chapter 6, the Monts Gelés: the questions Chloé may ask there (« Une question… », like
## story/ask.gd): how to get through the ice walls, the lady with the sled, the Col des Tempêtes,
## the sanctuary's guardian, the red lights at night, what lies above the Monts, and, to
## Bertille, her herds, Grelot and Hélène. Bertille has her own list (bertille_topics); Roc and
## Maïa get the chapter's questions through Ask.story_topics() (story_topics), answered by
## answer() (Ask.answer tries it first).

const S := preload("res://story/story.gd")
const MS := preload("res://story/monts_stage.gd")
const TOPICS := {
	&"manteau": "Où trouver un vêtement chaud ?",
	&"murs_glace": "Comment passer les murs de glace ?",
	&"traineau": "Et la dame au traîneau ?",
	&"col": "Et le Col des Tempêtes ?",
	&"titan": "Qui garde le sanctuaire ?",
	&"forges": "Et les lueurs rouges, la nuit ?",
	&"cieux": "Qu'y a-t-il au-dessus des Monts ?",
	&"troupeaux": "Et vos troupeaux ?",
	&"grelot": "Et Grelot ?",
	&"helene_monts": "Vous connaissiez bien Hélène ?",
}


## The question's words (the Monts' or Ask's).
static func label(npc: StringName, topic: StringName) -> String:
	if TOPICS.has(topic):
		return TOPICS[topic]
	return Ask.label(npc, topic)


## Ask.menu, for the Monts' questions too: `prompt` said by `speaker`, then `action` (when
## given), the `topics`, « Au revoir ». True when Chloé picked the action.
static func menu(npc: StringName, speaker: String, prompt: String, topics: Array, action := "") -> bool:
	if topics.is_empty() and action == "":
		await S.say([{"who": speaker, "text": prompt}])
		return false
	var asked := {}
	while true:
		var options: Array = []
		if action != "":
			options.append(action)
		var shown := topics.filter(func(t: StringName) -> bool: return not asked.has(t))
		for t: StringName in shown:
			options.append(label(npc, t))
		options.append(Ask.GOODBYE)
		var pick := await Dialogue.choose(speaker, prompt, options)
		if action != "" and pick == 0:
			return true
		var i := pick - (1 if action != "" else 0)
		if i < 0 or i >= shown.size():
			return false
		var topic: StringName = shown[i]
		asked[topic] = true
		await S.say([{"who": "Chloé", "text": label(npc, topic)}])
		var said := answer(npc, speaker, topic)
		await S.say(said if not said.is_empty() else Ask.answer(npc, speaker, topic))
		if asked.size() == topics.size() and action == "":
			return false
		prompt = Ask.AGAIN
	return false


## The Monts' questions of the moment, for Roc and Maïa (added to Ask.story_topics()).
static func story_topics() -> Array:
	var out: Array = []
	if Game.flag(&"maia_enfuie") and not Monts.has_coat():
		out.append(&"manteau")
	if not Game.flag(&"monts_arrivee"):
		return out
	if not Game.flag(&"grottes_glace_arrivee"):
		out.append(&"murs_glace")
	if Game.flag(&"suie_monts_battue") and not Game.flag(&"sanctuaire_givre_ouvert"):
		out.append(&"col")
	if Game.flag(&"sanctuaire_givre_ouvert") and not Game.flag(&"sceau_monts"):
		out.append(&"titan")
	if Game.flag(&"forges_vues"):
		out.append(&"forges")
	if Game.flag(&"suie_monts_battue"):
		out.append(&"cieux")
	return out


## What Chloé may ask Bertille.
static func bertille_topics() -> Array:
	var out: Array = []
	if Objectives.main_hint() != "":
		out.append(&"suite")
	if not Game.flag(&"grelot_rentre"):
		out.append(&"grelot")
	if not Game.flag(&"suie_monts_partie"):
		out.append(&"traineau")
	if not Game.flag(&"grottes_glace_arrivee"):
		out.append(&"murs_glace")
	elif Game.flag(&"suie_monts_battue") and not Game.flag(&"sanctuaire_givre_ouvert"):
		out.append(&"col")
	elif Game.flag(&"sanctuaire_givre_ouvert") and not Game.flag(&"sceau_monts"):
		out.append(&"titan")
	if Game.flag(&"forges_vues"):
		out.append(&"forges")
	out.append(&"troupeaux")
	out.append(&"helene_monts")
	return out


## The answer to one of the Monts' questions, [] for any other (Ask answers those).
static func answer(npc: StringName, speaker: String, topic: StringName) -> Array:
	match topic:
		&"suite":
			if npc == &"bertille":
				var hint := Objectives.main_hint()
				return [{"who": speaker, "text": "Moi, je ne suis qu'une vieille bergère. Mais si j'étais toi… " + hint if hint != ""
					else "Rien ne presse. La neige, elle, a tout son temps. Assieds-toi."}]
		&"manteau":
			return [{"who": speaker, "text": _coat(npc)}]
		&"murs_glace":
			return [{"who": speaker, "text": _ice_walls(npc)}]
		&"traineau":
			return [{"who": speaker, "text": _sled(npc)}]
		&"col":
			return [{"who": speaker, "text": _col(npc)}]
		&"titan":
			return [{"who": speaker, "text": _guardian(npc)}]
		&"forges":
			return [{"who": speaker, "text": _forges(npc)}]
		&"cieux":
			return [{"who": speaker, "text": _skies(npc)}]
		&"troupeaux":
			return [{"who": speaker, "text": "Des Edmontosaurus, qui chantent quand la neige arrive, et des Pachyrhinosaurus, qui ont une grosse bosse sur le nez au lieu d'une corne. Ils broutent la vallée le jour, sous la neige."},
				{"who": speaker, "text": "Si l'un d'eux veut bien te suivre, prends-en soin. Et ne t'étonne pas s'il casse la glace de ta gourde, le matin : c'est leur façon de dire bonjour."}]
		&"grelot":
			return [{"who": speaker, "text": "Mon plus petit. Il a suivi le traîneau vers le glacier, j'en suis sûre. S'il n'était pas si têtu… Tu le trouveras sûrement au pied des murs de glace, en train de leur foncer dessus. Il croit qu'il peut tout casser."}]
		&"helene_monts":
			return [
				{"who": speaker, "text": "Elle arrivait toujours en retard, les joues rouges, avec un carnet plein de dessins de mes troupeaux. Elle leur donnait des noms. Je ne les ai jamais retenus : ils ont tous la même tête."},
				{"who": speaker, "text": "Elle me racontait l'île, la mer, et une petite-fille qu'elle ne voyait pas assez. Elle disait que tu comptais sur tes doigts, comme moi. Et que tu te trompais aussi."},
				{"who": speaker, "text": "Et puis elle montait au col, toute seule, et elle redescendait sans rien dire. Je ne posais pas de questions. Je réchauffais la soupe."},
			]
	return []


## A warm coat for the Monts: where to buy it, and the coins (Monts.coat_step).
static func _coat(npc: StringName) -> String:
	var step := Monts.coat_step()
	match npc:
		&"roc":
			return "Là-haut ? Hélène montait avec trois pulls et l'écharpe que je lui avais tricotée. Enfin, commencée. Toi, prends plutôt un vrai manteau. " + step
		&"joss":
			return "Un manteau ? J'en ai justement ! Enfin, c'est Rosalie qui les a faits. Moi, j'ai fait les coutures. " + step
		&"gustave":
			return "Là-haut ? Même les poissons gèlent. Achète un manteau, petite. " + step
	return step


## The ice walls: a dino that charges (in the party, at the Cabinet, or where to find one).
static func _ice_walls(npc: StringName) -> String:
	var charge := MS.charger()
	var step := MS.charge_step()
	var how := "Ton %s a la tête qu'il faut : un bon coup, et la glace cédera." % charge.nickname if charge else step
	match npc:
		&"bertille":
			return "La glace du glacier repousse chaque nuit, comme de l'herbe. Il faut une tête dure pour passer. " + how
		&"roc":
			return "Hélène passait les murs de glace avec un vieux Pachyrhinosaurus de la vallée : il fonçait, et BOUM. Moi, je passais après, en m'excusant auprès de la glace. " + how
		&"maia":
			return "Un mur de glace ? Caillou le ferait voler en éclats ! … Enfin, Caillou est avec moi. " + how
	return how


## The lady in grey and her sled.
static func _sled(npc: StringName) -> String:
	match npc:
		&"bertille":
			return "Polie comme une vitre, et froide pareil. Elle a demandé si mes troupeaux avaient « bon caractère ». Je lui ai dit : meilleur que le vôtre. Elle a noté ça dans un petit carnet noir."
		&"roc":
			return "Une chimiste, avec des fioles, dans les Monts ? Hélène avait caché quelque chose là-haut, dans la glace. Elle ne me l'a jamais montré. … Va voir, Chloé. Vite."
	return "Une dame en gris, avec un traîneau plein de fioles. Elle est montée au glacier, au nord."


## The Col des Tempêtes, up to the sanctuary.
static func _col(npc: StringName) -> String:
	match npc:
		&"bertille":
			return "Le Col des Tempêtes, à l'est. Là-haut, le vent souffle si fort qu'on ne voit plus ses pieds. Hélène y montait seule. Elle disait qu'une porte l'attendait. Une porte ! En pleine montagne !"
		&"roc":
			return "Le col… C'est là qu'Hélène m'a fait promettre, il y a deux ans. Si le blizzard se lève, reste près d'un gros dino, et ne lâche pas le chemin."
		&"maia":
			return "Le Col des Tempêtes ? Avec un nom pareil, c'est sûrement le plus stylé de toute l'île. Ou le plus froid. Sûrement les deux."
	return "Le Col des Tempêtes, à l'est de la vallée. Tout en haut, une porte de givre."


## The sanctuary's guardian: the Cryolophosaure Titan (a battle of honour; the tip).
static func _guardian(npc: StringName) -> String:
	var tip := _tip()
	match npc:
		&"bertille":
			return "Là-haut ? Personne n'y va. Mais les nuits de grand froid, on entend quelque chose rugir, et mes troupeaux se serrent les uns contre les autres." + tip
		&"roc":
			return "Un Cryolophosaure, grand comme un arbre, avec une crête ridicule. C'est moi qui l'ai surnommé « Toupet ». Il ne me l'a jamais pardonné. Ce sera un combat d'honneur : pas de collier, pas de fuite." + tip
		&"maia":
			return "Un Cryolophosaure GÉANT ?! Avec une crête comme une coiffure ? Je veux le voir. Non. Je veux le dessiner. Non : je veux le voir, PUIS le dessiner." + tip
	return "Le Cryolophosaure Titan, gardien du sanctuaire de Givre. Un combat d'honneur." + tip


## The tip before the Titan: what hits it hard (read from its species, when it is there).
static func _tip() -> String:
	var id := MS.species_or(&"cryolophosaure_titan")
	var species := SpeciesDB.get_species(id)
	if species == null:
		return ""
	var weak := MS.weak_to(MovesDB.FAMILY_TYPES.get(species.family, "terre"))
	return " (%s le touche%s fort.)" % [weak.substr(0, 1).to_upper() + weak.substr(1), "nt" if " et " in weak else ""] if weak != "" else ""


## The red lights at the foot of the volcano, at night.
static func _forges(npc: StringName) -> String:
	match npc:
		&"bertille":
			return "Ça fait deux ans qu'elles sont là. Avant, la nuit, le volcan dormait tout noir. Hélène les comptait, assise sur mon rocher. Un soir, elle a dit : « Ce sont des forges. » Et elle n'a plus rien dit de la soirée."
		&"roc":
			return "Des forges. Celles de l'Ombre Noire, sur la Plaine Volcanique. C'est là qu'ils brûlent l'ambre. Chaque nuit, j'en compte une de plus. Je n'aime pas compter, en ce moment."
		&"maia":
			return "Les feux rouges, près du volcan ? … Maman rentrait avec de la cendre sur ses bottes. Je sais d'où elle venait, maintenant."
	return "Des forges, au pied du volcan. L'Ombre Noire y brûle l'ambre."


## What lies above the Monts: the Cieux Éternels (flying, chapter 7).
static func _skies(npc: StringName) -> String:
	match npc:
		&"bertille":
			return "Les Cieux Éternels. Des pitons de roche au-dessus des nuages. On dit que des ptérosaures grands comme des maisons y font leurs nids. On n'y monte pas à pied, petite. Il faudrait des ailes."
		&"roc":
			return "Les Cieux… Hélène y allait sur le dos d'un très grand ptérosaure. La première fois, elle est redescendue en riant, et moi je ne pouvais plus parler. Pour y monter, il faudra voler, Chloé."
		&"maia":
			return "Les Cieux ! Joss parle d'un harnais de vol. Pour les très grands ptérosaures. Il dit que ses coutures tiendraient. Il dit toujours ça."
	return "Les Cieux Éternels, au-dessus des nuages. Pour y monter, il faudrait voler."
