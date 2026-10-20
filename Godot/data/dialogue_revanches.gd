class_name DialogueRevanches
## Le post-game, les revanches (docs/post-game-scenes.md R1 à R4) : les répliques, dans le format des scènes
## ({"who", "text"}, {"flag"}…). Mot pour mot, sauf ce qui ne collait pas avec le jeu (corrigé ici, dit en tête de
## story/revanches.gd). Les mots dits pendant les combats (les Sceaux libres) sont dans battle/apex_engine.gd.

const CHLOE := "Chloé"
const MAIA := "Maïa"
const ISAURE := "Isaure"
const HELENE := "Hélène"

# ------------------------------------------------------------------ R1 : le défi n° 6 de Maïa

const MAIA_PROMPT := "Le défi n° 6 de Maïa : « pour voir »."
const MAIA_OPTIONS := ["Le relever", "Pas aujourd'hui"]


## Avant le combat (3 bulles). Ses niveaux : ApexBattles.MAIA_LEVELS (cinquante, et Caillou cinquante et un).
static func maia_before() -> Array:
	return [
		{"who": MAIA, "text": "Niveau cinquante, tous les trois. Caillou, cinquante et un : il a triché, il a mangé pendant que je dormais."},
		{"who": MAIA, "text": "Pas pour gagner. Pour voir. … Bon. Un peu pour gagner."},
		{"who": CHLOE, "text": "(Six. Elle a toujours l'œuf fort contre le mien, et elle a toujours perdu de peu. « De peu », c'est ce qui l'énerve.)"},
	]


## Gagné (3 bulles). Le tableau du Relais porte déjà « pour l'instant » de sa main (story/havre.gd) : elle le repasse.
static func maia_won() -> Array:
	return [
		{"who": MAIA, "text": "… De peu. ENCORE de peu. Tu fais exprès ?"},
		{"who": CHLOE, "text": "Non."},
		{"who": MAIA, "text": "C'est pire. Demain, même heure. Et au tableau du Relais, je repasse « pour l'instant » à la craie. En plus gros."},
	]


## Perdu (2 bulles).
static func maia_lost() -> Array:
	return [
		{"who": MAIA, "text": "J'AI GAGNÉ. Caillou ! On a gagné ! … Ne le dis pas à maman. Elle dirait « enfin »."},
		{"who": CHLOE, "text": "(Elle le dira elle-même avant ce soir.)"},
	]


## Le tableau du Relais, une fois le défi n° 6 gagné (à la place de la ligne à la craie d'avant).
const RELAIS_CRAIE := "Quelqu'un a ajouté à la craie, en bas : « Chloé V., rang Argent. » À côté, « pour l'instant » a été repassé à la craie, en plus gros, et signé : « Maïa »."

# ------------------------------------------------------------------ R2 : les Alphas, « pour voir »

const ALPHA_OPTIONS := ["Pour voir.", "Pas aujourd'hui."]
const ALPHA_THOUGHT := "(Il a vu l'insigne. Hélène a dit : « ce n'est pas un cadeau, c'est du travail ». … Il veut voir si c'est vrai.)"
## Déjà fait aujourd'hui (%s : l'Alpha ; debout, il ne « se recouche » pas : il reprend sa garde).
const ALPHA_TODAY := "%s a déjà vu, aujourd'hui. Il reprend sa garde. Demain."
## Ce que dit le combat quand l'Alpha tombe : jamais « K.O. » (règle « foe_faint » de BattleEngine).
const ALPHA_STOPS := "Il s'arrête. Il a vu."
const ALPHA_WON_THOUGHT := "(Le Sceau est chaud dans la sacoche. … Il a dit oui. À sa façon.)"
## Perdu : le monde a déjà ramené Chloé à l'entrée ; une bulle (%s : l'Alpha, « Le Tricératops Alpha »).
const ALPHA_LOST := "%s s'est arrêté, lui aussi. Il a vu autre chose. Il attendra demain."
## Chaque victoire : « ce n'est pas un cadeau, c'est du travail » (Hélène) ; la Réserve paie sa gardienne.
const ALPHA_COINS := "Tournée de gardienne : la Réserve te verse %d pièces."
## Le choix (%s : l'Alpha).
const ALPHA_PROMPT := "%s attend."
## Le premier mot du combat (%s : l'Alpha).
const ALPHA_INTRO := "%s se dresse devant toi, pour voir ! (Revanche : pas de collier, pas de fuite.)"

