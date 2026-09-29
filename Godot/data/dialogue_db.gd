class_name DialogueDB
## The game's lines, by id. A script is an Array of steps:
##   {"who": "Maïa", "text": "…"}   a line (no "who" = narration)
##   {"flag": &"met_maia"}           sets a story flag
##   {"text_fn": callable}           a line worked out when shown
##   {"voice": "res://…mp3"}         plays a recorded voice over the next line
##   {"letter": [paragraphs], "sign": "— H.", "voice": "res://…mp3"}
##                                  a handwritten page (first paragraph = its title)
## `lines(id)` picks the version that fits the current story flags.

const CHLOE := "Chloé"
const MAIA := "Maïa"


static func lines(id: StringName) -> Array:
	match id:
		&"maia":
			if not Game.flag(&"met_maia"):
				return [
					{"who": MAIA, "text": "Te voilà enfin ! Tu en as mis, du temps. Tu as entendu, pour le petit volé cette nuit ? Tout le port en parle."},
					{"who": CHLOE, "text": "Ma grand-mère venait souvent ici ?"},
					{"who": MAIA, "text": "Tout le temps ! Avant de partir vers le volcan, elle allait au vieux bosquet, à l'ouest."},
					{"who": MAIA, "text": "Mais un gros tronc est tombé en travers du sentier. Il faudrait des griffes bien affûtées pour le trancher…"},
					{"who": MAIA, "text_fn": claws_text},
					{"flag": &"met_maia"},
				]
			if Game.flag(&"boussole_volee") and not Game.flag(&"boussole_trouvee"):
				return [{"who": MAIA, "text": "Elle a filé vers le petit bois, au nord-ouest ! Les compsos cachent tout dans un nid, au ras du sol."}]
			if Game.flag(&"boussole_rendue") and not Game.flag(&"found_journal_2"):
				return [{"who": MAIA, "text": "Alors, l'étang ? Il chante vraiment, les soirs de pleine lune ? Maman ne ment jamais… enfin, presque jamais."}]
			if Game.flag(&"found_journal_1") and not Game.flag(&"maia_page1"):
				return [{"who": MAIA, "text": "Un fragment d'ambre et une page du journal ?! Montre ça au Professeur Roc. Et la prochaine fois, c'est toi contre moi !"},
					{"flag": &"maia_page1"}]
			return chatter(&"maia")
		&"route_cotiere":
			return [{"who": "Le garde du Havre", "text": "Halte ! La route côtière, c'est pour les dresseurs reconnus. Reviens quand un Alpha t'aura remis son Sceau, petite."}]
		&"garde_route":
			if Game.flag(&"sceau_plaines"):
				return [{"who": "Le garde du Havre", "text": "Un Sceau d'Alpha ! Passe, dresseuse. Havre-Doré est au bout de la route, à l'est. Tu verras : là-bas, même les lanternes ont l'air riches."}]
			return [{"who": "Le garde du Havre", "text": "La route côtière est réservée aux dresseurs qui portent un Sceau d'Alpha. Ordre du Comptoir. Moi, j'obéis, et on me paie pour."}]
		&"panneau_route_cotiere":
			return [{"text": "Est : route côtière vers Havre-Doré. Péage : un Sceau d'Alpha. (Les dinos sauvages, eux, passent gratuitement.)"}]
		&"enseigne_herboristerie":
			return [{"text": "« Herboristerie Pervenche — Baies, fougères, remèdes. On ne rend pas la monnaie aux impolis. »"}]
		&"enseigne_mercerie":
			return [{"text": "« Au Fil d'Ambre — Colliers, bottes, tout pour l'aventure. Rosalie, prop. »"}]
		&"enseigne_relais":
			return [{"text": "« Relais des Dresseurs — Combats amicaux tous les jours. Les perdants paient la limonade. »"}]
		&"enseigne_comptoir":
			return [{"text": "« Comptoir d'Ambre — Achat, vente, estimation. Maître Ferréol, négociant agréé. »"},
				{"text": "Sous l'enseigne, une petite plaque plus ancienne a été dévissée. On voit encore les trous des vis."}]
		&"enseigne_sellerie":
			return [{"text": "« Sellerie Bastide, père et fils — Selles, harnais, sur mesure. » Le mot « père » a été repeint plusieurs fois."}]
		&"enseigne_entrepot":
			return [{"text": "« Entrepôt du Comptoir — Accès interdit. » Le cadenas est neuf. Très neuf."}]
		&"entrepot":
			if Game.flag(&"barque_vue"):
				return [{"text": "L'entrepôt du Comptoir. Le cadenas est fermé. Par une fente, une odeur de fumée froide et de mer… et de cendre."}]
			return [{"text": "L'entrepôt du Comptoir. Fermé à double tour. On entend quelque chose remuer à l'intérieur, puis plus rien."}]
		&"marchande":
			return [{"who": "La marchande", "text": ["Des fruits du Havre ! Enfin, du continent. Enfin, d'un bateau. Bref, des fruits !",
				"Les dinos du Relais mangent mieux que moi. Mais bon, ils gagnent plus que moi aussi.",
				"Ferréol ? Un homme généreux. Il a payé la nouvelle fontaine. Enfin, la fontaine qu'on aura un jour."].pick_random()}]
		&"pecheur_havre":
			return [{"who": "Un pêcheur", "text": ["Ici, on ne pêche plus beaucoup. Pourquoi pêcher, quand on peut ramasser de l'ambre ?",
				"La nuit, des barques accostent à l'entrepôt sans allumer leurs lanternes. Je dis rien. Je répare mes filets.",
				"Port-Ambre ? Ils sont fiers, là-bas. Fiers et pauvres. Ça va souvent ensemble."].pick_random()}]
		&"cuir_trouve":
			return [{"text": "Sur la rive, à moitié dans les fougères, une grande peau fine et souple : un Parasaurolophus a mué ici. Parfait pour Joss."}]
		&"panneau_carrefour":
			return [{"text": "Nord : Grotte des Échos.  Nord-est : les Falaises.  Est : l'étang, puis le Grand Crâne.  Ouest : le vieux bosquet.  Sud : Port-Ambre."},
				{"text": "Tout en bas, quelqu'un a ajouté au couteau : « Paris : 9 874 km. À la nage, compter large. »"}]
		&"panneau_anse":
			return [{"text": "« Baignade déconseillée. — La direction. »"},
				{"text": "En guise de signature, une trace de dent. Grande comme ta main."}]
		&"panneau_oeuf":
			return [{"text": "« Ceci n'est pas un œuf. »"}, {"text": "C'est un rocher. Mais il y croit très fort."}]
		&"panneau_etang":
			return [{"text": "Étang des Chanteurs. On dit que les soirs de pleine lune, l'étang chante."}, {"text_fn": moon_text}]
		&"page_2":
			return [
				{"text": "Au milieu de l'îlot, sous une pierre plate, une page du journal. Sèche, malgré l'eau tout autour."},
				{"letter": ["Chacun chez soi",
					"Je les ramène un par un là où leur monde leur ressemble. Les cornus aux prairies, les crêtes à l'étang. Les Parasaurolophus ont choisi cette eau-là tout seuls : je n'ai eu qu'à ouvrir la caisse.",
					"Anselme dit que je leur parle trop. Il a raison. Mais ils répondent.",
					"Ce soir, ils chantent pour la lune. Je crois qu'ils se souviennent de quelque chose que je ne connais pas encore."],
					"sign": "— H."},
				{"flag": &"found_journal_2"},
			]
		&"isaure":
			return chatter(&"isaure")
		&"port_bloque":
			return [{"text": "Le Professeur Roc t'attend au Cabinet, la grande maison couverte de lierre à l'est du village."}]
		&"cabinet_bloque":
			return [{"who": "Prof. Roc", "text": "Où vas-tu comme ça ? Les petits sont sur les socles, à droite : choisis d'abord ton compagnon !"}]
		&"panneau_plaines":
			return [{"text": "Nord : les Plaines des Fougères.  Est : le Cabinet du Professeur Roc."}]
		&"panneau_port":
			return [{"text": "Sud : Port-Ambre et le Cabinet du Professeur Roc."}]
		&"panneau_debarcadere":
			return [{"text": "Nord : le carrefour des Plaines. Sud : Port-Ambre. Attention, dinos dans les herbes hautes !"}]
		&"panneau_grotte":
			return [{"text": "Grotte des Échos — entrée fermée par un éboulement."}]
		&"tronc_bloque":
			return [{"text": "Un gros tronc moussu barre le sentier. Des griffes acérées pourraient le trancher…"}]
		&"rocher_bloque":
			return [{"text": "Un énorme rocher bloque le chemin de la grotte. Il faudrait un dino à la tête solide pour l'enfoncer…"},
				{"text": "Les Protoceratops des hautes herbes ont justement une tête bien dure."}]
		&"ambre_proto":
			return [
				{"text": "Tu as trouvé un fragment d'ambre ! Un minuscule Protoceratops y est figé depuis 66 millions d'années."},
				{"text": "Une page de journal, pliée en quatre, est glissée dessous…"},
				{"letter": ["Le premier réveil",
					"12 mars. Il a ouvert les yeux ce matin. Trente-deux ans de recherche, et un petit Protoceratops me regarde comme si j'étais sa mère. L'Ambre-Mère ne ment pas : l'ADN est intact. Anselme a pleuré. Moi aussi, un peu.",
					"Je dois garder le secret. Si l'on apprend ce que l'île contient, ils viendront tous."],
					"sign": "— H.", "voice": "res://assets/audio/voices/journal-1.mp3"},
				{"flag": &"found_journal_1"},
				{"flag": &"amber_protoceratops"},
				{"text": "Au fond de la cachette brille autre chose : une écaille d'ambre, tiède comme une pierre au soleil."},
				{"flag": &"ecaille_bosquet"},
				{"text_fn": ecailles_text},
			]
		&"ecaille_grotte":
			return [{"text": "Une écaille d'ambre, coincée entre deux cristaux. Elle pulse doucement, comme un cœur."},
				{"flag": &"ecaille_grotte"}, {"text_fn": ecailles_text}]
		&"ecaille_falaises":
			return [{"text": "Une écaille d'ambre, posée sur la table du vieux poste d'observation. Hélène l'a laissée là exprès."},
				{"flag": &"ecaille_falaises"}, {"text_fn": ecailles_text}]
		&"page_3":
			return [
				{"text": "Une page du journal d'Hélène, glissée sous une pierre plate."},
				{"letter": ["La barque",
					"Je n'aurais jamais trouvé Ambrelune sans I. Elle avait dix-neuf ans, une barque trop petite et un courage trop grand. Elle a traversé la brume pour moi sans poser de questions.",
					"Quand l'île est apparue, elle a ri : « Tu vois, Hélène ? Les légendes, ça se trouve. » Je lui dois tout."],
					"sign": "— H."},
				{"flag": &"found_journal_3"},
			]
		&"page_4":
			return [
				{"text": "Une page du journal, roulée dans une fissure de la roche."},
				{"letter": ["Ce qui ne dort pas",
					"J'ai voulu forcer l'ambre. Réveiller un dino sans attendre qu'il soit prêt. Ce qui est sorti de la pierre n'était pas vivant comme les autres : des veines violettes, des yeux troubles, une peur qui ne s'éteignait jamais.",
					"J'ai tout arrêté. J'ai brûlé mes notes… presque toutes."],
					"sign": "— H."},
				{"flag": &"found_journal_4"},
			]
		&"page_5":
			return [
				{"letter": ["Le premier Alpha",
					"Le grand Tricératops m'a chargée trois fois avant de s'arrêter. Puis il a posé sa tête contre ma main. Je n'avais rien fait, rien dit : j'avais seulement refusé d'avoir peur de lui.",
					"C'est ça, le Lien. Pas un ordre : une confiance. Je l'écris ici pour ne jamais l'oublier."],
					"sign": "— H."},
				{"flag": &"found_journal_5"},
			]
		&"page_6":
			return [
				{"text": "Une page pliée en quatre. Sur le dessus, d'une écriture penchée : « Pour Chloé »."},
				{"letter": ["Pour Chloé"] + page_6_text(), "sign": "— H."},
				{"flag": &"found_journal_6"},
				{"text": "Chloé glisse la page avec les autres. Dehors, quelque part vers le volcan, une lanterne s'est éteinte."},
			]
		&"porte_ambre_bloquee":
			return [{"text": "Une porte d'ambre, éteinte et froide, scellée dans la roche. Une fougère est gravée dessus."},
				{"text": "On raconte que l'ambre répond au chant… Une crête qui résonne pourrait peut-être la réveiller."}]
		&"panneau_falaises":
			return [{"text": "Poste d'observation d'H. Varenne. Nids de Dimorphodons : ne pas déranger !"}]
		&"panneau_crane":
			return [{"text": "Le Grand Crâne. Dans sa grotte dort le gardien des Plaines."}]
		&"antre_gardien":
			if Game.flag(&"sceau_plaines"):
				return [{"text": "Du fond du tunnel monte une respiration lente et profonde… Le gardien dort."},
					{"text": "Mieux vaut ne pas le déranger."}]
			return [{"text": "Le tunnel sent le gardien, mais il est vide. Le Tricératops Alpha t'attend dehors, devant le crâne."}]
		&"panneau_grotte_int":
			return [{"text": "Quelqu'un a gravé une flèche dans la roche, vers le nord. Et, dessous : « H. »"}]
		# ------------------------------------------------ chapter 2, the Forêt Jurassique
		&"foret_bloquee":
			var blocked: Array = [
				{"text": "Le bois s'épaissit d'un coup : des troncs larges comme des maisons, des fougères plus hautes que Chloé, et des sentiers qui se séparent en trois tous les dix pas."},
				{"text": "C'est la Forêt Jurassique. Elle est immense : à pied, on s'y perdrait avant le goûter. Même les Stegosaurus s'y perdent. (Bon, ils ont un cerveau grand comme une noix.)"},
			]
			if Game.flag(&"havre_arrive"):
				blocked.append({"text": "Il faudrait un grand dino à monter, et une selle. Joss, le sellier de Havre-Doré, en fabrique justement."})
			elif Game.flag(&"sceau_plaines"):
				blocked.append({"text": "Il faudrait un grand dino à monter, et une selle. On dit qu'à Havre-Doré, au bout de la route côtière (à l'est de Port-Ambre), un sellier en fabrique."})
			else:
				blocked.append({"text": "Plus tard, peut-être, avec un grand dino à monter. Pour l'instant, les Plaines ont encore leurs secrets : le Grand Crâne attend toujours."})
			return blocked
		&"panneau_lisiere":
			return [{"text": "Forêt Jurassique. Ouest : le sous-bois. Nord : les clairières. Sud : la haute futaie. Est : les Plaines des Fougères."},
				{"text": "Dessous, une petite plaque : « Ne pas nourrir les Dilophosaurus. Ils crachent. Même pour dire merci. »"}]
		&"panneau_ravin":
			return [{"text": "Ravin. Sentier non entretenu. (Exprès.)"},
				{"text": "Plus bas, d'une écriture penchée que Chloé connaît bien : « Chez Griffe-Grise. On n'entre pas sans y être invité. Il n'invite jamais. — H. »"}]
		&"panneau_futaie":
			return [{"text": "Haute futaie. Rampes taillées à la main par A. Roc, qui a le vertige. Merci de ne pas le lui rappeler."},
				{"text": "Au crayon, dessous : « Les Microraptors volent les chapeaux. Et les lunettes. SURTOUT les lunettes. »"}]
		# Clins d'œil (docs/histoire.md « Clins d'œil »): the sign by the old broken fence of the
		# Prairie des brachiosaures, and the amber pebble with a mosquito in it (Forêt, a rare find).
		&"panneau_cloture":
			return [{"text": "Un vieux panneau, tout penché : « NE PAS NOURRIR LES ANIMAUX. »"},
				{"text": "Dessous, d'une écriture penchée que Chloé connaît bien : « De toute façon, ils se servent tout seuls. — H. »"}]
		&"ambre_moustique":
			return [
				{"text": "Dans les racines de la vieille souche, quelque chose brille. Un galet d'ambre, lisse et doré, gros comme un œuf de caille."},
				{"text": "Et dedans, figé depuis des millions d'années, un moustique. Les ailes bien à plat, les pattes repliées."},
				{"who": CHLOE, "text": "(Il a l'air aussi surpris que moi.)"},
				{"text": "Chloé range l'ambre au moustique tout au fond de sa sacoche. Roc voudra sûrement le voir."},
			]
		&"page_7":
			return [
				{"text": "Sous la plus grande fougère du sous-bois, roulée dans une feuille cirée, une page du journal."},
				{"letter": ["Confiance",
					"Trois jours cachée sous une fougère, à regarder la meute. Les Deinonychus ne suivent pas le plus fort : ils suivent celui qui revient chercher le dernier. Leur chef, un grand Utahraptor, compte les siens à chaque ruisseau.",
					"Anselme voudrait leur apprendre à obéir. Mais le Lien n'est pas l'obéissance : un dino qui obéit attend un ordre ; un dino qui a confiance n'en a pas besoin.",
					"(Quarante piqûres de moustique. Ça valait le coup.)"],
					"sign": "— H."},
				{"flag": &"found_journal_7"},
				{"who": CHLOE, "text": "(Un chef qui compte les siens à chaque ruisseau… Et maintenant qu'on l'a emmené, qui les compte ?)" if Game.flag(&"clairiere_vue")
					else "(Un chef qui compte les siens à chaque ruisseau… Alors pourquoi la meute appelle-t-elle dans le vide ?)"},
			]
		&"page_8":
			return [
				{"text": "Glissée dans une fente de l'écorce, tout en haut de la futaie, une page du journal."},
				{"letter": ["Anselme",
					"Anselme a taillé à la main les rampes de la haute futaie, pour que je puisse observer les Microraptors. Il a le vertige. Il est tombé deux fois, a cassé trois paires de lunettes, et ne s'est plaint qu'en latin.",
					"Il ne sait pas dire les choses : il les répare. C'est sa façon d'aimer.",
					"P.-S. S'il se sent coupable un jour de ne pas m'avoir retenue, dis-lui que non. Personne n'a jamais su me retenir."],
					"sign": "— H."},
				{"flag": &"found_journal_8"},
				{"text": "Le P.-S. est d'une autre encre, plus noire, plus récente. Hélène l'a ajouté bien plus tard. Peut-être juste avant de cacher la page."},
				{"who": CHLOE, "text": "(Coupable… de quoi, professeur ?)"},
			]
		&"page_9":
			var page: Array = [
				{"text": "Parmi les fleurs de la clairière, glissée sous une racine, une page du journal. L'écriture est plus serrée que d'habitude, comme écrite très vite."},
				{"letter": ["Les veines violettes",
					"Ce matin, dans la clairière, un jeune Stegosaurus blessé. Les yeux troubles, et sous la peau, des veines violettes.",
					"Je ne les avais vues qu'une fois, il y a dix-sept ans, dans mon propre laboratoire. Quelqu'un a refait ce que j'avais brûlé. Mal : il souffre. Mais assez bien pour me faire peur.",
					"Je l'ai veillé toute la nuit ; au matin, les veines avaient pâli. Je ne sais pas qui fait ça. J'ai peur de le savoir."],
					"sign": "— H."},
				{"flag": &"found_journal_9"},
			]
			if Game.flag(&"proto_apaise"):
				page.append({"who": CHLOE, "text": "(Des veines violettes… comme le Protoceratops de la grotte. Ça dure depuis si longtemps ?)"})
			return page
		&"page_10":
			return [
				{"text": "Au bord de la mare de la lisière, une page du journal brille doucement dans l'herbe, comme si la lune l'avait gardée au chaud." if Game.is_full_moon()
					else "Au bord de la mare de la lisière, à l'abri d'une touffe de fleurs, une page du journal."},
				{"letter": ["Apaiser",
					"Cette nuit, un jeune Brachiosaurus perdu, fou de peur. On ne calme pas un dino affolé en le tenant. On se met à sa hauteur (pour un Brachiosaurus : debout sur une souche), on respire lentement, assez fort pour qu'il l'entende, et on regarde la même chose que lui.",
					"Il ne comprend pas les mots. Il comprend qu'on reste.",
					"Avec les veines violettes, c'est plus long. Il faut rester plus longtemps que leur peur."],
					"sign": "— H."},
				{"flag": &"found_journal_10"},
				{"who": CHLOE, "text": "(« Rester plus longtemps que leur peur. » Je m'en souviendrai.)"},
			]
		# ------------------------------------------------ chapter 2, step 2 (story/foret_camp.gd, foret_fin.gd)
		&"mur_fissure_bloque":
			return cracked_wall()
		&"pont_marais_bloque":
			return marais_bridge()
		&"panneau_camp":
			return [{"text": "PROPRIÉTÉ DE L'OMBRE NOIRE. Défense d'entrer. Les curieux finissent en cage."},
				{"text": "Dessous, d'une écriture tremblante : « Et Brac a mauvais caractère le matin. Et le soir. Et entre les deux. »"}]
		&"panneau_pont":
			return [{"text": "Pont du Marais. Ouest : le Marais Brumeux. Un seul dino à la fois. (Et pas un Stegosaurus.)"},
				{"text": "Sur un poteau, deux initiales gravées dans une petite fougère : « H. + I. » Le bois est vieux. Très vieux."}]
		&"page_11":
			return [
				{"letter": ["Le port se meurt",
					"I. est venue ce soir, trempée. Trois bateaux vendus ce mois-ci ; au port, les filets sèchent vides. Elle m'a demandé de vendre l'ambre : « Juste un peu, Hélène. De quoi passer l'hiver. »",
					"J'ai dit non. L'ambre, c'est là que l'île garde ses dinos endormis : qu'on en vende un seul morceau, et ils viendront tous, avec des pioches.",
					"Elle n'a pas crié. Elle a reposé sa tasse, très doucement, et elle est partie.",
					"Elle n'a pas claqué la porte. C'est pire."],
					"sign": "— H."},
				{"flag": &"found_journal_11"},
			]
		# ------------------------------------------------ chapter 3, the Marais Brumeux (story/marais.gd, marais_temple.gd)
		&"panneau_marais":
			return [{"text": "Marais Brumeux. Attention : la brume cache les chenaux, et les chenaux cachent les Koolasuchus."},
				{"text": "Dessous, une planchette clouée de travers : « Gilets de nage : voir Joss, cabane sur pilotis. Testés et approuvés. (Bientôt approuvés.) »"}]
		&"panneau_temple":
			return [{"text": "Temple englouti. Entrée sur invitation. L'invitation se chante."},
				{"text": "Gravé plus bas, presque effacé : « La Voix d'abord. Le Spinosaure ensuite. Et on ne court pas dans les galeries. — H. »"}]
		&"panneau_desert":
			return [{"text": "Nord : le Désert Aride. Plus une goutte d'eau pendant trois jours de marche. Remplissez vos gourdes. Et vos dinos."},
				{"text": "Quelqu'un a gravé au couteau : « BRAC, RENTRE CHEZ TOI. » C'est barré. Dessous, en grosses lettres maladroites : « NON. — B. »"}]
		&"desert_bloque":
			return desert_road()
		&"porte_temple_fermee":
			return temple_door()
		&"porte_voix_bloquee":
			var sing: String = Marais.sing_step()
			return [{"text": "Une porte d'ambre ferme l'îlot, entre deux arbres noyés. Derrière, une voix grave chante, et l'ambre tremble à chaque note, comme s'il voulait répondre."},
				{"text": sing if sing != "" else "Une crête qui chante pourrait peut-être la réveiller…"}]
		&"crue_temple":
			return temple_flood()
		&"page_12":
			return [
				{"text": "Sur une corniche de la galerie, bien au sec, une page du journal, calée sous un coquillage."},
				{"letter": ["Les premiers habitants",
					"J'ai passé la nuit devant les fresques du temple, une bougie à la main. Bien avant nous, des gens vivaient ici. Ils n'avaient jamais vu un dino vivant : ils avaient les os que l'île recrache, l'ambre qui luit, et la lune.",
					"Ils ont taillé leurs masques dans les os des géants, pour leur ressembler, et pour leur promettre qu'on veillerait sur leur sommeil.",
					"Anselme voulait en emporter un au Cabinet. J'ai dit non. Ce ne sont pas des souvenirs : ce sont des promesses."],
					"sign": "— H."},
				{"flag": &"found_journal_12"},
				{"who": CHLOE, "text": "(Des promesses… Et l'Ombre Noire en a fait des masques pour faire peur.)" if Game.flag(&"fresques_vues")
					else "(Des masques pour veiller, pas pour faire peur… Les fresques du temple doivent raconter ça.)"},
			]
		&"page_13":
			var p13: Array = [
				{"text": "Entre les racines que Dame Suie cueillait, roulée dans une feuille de nénuphar séchée, une page du journal." if Game.flag(&"dame_suie_battue")
					else "Entre les racines tordues de l'îlot, roulée dans une feuille de nénuphar séchée, une page du journal."},
				{"letter": ["Le premier Cœur",
					"Le Spinosaure m'a regardée longtemps, du fond de son bassin. Puis il a ouvert la gueule, très doucement, et j'y ai posé le premier Cœur. Il l'a porté jusqu'à l'autel sans l'érafler.",
					"Je lui ai demandé de le garder jusqu'à ce que quelqu'un vienne, avec mes yeux et ma confiance. Il a soufflé par les naseaux. Je crois que c'était oui.",
					"(Mes mains me font encore mal. Je n'écris pas pourquoi.)"],
					"sign": "— H."},
				{"flag": &"found_journal_13"},
			]
			if Game.flag(&"coeur_1"):
				p13.append({"who": CHLOE, "text": "(Le Cœur qu'il m'a donné… Il l'a gardé pour moi pendant vingt-cinq ans.)"})
			elif Game.flag(&"temple_ouvert"):
				p13.append({"who": CHLOE, "text": "(Le premier Cœur est dans le temple englouti. Avec le Spinosaure.)"})
			else:
				p13.append({"who": CHLOE, "text": "(Un Spinosaure, un bassin, un autel… Le temple englouti ?)"})
			if Game.flag(&"masque_vu"):
				p13.append({"who": CHLOE, "text": "(« Avec mes yeux »… Le Masque disait que j'ai les yeux de ma grand-mère.)"})
			return p13
		&"page_14":
			var p14: Array = [
				{"text": "Dans le creux d'un arbre noyé, au-dessus de l'eau, une boîte en fer bien fermée. Dedans, une page du journal, toute sèche."},
				{"letter": ["Les notes volées",
					"Mes carnets sur l'ambre forcé ont disparu. Ceux que je n'avais pas brûlés, rangés sous clé dans le tiroir du bas.",
					"Pas de vitre cassée, pas de serrure forcée. Trois personnes ont la clé du Cabinet : moi, Anselme… et I.",
					"J'ai tourné ça dans ma tête toute la nuit, et je n'aime aucune des réponses. Je n'en parlerai à personne. Pas avant d'être sûre."],
					"sign": "— H."},
				{"flag": &"found_journal_14"},
				{"who": CHLOE, "text": "(Volés… sans effraction. Comme le petit, la nuit où je suis arrivée.)"},
			]
			if Game.flag(&"found_journal_11") or Game.flag(&"found_journal_3"):
				p14.append({"who": CHLOE, "text": "(« I. »… L'amie de la barque. Celle qui voulait vendre l'ambre.)"})
			p14.append_array([
				{"who": CHLOE, "text": "(Et Anselme, c'est Roc. Roc avait la clé. Roc sort la nuit." + (" Roc cache de l'ambre noir dans son tiroir.)" if Game.flag(&"ambre_noir_tiroir") else ")")},
				{"who": CHLOE, "text": "(Non. Je ne vais pas deviner. Je vais lui demander. En face.)"},
			])
			return p14
		&"page_15":
			var p15: Array = [
				{"text": "Coincée dans les racines d'un arbre noyé, au milieu du chenal, une bouteille bouchée à la cire. Dedans, roulée bien serrée, une page du journal."},
				{"letter": ["Le souffle du volcan",
					"Le volcan a grondé trois fois ce mois-ci. Avant, c'était une fois par an.",
					"Les Koolasuchus ne remontent plus des profondeurs, et les Baryonyx pêchent en silence. Le sceau s'use, comme une corde qu'on tire un peu plus chaque jour.",
					"Je vais vérifier les Cœurs, un par un. Et apprendre à Anselme le chemin des sanctuaires. Au cas où."],
					"sign": "— H."},
				{"flag": &"found_journal_15"},
				{"who": CHLOE, "text": "(« Au cas où »… Roc connaît le chemin des sanctuaires ?)"},
			]
			if Game.flag(&"coeur_1"):
				p15.append({"who": CHLOE, "text": "(Dans le temple, quand le volcan a grondé, le Cœur a battu plus vite…)"})
			return p15
		&"page_16":
			return [
				{"text": "Au milieu du bassin, sur le plus grand des nénuphars, une page du journal brille comme une petite lune."},
				{"letter": ["Ambrelune",
					"Pourquoi l'ambre luit-il à la pleine lune ? Les pêcheurs disent que l'île se souvient. J'ai mesuré, calculé, veillé douze nuits.",
					"Ma réponse de savante : je ne sais pas.",
					"Ma réponse de grand-mère (je n'en suis pas encore une, mais je m'entraîne) : l'Ambre-Mère a été une forêt, un jour, sous une autre lune. Elle la reconnaît, et elle lui fait signe."],
					"sign": "— H."},
				{"flag": &"found_journal_16"},
				{"who": CHLOE, "text": "(« Je m'entraîne »… Elle s'entraînait déjà pour moi.)"},
			]
	# (chapter 6 first: its « monts_bloques » — the warm coat — replaces the Côte's once chapter 5 is over)
	var monts: Array = DialogueMonts.lines(id)   # chapter 6 (data/dialogue_monts.gd)
	if not monts.is_empty():
		return monts
	var desert: Array = DialogueDesert.lines(id)   # chapter 4 (data/dialogue_desert.gd)
	if not desert.is_empty():
		return desert
	var cote: Array = DialogueCote.lines(id)   # chapter 5 (data/dialogue_cote.gd)
	if not cote.is_empty():
		return cote
	push_error("Dialogue inconnu : %s" % id)
	return []


