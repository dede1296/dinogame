class_name DialogueApex
## Chapter 9, la Terre des Apex, and the epilogue: its plain lines, by id (same steps as DialogueDB:
## {"who", "text"}, {"flag"}, {"letter", "sign"}…), word for word from docs/chapitre-9-scenes.md.
## DialogueDB.lines() asks lines() first for the ids it does not know (page_39 is the cairn's Pickup,
## page_40 is handed over on the jetty); the blocks of the giants; the Souverain lying down; the
## choice before Carène and Isaure's answers; Roc's words after the epilogue (chatter); the post-game
## pools (story/apex_autour.gd says them). The words said during the battles are the MÉCANIQUES
## agent's (battle/apex_battles.gd, battle/apex_engine.gd): not written twice.

const CHLOE := "Chloé"
const MAIA := "Maïa"
const ISAURE := "Isaure"
const HELENE := "Hélène"
const ROC := "Prof. Roc"
const SUIE := "Dame Suie"
const BRAC := "Brac"
const JOSS := "Joss"
const LEONCE := "Léonce"
const BERTILLE := "Bertille"


## The lines for `id`, [] when it is not one of the chapter's.
static func lines(id: StringName) -> Array:
	match id:
		&"page_39", &"cairn_helene":
			return page_39()
		&"page_40":
			return [page_40()] + [{"flag": &"found_journal_40"}, {"flag": &"page_40"}]
		&"bloc_geant_1", &"bloc_geant_2", &"bloc_geant_3", &"bloc_geant_4":
			return [bloc_geant(int(String(id).right(1))), {"flag": &"bloc_geant_vu"}]
		&"souverain_couche":
			if Game.flag(&"geants_reveilles"):   # (post-game : les quatre géants debout, G5)
				return [{"text": DialogueGeants.SOUVERAIN_APRES}]
			return [{"text": "Il dort les yeux ouverts. Il n'a plus peur. Il respire, et la cendre bouge."}]
	return []


# ------------------------------------------------------------------ the crater, pages 39 and 40

## 2 b, page 39 under a flat stone at the rim, Hélène's last cairn (2 lines, the page, 2 lines).
static func page_39() -> Array:
	return [
		{"text": "Trois pierres noires empilées, et dessous, une pierre plate. Le dernier cairn. Celui-là, elle l'a fait vite : les pierres ne sont pas droites."},
		{"text": "Sous la pierre plate, une boîte en fer. Dedans, une page, pliée en deux. L'écriture penche."},
		{"letter": ["Il a peur",
			"Je suis au bord. D'ici, je le vois à travers l'ambre, et je viens de comprendre quelque chose que j'aurais dû comprendre il y a vingt-cinq ans : il a les yeux ouverts. Il ne dort pas. Il n'a jamais dormi. Il a peur, et il attend que ça passe, et ça ne passe pas, parce qu'il est tout seul.",
			"Je descends lui tenir compagnie. Ce n'est pas un sacrifice, Anselme, si tu lis ceci : c'est une position confortable, j'ai laissé la couverture en haut, il fait chaud en bas.",
			"Il a peur. Moi aussi. J'y vais."],
			"sign": "— H."},
		{"flag": &"found_journal_39"},
		{"flag": &"page_39"},
		{"who": CHLOE, "text": "(Trois mots pour finir. Elle avait écrit « j'ai peur » une fois, à la porte. Elle l'écrit deux.)"},
		{"who": CHLOE, "text": "(Il a les yeux ouverts. … Alors il nous voit arriver.)"},
	]


## 5 e, page 40, written this morning (the letter step only: the jetty's scene says the rest).
static func page_40() -> Dictionary:
	return {"letter": ["Ce qui dort n'est pas mort",
		"J'ai passé trente ans à réveiller ce qui dormait, et un an à dormir à côté de ce qui avait peur. J'ai appris la deuxième chose trop tard : on ne réveille rien de force, ni un dino, ni une amie, ni un port. On s'assoit à côté, et on attend qu'il n'ait plus peur.",
		"Je t'ai écrit « ne fais confiance qu'aux dinos ». J'avais tort d'un mot. Fais confiance comme les dinos : à qui reste.",
		"Ce qui dort n'est pas mort. Ni l'ambre, ni l'île, ni ce qu'il y avait entre Isaure et moi. Il fallait quelqu'un pour s'asseoir à côté. C'était toi. Tu as grandi, et je l'ai vu : c'est la seule chose que je ne voulais pas rater, et je ne l'ai pas ratée.",
		"Le Cabinet est à toi. Il l'a toujours été. Je reprends juste mon fauteuil."],
		"sign": "— H."}