## La leçon du combat (RevancheBattles : « home », ses crans chez lui) : ce qui part plus haut.
const HOME_WORDS := {"atk": "il frappe plus fort", "def": "il encaisse mieux", "spd": "il va plus vite"}


static func home_lesson(home: Dictionary) -> String:
	var said: Array = []
	for stat: String in ["atk", "def", "spd"]:
		if int(home.get(stat, 0)) > 0:
			said.append(HOME_WORDS[stat])
	if said.is_empty():
		return "Il est chez lui. Il connaît chaque pierre."
	var list := ", ".join(said.slice(0, -1)) + (" et " if said.size() > 1 else "") + String(said[-1])
	return "Il est chez lui : %s." % list


## Les Alphas : qui (le début d'une phrase), la ligne d'arrivée, la ligne d'après (%s : le dino en tête, s'il y en a
## un), le nom de son Sceau. Le Tricératops et le Chef de Meute ne sont pas devant Chloé : ils arrivent.
const ALPHAS := {
	&"plaines": {"who": "Le Tricératops Alpha", "seal": "Sceau de la Prairie",
		"arrival": "Le Tricératops Alpha sort de l'ombre du Crâne. Il baisse ses cornes jusqu'au sol, comme on salue. Puis il regarde l'insigne.",
		"after": "Il souffle par les naseaux, deux fois, et retourne au Crâne. De loin, Caillou souffle aussi : il copie."},
	&"foret": {"who": "Le Chef de Meute", "seal": "Sceau de la Forêt",
		"arrival": "Le Chef de Meute sort des fougères, et siffle. Trois raptors le suivent, s'assoient, et regardent : eux ne joueront pas. Lui, si.",
		"after": "Il incline la tête. Les trois autres aussi. Toute la meute, en même temps."},
	&"marais": {"who": "Le Spinosaure Ancestral", "seal": "Sceau du Marais",
		"arrival": "Le Spinosaure déploie sa voile, lentement, comme on ouvre un livre.",
		"after": "Il replie la voile. Il apporte de l'eau dans sa gueule et la verse sur les pattes de %s, sans en perdre une goutte."},
	&"desert": {"who": "Piment", "seal": "Sceau du Désert",
		"arrival": "Piment rugit. Pas contre Chloé : pour dire qu'il est là. Le vrai rugissement.",
		"after": "Il se gratte le museau contre l'entrée du sanctuaire, et grogne doucement : c'est son « à demain »."},
	&"cote": {"who": "Minuit", "seal": "Sceau de la Côte",
		"arrival": "Minuit monte des profondeurs, les yeux presque fermés. Il écoute. Il entend le cœur de %s battre vite.",
		"after": "Il écoute encore. Le cœur de %s bat moins vite. Il redescend dans le noir, satisfait."},
	&"monts": {"who": "Toupet", "seal": "Sceau des Monts",
		"arrival": "Toupet descend de sa paroi de glace. Sa crête a du givre dessus. Il attend que Chloé ait fini de la regarder.",
		"after": "Il souffle sur l'autel. Le givre s'y pose, puis fond : un oui, en givre."},
	&"volcan": {"who": "Cheminée", "seal": "Sceau du Volcan",
		"arrival": "Cheminée ouvre un œil, puis l'autre, et se lève en fumant. Il regarde le chapeau de Chloé. Chloé n'a pas de chapeau. Il a l'air déçu.",
		"after": "Il se couche à côté de %s. Il fume. Le sol tremble un peu. C'est sa façon d'être d'accord."},
}


## Une ligne d'un Alpha (`key` : "arrival", "after"), le dino en tête à la place de %s (« son dino » sans lui).
static func alpha_line(id: StringName, key: String, lead_name: String) -> String:
	var text: String = ALPHAS.get(id, {}).get(key, "")
	return text % (lead_name if lead_name != "" else "son dino") if text.contains("%s") else text


