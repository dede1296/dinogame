class_name ItemsDB
## Chloé's things and the shops that sell them (Havre-Doré). Prices in pièces (Game.items
## "piece"). `kind`: "soin" (used on a dino), "capture", "cle" (a key item: kept once, never
## sold), "quete" (for a quest). `sell`: what the Comptoir gives back (0: cannot be sold).

const ICON := "res://assets/art/ui/%s"

const ITEMS := {
	"baie": {"name": "Baie", "icon": "baie", "kind": "soin", "price": 30, "sell": 12,
		"desc": "Rend 20 PV à un dino. Les dinos en raffolent."},
	"fougere": {"name": "Fougère curative", "icon": "fougere", "kind": "soin", "price": 90, "sell": 35,
		"desc": "Soigne complètement un dino. Recette de Mémé Pervenche."},
	"collier": {"name": "Collier d'ambre", "icon": "collier", "kind": "capture", "price": 60, "sell": 25,
		"desc": "Lancé sur un dino sauvage affaibli, il peut le convaincre de te suivre."},
	"bottes": {"name": "Bottes de marche", "icon": "bottes", "kind": "cle", "price": 400, "sell": 0,
		"desc": "Semelles d'ambre souple : Chloé marche plus vite partout."},
	"boucle": {"name": "Boucle d'ambre", "icon": "boucle", "kind": "quete", "price": 150, "sell": 0,
		"desc": "Une boucle taillée dans l'ambre, pour une selle solide."},
	"cuir": {"name": "Cuir mué", "icon": "cuir", "kind": "quete", "price": 0, "sell": 0,
		"desc": "Une peau de Parasaurolophus, perdue à la mue. Souple et solide."},
	"selle": {"name": "Selle de Joss", "icon": "selle", "kind": "cle", "price": 0, "sell": 0,
		"desc": "Faite sur mesure. Un grand dino adulte peut porter Chloé."},
	# Marais et Désert (chapitres 3 et 4).
	"gilet_nage": {"name": "Gilet de nage", "icon": "gilet_nage", "kind": "cle", "price": 0, "sell": 0,
		"desc": "Cuir huilé et flotteurs de liège : avec un dino nageur adulte, Chloé traverse l'eau profonde sur son dos."},
	"masque_plongee": {"name": "Masque de plongée", "icon": "masque_plongee", "kind": "cle", "price": 0, "sell": 0,
		"desc": "Verre de lagon, joint de cuir huilé et une outre d'air cousue par Joss : avec un dino plongeur adulte, Chloé descend sous l'eau sur son dos."},
	"fossile": {"name": "Fossile", "icon": "fossile", "kind": "quete", "price": 0, "sell": 0,
		"desc": "Un os pétrifié, déterré grâce au Flair. Roc saura quoi en faire au Cabinet."},
	"pinceau_fouille": {"name": "Pinceau de fouille", "icon": "pinceau_fouille", "kind": "cle", "price": 0, "sell": 0,
		"desc": "Le vieux pinceau de Tante Sirocco. Hélène avait le même : on les avait achetés ensemble, au marché du port. Pour dépoussiérer les os sans les abîmer."},
	"coeur_1": {"name": "Premier Cœur d'ambre", "icon": "coeur_ambre", "kind": "cle", "price": 0, "sell": 0,
		"desc": "Il bat doucement, comme un cœur. Confié par le Spinosaure Ancestral, au fond du temple englouti."},
	"coeur_2": {"name": "Deuxième Cœur d'ambre", "icon": "coeur_ambre", "kind": "cle", "price": 0, "sell": 0,
		"desc": "Encore chaud du soleil du désert. Remis par le Carnotaurus Rouge, libéré de l'ambre noir."},
	# Prairie du Grand Crâne (chapitre 2, story/plaines.gd) : un drapeau, pas un objet du sac ; l'entrée donne son nom
	# et son image aux listes des Sceaux (battle/apex_hud.gd, Sceaux libres). Icône : assets/art/ui/sceau_plaines.png
	# (agent images ; l'ambre en attendant).
	"sceau_plaines": {"name": "Sceau de la Prairie", "icon": "sceau_plaines", "kind": "cle", "price": 0, "sell": 0,
		"desc": "Un disque d'ambre gravé de la fougère d'Hélène, posé au bout de la corne du Tricératops Alpha, au fond du Grand Crâne : sa confiance. Il ouvre la route côtière, vers le Havre."},
	"sceau_foret": {"name": "Sceau de la Forêt", "icon": "sceau_foret", "kind": "cle", "price": 0, "sell": 0,
		"desc": "Un disque d'ambre gravé de la fougère d'Hélène, remis par le chef de la meute d'Utahraptors. Il ouvre la route du Marais."},
	"sceau_marais": {"name": "Sceau du Marais", "icon": "sceau_marais", "kind": "cle", "price": 0, "sell": 0,
		"desc": "La confiance du Spinosaure Ancestral. Il ouvre la route du Désert."},
	"sceau_desert": {"name": "Sceau du Désert", "icon": "sceau_desert", "kind": "cle", "price": 0, "sell": 0,
		"desc": "La confiance du Carnotaurus Rouge. Il ouvre la route de la Côte."},
	# Côte Préhistorique (chapitre 5).
	"coeur_3": {"name": "Troisième Cœur d'ambre", "icon": "coeur_ambre", "kind": "cle", "price": 0, "sell": 0,
		"desc": "Frais comme un galet mouillé, il bat au rythme de la houle. Confié par le Mosasaure Abyssal, au fond du récif."},
	"sceau_cote": {"name": "Sceau de la Côte", "icon": "sceau_cote", "kind": "cle", "price": 0, "sell": 0,
		"desc": "Un disque d'ambre bleu de nuit, une vague qui s'enroule et la fougère d'Hélène : la confiance du Mosasaure Abyssal."},
	"masque_carton": {"name": "Masque en carton", "icon": "masque_carton", "kind": "cle", "price": 0, "sell": 0,
		"desc": "Le masque noir que Maïa s'était découpé après la Forêt. L'élastique est cassé. Chloé le lui rendra."},
	# Monts Gelés (chapitre 6).
	"coeur_4": {"name": "Quatrième Cœur d'ambre", "icon": "coeur_ambre", "kind": "cle", "price": 0, "sell": 0,
		"desc": "Froid comme une boule de neige, il bat tout doucement, comme quelqu'un qui dort. Confié par le Cryolophosaure Titan, au fond du sanctuaire de Givre."},
	"sceau_monts": {"name": "Sceau des Monts", "icon": "sceau_monts", "kind": "cle", "price": 0, "sell": 0,
		"desc": "Un disque d'ambre bleu pâle, un flocon et la fougère d'Hélène : la confiance du Cryolophosaure Titan."},
	"moufles_helene": {"name": "Moufles d'Hélène", "icon": "moufles", "kind": "cle", "price": 0, "sell": 0,
		"desc": "Rouges, tricotées main, un peu feutrées, reprisées au pouce. Bertille les avait tricotées pour Hélène. Trop grandes pour Chloé. Parfaites."},
	# Cieux Éternels (chapitre 7) : le harnais de Joss (donné par l'histoire, story/cieux.gd ; le Vol :
	# story/vol.gd) et le Sceau du Quetzalcoatlus Roi.
	"harnais_vol": {"name": "Harnais de vol", "icon": "harnais_vol", "kind": "cle", "price": 0, "sell": 0,
		"desc": "Cousu deux fois par Joss, avec une fougère frappée dans la sangle, « comme sur les boussoles d'Hélène ». Avec un grand ptérosaure adulte, Chloé vole où elle veut."},
	"sceau_cieux": {"name": "Sceau des Cieux", "icon": "sceau_cieux", "kind": "cle", "price": 0, "sell": 0,
		"desc": "Un disque d'ambre blanc doré, une aile ouverte et la fougère d'Hélène : la confiance du Quetzalcoatlus Roi. Il était caché sous le vieux harnais d'Hélène."},
	# Plaine Volcanique (chapitre 8, docs/chapitre-8-scenes.md) : l'antidote de Dame Suie (une dose,
	# réservée au dernier combat : règle « antidote » de BattleEngine), le Sceau et le Cœur du T-Rex de
	# Magma, la lettre d'Hélène pour Isaure (donnée à la porte : elle quitte le sac). Icônes :
	# assets/art/ui/<icon>.png (agent images ; l'ambre en attendant).
	"antidote_ambre": {"name": "Ambre clair", "icon": "antidote_ambre", "kind": "cle", "price": 0, "sell": 0,
		"desc": "Une fiole d'ambre liquide, clair, presque doré, qui luit un peu. « Une goutte. Pas une de plus. — S. » Versée sur un dino corrompu, elle efface ses veines d'un coup. Une seule dose : Dame Suie a dit de choisir le moment."},
	"sceau_volcan": {"name": "Sceau du Volcan", "icon": "sceau_volcan", "kind": "cle", "price": 0, "sell": 0,
		"desc": "Un disque d'ambre rouge sombre, une flamme et la fougère d'Hélène : la confiance du T-Rex de Magma. Il était dans la coque de lave, à côté du dernier Cœur."},
	"coeur_5": {"name": "Cinquième Cœur d'ambre", "icon": "coeur_ambre", "kind": "cle", "price": 0, "sell": 0,
		"desc": "Chaud comme du pain qui sort du four, il bat fort et vite, comme s'il avait couru. Le T-Rex de Magma l'avait couvert de lave, comme on couvre une braise pour la nuit."},
	"lettre_isaure": {"name": "Lettre pour Isaure", "icon": "lettre_isaure", "kind": "cle", "price": 0, "sell": 0,
		"desc": "La page 37 du journal d'Hélène, pliée en quatre, pas scellée. Dame Suie l'a gardée un an sans l'ouvrir. Elle est pour Isaure."},
	# Épilogue (chapitre 9, docs/chapitre-9-scenes.md 5 c) : remis par Hélène sur la jetée (ApexBag.give_insigne ;
	# celui de Maïa reste à Maïa). Icône : assets/art/ui/insigne_gardienne.png (agent images ; l'ambre en attendant).
	"insigne_gardienne": {"name": "Insigne de gardienne", "icon": "insigne_gardienne", "kind": "cle", "price": 0, "sell": 0,
		"desc": "Un disque d'ambre nu, avec la fougère d'Hélène. Chloé Varenne, gardienne de la Réserve d'Ambrelune. « Les Alphas te reconnaîtront. Ils te reconnaissent déjà. »"},
	# A rare find in the Forêt (a wink: docs/histoire.md « Clins d'œil »); Roc has a word about it.
	"ambre_moustique": {"name": "Ambre au moustique", "icon": "ambre_moustique", "kind": "cle", "price": 0, "sell": 0,
		"desc": "Un galet d'ambre trouvé dans les racines d'une vieille souche de la Forêt. Dedans, un moustique figé depuis des millions d'années. Il a l'air très surpris."},
	# The warm coat: without it, no going up into the cold regions (the Monts, later the Cieux).
	# Priced for what a player has at the end of chapter 5 (docs/mecaniques.md, « Les régions froides »).
	# Post-game, les géants (story/apex_geants.gd) : ramassée au réveil du petit bloc ; Hélène la laisse à Chloé (G4).
	# Icône : assets/art/ui/plume_helene.png (lot A' : une plume à écrire taillée, l'encre au bout ; l'ambre en attendant).
	"plume_helene": {"name": "Plume d'Hélène", "icon": "plume_helene", "kind": "cle", "price": 0, "sell": 0,
		"desc": "La plume avec laquelle Hélène écrivait son journal, coincée dans la fissure du petit bloc comme un marque-page. « Garde-la. Il reste des pages blanches dans ce journal, et ce n'est plus moi qui les écris. »"},
	"manteau_duvet": {"name": "Manteau de duvet", "icon": "manteau_duvet", "kind": "cle", "price": 300, "sell": 0,
		"desc": "Cousu par Rosalie avec le duvet que les dinos à plumes perdent à la mue. Une capuche bordée de duvet, des bottes chaudes : de quoi monter là où il neige."},
	# Post-game, les fossiles légendaires (lot B, story/fossiles.gd) : les os des trois squelettes (0 à 5
	# chacun, jamais vendus ; la Nouvelle partie+ les garde) et le carnet de Tante Sirocco.
	"os_titanosaure": {"name": "Os du Titanosaure d'Or", "icon": "os_titanosaure", "kind": "quete", "price": 0, "sell": 0,
		"desc": "Un os doré, léger comme s'il attendait qu'on le porte. Cinq font un squelette : Hélène et la couveuse du Cabinet sauront quoi en faire."},
	"os_kronosaurus": {"name": "Os du Kronosaurus", "icon": "os_kronosaurus", "kind": "quete", "price": 0, "sell": 0,
		"desc": "Un os bleu de sel, lourd comme une ancre. Cinq font un squelette : Hélène et la couveuse du Cabinet sauront quoi en faire."},
	"os_gigantoraptor": {"name": "Os du Gigantoraptor", "icon": "os_gigantoraptor", "kind": "quete", "price": 0, "sell": 0,
		"desc": "Un os creux, léger comme un os d'oiseau, d'une bête de huit mètres. Cinq font un squelette : Hélène et la couveuse du Cabinet sauront quoi en faire."},
	"carnet_os": {"name": "Carnet des os", "icon": "carnet_os", "kind": "cle", "price": 0, "sell": 0,
		"desc": "Trois feuilles pliées : les devinettes de Tante Sirocco, cinq os par bête. La troisième, celle de la mer, c'est Isaure qui l'a remplie. Elles se relisent au mur du journal et dans la fiche de chaque bête, au Dinodex."},
}