## 2 c, a block of the giants (1 to 4): one line.
static func bloc_geant(n: int) -> Dictionary:
	var text: String = [
		"Dans l'ambre, une patte plus grande que Chloé, et des griffes comme des faux. Celui-là dort pour de bon. Pour l'instant.",
		"Un cou qui fait le tour du bloc deux fois. On ne voit pas la tête : elle est de l'autre côté. Il a l'air de sourire. Les grands herbivores ont toujours l'air de sourire.",
		"Des plaques, des pointes, et une queue qu'on ne voudrait pas croiser en rêve. Il ronfle. Dans l'ambre. C'est possible, apparemment.",
		"Celui-là est petit, pour un géant : à peine la taille d'une maison. Il a une plume d'Hélène coincée dans une fissure, comme un marque-page.",
	][clampi(n, 1, 4) - 1]
	return {"text": text}


# ------------------------------------------------------------------ the duel of Isaure (1 d): the choice before Carène

## The choice before Carène: what Chloé says (none is « the wrong one »).
const CARENE_PROMPT := "Carène avance. Isaure la regarde, puis Chloé. Que dit Chloé ?"
const CARENE_OPTIONS := ["« Maïa regarde. »", "« Ils n'ont pas peur de vous. »", "Ne rien dire"]


## Isaure's answer to the choice `pick`, then Carène who takes her time (2 lines).
static func carene_reply(pick: int) -> Array:
	var answer: String = [
		"Je sais. C'est bien pour ça que je me bats proprement. … Carène.",
		"Non. Ils n'ont jamais eu peur. C'est moi qui… Carène. Vas-y.",
		"Tu ne dis rien. Elle non plus ne disait rien, dans ces moments-là. C'est reposant et c'est terrible. Carène.",
	][clampi(pick, 0, 2)]
	return [
		{"who": ISAURE, "text": answer},
		{"text": "Carène regarde Isaure, puis Chloé. Et elle prend son temps."},
	]


## A duel lost: she takes nothing (« Je demandais. »); the dawn stays.
const ISAURE_LOST := "Soigne-les, moussaillon. Je ne bouge pas. L'aube peut attendre encore un peu : elle a attendu un an."


# ------------------------------------------------------------------ around (post-game)

## Roc at the Cabinet, once the epilogue is over (roc_epilogue_n).
const ROC_EPILOGUE := [
	"Elle a repris son fauteuil. J'ai repris la cuisine. On se croise au thé.",
	"Elle veut que j'aille démonter les forges avec Isaure. Tenir l'échelle. J'ai dit oui. J'ai le vertige depuis.",
	"Cheminée a demandé après vous. Enfin, il a fumé dans ma direction. Chez lui, c'est pareil.",
]
const ROC_FOURNAISE := "Le gros de Brac dort devant la couveuse. Il fume aussi. Je vais finir par m'habituer."
## Hélène in her armchair (helene_cabinet_n); the second line by the starter.
const HELENE_CABINET := [
	"Les géants du cratère vont se réveiller un par un. Pas de force : à leur heure. Quand l'un d'eux ouvre l'œil, viens me le dire ; j'ai des choses à t'apprendre sur chacun.",
	"",
	"Isaure a démonté la première forge. Elle a mis trois jours. Anselme a tenu l'échelle deux heures, puis il a tenu la théière.",
	"Les œufs rares, dans la couveuse : ce sont les derniers de l'Ambre-Mère que je réveillerai. Les autres, c'est toi. Doucement.",
	"Tu veux ma recette pour un Alpha qui boude ? Trois semaines sur une pierre chaude. Prévois deux chapeaux.",
]
const HELENE_ANCIEN := {
	&"velociraptor": "Griffe-Grise ? Il va bien ? … Il grogne ? Alors il va bien.",
	&"ankylosaurus": "On s'est assis dessus ?",
	&"parasaurolophus": "Elle chante faux le matin. C'est très bien.",
}
## Isaure at her boat (isaure_barque_n); the fast travel's words.
const ISAURE_BARQUE := [
	"Les forges, c'est fait. Il reste les cendres. Les cendres, ça se balaye.",
	"J'ai remis le masque en carton pour les enfants du Havre. Ils ont ri. Un seul a eu peur : le fils de Ferréol. Il a de quoi.",
	"Hauban pêche pour le port. Il a repris tout seul. Il n'a jamais eu besoin qu'on lui dise.",
]
const ISAURE_CAP := "Où met-on le cap, moussaillon ? Tarif unique : rien."
## Maïa at the Grand Crâne (maia_gardienne_n).
const MAIA_GARDIENNE := [
	"Gardienne, ça veut dire qu'on garde. Alors je garde le Crâne. Et toi ? … Tout le reste ? C'est injuste. On échange demain.",
	"Caillou a éternué sur Brac. Il a dit que c'était un signe. Brac. Pas Caillou.",
	"Je l'ai battue aux nœuds, hier. Maman. Pour la première fois. Elle a dit « enfin ».",
]
## Bertille at the Monts, once (bertille_helene_remontee).
const BERTILLE_LINE := "La dame aux mains abîmées est descendue… et remontée. Zéro feu, et une de plus. Je recompte : ça fait juste. … Je vais tricoter. Elle va encore les perdre."
## Joss, on the jetty after the epilogue, once (joss_poche_piaf).
static func joss_lines() -> Array:
	return [
		{"who": JOSS, "text": "Maïa ! Le manteau. À ta taille. Avec une poche pour le piaf."},
		{"text": "Moustique entre dans la poche, et n'en ressort plus."},
		{"who": JOSS, "text": "… Regarde ces coutures. Non, vraiment : regarde-les."},
		{"flag": &"joss_poche_piaf"},
	]