## L'arrivée (2 bulles, puis le choix) : sa ligne, la pensée de Chloé.
static func arrival(id: StringName, lead_name: String) -> Array:
	return [{"text": alpha_line(id, "arrival", lead_name)}, {"who": CHLOE, "text": ALPHA_THOUGHT}]


## Le toast de la première victoire.
static func woken_toast(id: StringName) -> String:
	return "Le %s s'éveille : l'Alpha répond à ton appel, une fois par jour, dans tous les combats." % ALPHAS[id]["seal"]

# ------------------------------------------------------------------ R3 : le pari d'Isaure

const ISAURE_PROMPT := "Un pari de marin."
const ISAURE_OPTIONS := ["Je parie.", "Pas aujourd'hui."]


## L'offre (2 bulles, puis le choix).
static func isaure_offer() -> Array:
	return [
		{"who": ISAURE, "text": "Un pari, moussaillon ? Les miens s'ennuient : Hauban pêche, les trois autres regardent la mer. Carène a arrêté d'hésiter. Je l'ai prévenue."},
		{"who": ISAURE, "text": "Si je gagne, tu laves la barque. Si tu gagnes… tu verras. Je ne dis pas mes paris avant."},
	]


## Gagné, la première fois : la page de la mer. Sirocco ne l'a dit « depuis sa tente » que si elle a déjà donné la
## terre (`carnet_terre`, le lot des fossiles) ; sinon elle le fera.
static func isaure_won_first(sirocco_gave_land: bool) -> Array:
	var land := "Sirocco t'a donné la terre : je le sais, elle me l'a crié depuis sa tente, elle crie toujours." if sirocco_gave_land \
		else "Sirocco te donnera la terre : elle crie, elle ne pourra pas s'en empêcher."
	return [
		{"who": ISAURE, "text": "Perdu."},
		{"text": "Elle ne sourit pas. Puis si."},
		{"who": ISAURE, "text": "Tiens. %s La mer, c'est moi." % land},
		{"text": "Une feuille pliée. L'écriture penche à gauche : une écriture de marin. Cinq os, cinq endroits."},
		DialogueFossiles.page(&"kronosaurus"),
		{"who": ISAURE, "text": "Le dernier, au bout du quai du Havre, après mon ponton : je le sais depuis vingt ans. Les enfants jouaient dessus. Je n'ai jamais creusé : ce n'était pas à moi."},
		{"who": CHLOE, "text": "(« Ce n'était pas à moi. » Elle a mis vingt ans à le dire d'un os. Elle le dit.)"},
	]


## Gagné ensuite (1 bulle ; ISAURE_COINS pièces).
const ISAURE_WON_AGAIN := "Encore perdu. Je garde une pièce sur deux pour la barque. Tiens, l'autre moitié."
## Perdu : la barque à laver (1 bulle, Chloé frotte le pont trois secondes, Carène regarde, puis 1 bulle).
const ISAURE_LOST := "Gagné. La barque. Avec l'eau de mer, pas celle du puits : Carène n'aime pas l'eau douce."
const ISAURE_SCRUB := "Chloé frotte le pont. Carène regarde."
const ISAURE_TOMORROW := "Demain, moussaillon."

# ------------------------------------------------------------------ R4 : Hélène, les Sceaux

const HELENE_SCEAUX := "Un Sceau s'est réveillé ? Alors ils t'ont reconnue. Appelle-les quand tu veux : une fois par jour. Ils ont une région à garder, et toi, tu as le reste."

# ------------------------------------------------------------------ l'objectif

## L'objectif « Les revanches » (ApexObjectives.side) : qui attend, et combien de Sceaux sont éveillés sur sept.
static func objective(woken: int, total: int) -> String:
	var seals := "aucun Sceau éveillé" if woken == 0 else "%d Sceau%s éveillé%s sur %d" % [woken, "x" if woken > 1 else "", "s" if woken > 1 else "", total]
	return "Les revanches : Maïa au Grand Crâne, les Alphas chez eux (%s), le pari d'Isaure à sa barque. Une fois par jour chacun." % seals
