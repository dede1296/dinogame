class_name DialogueFossiles
## The post-game's legendary fossils (docs/post-game-scenes.md « F »): their plain lines, as dialogue
## steps ({"who", "text"}, {"flag"}, {"letter", "sign"}), word for word from the document, except the
## corrections said in the report of lot B (a line that must change with what Chloé holds: page 17,
## the first bone found, the missing piece, the second and third resurrections). The staging is
## story/fossiles.gd's. `%s` is always the name of the dino that acts (the one that dug, the one
## Chloé swims on) or the egg's.

const CHLOE := "Chloé"
const SIROCCO := "Tante Sirocco"
const HELENE := "Hélène"
const ISAURE := "Isaure"

## The three beasts: how the lines name them (« Un os du Titanosaure d'Or ! »).
const OF := {&"titanosaure": "du Titanosaure d'Or", &"kronosaurus": "du Kronosaurus", &"gigantoraptor": "du Gigantoraptor"}
## The five pieces (os_<beast>_1..5): « Tu as trouvé la tête. Ce n'est pas rien, une tête. »
const PIECES := [["la tête", "une tête"], ["une vertèbre", "une vertèbre"], ["une côte", "une côte"],
	["une patte", "une patte"], ["la queue", "une queue"]]
## The Kronosaurus had flippers, not legs.
const FLIPPERS := ["une nageoire", "une nageoire"]
## What is missing, said by Hélène (« ça se voit, une bête sans queue »).
const WITHOUT := ["tête", "dos", "côtes", "pattes", "queue"]


# ------------------------------------------------------------------ F1, Tante Sirocco's notebook

## F1 (9 lines): Sirocco and the bones, the notebook; flags carnet_os, carnet_terre (the two pages of
## the land are opened just after, by Fossiles). `page_17`: Chloé has found it (else she asks where).
## The stage directions are moves (Fossiles: she taps the mat at TAP, hands the three sheets at GIVE).
const TAP := 2
const GIVE := 4


static func carnet(page_17: bool) -> Array:
	var half: Array = [
		{"who": CHLOE, "text": "Page 17. Je l'ai."},
		{"who": SIROCCO, "text": "Alors tu as la moitié. L'autre moitié, c'est mon carnet. Cinq os par bête : la tête, le dos, les côtes, les pattes, la queue. Où ils sont, à ma façon. Mes genoux ne creusent plus. Les tiens, si."},
	] if page_17 else [
		{"who": CHLOE, "text": "Elle a écrit ça ? Où ?"},
		{"who": SIROCCO, "text": "Page 17, dans mon cimetière, entre les côtes : va la lire. L'autre moitié, c'est mon carnet. Cinq os par bête : la tête, le dos, les côtes, les pattes, la queue. Mes genoux ne creusent plus. Les tiens, si."},
	]
	return [
		{"who": SIROCCO, "text": "Chloé ! On me dit « gardienne ». On me dit « Réserve ». On me dit que la petite Varenne a réveillé le gros du cratère. Et personne ne me dit rien sur les os !"},
		{"who": CHLOE, "text": "Quels os ?"},
		{"who": SIROCCO, "text": "Ceux-là. Hélène et moi, on a passé vingt ans à les chercher, par morceaux. Trois bêtes de l'île d'avant l'ambre. Jamais une entière. Elle disait : « ceux-là dorment pour de bon ». Et puis elle ajoutait : « pour l'instant »."},
	] + half + [
		{"who": CHLOE, "text": "Et une fois que j'ai les cinq ?"},
		{"who": SIROCCO, "text": "Tu les portes à Hélène. Elle a une couveuse et une idée. Elle a toujours une idée, c'est reposant pour les autres."},
		{"who": SIROCCO, "text": "Deux feuilles pour la terre. La troisième est vide : la mer, je n'y mets pas les pieds. Demande à quelqu'un qui y met sa barque."},
		{"who": CHLOE, "text": "(Isaure. « Tarif unique : rien. » On verra ce que coûte une feuille.)"},
		{"flag": &"carnet_os"},
		{"flag": &"carnet_terre"},
	]


