class_name DialogueVolcan
## Chapter 8, the Plaine Volcanique: its plain lines, by id (same steps as DialogueDB: {"who",
## "text"}, {"flag"}, {"letter", "sign"}…). DialogueDB.lines() asks lines() first for the ids it
## does not know (before the Cieux: « volcan_bloque » becomes the Descente de Cendre once the mask
## has fallen); the chapter's questions (TOPICS, story_topics, label, answer) are read by Ask.
## Signs, examined things, closed ways (the lava without the hide for it, the crater's path, the
## gate of the Terre des Apex), pages 35 to 38 (Pickups in the zones; 37 is given by Dame Suie).

const CHLOE := "Chloé"
const ROC := "Prof. Roc"
const V := preload("res://story/volcan.gd")
const TOPICS := {
	&"volcan_trex": "Un T-Rex ne voit pas ce qui ne bouge pas, c'est vrai ?",
	&"volcan_lave": "Comment on traverse la lave ?",
	&"volcan_forges": "Qu'est-ce qu'on fait des forges ?",
	&"volcan_antidote": "À quoi sert l'ambre clair ?",
}


## The lines for `id`, [] when it is not one of the Plaine Volcanique's.
static func lines(id: StringName) -> Array:
	match id:
		&"volcan_bloque":   # (the Arche's way down: chapter 7's text until the mask has fallen)
			if Game.flag(&"masque_tombe"):
				return V.descent(true)
			return []
		&"descente_cendre":
			return V.descent(false)
		&"cendres_bloquees":
			return [{"text": "La Descente de Cendre remonte vers l'Arche. En haut, le masque est toujours dans l'herbe, sans doute."}]
		&"panneau_cendres", &"panneau_volcan_entree", &"panneau_champs":
			return [{"text": "Plaine Volcanique. Ne pas marcher sur ce qui est rouge. Ni sur ce qui est noir et encore chaud. En fait : regarder où on marche. — H."}]
		&"cage_ouverte_cendres":
			return [{"text": "Une cage de l'Ombre Noire, ouverte, à moitié enterrée dans la cendre. Les barreaux sont tordus vers l'extérieur. Quelqu'un est sorti sans demander."}]
		&"fut_renverse":
			return [{"text": "Un fût marqué d'un masque d'os. Vide. Il sent le brûlé et un peu la réglisse."}]
		&"pierre_plate":
			return [{"text": "Deux creux dans la cendre, côte à côte. Et un énorme, un peu plus loin."}]
		&"saichania_marque":   # (Numéro 7, wild again in the fields: its sighting, if the mechanics show one)
			return [{"text": "Un Saichania sauvage. Il a une marque claire au cou, comme un collier qu'on aurait retiré."}]
		&"fournaise_sauvage":   # (Fournaise at night on the lava flows, when he did not join)
			return [{"text": "Un Daspletosaurus. Il a une marque claire au cou. Il vous a reconnue."}]
		&"panneau_coulee", &"panneau_lave", &"panneau_coulees":
			return [{"text": "« La lave, ça se regarde de loin. Ou du dos d'un dino qui a le cuir pour. Pas des deux à la fois. — H. »"}]
		&"lave_bloquee":
			return lave_bloquee()
		&"lave_franchie":
			return lave_franchie(Lava.walker())
		&"faille_sanctuaire", &"gravure_faille":
			return _crack()
		&"chemin_cratere_bloque":
			return _crater_path()
		&"coulees_bloquees":   # (the forges' way north to the lava flows, until Dame Suie has gone; added: Greg to validate)
			return [{"text": "Le chemin des coulées passe au pied de la grande forge. On ne peut pas s'en approcher : la chaleur repousse."}]
		&"camp_helene":
			return [camp_line()]
		&"apex_bloque":
			return apex_bloque()
		&"page_35":
			return _page_35()
		&"page_36":
			return _page_36()
		&"page_37":
			return page_37(true)
		&"page_38":
			return _page_38()
	return []


# ------------------------------------------------------------------ the lava, the crack, the path

## Without a lead dino of stone or fire: the flow bars the way; who could (the party, the Cabinet),
## else where to find one. The MÉCANIQUES agent's words (actors/lava.gd), the same as the scenes'.
static func lave_bloquee() -> Array:
	return Lava.blocked_lines()