## The cracked wall hiding the camp (Obstacle, Coup de crâne): what is behind, and who could
## break it (a Pachycephalosaurus of the rocky clearings). Shorter once seen.
static func cracked_wall() -> Array:
	var steps: Array = []
	if not Game.flag(&"mur_vu"):
		steps.append({"text": "Une paroi de roche barre le chemin. Mais elle est fendue de haut en bas, et par la fissure passe un filet d'air froid… qui sent la cendre."})
		if Game.flag(&"clairiere_vue"):
			steps.append({"text": "Les sillons de la clairière s'arrêtent ici, net, au pied de la roche. Ce qu'on a traîné est passé de l'autre côté."})
		steps.append({"text": "L'oreille contre la pierre, Chloé entend des coups de marteau, des voix… et, très loin, un raptor qui gronde."})
		steps.append({"flag": &"mur_vu"})
	else:
		steps.append({"text": "La paroi fendue. Derrière, les coups de marteau continuent."})
	for d: Dino in Game.box:
		if Abilities.has(d, &"coup_crane"):
			steps.append({"text": "La roche sonne creux. Ton %s saurait quoi en faire… mais il attend au Cabinet. Fais-le venir depuis ton Dinodex, ou demande au Pr Roc." % d.nickname})
			return steps
	steps.append({"text": "La roche sonne creux : un bon coup de tête bien placé, et elle céderait. Les Pachycephalosaurus des clairières rocheuses, au nord-est, passent leurs journées à se cogner le crâne. Pour eux, un mur, c'est un bonjour."})
	return steps


