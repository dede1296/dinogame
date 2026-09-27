class_name Foret
## Chapter 2, the Forêt Jurassique, step 1 (docs/histoire.md, ch. 2): arriving under the giant
## ferns while the raptors call each other and no one answers (the pack has lost its leader);
## Griffe-Grise, Hélène's old Velociraptor, in his hidden ravine: Vif's father when Chloé chose
## Vif (a reunion, and the Ancien's page), otherwise a wary old friend of Hélène's who ends up
## trusting her and shows a clue (a poacher's trap, torn open, smelling of ash); both times he
## looks towards the clearing of the giant ferns. That clearing is empty: a ring of stakes, cut
## ropes, ash, a piece of bone mask, drag marks going west (step 2: Brac, the camp, the Alpha).
## Flags: foret_arrivee, griffe_grise_vu, found_journal_ancien, clairiere_vue; griffe_grise_n,
## clairiere_n (visits since, for the next line), griffe_apres_clairiere.
## (Pages 7 to 10 are Pickups placed by the zone: DialogueDB page_7 … page_10.)

const S := preload("res://story/story.gd")
const CHLOE := "Chloé"
const RAPTOR_CRY := "res://assets/audio/cries/raptor-%s.mp3"
const LATCH := preload("res://assets/audio/sfx/latch.wav")
const LEAVES := preload("res://assets/audio/sfx/feuillage.mp3")
## Griffe-Grise's voice: a raptor's cry, but old and deep.
const OLD_PITCH := 0.72
const XP_GRIFFE := 50
const XP_ANCIEN := 30   # the Ancien's page, on top (Vif's father)
const XP_CLAIRIERE := 40
## The first lines under the trees: it rains, or the ferns are still dripping.
const RAIN_NOW := "La pluie crépite sur les fougères géantes. Sous les arbres, elle tombe en retard : chaque feuille la garde un moment, puis la laisse filer, goutte à goutte."
const RAIN_AFTER := "Une averse vient de passer. Sous les arbres géants, il pleut encore : chaque fougère égoutte l'averse, goutte à goutte, bien après les nuages."
## The Ancien's page, left in Griffe-Grise's ravine a year ago (only with Vif).
const ANCIEN_PAGE := [
	"Griffe-Grise",
	"Mon deuxième réveil : un Velociraptor pas plus gros qu'un chat, qui m'a mordu le pouce puis s'est endormi dessus. Une griffe grise comme un galet : son nom s'est trouvé tout seul.",
	"Chez les raptors, c'est souvent le père qui couve. Il a veillé cet œuf un mois sans fermer l'œil, puis il l'a poussé vers moi du bout du museau. Il savait pour qui.",
	"S'il t'a laissée approcher, gratte-le sous le menton. Il fait semblant de détester ça.",
]
## Griffe-Grise once he knows Chloé: with Vif at her side ("%s" = Vif's name), or not.
const AGAIN_VIF := [
	"Griffe-Grise ouvre un œil, voit %s, et le referme. Tout va bien.",
	"%s et Griffe-Grise se reniflent longuement. Chloé a un peu l'impression de déranger.",
	"Griffe-Grise bondit sur son rocher, sans élan. %s essaie de faire pareil et atterrit à côté. Son père fait semblant de n'avoir rien vu.",
	"Chloé gratte Griffe-Grise sous le menton. Il grogne. Il ne bouge pas d'un poil.",
]
const AGAIN := [
	"Griffe-Grise ouvre un œil, reconnaît Chloé, et le referme.",
	"Le vieux raptor renifle la sacoche de Chloé, pour vérifier. Oui : ça sent toujours Hélène.",
	"Griffe-Grise bâille. Il lui manque deux dents, et visiblement, il s'en fiche.",
	"Il regarde vers le nord-ouest, comme la dernière fois. Il attend des nouvelles de la meute.",
]
const CLEARING_AGAIN := [
	"La clairière est toujours vide. Les fougères écrasées commencent à peine à se redresser.",
	"Les sillons partent toujours vers l'ouest. C'est par là qu'on a emmené le chef de la meute.",
	"Entre les fougères, un Deinonychus te regarde passer. Il ne gronde même pas. Il attend.",
	"Chloé ramasse un bout de corde. Coupée net, d'un seul coup de lame. Ceux qui ont fait ça avaient l'habitude.",
]


# ------------------------------------------------------------------ arriving

