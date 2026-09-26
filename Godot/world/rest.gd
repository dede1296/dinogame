class_name Rest
## Sitting down on a bench, or by a campfire: rest an hour (the party gets its strength back),
## or wait for the evening or the morning, to the little resting tune of the web version.
## By a fire, the game is saved too.

const KINDS := ["banc", "feu_camp"]
const EVENING := 18.5
const MORNING := 7.0
const FADE_S := 0.6
const DARK_S := 1.2   # the screen stays dark this long (time passing)
const TAIL_S := 1.0   # the place's music comes back under the tune's last second
const TUNE := preload("res://assets/audio/music/repos.ogg")

## Rests in a row share one tune: the music of the place comes back after the last one.
static var _tune_playing := false
static var _rests := 0


static func sit(prop: Prop, player: Player) -> void:
	player.face_towards(prop.global_position)
	var by_fire := prop.kind == "feu_camp"
	var intro := "Chloé s'installe près du feu. Il fait bon." if by_fire else "Chloé s'assoit sur le banc."
	var pick := await Dialogue.choose("", intro, ["Se reposer un moment", "Attendre le soir", "Attendre le matin", "Repartir"])
	if pick < 0 or pick == 3:
		return
	var tree := player.get_tree()
	if not _tune_playing:
		Audio.push_music(TUNE, 0.6, false)
		_tune_playing = true
	_rests += 1
	var this_rest := _rests
	await Router.fade_out(FADE_S)
	match pick:
		0:
			Game.pass_time_until(fmod(Game.clock / 60.0 + 1.0, 24.0))
		1:
			Game.pass_time_until(EVENING)
		2:
			Game.pass_time_until(MORNING)
	Game.heal_party()
	Game.party_changed.emit()
	await tree.create_timer(DARK_S).timeout
	await Router.fade_in(FADE_S)
	# The tune plays on while Chloé sets off again, then the place's music comes back.
	tree.create_timer(TUNE.get_length() - DARK_S - FADE_S * 2.0 - TAIL_S).timeout.connect(func() -> void:
		if this_rest == _rests and _tune_playing:
			_tune_playing = false
			Audio.pop_music())
	if by_fire:
		Save.save_game()
		Toast.say(tree, "L'équipe a repris des forces. Partie sauvegardée.")
	else:
		Toast.say(tree, "L'équipe a repris des forces.")
