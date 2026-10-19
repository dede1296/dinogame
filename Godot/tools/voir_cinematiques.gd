extends SceneTree
## Regarder un film d'Ambrelune en entier, en TEMPS RÉEL, dans une vraie fenêtre de 1600 × 900
## (docs/cinematiques.md § Voir les films) : l'intro seule, ou la fin puis les crédits. Rien n'est
## accéléré ni capturé, aucun bandeau de test : le film tel qu'il se joue dans le jeu, « Passer » compris
## (Échap deux fois ou maintenu, B, ou un clic sur le bouton). La fenêtre se ferme à la fin du film.
## Jamais sur la partie de Greg : la sauvegarde est redirigée vers un fichier de test, où rien n'est
## écrit ; ses réglages (volume, plein écran) ne sont pas touchés.
##   godot --path Godot --script res://tools/voir_cinematiques.gd -- film=intro
##   godot --path Godot --script res://tools/voir_cinematiques.gd -- film=fin [starter=velociraptor|ankylosaurus|parasaurolophus]
## (le dino de départ de F-06 : velociraptor = Vif, ankylosaurus = Bastion, parasaurolophus = Écho ;
## « vif », « bastion », « echo » marchent aussi). Lancés d'un double-clic par tools/voir-intro.cmd et
## tools/voir-fin-et-credits.cmd. Les autoloads (Game, Save…) sont lus par leur nœud et les scripts du jeu
## chargés à l'exécution, comme dans tools/capture.gd : ce script est compilé avant eux.

const SAVE_PATH := "user://voir_cinematiques_save.json"
const WINDOW := Vector2i(1600, 900)
const CINEMATIQUES := "res://story/cinematiques.gd"
const CINEMATIC := "res://ui/cinematic.gd"
## What may be asked for F-06 → the starter's species.
const STARTERS := {
	"velociraptor": &"velociraptor", "vif": &"velociraptor",
	"ankylosaurus": &"ankylosaurus", "bastion": &"ankylosaurus",
	"parasaurolophus": &"parasaurolophus", "echo": &"parasaurolophus", "écho": &"parasaurolophus",
}

var _what := "intro"
var _starter: StringName = &"velociraptor"
var _started_ms := 0


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		var value := arg.get_slice("=", 1) if arg.contains("=") else arg
		if arg.begins_with("film="):
			_what = value
		elif STARTERS.has(value.to_lower()):
			_starter = STARTERS[value.to_lower()]
		else:
			printerr("voir_cinematiques : argument inconnu « %s » (film=intro|fin, starter=velociraptor|ankylosaurus|parasaurolophus)" % arg)
	if _what not in ["intro", "fin"]:
		printerr("voir_cinematiques : film=%s inconnu, l'intro à la place." % _what)
		_what = "intro"
	var save := root.get_node("Save")
	save.set("path", SAVE_PATH)   # (never the player's game…)
	save.set("enabled", false)    # (…and nothing written at all)
	# The first frame: the autoloads are all ready (Screen has put the window as the player likes it).
	process_frame.connect(_start, CONNECT_ONE_SHOT)


func _start() -> void:
	_window()
	var game := root.get_node("Game")
	game.call("new_game")
	if _what == "fin":
		game.call("give_starter", _starter)
	var films: Script = load(CINEMATIQUES)
	var seq: Dictionary = films.call("intro_sequence") if _what == "intro" else films.call("end_sequence")
	seq.erase("flag")   # (intro_vue, fin_vue: nothing to remember)
	seq["end"] = "black"
	print("Film « %s »%s : %d plans, en temps réel." % [_what, " (F-06 : %s)" % _starter if _what == "fin" else "", seq["plans"].size()])
	_started_ms = Time.get_ticks_msec()
	var film: Node = load(CINEMATIC).call("play", root, seq)
	film.connect(&"finished", _on_finished.bind(films))


## A real window, 1600 × 900, centred: never the full screen (the player's choice stays as it is).
func _window() -> void:
	root.get_node("Screen").call("set_fullscreen", false, false)
	root.mode = Window.MODE_WINDOWED
	root.size = WINDOW
	root.move_to_center()
	root.title = "Ambrelune — cinématique"


func _on_finished(skipped: bool, films: Script) -> void:
	print("Fin du film%s : %.1f s à l'écran." % [" (passé)" if skipped else "", (Time.get_ticks_msec() - _started_ms) / 1000.0])
	print("Plans : ", films.call("debug_timeline"))
	quit()