## The bridge to the Marais over the marshy pond, its last span's ropes cut (a closed ZoneExit):
## Maïa ties it back up after her second challenge.
static func marais_bridge() -> Array:
	if Game.flag(&"maia_defi_2"):
		return [{"text": "Le pont tient bon, grâce aux nœuds de Maïa. De l'autre côté, la brume du Marais avale les roseaux…"}]
	if Game.flag(&"sceau_foret"):
		return [{"text": "Au bout des planches, la dernière travée du pont pend toujours dans l'eau."},
			{"who": MAIA, "text": "Hé ! Pas si vite ! Ce pont, c'est moi qui le répare. Et avant, tu me dois un défi !"}]
	var steps: Array = [{"text": "Un vieux pont de planches file vers l'ouest, au-dessus de l'étang, vers la brume du Marais. Mais au bout, la dernière travée pend dans l'eau : ses cordes ont été tranchées net."}]
	if Game.flag(&"clairiere_vue"):
		steps.append({"text": "Tranchées d'un seul coup de lame, comme les cordes de la clairière…"})
	steps.append_array([
		{"who": CHLOE, "text": "(Quelqu'un ne veut pas qu'on aille au Marais. Ou qu'on en revienne.)"},
		{"text": "Impossible de passer. Et pour l'instant, la meute a besoin de Chloé."},
	])
	return steps