## shop id -> {name, keeper, stock: [item ids], sells: can Chloé sell here, tears: buys amber tears}
const SHOPS := {
	&"herboristerie": {"name": "Herboristerie Pervenche", "keeper": "Mémé Pervenche", "stock": ["baie", "fougere"], "sells": true},
	&"mercerie": {"name": "Mercerie « Au Fil d'Ambre »", "keeper": "Rosalie", "stock": ["collier", "bottes", "manteau_duvet"], "sells": true},
	&"comptoir": {"name": "Comptoir d'Ambre", "keeper": "Maître Ferréol", "stock": ["boucle"], "sells": true, "tears": true},
	# Joss on the Côte (chapter 5 on): the coats Rosalie gave him « pour ceux qui montent » (no need
	# to cross the island back to the Havre); he takes back what Chloé no longer needs.
	&"joss_cote": {"name": "Sellerie Bastide (en voyage)", "keeper": "Joss", "stock": ["manteau_duvet", "collier"], "sells": true},
}
## What the Comptoir pays for an amber tear (Roc would rather have them…).
const TEAR_PRICE := 40


static func item(id: String) -> Dictionary:
	return ITEMS.get(id, {"name": id, "icon": "ambre", "kind": "quete", "price": 0, "sell": 0, "desc": ""})


## Its picture (png or webp); the amber's while a new one is not imported yet.
static func icon(id: String) -> Texture2D:
	var path: String = ICON % item(id)["icon"]
	for ext: String in [".png", ".webp"]:
		if ResourceLoader.exists(path + ext):
			return load(path + ext)
	return load(ICON % "ambre" + ".png")
