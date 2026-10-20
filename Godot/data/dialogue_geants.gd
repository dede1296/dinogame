class_name DialogueGeants
## Post-game, les géants du cratère : leurs mots (docs/post-game-scenes.md § G), au format de DialogueDB
## ({"who", "text"}, {"flag"}). Les blocs par leur numéro (BlocGeant1..4) : 1 Therizinosaurus géant (Râteau),
## 2 Argentinosaurus (Nuage), 3 Dacentrurus (Ronfleur), 4 Deinocheirus (Moufle). `lead` : le nom du dino EN
## TÊTE (celui qui s'est assis avec Chloé), jamais le dino de départ. Les gestes : story/apex_geants.gd.
## Retouches faites au texte du doc (cohérence, lot A, 20/10) : les bulles disent ce que les didascalies seules
## ne montreraient pas (la fougère, le doigt) ; « une patte grosse comme le Cabinet » → « large comme une
## table » ; « une tête pas plus grosse que Caillou » (un Tricératops !) → « qu'un tonneau » ; « trop grand pour
## l'écran » → « lever la tête très haut » ; Therizinosaurus : des griffes « pas faites pour chasser » (pas
## « pour mordre ») ; Hélène, le ronfleur : « quand il s'est rendormi » (Chloé vient de dire qu'il ne ronfle
## plus) ; Anselme a nommé les géants AUTREFOIS, dans l'ambre (plus-que-parfait : il n'est pas descendu) ;
## G5 « Il n'y a plus personne dans l'ambre. — Si. Lui. » (le Souverain n'est plus dans l'ambre) → « Et lui ?
## Il est toujours couché. » ; « Plus personne ne dort dans le cratère » → « dans l'ambre » (le Souverain « dort
## les yeux ouverts ») ; le mauvais dino : une phrase sans « lui » (un dino peut être une femelle) ; Moufle
## pêche « dans la cendre » (pas de flaque dans le cratère) ; Nuage : sa tête se voit (« On ne voit que les
## pattes » était faux à l'écran).

const CHLOE := "Chloé"
const HELENE := "Hélène"
## Les blocs comme Chloé les appelle (sans article).
const BLOCS := {1: "bloc aux griffes", 2: "grand bloc", 3: "bloc qui ronfle", 4: "petit bloc"}
## Les noms qu'Anselme leur avait donnés (G4), ceux des examens.
const NOMS := {1: "Râteau", 2: "Nuage", 3: "Ronfleur", 4: "Moufle"}
## Avec qui s'asseoir, quand (les objectifs).
const AVEC := {1: "un dino à Tranche (des griffes qui tranchent les lianes)", 2: "un herbivore", 3: "un dino qui chante (Résonance)",
	4: "un dino qui nage"}
const QUAND_OEIL := {1: "au coucher du soleil", 2: "à la pleine lune", 3: "la nuit", 4: ""}
const QUAND_ASSIS := {1: ", le soir ou la nuit (il dort le jour)", 2: "", 3: ", la nuit", 4: ""}
## Le pool d'Hélène après les quatre (G5).
const HELENE_POOL_APRES := "Les quatre font du bruit la nuit. Le Souverain n'a pas l'air de les entendre. Il a l'air content."
## Le Souverain couché, dès geants_reveilles (au lieu de « Il dort les yeux ouverts… »).
const SOUVERAIN_APRES := "Il regarde la mer. Derrière lui, quatre géants font du bruit. Il n'a pas l'air de les entendre. Il a l'air content."
## Le choix au bloc (G3), avant le temps regardé.
const ASSEOIR_TEXTE := "L'œil est ouvert, dans l'ambre. Hélène a dit : s'asseoir à côté, et attendre qu'il n'ait plus peur."
const ASSEOIR_CHOIX := ["S'asseoir à côté", "Pas maintenant"]


# ------------------------------------------------------------------ G1, l'œil (2 bulles)

