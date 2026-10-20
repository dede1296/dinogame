class_name DialogueBrac
## Brac on the jetty of Port-Ambre (docs/post-game-scenes.md § B, post-game-plan.md § 5): his words,
## word for word from the scenes, with what did not make sense put right (said in the report of the
## lot E, 20/10). Same steps as DialogueDB ({"who", "text"}, {"flag"}); a step may carry a "cue" (the
## name of a move story/brac_jetee.gd plays when it shows: it takes the key away before the dialogue
## box sees it). B1 « Le phare qui boude » (from brac_parti, before the epilogue, once), then a line
## per visit; B2 « Le partage » (after the epilogue, by day, once); B3 the beasts and the sign. His
## night watchman's lines after the end are DialogueApex.BRAC_JETEE (brac_jetee_n), unchanged.
## Flags: brac_jetee_vu, brac_jetee_avant_n (lines), brac_sandwich_partage.

const BRAC := "Brac"
const CHLOE := "Chloé"


# ------------------------------------------------------------------ B1, le phare qui boude

## B1 (10 lines): the sandwich lifted, the three heads that turn, « le même depuis les forges »;
## his three, with their real species (Mastoc the Allosaurus, Cabosse the Stygimoloch, Grognon the
## Majungasaurus); « Personne ne demande jamais rien à Brac. » `heard_from_roc`: Chloé has heard Roc
## say « il a mangé un sandwich » (roc_brac_parti); else she only sees one on the cage.
static func phare(heard_from_roc: bool) -> Array:
	var asks := "Roc a dit que vous aviez mangé un sandwich." if heard_from_roc else "Vous ne le mangez pas, votre sandwich ?"
	var lifts := "Roc tient ça de Léonce. Et Léonce me voit de dos : il a cru que je mangeais. … J'ai levé le sandwich. Ils ont regardé. J'ai reposé le sandwich." \
		if heard_from_roc else "J'ai essayé. … J'ai levé le sandwich. Ils ont regardé. J'ai reposé le sandwich."
	return [
		{"who": BRAC, "text": "Moucheron. Tu viens voir la mer aussi ? Elle est grande. On me l'avait dit. Je ne pensais pas à ce point.", "cue": "tourne"},
		{"who": CHLOE, "text": asks},
		{"who": BRAC, "text": lifts, "cue": "leve"},
		{"who": BRAC, "text": "C'est le même depuis les forges. Il est un peu dur. Je m'y suis attaché."},
		{"who": CHLOE, "text": "(Il ne mange pas parce qu'ils le regardent, lui. Il croit que c'est le sandwich qu'ils regardent.)", "cue": "regardent"},
		{"who": BRAC, "text": "Tu veux les connaître ? Ils ne mordent plus. Enfin, Grognon, si, mais il mord tout : c'est pas contre toi."},
		{"who": BRAC, "text": "Mastoc. Un Allosaure. Je l'ai depuis la Forêt : il était petit. Huit mètres, maintenant, et il a peur du noir.", "cue": "mastoc"},
		{"who": BRAC, "text": "Cabosse, le Stygimoloch. Une tête en dôme, avec des cornes et des bosses tout autour, et il fonce avec. … Non. Pas maintenant.", "cue": "cabosse"},
		{"who": BRAC, "text": "Grognon, le Majungasaurus. Une petite corne sur le front, et pas un ami au monde. À part moi.", "cue": "grognon"},
		{"who": BRAC, "text": "Et moi, je regarde la mer. De loin. … Et j'attends que quelqu'un me demande quelque chose. Personne ne demande jamais rien à Brac. Ça viendra peut-être.", "cue": "mer"},
		{"flag": &"brac_jetee_vu"},
	]


## Afterwards, before the epilogue: a line per visit (brac_jetee_avant_n).
const AVANT := [
	"Elle est toujours grande. Je vérifie tous les matins.",
	"Léonce m'a prêté une ligne. Je ne sais pas pêcher. Un Ptéranodon avec du sel sur le bec, lui, il sait. Il m'a regardé comme on regarde un sandwich.",
	"Quand tu auras fini là-bas, moucheron… reviens me dire. Je ne demande rien. Je dis juste : reviens me dire.",
]


## The lines he may say now: once the crater is over (apex_fini), « Quand tu auras fini là-bas » is
## said no more (she has finished; the jetty's « ET MOI ? » comes the next morning).
static func avant_pool(crater_over: bool) -> Array:
	return AVANT.slice(0, 2) if crater_over else AVANT.duplicate()


# ------------------------------------------------------------------ B2, le partage

## B2 (6 lines), after the epilogue, by day: Brac asleep on his cage, the sandwich on his knee;
## Hélène's words of yesterday; « Ils me regardent. Pas le sandwich. Moi. »; cut in four with his
## rope knife; « le meilleur sandwich du monde ».
static func partage() -> Array:
	return [
		{"who": BRAC, "text": "Moucheron. … Tu sais ce que madame Varenne m'a dit, hier ? « On ne garde pas un sandwich. On le partage, ou on le mange. » Elle a dit ça comme si c'était grave.", "cue": "reveil"},
		{"who": CHLOE, "text": "C'est peut-être grave."},
		{"who": BRAC, "text": "… Ils me regardent. Pas le sandwich. Moi.", "cue": "regarde"},
		{"text": "Il coupe le sandwich en quatre avec son couteau à cordes. Trois parts pour trois gueules, une pour lui. Dix secondes plus tard, il n'y a plus de sandwich.", "cue": "partage"},
		{"who": BRAC, "text": "Il était dur. C'était le meilleur sandwich du monde. Ne le dis à personne.", "cue": "content"},
		{"who": CHLOE, "text": "(Il a fallu une Réserve, ma grand-mère et un panneau mal écrit pour qu'il mange un sandwich. … Ça valait le coup.)"},
		{"flag": &"brac_sandwich_partage"},
	]


# ------------------------------------------------------------------ B3, les bêtes et la nuit

## A line each when Chloé looks at them after the epilogue (events of their nodes); Mastoc by day
## (asleep: the only time a dino lies down) or by night (up, by the lit lantern: he watches it).
const MASTOC_JOUR := "Mastoc dort au pied de la lanterne. Un Allosaure de huit mètres qui a peur du noir : il ne s'en éloigne jamais, même le jour, au cas où."
const MASTOC_NUIT := "Mastoc se tient tout contre la lanterne allumée. Il ne dort pas : il la surveille. Un Allosaure de huit mètres qui a peur du noir."
const CABOSSE := "Cabosse regarde la mer en penchant la tête. Il a essayé de foncer dedans, une fois. Il recommencera."
const GROGNON := "Grognon grogne. C'est son nom, et c'est son travail. Il grogne un peu moins quand Brac est réveillé."
## The sign planted on the jetty (prop « PanneauBarc », from epilogue_fini).
const PANNEAU := "Un panneau planté dans la jetée, écrit à la main : « Gardien : BARC ». Dessous, au charbon, quelqu'un a ajouté un « R » à la bonne place… puis l'a effacé. C'est Roc qui l'a écrit : Brac ne veut pas qu'on y touche."


## The line of a beast of Brac's (its node's event), "" for another event.
static func bete(event: StringName, night: bool) -> String:
	match event:
		&"mastoc_jetee":
			return MASTOC_NUIT if night else MASTOC_JOUR
		&"cabosse_jetee":
			return CABOSSE
		&"grognon_jetee":
			return GROGNON
	return ""