## A page of the notebook, as a letter (« — S. » for Sirocco's two, « — I. » for Isaure's): five
## riddles, one per bone. `page`: &"titanosaure", &"gigantoraptor" (the land), &"kronosaurus" (the sea).
static func page(beast: StringName) -> Dictionary:
	var riddles: Array = RIDDLES.get(beast, [])
	return {"letter": [TITLES.get(beast, "")] + riddles, "sign": "— I." if beast == &"kronosaurus" else "— S."}


const TITLES := {&"titanosaure": "Le doré", &"gigantoraptor": "Le plumeux", &"kronosaurus": "La mer"}
## The riddles, in the order of the bones (the head, the back, the ribs, the legs, the tail). Five
## follow the places as they are in the game (lot B's report): the crater's skull (by the block that
## snores), the Cimetière (the big bone of page 17, Gérard further off), the glacier (one blue block),
## Bertille's shelter (a mound, not a bench), Griffe-Grise (beside him), the Havre (no shore of sand).
const RIDDLES := {
	&"titanosaure": [
		"La tête : dans la paroi du cratère, tout au fond de l'île, près du bloc qui ronfle. Pas une goutte d'ambre dessus. Hélène l'a vue la dernière.",
		"Le dos : mon cimetière, au pied du grand os où Hélène s'est assise pour écrire. Une vertèbre plus petite. Dorée. Gérard la surveille, de loin.",
		"Les côtes : au pied des falaises de la Prairie, côté levant. Le vent a mis vingt ans à les découvrir, et une nuit à les recouvrir.",
		"Les pattes : au milieu du glacier, au pied d'un bloc bleu, à deux pas de sa page 29. Elle y a mis ses mains brûlées ; lui y a laissé ses pieds.",
		"La queue : sous la cendre des champs, au pied du volcan. La cendre garde tout : les bottes, les os, les secrets.",
	],
	&"gigantoraptor": [
		"La tête : au fond de la grotte qui répète tout. Elle a entendu son nom mille fois.",
		"Le dos : sous les grands arbres de la Forêt, là où Hélène écrivait sur Anselme. Il y a des racines dessus.",
		"Les côtes : là-haut, aux Pitons, au pied d'un poteau de pont. Le vent les a nettoyées.",
		"Les pattes : dans la vallée de la tricoteuse, devant son abri. Elle s'assoit dessus pour tricoter : elle croit que c'est une bosse.",
		"La queue : dans le ravin du vieux raptor gris. Il dort juste à côté. Demande-lui gentiment.",
	],
	&"kronosaurus": [
		"La tête : au fond du récif, là où Minuit écoute. Posée sur le sable, grande comme ma barque. On n'y va qu'en nageant.",
		"Le dos : la plage, la cale des anciens, dans le sable de la troisième marche.",
		"Les côtes : la cache des grottes marines, sous « H. + I. ». Je le savais. Je n'ai jamais creusé.",
		"Les pattes : il n'en avait pas, des nageoires. Les chenaux du Marais, un banc de vase.",
		"La queue : au bout du quai du Havre, dans l'herbe, après mon ponton. Les enfants jouent dessus depuis vingt ans.",
	],
}


# ------------------------------------------------------------------ F2, a bone

## The toast of a bone found: « Un os du Titanosaure d'Or ! Il en reste 4. »; the fifth says it is whole.
static func toast(beast: StringName, found: int) -> String:
	var left := 5 - found
	if left <= 0:
		return "Le dernier os %s ! Le squelette est complet : à porter à Hélène." % OF.get(beast, "")
	return "Un os %s ! Il en reste %d." % [OF.get(beast, ""), left]


## Chloé's thought at the first bone of each beast (1 line); `who`: the dino that dug it up, or that
## she swims on (the Kronosaurus's skull).
static func first_bone(beast: StringName, who: String) -> Array:
	var text: String = {
		&"titanosaure": "(Un os doré. Léger, comme s'il attendait qu'on le porte.)",
		&"kronosaurus": "(Un os bleu de sel, et plus lourd que moi. %s le porte. Il a l'air fier.)" % who,
		&"gigantoraptor": "(Un os creux, léger comme un os d'oiseau. Il vient pourtant d'une bête de huit mètres.)",
	}.get(beast, "")
	return [{"who": CHLOE, "text": text}]