static func eye(n: int) -> Array:
	var first: String = {
		4: "Le petit bloc. Dans l'ambre, quelque chose a bougé. Un œil. Ouvert, rond, de la couleur d'un œuf au plat. Il regarde Chloé, puis la plume coincée dans la fissure, puis Chloé.",
		2: "Le grand bloc luit comme la lune. Tout en haut, là où le cou disparaît, un œil s'est ouvert. Il ne regarde pas Chloé : il est trop haut. Il regarde la lune.",
		1: "Le bloc aux griffes. Entre deux lames, un œil. Il regarde les griffes, puis Chloé, puis les griffes. Il a l'air de s'excuser.",
		3: "Le bloc qui ronfle ne ronfle plus. Tout en bas, entre deux pointes, un petit œil s'est ouvert. Il ne voit pas Chloé : elle est du côté de la queue. Elle fait le tour.",
	}[clampi(n, 1, 4)]
	return [
		{"text": first},
		{"who": CHLOE, "text": "(Il a ouvert l'œil. Elle a dit : « Quand l'un d'eux ouvre l'œil, viens me le dire. » … Je vais le lui dire.)"},
		{"flag": StringName("geant_%d_oeil" % clampi(n, 1, 4))},
	]


# ------------------------------------------------------------------ G2, Hélène conseille

static func advice(n: int) -> Array:
	var lines: Array = []
	match clampi(n, 1, 4):
		4:
			lines = [[CHLOE, "Le petit bloc. Celui avec ta plume. Il a ouvert un œil."],
				[HELENE, "Un seul ? … C'est lui. Il fait toujours les choses à moitié, et c'est pour ça que je l'avais marqué : on commence par lui."],
				[HELENE, "Un Deinocheirus. Des bras longs comme la barque de Maïa, un bec de canard, pas une dent. Il pêchait. Il n'a jamais fait de mal à personne, et il ne le sait pas : il a peur de ses propres mains."],
				[CHLOE, "Qu'est-ce que je fais ?"],
				[HELENE, "Rien. C'est le plus dur. Tu t'assois à côté du bloc, et tu attends qu'il n'ait plus peur. Page 40."],
				[CHLOE, "Toute seule ?"],
				[HELENE, "Avec un pêcheur. Un de tes dinos qui nage. Qu'il voie que des pattes, ça sert à nager, pas qu'à attraper. Il comprendra avant toi."],
				[HELENE, "Et ne le réveille pas de force. Je l'ai fait une fois dans ma vie. Tu as vu ce que ça a donné."]]
		2:
			lines = [[CHLOE, "Le grand bloc, celui où le cou fait deux fois le tour. Il a ouvert un œil. À la pleine lune."],
				[HELENE, "Forcément. L'ambre luit, il a cru que c'était le matin. Un Argentinosaurus. Le plus grand animal qui ait jamais marché : trente-cinq mètres. Sa tête ne t'a jamais vue, elle est trop haut."],
				[CHLOE, "Alors comment il saura que je suis là ?"],
				[HELENE, "Par ses pieds. Un sauropode écoute par terre. Assieds-toi contre le bloc avec un herbivore, n'importe lequel : un qui mâche. Il entendra mâcher, et il saura qu'il n'y a pas de dents pour lui ici."],
				[CHLOE, "Il mange quoi, un géant comme ça ?"],
				[HELENE, "Une forêt par jour. Le cratère n'en a pas… mais il y a des fougères qui poussent sur les veines d'ambre, en bas. Tu ne les as pas vues ? Tu les verras : il te les montrera."],
				[HELENE, "Il prendra son temps. Les grands herbivores en prennent toujours. Ne compte pas."]]
		1:
			lines = [[CHLOE, "Le bloc aux griffes. Il a ouvert un œil au coucher du soleil."],
				[HELENE, "Lui, il fait tout à l'envers : il dort le jour. Un Therizinosaurus. Des griffes d'un mètre, les plus longues qu'on ait jamais trouvées, et pas une faite pour chasser : il s'en servait pour tirer les branches. Un herbivore avec des sabres."],
				[CHLOE, "Il a peur de ses griffes, lui aussi ?"],
				[HELENE, "Non. Il a peur qu'on ait peur de lui. Tout le monde a peur de lui, depuis toujours. Moi aussi, le premier jour."],
				[HELENE, "Assieds-toi avec un dino qui a des griffes et qui s'en sert pour autre chose que faire mal. Un qui tranche les lianes. Qu'il voie des griffes au repos."],
				[CHLOE, "Et s'il bouge les siennes ?"],
				[HELENE, "Il les bougera. Pour tirer une branche. Ne recule pas. … Recule un peu. Un mètre. Elles font un mètre."]]
		3:
			lines = [[CHLOE, "Le bloc qui ronfle. Il a ouvert un œil, cette nuit. Un tout petit. Et il a arrêté de ronfler."],
				[HELENE, "Un petit œil, une petite tête : c'est lui. Un Dacentrurus. Un stégosaure, mais vieux comme le monde, le premier qu'on ait jamais trouvé. Deux rangées de pointes sur le dos, quatre au bout de la queue, et une tête grosse comme ta sacoche."],
				[CHLOE, "Il ronflait depuis vingt-cinq ans ?"],
				[HELENE, "Il dort profond. C'est sa façon d'avoir peur : il ferme tout, et sa queue veille à sa place. Elle frappe toute seule ce qui arrive derrière. Lui ne le sait même pas."],
				[CHLOE, "Alors je m'assois devant."],
				[HELENE, "Devant, oui : là où sa petite tête te voit. Et avec un dino qui chante. On ne réveille pas un ronfleur en criant : on chante. Il se réveille en croyant qu'il a rêvé, et il n'a pas peur."],
				[CHLOE, "Et la queue ?"],
				[HELENE, "Elle écoutera aussi. Les queues écoutent, chez eux. … Vas-y la nuit, quand il s'est rendormi et qu'il ronfle le plus fort : c'est là qu'il est le plus loin de sa queue."]]
	var out: Array = lines.map(func(l: Array) -> Dictionary: return {"who": l[0], "text": l[1]})
	out.append({"flag": StringName("geant_%d_conseil" % clampi(n, 1, 4))})
	return out