## The road north to the Désert (a closed ZoneExit until Maïa's third challenge).
static func desert_road() -> Array:
	var steps: Array = [{"text": "Au bout de la roselière, la vase sèche et craque. Au loin, une terre jaune et plate : le Désert."}]
	if Game.flag(&"sceau_marais"):
		steps.append({"who": MAIA, "text": "Hé ! Pas si vite, championne ! La route du Désert, ça se mérite. Et tu me dois un défi !"})
	else:
		steps.append({"text": "Mais le Marais n'a pas fini de parler : quelque part dans la brume, le temple englouti garde encore son secret."})
	return steps


## The sunken temple's great door, closed until the Voix du Marais sings to it.
static func temple_door() -> Array:
	var steps: Array = [
		{"text": "Une grande porte de pierre, couverte de mousse et de coquillages, fermée comme une bouche qui se tait. Au-dessus, une tête de Spinosaure sculptée."},
		{"text": "La pierre est percée de trous ronds, comme une flûte. Quand le vent passe, la porte chante une seule note, très grave."},
	]
	if Game.flag(&"porte_voix_ouverte"):
		steps.append({"who": CHLOE, "text": "(Une note grave… comme le chant de la Voix, sur son îlot.)"})
	else:
		steps.append({"who": CHLOE, "text": "(Il faudrait lui répondre avec une voix bien plus grande que la mienne. Celle qui chante au cœur de la roselière, peut-être ?)"})
	return steps