## The two skulls one finds without digging (examined): in the wall of the crater, on the reef's sand.
static func skull(beast: StringName, who: String) -> Array:
	if beast == &"kronosaurus":
		return [{"text": "Sur le sable, un crâne grand comme une barque. %s le pousse du museau jusqu'à la surface." % who}]
	return [{"text": "Dans la paroi, un crâne doré, sans une goutte d'ambre autour. Il sort tout seul : il n'attendait que ça."}]


# ------------------------------------------------------------------ F3, Hélène and a first bone

## F3 (1 line, once per beast, before her pool); `piece`: a bone Chloé has of it (0 the head … 4 the tail).
static func helene_first(beast: StringName, piece: int) -> Array:
	var text := ""
	match beast:
		&"titanosaure":
			var p: Array = PIECES[clampi(piece, 0, 4)]
			text = "Un os doré ? … Celui-là, Sirocco et moi, on l'a cherché vingt ans. Tu as trouvé %s. Ce n'est pas rien, %s : ça dit où est le reste." % p
		&"kronosaurus":
			text = "Du Kronosaurus ? Alors tu as battu Isaure à son pari. Elle ne l'a pas dit. Elle ne dit jamais quand elle perd ; elle le fait, c'est tout."
		&"gigantoraptor":
			text = "Le plumeux. Sirocco l'appelle comme ça parce qu'elle ne sait pas dire « Gigantoraptor ». Moi non plus, le matin."
	return [{"who": HELENE, "text": text}, {"flag": StringName("helene_os_%s" % beast)}]


# ------------------------------------------------------------------ F4, the resurrection

## Before laying the bones on the table: the choice (the twenty tears are spent only on « yes »).
static func ask(beast: StringName) -> String:
	return "Les cinq os %s, la couveuse, et vingt larmes d'ambre." % OF.get(beast, "")


const ASK_OPTIONS := ["Les poser sur la table", "Pas maintenant"]


## Hélène when one is missing (once per beast, at four out of five): which one, she can tell.
static func missing(beast: StringName, piece: int) -> Array:
	var without: String = "nageoires" if beast == &"kronosaurus" and piece == 3 else WITHOUT[clampi(piece, 0, 4)]
	return [{"who": HELENE, "text": "Il en manque un. Je sais lequel : ça se voit, une bête sans %s." % without},
		{"flag": StringName("helene_manque_%s" % beast)}]


## A refusal (1 line): `why` = &"larmes" (fewer than twenty tears: `tears`) or &"oeuf" (an egg carried).
static func refusal(why: StringName, tears := 0) -> Array:
	if why == &"larmes":
		return [{"who": HELENE, "text": "Vingt larmes d'ambre. Tu en as %d. L'île en cache encore, sous les pierres et dans les arbres." % tears}]
	return [{"who": HELENE, "text": "Un à la fois. Celui que tu portes d'abord. Tu n'as que deux mains, et il en faut une pour le sac."}]


## F4 up to the incubator (5 lines): the bones on the table, the tears; `n`: resurrections already done
## (0, 1, 2: « Je ne l'ai jamais fait » is only true the first time).
static func resurrection_before(beast: StringName, n: int) -> Array:
	var legs := "les nageoires" if beast == &"kronosaurus" else "les pattes"
	var k := clampi(n, 0, 2)
	return [
		{"text": "Chloé pose les cinq os sur la table, dans l'ordre : la tête, le dos, les côtes, %s, la queue. Ça fait une bête, à plat." % legs},
		{"who": HELENE, "text": ["… Vingt ans. Sirocco va être insupportable.",
			"… Encore un. Sirocco va être encore plus insupportable.",
			"… Le dernier. Sirocco ne va plus jamais parler d'autre chose."][k]},
		{"who": HELENE, "text": "Donne-moi tes larmes d'ambre. Vingt. Un os, ce n'est pas un fragment : il n'y a plus personne dedans. Il faut lui prêter de quoi recommencer."},
		{"who": CHLOE, "text": ["Et ça marche ?", "Ça va remarcher ?", "Et la troisième fois ?"][k]},
		{"who": HELENE, "text": ["Je n'en sais rien. Je ne l'ai jamais fait. C'est bien pour ça que je ne l'ai pas fait sans toi.",
			"Je n'en sais rien. Une fois, ce n'est pas savoir. C'est bien pour ça que je ne le refais pas sans toi.",
			"Je n'en sais toujours rien. Deux fois, ce n'est pas savoir non plus. Alors on le fait encore ensemble."][k]},
	]