# ------------------------------------------------------------------ G3, au bloc

## Sans conseil (l'œil ouvert, Hélène pas encore vue).
static func no_advice() -> Array:
	return [{"who": CHLOE, "text": "(Elle a dit de venir le lui dire. Je vais le lui dire d'abord. Elle le saurait, de toute façon.)"}]


## Le mauvais dino en tête : une bulle, on ressort.
static func wrong_lead(n: int, lead: String) -> Array:
	var text: String = {
		4: "(Hélène a dit : un pêcheur, un dino qui nage. %s ne nage pas. Il me faut quelqu'un d'autre en tête.)",
		2: "(Hélène a dit : un herbivore, un qui mâche. %s n'en est pas un. Il me faut quelqu'un d'autre en tête.)",
		1: "(Hélène a dit : des griffes qui tranchent les lianes. %s n'en a pas. Il me faut quelqu'un d'autre en tête.)",
		3: "(Hélène a dit : un dino qui chante. %s ne chante pas. Il me faut quelqu'un d'autre en tête.)",
	}[clampi(n, 1, 4)]
	return [{"who": CHLOE, "text": text % lead}]


## Pas son heure (l'heure qu'Hélène a dite : le 1 et le 3 seulement).
static func not_now(n: int) -> Array:
	var text := "(Il ferme l'œil. Ce n'est pas son heure : Hélène a dit la nuit. Je reviendrai.)" if n == 3 \
		else "(Il ferme l'œil. Ce n'est pas son heure : il dort le jour, Hélène l'a dit. Je reviendrai le soir.)"
	return [{"who": CHLOE, "text": text}]