## The first time in the Forêt: rain under the ferns, raptors calling each other with no one to
## answer, then a deep cry from the south-west that silences them all (Griffe-Grise).
static func arrival() -> void:
	if Game.flag(&"foret_arrivee"):
		return
	var w = S.world()
	if w == null:
		return
	S.lock(true)
	await S.wait(0.8)
	await S.say([
		{"text": RAIN_NOW if Game.is_raining() else RAIN_AFTER},
		{"text": "Les troncs montent si haut qu'on n'en voit pas la cime, et les fougères dépassent Chloé d'une bonne tête. Ça sent la mousse, la terre mouillée… et quelque chose de très, très ancien."},
	])
	_raptor_cry("neutre", -14.0)
	await S.wait(0.6)
	_raptor_cry("neutre", -19.0, 1.1)
	await S.wait(0.35)
	_raptor_cry("attaque", -17.0, 0.95)
	await S.say([
		{"text": "Un cri de raptor, quelque part dans le sous-bois. Un autre lui répond, plus loin. Puis un troisième, tout de suite, trop vite. Ils s'appellent dans tous les sens."},
		{"who": CHLOE, "text": "(On dirait qu'ils cherchent quelqu'un. Et que personne ne leur répond.)"},
	])
	await S.wait(0.4)
	_raptor_cry("neutre", -8.0, OLD_PITCH)
	await S.wait(0.9)
	await S.say([{"text": "Alors, venu du sud-ouest, un cri plus grave, plus lent, fait taire tous les autres. Le sous-bois retient son souffle… puis les appels reprennent, tout bas."}])
	var vif := vif_dino()
	var lead := Game.lead_dino()
	var lines: Array = []
	if vif and Game.party.has(vif):
		if lead == vif:
			w.companion.cry(&"neutre")
		lines = [
			{"text": "%s se fige, la tête tournée vers le sud-ouest. Puis il répond : un petit cri aigu, que Chloé ne lui a jamais entendu." % vif.nickname},
			{"who": CHLOE, "text": "(« Son père, Griffe-Grise, veille encore dans la Forêt »… C'était lui ?)"},
			{"who": CHLOE, "text": "Viens, %s. On va voir qui t'appelle." % vif.nickname},
		]
	else:
		if lead:
			lines.append({"text": "%s se colle contre la jambe de Chloé, les yeux ronds." % lead.nickname})
		lines.append({"who": CHLOE, "text": "(Celui-là n'avait pas peur. Il venait d'un ravin, au sud-ouest.)"})
		if vif:   # Vif waits at the Cabinet, but Chloé read page 6
			lines.append({"who": CHLOE, "text": "(« Son père, Griffe-Grise, veille encore dans la Forêt »… Le père %s ?)" % French.de(vif.nickname)})
		lines.append({"who": CHLOE, "text": "Allez. On va voir qui peut faire taire une meute entière d'un seul cri."})
	lines.append({"flag": &"foret_arrivee"})
	await S.say(lines)
	Save.save_game()
	S.lock(false)


# ------------------------------------------------------------------ Griffe-Grise

## Talking to Griffe-Grise (`who`, the DinoNpc of his ravine): the meeting the first time, then
## a short line at each visit. He stays in his ravine.
static func griffe_grise(who: Node) -> void:
	if Game.flag(&"griffe_grise_vu"):
		await S.say([{"text": _griffe_again()}])
		return
	var w = S.world()
	if w == null:
		return
	S.lock(true)
	var home: Vector2 = who.global_position
	await S.say([
		{"text": "Au fond du ravin, sur un rocher couvert de mousse, un vieux Velociraptor somnole, immobile comme une statue. Museau gris, plumes ternies, et en travers du flanc, une longue éraflure à peine refermée."},
		{"text": "Au-dessus de sa couche, quelqu'un a gravé un nom dans la roche, avec une petite fougère : « Griffe-Grise »."},
		{"text": "Il ouvre un œil jaune. Puis il se redresse, beaucoup plus vite qu'un vieux dino ne devrait."},
	])
	_raptor_cry("attaque", -3.0, OLD_PITCH)
	await who.walk_to(home.lerp(w.player.global_position, 0.3), 220.0)
	w.player.get_node("Camera").call(&"shake", 4.0, 0.3)
	await S.say([{"text": "Il gronde, les griffes plantées dans la mousse. À chaque patte, une griffe recourbée, grise comme un galet de rivière."}])
	var vif := vif_dino()
	if vif:
		await _reunion(vif)
	else:
		await _wary()
	await _the_trap()
	await _the_pack(who)
	if is_instance_valid(who):
		await who.walk_to(home, 110.0)
	Game.set_flag(&"griffe_grise_vu")
	Game.award_team_xp(XP_GRIFFE + (XP_ANCIEN if vif else 0))
	Save.save_game()
	S.lock(false)