## The temple's flood water (Flood, blocked_dialogue): which sluice to turn next.
static func temple_flood() -> Array:
	if not Game.flag(&"temple_vanne_1"):
		return [{"text": "L'eau monte jusqu'au plafond. Impossible de passer, même à la nage."},
			{"text": "Dans le hall, une grande roue de pierre sort du mur, avec des traits gravés qui mènent jusqu'ici. Une vanne ?"}]
	if not Game.flag(&"temple_vanne_2"):
		return [{"text": "Ici, l'eau monte toujours jusqu'au plafond."},
			{"text": "Au bout de la galerie ouest, maintenant à sec, une deuxième roue attend. Son trait gravé file jusqu'ici."}]
	if not Game.flag(&"temple_vanne_3"):
		return [{"text": "L'escalier de la grande salle est encore sous l'eau. Tout au fond, quelque chose respire."},
			{"text": "Au bout de la galerie est, la dernière roue attend."}]
	return [{"text": "L'eau baisse encore, en gargouillant."}]


## What people say when there is nothing special to say: a line from their pool, the next one
## each time (flag "bavard_<who>"), the pool depending on the time, the weather, the story.
## Maïa and Roc also slip in the main objective as a hint (Objectives.main_hint).
static func chatter(who: StringName) -> Array:
	var pool := []
	var night := Game.phase() == &"night"
	var hint := Objectives.main_hint()
	match who:
		&"isaure":
			pool = [
				"La pêche est maigre, ces temps-ci… Mais toi, va ! L'île t'attend. Et garde un œil sur ma fille, d'accord ?",
				"Hélène ? On a été amies, oui. Il y a longtemps. Les gens changent… ou ils restent pareils trop longtemps. Ça revient au même.",
				"Tu vois cette jetée ? Quand j'avais ton âge, on ne voyait pas le bois, tellement il y avait de barques.",
				"Maïa t'attend aux Plaines, je parie. Elle ne tient pas en place. Comme moi, à son âge.",
			]
			if Game.flag(&"sceau_plaines"):
				pool.insert(0, "Le Havre ? Là-bas, ils ont de l'argent. Et ils ne se demandent jamais d'où il vient. Toi, demande-toi toujours.")
			if Game.flag(&"selle") and not Game.flag(&"griffe_grise_vu"):
				pool.insert(0, "La Forêt… Hélène y avait un vieux raptor, gris comme un rocher. Il ne laissait approcher personne. Sauf elle.")
			if Game.flag(&"griffe_grise_vu"):
				pool.insert(0, "Il t'a laissée approcher ? … Moi, il m'a toujours montré les dents. Il avait peut-être ses raisons.")
			var little: Dino = ForetCamp.recovered()
			if little:
				pool.insert(0, "On raconte sur le port que tu as retrouvé %s, le petit volé au Cabinet. … Il a l'air bien, avec toi. C'est… c'est bien. Vraiment." % little.nickname)
			if Game.flag(&"sceau_foret"):
				pool.insert(0, "Une fougère gravée sur ton Sceau ? Hélène en mettait partout. Sur ses portes, sur ses caisses, sur les boussoles qu'elle offrait… Bref. Va, moussaillon.")
			if Game.flag(&"masque_vu"):
				pool.insert(0, "Un masque noir, sur une passerelle ? Les gens du port racontent n'importe quoi. Ne crois pas tout ce qu'on te dit, moussaillon. Même moi.")
			if Game.flag(&"found_journal_11"):
				pool.append("Tu lis toutes les pages d'Hélène, on dirait. Elle écrivait bien. Elle avait toujours le dernier mot, même sur le papier.")
			if Game.flag(&"marais_arrivee"):
				pool.insert(0, "Le Marais ? Hélène y chantait avec sa vieille Parasaurolophus. Faux, toutes les deux. Ça s'entendait jusqu'au port, les soirs de brume.")
			if Game.flag(&"found_journal_14"):
				pool.insert(0, "Il paraît que tu poses des questions sur les clés du Cabinet ? Roc a toujours été distrait avec les siennes. Toujours.")
			if Game.flag(&"dame_suie_battue"):
				pool.append("Une dame en gris, dans le Marais ? Je ne connais personne de ce genre. … Personne.")
			if Game.flag(&"coeur_1"):
				pool.insert(0, "Un Cœur d'ambre ? … Garde-le bien, moussaillon. Il y a des gens qui traverseraient la mer pour ça.")
			if Game.flag(&"boussole_rendue"):
				pool.append("Maïa m'a rapporté ma boussole. Merci de l'avoir rattrapée. J'y tiens… plus que je ne devrais.")
			if night:
				pool.append("Tu devrais dormir, moussaillon. La nuit, sur cette île, il se passe des choses qu'on ne voit pas de jour.")
			if Game.is_full_moon():
				pool.append("Pleine lune… L'ambre brille dans les falaises. Hélène adorait ces nuits-là. Moi aussi, avant.")
			if Game.is_raining():
				pool.append("Rentre donc t'abriter. La pluie d'Ambrelune ne mouille pas moins que celle du continent.")
		&"maia":
			pool = [
				"Caillou a encore mangé mes lacets. Il croit que ce sont des vers de terre. Il n'a jamais vu de vers de terre.",
				"Un jour, je ferai le tour de l'île en une journée. Maman dit que c'est impossible. Maman dit ça de tout.",
				"Tu sais pourquoi on les appelle les Plaines des Fougères ? Moi non plus. Il y a plus de dinos que de fougères.",
			]
			if hint != "":
				pool.insert(1, "Un conseil de championne ? " + hint)
			if not Game.flag(&"sceau_plaines"):
				pool.append("Le Grand Crâne, au sud-est : c'est là que je vais t'écraser. Prépare-toi.")
			else:
				pool.append("Tu as eu le sceau ?! … Bon. Bravo. Mais la prochaine fois, c'est moi. Et ça fait mal de le dire.")
			if night:
				pool.append("Il fait nuit ! Les Velociraptor sortent aux lisières. Moi, je rentre avant que maman s'inquiète… enfin, avant qu'elle rentre.")
		&"maia_havre":
			pool = [
				"Le Relais, c'est simple : tu bats Gaspard, tu bats Lilou, et après… tu me bats moi. Enfin, tu essaies.",
				"Joss a fait ma selle quand on avait dix ans. Pour Caillou. Caillou l'a mangée.",
				"Maman passe au Comptoir le soir, des fois. Elle dit que c'est « pour le port ». Elle dit toujours ça.",
			]
			if hint != "":
				pool.insert(0, "Conseil de championne : " + hint)
			if Game.flag(&"selle") and not Game.flag(&"griffe_grise_vu"):
				pool.append("Tu pars pour la Forêt ? Il paraît que les raptors y crient toute la nuit, en ce moment. Comme s'ils avaient perdu quelqu'un.")
			if Game.flag(&"griffe_grise_vu"):
				pool.append("Un vieux raptor t'a laissée approcher ?! Moi, la dernière fois, un Dilophosaurus m'a craché dessus. On n'a pas la même Forêt.")
			if Game.flag(&"clairiere_vue") and not Game.flag(&"masque_vu"):
				pool.append("Un masque d'os dans la Forêt ? Je parie que c'est leur chef, le Masque. Il paraît que le sien est tout noir. Trop stylé. … Enfin, trop méchant. Mais stylé.")
			if Game.flag(&"camp_arrive") and not Game.flag(&"brac_battu"):
				pool.insert(0, "Un camp de l'Ombre Noire ?! Dans la Forêt ?! Et tu y vas SANS MOI ? … Bon, vas-y. Mais tu me raconteras tout. TOUT.")
			if Game.flag(&"oeuf_vole_apaise"):
				var hers: String = Prologue.MAIA_NAMES.get(StringName(str(Game.flag(&"maia_starter"))), "Caillou")
				pool.append("Tu as retrouvé le troisième petit ?! %s va être tellement content ! Ils ont dormi côte à côte, le premier jour. Enfin, il ne le montrera pas. Il est fier." % hers)
			if Game.flag(&"sceau_foret") and not Game.flag(&"maia_defi_2"):
				pool.insert(0, "Deux Sceaux, hein ? Viens me voir au pont du Marais, au nord-ouest de la Forêt. J'ai un défi tout neuf. Il pique.")
			if Game.flag(&"masque_vu"):
				pool.append("Je me suis fait un masque noir, avec du carton et du cirage. Maman est devenue toute pâle et m'a dit de l'enlever. Tout de suite. … Elle n'a aucun sens du style.")
			if Game.flag(&"maia_defi_2") and not Game.flag(&"maia_defi_3"):
				pool.append("Deux défaites. DEUX. Je m'entraîne jour et nuit, maintenant. Enfin, surtout le jour. La nuit, je dors.")
			if Game.flag(&"marais_arrivee") and not Game.flag(&"maia_defi_3"):
				pool.append("Le Marais, c'est plein de vase. J'y ai perdu une chaussure. Caillou l'a retrouvée. Il l'a mangée.")
			if Game.flag(&"gilet_nage"):
				pool.append("Joss t'a donné MON gilet ? … Bon, garde-le. Les gilets, c'est pour les poules mouillées. Enfin… il est joli quand même.")
			if Game.flag(&"maia_defi_3"):
				pool.append("Trois défaites. TROIS. Au Désert, ce sera différent : Caillou mange des cailloux depuis une semaine. C'est sa préparation.")
		&"roc":
			pool = [
				"Hélène disait qu'un dino ne se dresse pas : il se rencontre. Je n'ai jamais bien compris la différence. Elle, si.",
				"Trente ans que je vis ici, et les Parasaurolophus me font encore sursauter quand ils chantent.",
			]
			if not Game.flag(&"ambre_noir_tiroir"):
				pool.append("Ne touche pas au tiroir de gauche. Il est… cassé. Voilà. Cassé.")
			else:
				pool.insert(0, "Le tiroir ? Quel tiroir ? … Tiens, mange donc une baie.")
				pool.append("Je sais ce que tu penses. Tu te trompes. … Enfin, j'espère que tu te trompes.")
			if Game.flag(&"camp_arrive") and not Game.flag(&"brac_battu"):
				pool.insert(0, "Un camp de braconniers, dans la Forêt ? … Prends des baies. Beaucoup de baies. Et reviens entière, tu m'entends ?")
			if Game.flag(&"brac_battu"):
				pool.append("Un braconnier, dans la Forêt d'Hélène… Elle en a chassé trois de cette île, autrefois. À coups de parapluie. Le parapluie n'y a pas survécu.")
			if Game.party.any(func(d: Dino) -> bool: return d.species().id == &"dilophosaurus"):
				pool.append("Ton Dilophosaurus a ouvert sa collerette sur mon bureau. Toutes mes notes se sont envolées. Il paraît que les vrais n'en avaient pas. Ça ne me console pas du tout.")
			var little: Dino = ForetCamp.recovered()
			if little and Game.flag(&"roc_oeuf_retrouve"):
				pool.append("Chaque fois %s passe au Cabinet, il file droit se coucher contre la couveuse. Moi, je ne dis rien. Je pose une couverture." % French.que(little.nickname))
			if Game.flag(&"masque_vu"):
				pool.append("Un masque qui parle d'Hélène comme s'il la connaissait… Beaucoup de gens l'ont connue, Chloé. Beaucoup trop.")
			if hint != "":
				pool.insert(0, "Où en es-tu ? … Hmm. " + hint)
			if Game.flag(&"selle") and not Game.flag(&"griffe_grise_vu"):
				pool.insert(0, "La Forêt ? Hélène y passait des semaines. Elle en revenait trempée, pleine de mousse, et heureuse comme une gamine. Méfie-toi des Deinonychus : ils chassent à plusieurs.")
			if Game.flag(&"griffe_grise_vu"):
				pool.insert(0, "Griffe-Grise ? Ce vieux grincheux est encore en vie ? Il m'a mordu trois fois. Enfin, deux. La troisième, je l'avais un peu cherchée.")
			if Game.flag(&"clairiere_vue"):
				pool.append("Des pièges, des pieux, un masque d'os… dans la Forêt d'Hélène. … Sois prudente, Chloé. Vraiment prudente.")
			if Game.flag(&"marais_arrivee") and not Game.flag(&"gilet_nage"):
				pool.insert(0, "Le Marais ? Hélène y allait avec un vieux gilet de liège. Elle ressemblait à un bouchon. Un bouchon très heureux.")
			if Game.flag(&"voix_rencontree"):
				pool.append("La Voix t'a chanté quelque chose ? Elle ne chantait que pour Hélène… et pour la lune.")
			if Game.flag(&"dame_suie_battue"):
				pool.append("Une chimiste qui « améliore » les dinos… Hélène a passé sa vie à prouver qu'on ne les améliore pas. On les écoute.")
			if Game.flag(&"coeur_1"):
				pool.append("Garde ce Cœur contre toi. Toujours. Même quand tu dors. Surtout quand tu dors.")
			if Game.flag(&"roc_marais_vu"):
				pool.insert(0, "À propos de l'autre soir… Non. Rien. Tu veux une baie ? Prends une baie.")
				pool.append("Je sais ce que tu penses. À ta place, je me poserais des questions aussi. … Pose-les-toi. Mais pas trop fort.")
			if night and Game.flag(&"roc_marais_vu"):
				pool.append("Tu es encore debout ? … Non, moi, je ne sors pas ce soir. Enfin, pas tout de suite.")
			elif night:
				pool.append("Tu es encore debout ? Moi aussi. Je… vérifie des choses. Va dormir, va.")
		&"joss":
			pool = [
				"Si tu vois un gilet flotter tout seul dans le Marais, c'est qu'il y a un Baryonyx dessous. Ou pas. Mais souvent si.",
				"J'ai cousu un gilet pour Caillou, une fois. Il l'a mangé. Maïa dit que c'est un compliment.",
				"Le soir, la Voix chante, et toutes mes aiguilles vibrent dans leur boîte. Je couds de travers, mais c'est joli.",
			]
			if hint != "":
				pool.insert(1, "Si j'ai bien compris, toi, tu cherches ça : " + hint)
			if night:
				pool.append("La nuit, je vois parfois une lanterne sur les pontons. Un pêcheur, sûrement. Un pêcheur très maladroit : j'entends souvent « plouf ».")
			if Game.flag(&"dame_suie_battue"):
				pool.append("La dame en gris est repartie en barque ? Tant mieux. Elle regardait mes flotteurs comme si c'étaient des cobayes.")
			if Game.flag(&"coeur_1"):
				pool.insert(0, "Tu as vu la lumière dorée, au-dessus du temple ? Toute la roselière s'est tournée vers elle. Même les grenouilles.")
			if Game.is_raining():
				pool.append("La pluie ? Parfait pour tester l'étanchéité. Enfin, moi, je ne suis pas étanche.")
	pool = DialogueDesert.chatter(who, pool)   # chapter 4 (data/dialogue_desert.gd)
	pool = DialogueCote.chatter(who, pool)   # chapter 5 (data/dialogue_cote.gd)
	pool = DialogueMonts.chatter(who, pool)   # chapter 6 (data/dialogue_monts.gd)
	if pool.is_empty():
		return []
	var n := int(Game.flag(StringName("bavard_%s" % who)))
	Game.set_flag(StringName("bavard_%s" % who), n + 1)
	var speaker: String = {&"isaure": "Isaure", &"maia": MAIA, &"roc": "Prof. Roc", &"maia_havre": MAIA, &"joss": "Joss"}[who]
	return [{"who": speaker, "text": pool[n % pool.size()]}]


