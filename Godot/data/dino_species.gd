class_name DinoSpecies
extends Resource
## One species of dinosaur. Each species is a .tres file in data/species/ (editable in the
## Inspector) and is listed in SpeciesDB. Adding a dino = one sprite sheet + one .tres.

@export var id: StringName
@export var display_name := ""
## Donor family, used by exploration abilities and elemental types
## (raptor, ceratopsian, tyrant, sauropod, armored, hadrosaur, flyer, marine, spino).
@export var family: StringName
@export_multiline var description := ""

@export_group("Sprite")
## Sheet of equal frames, the dino facing RIGHT.
@export var sheet: Texture2D
@export var sheet_columns := 3
@export var sheet_rows := 2
@export var walk_frames: PackedInt32Array = [0, 1, 2]
@export var idle_frames: PackedInt32Array = [3, 4]
@export var attack_frame := 5
## Front and back views, same frame size as `sheet`: row 1 toward the camera, row 2 away.
@export var face_back_sheet: Texture2D
@export var face_back_columns := 4
@export var down_walk_frames: PackedInt32Array = [0, 1, 2]
@export var down_idle_frame := 3
@export var up_walk_frames: PackedInt32Array = [4, 5, 6]
@export var up_idle_frame := 7
## Scale of the sprite in the world (sheets are drawn at 2x the base resolution).
@export var world_scale := 0.5
@export var walk_fps := 8.0

@export_group("Sound")
## Prefix of the cries in assets/audio/cries: <prefix>-neutre / -attaque / -degat / -ko.
@export var cry_prefix := ""

@export_group("Parts")
## The species' body parts, 1..10, copied from the Phaser data (src/data/dinos.js).
## A hybrid takes each part's values from the species that part comes from.
@export var head_size := 5
@export var head_bite := 5
@export var teeth_sharp := 5
@export var teeth_count := 5
@export var front_power := 5
@export var front_reach := 5
@export var back_legs_power := 5
@export var back_legs_speed := 5
@export var back_armor := 5
@export var back_spikes := 0
@export var tail_power := 5
@export var tail_length := 5
@export_enum("common", "rare", "epic", "legendary") var rarity := "common"


## How easy it is to catch (Phaser catchDifficulty): exclusives and big dinos resist more.
func catch_ease() -> float:
	match rarity:
		"legendary": return 0.25
		"epic": return 0.4
		"rare": return 0.55
	return 0.7 if head_size >= 8 else 0.9


func cry(kind: String) -> AudioStream:
	var path := "res://assets/audio/cries/%s-%s.mp3" % [cry_prefix, kind]
	return load(path) if ResourceLoader.exists(path) else null