## The first crossing, on `crosser`'s back (the lead dino of stone or fire): « J'ai regardé en bas. »
## (Lava.crossed_lines; the crossing itself shows it once, Lava.tell_crossed.)
static func lave_franchie(crosser: Dino) -> Array:
	if crosser == null:
		return lave_bloquee()
	return Lava.crossed_lines(crosser) + [{"flag": &"lave_franchie"}]


## 7 e, the crack of the sanctuary: « On n'entre pas sans frapper. Ici, c'est lui qui frappe. »
## Roc's « Une légende. Cours. » only if Chloé asked him (roc_trex_legende).
static func _crack() -> Array:
	return [
		{"text": "Une faille dans le flanc du volcan, haute et étroite, d'où sort un souffle chaud et régulier. Comme une respiration. Au-dessus, gravé dans la roche : « On n'entre pas sans frapper. Ici, c'est lui qui frappe. — H. »"},
		{"who": CHLOE, "text": "(Le sanctuaire de Magma. Le cinquième Cœur. Et le gardien « le plus difficile à convaincre ». … Roc a dit : une légende. Cours. Je ne vais pas courir.)" if Game.flag(&"roc_trex_legende")
			else "(Le cinquième Cœur. Et le gardien « le plus difficile à convaincre ».)"},
	]


## The crater's path, still under the lava until the fifth Cœur (lave_retiree). (Added for the
## closed way: Greg to validate.)
static func _crater_path() -> Array:
	return [
		{"text": "Le chemin du cratère monte en lacets vers le bord du volcan. La lave le recouvre encore, rouge et lente."},
		{"who": CHLOE, "text": "(Pas par là. Pas encore.)"},
	]


# ------------------------------------------------------------------ the door

## Hélène's camp against the rock (9 b).
static func camp_line() -> Dictionary:
	return {"text": "Un petit camp, contre la paroi : une lanterne d'ambre éteinte, une couverture pliée au carré, un cairn de pierres noires. Quelqu'un a dormi ici, une nuit, il y a un an, et a rangé avant de partir."}


## 9 f, the gate: five round hollows in a star; « Demain, à l'aube. »; to be continued.
static func apex_bloque() -> Array:
	var steps: Array = [
		{"text": "Le portail de bois, à deux battants. Cerclé de fer, noirci par vingt-cinq ans de fumée. Cinq creux ronds dans le bois, à hauteur de main, en étoile. Quatre sont vides, pour l'instant. Le cinquième aussi."},
		{"who": CHLOE, "text": "(Cinq creux. Elle a quatre Cœurs, j'en ai un. Et une fiole d'ambre noir pour « tenir ».)"},
		{"who": CHLOE, "text": "(Demain, à l'aube.)"},
		{"text": "(À suivre… La Terre des Apex.)"},
		{"flag": &"apex_bloque"},
	]
	if not Game.flag(&"apex_ouvert"):
		steps.insert(4, {"text": "La suite de l'aventure arrive bientôt !"})
	return steps


# ------------------------------------------------------------------ pages 35 to 38

## Page 35, in a crack of the glass wall behind the altar: twenty-five years ago; three weeks; « il
## a mangé mon chapeau »; Cheminée; « I. a ramassé un éclat de verre noir grand comme une assiette ».
static func _page_35() -> Array:
	return [
		{"text": "Dans une fente du mur de verre, derrière l'autel, une boîte en fer noircie. Elle est tiède depuis vingt-cinq ans. Dedans, une page du journal, et une plume de chapeau à moitié brûlée."},
		{"letter": ["Le cinquième Cœur",
			"Le T-Rex de Magma ne m'a pas chargée : c'est pire, il ne m'a pas regardée. Trois semaines. Je venais chaque jour m'asseoir sur la pierre chaude, et je lui parlais, et il regardait la lave. Le vingt-deuxième jour, il a mangé mon chapeau. Le vingt-troisième, il s'est couché à côté de moi, et le sol a tremblé, et je crois que c'était sa façon de dire oui.",
			"Je lui ai confié le dernier Cœur, le plus chaud : il l'a couvert de lave comme on couvre une braise pour la nuit. Il fume quand il dort. Anselme l'a appelé Cheminée. Anselme n'a aucun respect, et il avait raison.",
			"I. a ramassé un éclat de verre noir grand comme une assiette, « pour en faire quelque chose ». Je lui ai dit de ne pas se couper. Nous avons ri. Je crois que c'est le dernier endroit où nous avons ri toutes les deux ; je ne le savais pas encore."],
			"sign": "— H."},
		{"flag": &"found_journal_35"},
		{"flag": &"page_35"},
		{"who": CHLOE, "text": "Cheminée. … Ça vous va."},
		{"who": CHLOE, "text": "(« Un éclat de verre noir grand comme une assiette. » … Le masque. Elle l'a taillé dans un souvenir. Dans le dernier endroit où elles ont ri.)"},
		{"who": CHLOE, "text": "(Je ne le dirai pas à Maïa. Pas comme ça. … Peut-être un jour.)"},
	]