## Vif and his father: he knows his little one's smell. The Ancien's page, in a tin box.
static func _reunion(vif: Dino) -> void:
	var w = S.world()
	var with_her := Game.party.has(vif)
	var name := vif.nickname
	if with_her:
		await S.say([
			{"text": "%s passe devant Chloé. Il ne gronde pas. Il avance tout doucement, le cou tendu, en reniflant l'air." % name},
			{"text": "Le vieux raptor se tait d'un coup. Il baisse la tête, très bas, jusqu'à toucher le museau du petit. Et il ne bouge plus."},
		])
		if Game.lead_dino() == vif:
			w.companion.rejoice()
	else:
		await S.say([
			{"text": "Le vieux raptor s'approche de Chloé, tout près. Il renifle ses mains : celles qui caressent %s chaque soir, au Cabinet." % name},
			{"text": "Il se tait d'un coup. Et il ne bouge plus."},
		])
	_raptor_cry("neutre", -6.0, OLD_PITCH)
	var cry_line := "Griffe-Grise pousse un cri doux et grave, qu'il n'a pas dû pousser depuis longtemps."
	if with_her:
		cry_line += " %s lui répond, plus aigu, exactement sur la même note." % name
	var lines: Array = [
		{"who": CHLOE, "text": "Tu le reconnais… Tu es Griffe-Grise. Son papa." if with_her
			else "Tu sens son odeur sur moi… Tu es Griffe-Grise. Le papa %s." % French.de(name)},
		{"text": cry_line},
	]
	if Game.flag(&"lettre_scellee"):
		lines.append_array([
			{"who": CHLOE, "text": "Hélène m'a demandé de te dire qu'elle va bien."},
			{"text": "Griffe-Grise penche la tête. Il n'a pas l'air d'y croire tout à fait. Chloé non plus."},
		])
	lines.append_array([
		{"text": "Le vieux raptor gratte la mousse au pied de son rocher et en tire une boîte en fer-blanc, toute cabossée. Il la pousse vers Chloé, du bout du museau."},
		{"text": "Sur le couvercle, de l'écriture penchée d'Hélène : « Pour Chloé. Il te la donnera. »"},
		{"letter": ANCIEN_PAGE, "sign": "— H."},
		{"flag": &"found_journal_ancien"},
		{"text": "Chloé gratte Griffe-Grise sous le menton. Il grogne, pour la forme… et ne bouge plus d'un poil."},
	])
	if with_her:
		lines.append({"text": "%s se roule en boule contre le flanc de son père. Pour la première fois de sa vie, il a l'air de n'avoir rien à prouver." % name})
	else:
		lines.append({"who": CHLOE, "text": "Je te ramènerai %s. Promis." % name})
	await S.say(lines)
	Toast.say(S.world().get_tree(), "Page de l'Ancien : Griffe-Grise")


## Chloé chose another egg: he does not know her, but she smells of Hélène (the pages she carries).
static func _wary() -> void:
	var pick := await Dialogue.choose("", "Griffe-Grise avance d'un pas. Puis d'un autre. Que fait Chloé ?", ["Ne pas bouger", "Reculer doucement"])
	var lines: Array = []
	if pick == 0:
		lines.append({"text": "Chloé ne bouge pas. Elle respire lentement, les mains ouvertes. Pas d'ordre, pas de cri, pas de peur : juste elle."})
	else:
		lines.append({"text": "Chloé recule d'un pas. Griffe-Grise avance d'un pas. Elle recule encore ; il avance encore. Ce n'est pas une chasse : il la renifle."})
	lines.append_array([
		{"text": "Le vieux raptor tourne autour d'elle. Il plonge le museau dans la sacoche où elle range les pages du journal… et il s'arrête net."},
		{"text": "Il reste là, les yeux fermés, à respirer le vieux papier. L'odeur du Cabinet, de l'encre et de l'ambre. L'odeur d'Hélène."},
		{"who": CHLOE, "text": "Tu la connaissais… Tu es un de ses dinos, toi aussi."},
	])
	var lead := Game.lead_dino()
	if lead:
		lines.append({"text": "%s s'approche, prudent. Griffe-Grise le renifle à peine et le laisse passer : l'ami d'Hélène a décidé que vous faisiez partie des siens." % lead.nickname})
	# Her own dino's mother waits elsewhere (docs/lore.md, the Anciens).
	var mine := starter()
	var home_region: String = {"ankylosaurus": "le Désert", "parasaurolophus": "le Marais"}.get(str(Game.flag(&"starter")), "")
	if mine and home_region != "":
		lines.append({"who": CHLOE, "text": "(Quelque part dans %s, la mère %s l'attend peut-être comme ça, elle aussi.)" % [home_region, French.de(mine.nickname)]})
	await S.say(lines)