## Le réveil, après le temps regardé : 5 bulles (les gestes et le cœur : story/apex_geants.gd).
static func wake(n: int, lead: String) -> Array:
	match clampi(n, 1, 4):
		4:
			return [
				{"text": "Un bras immense sort de l'ambre et se pose à plat sur la roche, tout doucement, à côté de Chloé. Puis l'autre. Puis le géant se lève : petit, pour un géant, et pourtant Chloé doit lever la tête très haut. Ses deux bras pendent. Il ne sait pas où les mettre."},
				{"text": "Il regarde %s. Longtemps. Puis il pose un doigt, un seul, sur le sol, à côté de %s. Il ne gronde pas. Il n'a plus peur." % [lead, lead]},
				{"who": CHLOE, "text": "(On s'assoit à côté. C'est tout. C'est ce qu'elle a mis trente ans à apprendre, et moi une page.)"},
				{"text": "%s se lève, s'étire, et vient se frotter contre la jambe de Chloé. Dans la fissure, la plume d'Hélène a glissé. Chloé la ramasse." % lead},
				{"who": CHLOE, "text": "Un. Il en reste trois. Et une plume à rendre."},
			]
		2:
			return [
				{"text": "Le bloc se fend par en bas : c'est par là qu'il écoute. Une patte sort, large comme une table, et se pose sans un bruit. Puis le cou monte, monte, monte… Tout en haut, quelque part, on entend mâcher."},
				{"text": "%s arrête de mâcher. Là-haut, le géant aussi. Puis ils reprennent, tous les deux, en même temps." % lead},
				{"text": "Le cou redescend, lentement. Une tête pas plus grosse qu'un tonneau arrive à hauteur de Chloé, une fougère d'ambre dans le bec. Il la pose devant %s. Il en a une autre pour lui." % lead},
				{"who": CHLOE, "text": "(Je ne verrai presque jamais sa tête. Ça ne fait rien. Il sait que je suis là : il l'a entendu par les pieds.)"},
				{"who": CHLOE, "text": "(Deux. Il faut lever la tête pour les compter, maintenant.)"},
			]
		1:
			return [
				{"text": "L'ambre se fend le long des griffes, comme si elles l'avaient coupé de l'intérieur. Trois lames sortent, puis la main, puis le géant. Et les lames se replient contre son ventre, comme on range des ciseaux."},
				{"text": "Il regarde %s. %s regarde les griffes. Personne ne bouge." % [lead, lead]},
				{"text": "Puis le géant tend un bras, très lentement, attrape une fougère d'ambre sur la paroi, et la tire jusqu'à Chloé. Il la pose devant elle. Chloé a reculé d'un mètre. Pas plus."},
				{"who": CHLOE, "text": "(Des sabres pour cueillir des fougères. Elle avait raison : on a tous eu peur pour rien. Même elle.)"},
				{"who": CHLOE, "text": "(Trois. Le cratère commence à être habité.)"},
			]
	return [
		{"text": "L'ambre craque le long des pointes. La queue sort la première ; ses quatre pointes s'abaissent lentement jusqu'au sol, dans la cendre. Puis le dos, deux rangées de pointes qui se déplient. Puis la tête, petite et basse, qui cherche d'où vient le chant. Elle trouve %s." % lead},
		{"text": "Il bâille. Un bâillement de stégosaure : pas très grand, très long. Il a l'air de se demander s'il a rêvé."},
		{"text": "%s chante encore une note. Le géant pose sa tête par terre, juste à côté. Sa queue reste où elle est, les pointes dans la cendre." % lead},
		{"who": CHLOE, "text": "(Il s'est réveillé en croyant qu'il rêvait. Elle avait raison. … Et il ne ronfle plus.)"},
		{"who": CHLOE, "text": "(Quatre. Il n'y a plus personne dans l'ambre.)"},
	]


# ------------------------------------------------------------------ G4, Hélène après ; G5, quatre

static func after(n: int, lead: String) -> Array:
	match clampi(n, 1, 4):
		4:
			return [
				{"who": CHLOE, "text": "Il est debout. Il a posé un doigt à côté de %s. … Et j'ai ta plume." % lead},
				{"who": HELENE, "text": "Garde-la. Il reste des pages blanches dans ce journal, et ce n'est plus moi qui les écris."},
				{"who": HELENE, "text": "Anselme l'avait appelé Moufle, il y a longtemps, à cause des mains. Je n'ai rien dit : Moufle, c'est très bien."},
				{"who": HELENE, "text": "Le suivant ouvrira l'œil à son heure. Pas à la tienne. Va voir ailleurs, et reviens me le dire."},
				{"flag": &"geant_4_raconte"},
				{"flag": &"plume_rendue"},
			]
		2:
			return [
				{"who": CHLOE, "text": "Il m'a donné une fougère. Enfin, à %s. Par le bec. Sa tête est descendue jusqu'à nous." % lead},
				{"who": HELENE, "text": "Alors tu l'as vue. Anselme, non : il n'avait vu que les pattes, dans l'ambre, et il avait décidé que le reste était un nuage. Il l'avait appelé Nuage. Il avait raison, en un sens."},
				{"flag": &"geant_2_raconte"},
			]
		1:
			return [
				{"who": CHLOE, "text": "Il a cueilli une fougère avec ses griffes. Pour moi. J'ai reculé d'un mètre."},
				{"who": HELENE, "text": "Un mètre, c'est bien. Anselme l'avait appelé Râteau, et il m'avait demandé si c'était méchant. Un râteau ne fait de mal à personne, sauf quand on marche dessus."},
				{"flag": &"geant_1_raconte"},
			]
	return [
		{"who": CHLOE, "text": "%s a chanté. Il a bâillé, et il a posé sa tête juste à côté. Sa queue n'a pas bougé." % lead},
		{"who": HELENE, "text": "Les queues écoutent. Anselme l'avait appelé Ronfleur ; je lui avais dit que ça ne durerait pas. Il ronfle encore ? … Non ? Alors Anselme a tort, et on garde le nom quand même."},
		{"flag": &"geant_3_raconte"},
	]