## Page 36, on the rock in the middle of the flows: if the seal gives, someone inside to calm him
## from within. « Elle n'a pas disparu. Elle est entrée. »
static func _page_36() -> Array:
	return [
		{"text": "Sur le rocher noir, au milieu du rouge, une boîte en fer calée sous une pierre. Le fer est tiède. Le papier, à l'intérieur, a jauni comme du pain trop cuit."},
		{"letter": ["Si le sceau cède",
			"Le sceau s'use. Je l'entends d'ici : la lave bat comme un cœur qui a couru. Si quelqu'un l'ouvre, il ne suffira pas de refermer : il faudra quelqu'un dedans, pour le calmer de l'intérieur. Pas une clé. Pas un Cœur. Quelqu'un.",
			"Je connais une personne qui l'a déjà fait une fois, avec ses deux mains, et qui a encore les cicatrices pour le prouver. L'ambre se referme sur ce qui ne bouge plus. Je ne bougerai plus. Il m'écoutera dormir, et il dormira.",
			"Ce n'est pas un sacrifice, Anselme, si tu lis ceci : c'est une position confortable, et j'ai toujours aimé les positions confortables. Garde le thé au chaud."],
			"sign": "— H."},
		{"flag": &"found_journal_36"},
		{"flag": &"page_36"},
		{"who": CHLOE, "text": "(Se sceller avec lui. De l'intérieur. … Elle n'a pas disparu. Elle est entrée.)"},
		{"who": CHLOE, "text": "(« Il faut les cinq pour ouvrir, et quelqu'un pour le tenir. » Isaure a lu ça. Isaure l'a écrit avec les mêmes mots. … Elle ne veut pas le tenir. Elle veut la sortir de là.)"},
	]


## Page 37, the letter « Pour Isaure » (a year ago, left on Dame Suie's bench): « La moitié est de
## ma faute. » `intro`: the envelope's lines first (when it is read outside Dame Suie's scene).
static func page_37(intro: bool) -> Array:
	var steps: Array = []
	if intro:
		steps.append({"text": "Une enveloppe de papier épais, pliée en deux, jaunie par la chaleur. Dessus, une écriture qu'on connaît : « Pour Isaure »."})
	steps.append_array([
		{"letter": ["Pour Isaure",
			"Isaure,",
			"Je suis descendue voir tes forges. Elles sont sept, j'ai compté : je n'ai pas pleuré, j'ai compté, c'est ce que je sais faire. Je sais que c'est toi. Je l'ai su avant mes carnets, je crois, et je n'ai rien dit, parce que je préférais te perdre doucement que d'un coup. C'était lâche. Je te le dis une fois : c'était lâche.",
			"Tu n'as pas tort pour le port. Tu as tort sur le moyen. Je te l'ai déjà écrit, et j'ai jeté la lettre à la mer ; tu vois que je progresse : celle-ci, je la pose là où tu passeras.",
			"Je ne te hais pas. Je ne t'ai jamais haïe. J'ai eu peur pour toi, ce qui est autre chose et dure plus longtemps.",
			"Reviens. Pas au Cabinet : reviens tout court. Il y a ta tasse, et il y a du thé, et il y a vingt ans à rattraper, dont la moitié est de ma faute."],
			"sign": "— H."},
		{"flag": &"found_journal_37"},
		{"flag": &"page_37"},
		{"who": CHLOE, "text": "(« La moitié est de ma faute. » … Elle ne disait jamais rien fort. Mais elle le disait.)"},
		{"who": CHLOE, "text": "(Isaure est là-haut, devant une porte, avec les Cœurs. Et cette lettre a un an de retard.)"},
	])
	if Game.flag(&"found_journal_25"):
		steps.append({"who": CHLOE, "text": "(Elle a gardé la tasse. Et elle a réécrit la lettre. Deux fois, c'est une habitude.)"})
	return steps