## Dame Suie on the quay, without her gloves (suie_port_n); with Hélène, once.
const SUIE_PORT := [
	"Je refais mes tables, mademoiselle Varenne. Il y a une colonne pour vous, maintenant. Et une pour le Souverain : « sans une goutte ». … Une goutte, en fait. La bonne.",
	"Si un dino de la Réserve a des veines, un jour, venez me voir. Je sais défaire. C'est la première règle ; je l'ai apprise en dernier.",
]
static func suie_helene() -> Array:
	return [
		{"who": HELENE, "text": "Vous avez brûlé mes notes."},
		{"who": SUIE, "text": "Presque toutes, madame."},
		{"who": HELENE, "text": "… C'est un mot merveilleux, « presque »."},
		{"who": SUIE, "text": "C'est ce que j'ai dit à votre petite-fille. Elle n'a pas souri non plus."},
	]
## Brac at the end of the jetty, at night, a lantern (brac_jetee_n).
const BRAC_JETEE := [
	"Gardien de nuit. Je surveille la mer. De loin. Rien ne bouge. C'est le meilleur boulot du monde.",
	"Mastoc a peur du noir. Je lui laisse la grande lanterne, je prends la petite. Moi, j'ai pas peur. J'ai l'habitude d'avoir peur, c'est pas pareil.",
	"Il m'a fait un panneau, le vieux : « Gardien : BRAC ». Avec les lunettes, il a écrit « BARC ». Je garde.",
]
## Léonce, on the pontoon.
const LEONCE_PORT := [
	"Le poisson est revenu. Pas beaucoup. Assez.",
	"La capitaine a mis un masque en carton. On a tous fait semblant d'avoir peur. Elle a dit merci.",
]
## The Anciens, an examined line each (anciens_helene_n): Griffe-Grise, the Vieux Rempart, the Voix.
const ANCIENS := {
	&"griffe_grise": "Griffe-Grise a grogné vers le port, longuement, puis s'est roulé en boule. Il sait.",
	&"vieux_rempart": "Le Vieux Rempart souffle un nuage de sable deux fois : une pour Chloé, une pour quelqu'un d'autre.",
	&"voix_du_marais": "La Voix chante une note qu'elle n'a pas chantée depuis un an. Elle la tient longtemps.",
}


## Roc's words after the epilogue (DialogueDB.chatter asks this last): his pool, one line each time.
static func chatter(who: StringName, pool: Array) -> Array:
	if who != &"roc" or not Game.flag(&"epilogue_fini"):
		return pool
	var mine: Array = ROC_EPILOGUE.duplicate()
	if Game.flag(&"fournaise_garde") and Game.party.any(func(d: Dino) -> bool: return d.nickname == "Fournaise"):
		mine.append(ROC_FOURNAISE)
	return [ForetCamp.next_line(&"roc_epilogue_n", mine)]