## What he kept: a poacher's trap he tore open, smelling of ash (someone hunts in the Forêt).
static func _the_trap() -> void:
	await S.say([{"text": "Griffe-Grise plonge la tête derrière son rocher et revient avec quelque chose entre les dents. Il le laisse tomber aux pieds de Chloé."}])
	Audio.play_sfx(LATCH, -2.0)
	var seen_ash: bool = Game.flag(&"maia_defi_1") or Game.flag(&"roc_nuit_niee")
	await S.say([
		{"text": "Clang. Un piège à mâchoires d'acier, arraché de sa chaîne. Les dents de fer sont tordues, écartées de force. Il a fallu des griffes terribles pour ouvrir ça."},
		{"who": CHLOE, "text": "C'est ça, ta blessure… Quelqu'un pose des pièges dans la Forêt. Des braconniers."},
		{"text": "Le piège sent la cendre froide."},
		{"who": CHLOE, "text": "(De la cendre. Encore.)" if seen_ash else "(De la cendre ? Il n'y a pas le moindre feu, ici.)"},
	])


## He calls towards the north-west; the pack answers, and no voice leads it. The clearing.
static func _the_pack(who: Node) -> void:
	if is_instance_valid(who):
		who.sprite.flip_h = true   # towards the north-west
	_raptor_cry("neutre", -2.0, OLD_PITCH)
	await S.say([{"text": "Griffe-Grise se tourne vers le nord-ouest, lève le museau et appelle. Un long cri grave, qui roule entre les arbres."}])
	_raptor_cry("neutre", -18.0, 1.08)
	await S.wait(0.3)
	_raptor_cry("neutre", -20.0, 0.97)
	await S.wait(0.3)
	_raptor_cry("attaque", -21.0, 1.12)
	var lines: Array = [
		{"text": "Au loin, la meute répond. Des dizaines de voix qui se chevauchent… et pas une qui commande."},
		{"who": CHLOE, "text": "Ils avaient un chef, c'est ça ? Et quelqu'un l'a pris."},
		{"text": "Le vieux raptor ne quitte pas le nord-ouest des yeux. Par là-bas, il y a une clairière où les fougères poussent plus haut que partout ailleurs. Dans la Forêt, tout le monde sait à qui elle est."},
	]
	if Game.flag(&"clairiere_vue"):
		lines.append({"who": CHLOE, "text": "La clairière aux fougères écrasées… C'était la sienne. Le chef de la meute dormait là, et on l'a emmené de force."})
	else:
		lines.append({"who": CHLOE, "text": "C'est là-bas qu'il vivait, votre chef ? D'accord. J'y vais."})
	lines.append({"text": "Griffe-Grise ne la suit pas. Ce ravin est le sien, et il est trop vieux pour la meute. Mais il garde un œil ouvert, tourné vers la clairière."})
	await S.say(lines)


## A short line when Chloé comes back (the next one each time).
static func _griffe_again() -> String:
	if Game.flag(&"clairiere_vue") and not Game.flag(&"griffe_apres_clairiere"):
		Game.set_flag(&"griffe_apres_clairiere")
		return "Griffe-Grise renifle Chloé : elle sent la clairière, les fougères écrasées, la cendre. Il gronde tout bas, vers l'ouest."
	if Game.phase() == &"night":
		return "Griffe-Grise somnole. Même endormi, il garde un œil entrouvert : les vieux raptors ne dorment jamais tout à fait."
	var n := int(Game.flag(&"griffe_grise_n"))
	Game.set_flag(&"griffe_grise_n", n + 1)
	var vif := vif_dino()
	if vif == null:
		return AGAIN[n % AGAIN.size()]
	if not Game.party.has(vif):
		return "Griffe-Grise renifle les mains de Chloé, puis regarde derrière elle. Il cherche %s." % vif.nickname
	return (AGAIN_VIF[n % AGAIN_VIF.size()] as String).replace("%s", vif.nickname)


# ------------------------------------------------------------------ the empty clearing