## Page 6, written a year ago for Chloé: why the hatchling she chose suits her (Hélène knew
## which one she would choose). Three versions, by the starter.
static func page_6_text() -> Array:
	var why: String = {
		"velociraptor": "Je t'ai laissé trois œufs, mais je crois savoir lequel tu choisiras : le plus vif. Petite, tu courais toujours devant, sans regarder derrière toi. Un raptor ne suit personne : il choisit qui suivre. S'il t'a choisie, c'est pour toujours. Son père, Griffe-Grise, veille encore dans la Forêt.",
		"ankylosaurus": "Je t'ai laissé trois œufs, mais je crois savoir lequel tu choisiras : le plus calme. Tu es de celles qui tiennent bon quand tout tremble autour. Un Ankylosaurus ne recule jamais : il protège. Sa mère, le Vieux Rempart, garde un canyon du Désert.",
		"parasaurolophus": "Je t'ai laissé trois œufs, mais je crois savoir lequel tu choisiras : celui qui chante. Petite, tu parlais aux mouettes, et elles te répondaient. Sa crête répond à l'ambre comme ton cœur répond aux gens. Sa mère, la Voix du Marais, chante encore dans les roseaux.",
	}.get(str(Game.flag(&"starter")), "Je t'ai laissé trois œufs. Celui que tu as choisi t'a choisie aussi : c'est toujours comme ça que ça marche.")
	return [why,
		"Je n'ai pas eu le temps de tout t'apprendre. Alors l'île le fera, page après page. Ne fais confiance qu'à ceux qui ne veulent rien de l'ambre.",
		"Un jour, je te montrerai tout. Promis."]