## G5 (6 bulles), à la suite du G4 du quatrième.
static func four() -> Array:
	return [
		{"who": HELENE, "text": "Quatre. Il n'y a plus personne dans l'ambre, en bas."},
		{"who": CHLOE, "text": "Et lui ? Il est toujours couché."},
		{"who": HELENE, "text": "Lui, il n'a jamais dormi. On ne le réveille pas : on le laisse regarder la mer. … Trente ans de mon travail. Tu as mis combien de temps ?"},
		{"who": CHLOE, "text": "Je n'ai pas compté."},
		{"who": HELENE, "text": "Elle ne compte pas. C'est agaçant. Comme moi. Va voir Anselme : il compte les espèces, et il a une récompense qu'il n'arrive pas à cacher. Il n'y arrive jamais."},
		{"who": CHLOE, "text": "(Quatre géants debout, un Souverain couché, et des fougères d'ambre sur les veines. Plus personne ne dort dans l'ambre.)"},
		{"flag": &"geants_reveilles"},
	]


# ------------------------------------------------------------------ les examens, les objectifs

## Un géant réveillé, examiné dans le cratère (une ligne).
static func resident(n: int) -> String:
	return {
		4: "Moufle fait semblant de pêcher dans la cendre, avec ses grandes mains. Il n'y a pas de poisson. Il pêche quand même. Il a l'air content.",
		2: "Nuage mange, la tête tout là-haut. De temps en temps, une fougère tombe de son bec.",
		1: "Râteau range ses griffes contre son ventre, comme des ciseaux. Il les sort pour une fougère, et il les range.",
		3: "Ronfleur broute les fougères d'ambre, la tête au ras du sol, les pointes vers le ciel. Il ne ronfle plus : il chantonne, un peu faux. Quelqu'un lui a appris.",
	}[clampi(n, 1, 4)]


static func _bloc(n: int, capital := false) -> String:
	var s := "le " + String(BLOCS[clampi(n, 1, 4)])
	return "L" + s.substr(1) if capital else s


## Le géant `n` n'a pas encore ouvert l'œil (`moon` : « (dans 2 nuits) », pour la pleine lune).
static func obj_wait(n: int, moon := "") -> String:
	if n == 4:
		return "Les géants du cratère se réveillent un à un. Dans le petit bloc, celui à la plume d'Hélène, quelque chose a bougé."
	return "%s ouvrira l'œil %s%s. Les géants se réveillent un à un, à leur heure." % [_bloc(n, true), QUAND_OEIL[n], moon]


static func obj_look(n: int) -> String:
	if n == 4:
		return obj_wait(4)
	return "Quelque chose bouge dans %s : c'est son heure. Va voir." % _bloc(n)


static func obj_helene(n: int) -> String:
	return "%s a ouvert l'œil. Va le dire à Hélène, au Cabinet." % _bloc(n, true)


static func obj_sit(n: int) -> String:
	return "S'asseoir à côté du %s, avec %s en tête%s." % [BLOCS[clampi(n, 1, 4)], AVEC[clampi(n, 1, 4)], QUAND_ASSIS[clampi(n, 1, 4)]]


static func obj_tell(n: int) -> String:
	return "Le géant du %s est debout. Va le raconter à Hélène, au Cabinet." % BLOCS[clampi(n, 1, 4)]