## The clearing of the giant ferns, where the pack's leader lived: empty, and the Ombre Noire's
## marks everywhere. A hook towards step 2.
static func clairiere_vide(_who: Node) -> void:
	if Game.flag(&"clairiere_vue"):
		var n := int(Game.flag(&"clairiere_n"))
		Game.set_flag(&"clairiere_n", n + 1)
		await S.say([{"text": CLEARING_AGAIN[n % CLEARING_AGAIN.size()]}])
		return
	var w = S.world()
	if w == null:
		return
	S.lock(true)
	var griffe: bool = Game.flag(&"griffe_grise_vu")
	await S.say([
		{"text": "La clairière aux fougères géantes. Elles sont si hautes qu'elles font de l'ombre aux arbres… mais au milieu, elles sont couchées, écrasées, comme si quelque chose d'énorme s'était débattu ici."},
		{"text": "Tout autour, un anneau de pieux plantés dans la terre, reliés par des cordes coupées. Une cage sans toit ni porte. Vide."},
		{"text": "Dans la boue, une empreinte à deux doigts seulement : un raptor, qui marche la grande griffe relevée. Sauf que celle-ci est grande comme une bassine."},
		{"who": CHLOE, "text": "Un raptor grand comme ÇA ?"},
		{"text": "Ça sent la cendre froide, comme le piège de Griffe-Grise." if griffe else "Ça sent la cendre froide. Pourtant, aucun feu n'a brûlé ici."},
		{"text": "Entre deux pieux, quelque chose de blanc dépasse de la boue. Chloé le ramasse : un morceau d'os taillé, poli, percé d'un trou pour l'œil."},
		{"who": CHLOE, "text": "Un masque d'os… comme celui du voleur du Cabinet. L'Ombre Noire est venue jusqu'ici."},
		{"who": CHLOE, "text": "(Ceux qui ont volé le troisième œuf…)"},
	])
	var lead := Game.lead_dino()
	if lead:
		w.companion.cry(&"attaque")
		await S.say([{"text": "%s gronde, le nez au ras du sol. De profonds sillons partent de la cage : on a traîné quelque chose de très lourd… vers l'ouest." % lead.nickname}])
	else:
		await S.say([{"text": "De profonds sillons partent de la cage : on a traîné quelque chose de très lourd… vers l'ouest."}])
	Audio.play_sfx(LEAVES, -6.0)
	_raptor_cry("neutre", -12.0, 1.05)
	await S.say([
		{"text": "Entre les fougères, des yeux jaunes s'allument. Trois Deinonychus observent Chloé, sans bouger. Ils ne chassent pas. Ils attendent quelqu'un."},
		{"text": "Puis les fougères se referment, et ils ne sont plus là."},
		{"who": CHLOE, "text": "Le chef de la meute… Griffe-Grise avait raison : on l'a pris." if griffe else "Leur chef. C'est lui qu'on a emmené, et c'est lui qu'ils appellent."},
		{"who": CHLOE, "text": "Tiens bon, qui que tu sois. On va te retrouver."},
		{"flag": &"clairiere_vue"},
	])
	Game.award_team_xp(XP_CLAIRIERE)
	Save.save_game()
	S.lock(false)


# ------------------------------------------------------------------ helpers

## Chloé's dino from the Cabinet (the one she chose, whatever she named it), or null: the first
## of its species in the party, then in the box.
static func starter() -> Dino:
	var id := str(Game.flag(&"starter"))
	if id == "" or id == "false":
		return null
	for d: Dino in Game.party:
		if String(d.species().id) == id:
			return d
	for d: Dino in Game.box:
		if String(d.species().id) == id:
			return d
	return null


## Vif (Chloé's Velociraptor from the Cabinet, Griffe-Grise's little one), or null when she
## chose another egg.
static func vif_dino() -> Dino:
	return starter() if Game.flag(&"starter") == "velociraptor" else null


## A raptor's call, not tied to anyone on screen (the pack in the distance, Griffe-Grise's deep
## voice): quieter when far, lower when old.
static func _raptor_cry(kind: String, volume_db: float, pitch := 1.0) -> void:
	var w = S.world()
	var path := RAPTOR_CRY % kind
	if w == null or not ResourceLoader.exists(path):
		return
	var p := AudioStreamPlayer.new()
	p.bus = &"SFX"
	p.stream = load(path)
	p.volume_db = volume_db
	p.pitch_scale = pitch
	w.add_child(p)
	p.finished.connect(p.queue_free)
	p.play()