## Page 38, under the cairn of Hélène's camp: her last night outside. « Ne me cherche pas tout de
## suite. Occupe-toi d'eux d'abord. Ils sont plus petits. »
static func _page_38() -> Array:
	var steps: Array = []
	if not Game.flag(&"camp_helene_vu"):
		steps.append(camp_line())
		steps.append({"flag": &"camp_helene_vu"})
	steps.append_array([
		{"text": "Sous les pierres du cairn, une boîte en fer. Dedans, une page du journal. La dernière qu'elle a écrite de ce côté-ci."},
		{"letter": ["La veille",
			"Dernière nuit dehors. J'ai laissé trois œufs au Cabinet, dans la couveuse, avec une lettre pour Chloé qui dit beaucoup moins que je voudrais : on n'écrit pas « je t'aime » à une enfant qu'on a vue trop peu, on écrit « trouve les Cœurs ». J'espère qu'elle lira entre les lignes. Elle a mes yeux : ils lisent entre les lignes, et ils disent non avant la bouche.",
			"J'ai peur. Je l'écris une fois, ici, pour que ce soit dit, et je ne l'écrirai plus. Anselme a ma clé, I. a mes carnets, Chloé aura mes dinos. Il ne me reste que mes mains, et elles savent quoi faire : elles l'ont déjà fait.",
			"Demain, je descends. Si quelqu'un lit ceci avant moi : ne me cherche pas tout de suite. Occupe-toi d'eux d'abord. Ils sont plus petits."],
			"sign": "— H."},
		{"flag": &"found_journal_38"},
		{"flag": &"page_38"},
		{"who": CHLOE, "text": "(« Ne me cherche pas tout de suite. » … Je ne t'ai pas cherchée. Je les ai trouvés, eux, un par un. Et maintenant je suis là quand même.)"},
		{"who": CHLOE, "text": "(Elle a eu peur. Elle l'a écrit une fois. Et elle est descendue.)"},
	])
	return steps


# ------------------------------------------------------------------ questions

## The chapter's questions of the moment, for Roc (added to Ask.story_topics() once the mask fell).
static func story_topics() -> Array:
	var out: Array = []
	if not Game.flag(&"masque_tombe"):
		return out
	if not Game.flag(&"trex_magma_battu"):
		out.append(&"volcan_trex")
	if Game.flag(&"coulees_arrivee") and not Game.flag(&"lave_franchie"):
		out.append(&"volcan_lave")
	if Game.flag(&"forges_arrivee") and not Game.flag(&"grande_forge_eteinte"):
		out.append(&"volcan_forges")
	if Game.flag(&"antidote_ambre"):
		out.append(&"volcan_antidote")
	return out


## The question's words, "" when it is not one of the Plaine Volcanique's.
static func label(topic: StringName) -> String:
	return TOPICS.get(topic, "")


## The answer to one of the chapter's questions (Roc's words), [] for any other.
static func answer(_npc: StringName, speaker: String, topic: StringName) -> Array:
	match topic:
		&"volcan_trex":
			return [
				{"who": speaker, "text": "Une légende. Cours."},
				{"text": "Il tourne une page."},
				{"who": speaker, "text": "… Hélène l'a testée. Elle n'a pas couru. Il l'a regardée pendant trois semaines. Ne teste pas, Chloé. Cours. Ou ne cours pas. Fais comme elle. Non : cours."},
				{"flag": &"roc_trex_legende"},
			]
		&"volcan_lave":
			var bastion: Dino = Desert.bastion_dino()
			var who := "%s, un cuirassé" % bastion.nickname if bastion else "Un cuirassé"
			var step := V.lava_step()
			if step == "" and V.lava_crosser():
				step = "Ton %s a le cuir pour." % V.lava_crosser().nickname
			return [{"who": speaker, "text": "Avec un dino qui a le cuir pour : de la pierre, ou du feu. %s, un grand théropode qui ne craint pas le feu. Pas toi. Surtout pas toi. %s" % [who, step]}]
		&"volcan_forges":
			return [{"who": speaker, "text": "On les éteint. Hélène les a comptées ; toi, éteins-les. Les dinos sauront comment : ils ont vu comment ça s'allume."}]
		&"volcan_antidote":
			return [{"who": speaker, "text": "Une goutte, et les veines s'effacent. D'un coup. La dame en gris a fait ça ? … Garde-la pour quand tu n'auras pas le temps de parler. Elle a dit ça ? Elle a raison. C'est agaçant."}]
	return []