## The egg's colour, in the line after the incubator's light.
const EGG_LOOK := {&"titanosaure": "doré, comme une pièce", &"kronosaurus": "bleu de sel", &"gigantoraptor": "tacheté comme une plume"}


## F4 after the incubator (4 lines): the egg, Hélène, Chloé; flag ressuscite_<beast>.
static func resurrection_after(beast: StringName, n: int) -> Array:
	var k := clampi(n, 0, 2)
	return [
		{"text": "Les os fondent dans l'ambre comme du sucre dans le thé. Quand la lumière baisse, il reste un œuf, %s." % EGG_LOOK.get(beast, "")},
		{"who": HELENE, "text": "Un œuf. … Anselme, tu as vu ? … Il fait du thé. Évidemment."},
		{"who": HELENE, "text": "Garde-le contre toi. Marche, parle-lui. Et pas d'autre œuf tant que celui-là n'a pas éclos."},
		{"who": CHLOE, "text": ["(Un œuf d'une bête que plus personne n'a vue. … Elle a dit « je n'en sais rien ». Elle a dit « sans toi ». C'est la première fois pour les deux.)",
			"(Un deuxième œuf d'une bête que plus personne n'a vue. … Elle a encore dit « sans toi ». Ça ne s'use pas.)",
			"(Le troisième. … Sirocco a cherché vingt ans, Isaure a gardé un secret vingt ans. Et ça finit contre moi, dans un œuf.)"][k]},
		{"flag": StringName("ressuscite_%s" % beast)},
	]


# ------------------------------------------------------------------ the hatching, F5

## The egg hatches (3 lines; the toast says where it goes): level 45, so it grows « à vue d'œil ».
static func hatching(beast: StringName, name_: String) -> Array:
	var out: String = {
		&"titanosaure": "Un Titanosaure d'Or sort de la coquille, s'ébroue… et grandit à vue d'œil, comme si l'ambre lui rendait d'un coup tout le temps perdu. Ses plaques brillent comme des pièces neuves.",
		&"kronosaurus": "Un Kronosaurus glisse hors de la coquille, ouvre une gueule plus grande que lui… et grandit à vue d'œil, comme si l'ambre lui rendait d'un coup tout le temps perdu. Il cherche l'eau des yeux.",
		&"gigantoraptor": "Un Gigantoraptor déplie ses bras à plumes hors de la coquille… et grandit à vue d'œil, comme si l'ambre lui rendait d'un coup tout le temps perdu. Il penche la tête, comme un oiseau.",
	}.get(beast, "")
	return [
		{"text": "Crac ! L'œuf se fend contre Chloé…"},
		{"text": out},
		{"who": CHLOE, "text": "Bonjour, %s." % name_},
		{"flag": StringName("eclos_%s" % beast)},
	]


## F5 (1 line, once per beast once hatched).
static func helene_after(beast: StringName) -> Array:
	var text: String = {
		&"titanosaure": "Il a des pièces d'or cousues dans la peau. Ne le dis pas à Ferréol.",
		&"kronosaurus": "Quatre nageoires et une tête d'un quart de lui. Il ne marchera jamais : ne lui demande pas. Nage dessus.",
		&"gigantoraptor": "Des plumes, un bec, et huit mètres. Oviraptor va être jaloux. Il a le droit.",
	}.get(beast, "")
	return [{"who": HELENE, "text": text}, {"flag": StringName("helene_eclos_%s" % beast)}]