## Maïa, about the trunk: Chloé's own dino, or where to find one with claws.
static func claws_text() -> String:
	var vif: Dino = Foret.vif_dino()
	if vif and Game.party.has(vif):
		return "Ton Velociraptor a l'air d'en avoir, des griffes. Et méfie-toi des hautes herbes : les dinos sauvages adorent s'y cacher !"
	if vif:   # (Vif waits at the Cabinet)
		return "Ton Velociraptor en a, des griffes… mais il attend au Cabinet. Fais-le venir depuis ton Dinodex. Et méfie-toi des hautes herbes : les dinos sauvages adorent s'y cacher !"
	return "Il te faudrait un raptor : les Velociraptor sauvages rôdent aux lisières, au crépuscule. Et méfie-toi des hautes herbes : les dinos adorent s'y cacher !"


## When the next full moon is (the pond's sign).
static func moon_text() -> String:
	if Game.is_full_moon():
		return "Ce soir, justement, la lune est pleine. Écoute…"
	var n := Game.nights_to_full_moon()
	return "Prochaine pleine lune : cette nuit." if n == 0 else "Prochaine pleine lune : dans %d nuit%s." % [n, "s" if n > 1 else ""]


## How many of the three amber scales Chloé has, said after finding one.
static func ecailles_text() -> String:
	var n := ecailles()
	if n >= 3:
		return "Chloé a les trois écailles d'ambre ! Le Grand Crâne, au sud-est des Plaines, attend."
	return "Écailles d'ambre : %d sur 3." % n


static func ecailles() -> int:
	var n := 0
	for f: StringName in [&"ecaille_bosquet", &"ecaille_grotte", &"ecaille_falaises"]:
		if Game.flag(f):
			n += 1
	return n
