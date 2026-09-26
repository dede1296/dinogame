@tool
class_name Prop
extends StaticBody2D
## A piece of scenery (tree, rock, flowers…). Place it in a region's Entities node and
## pick its `kind` in the Inspector: sprite, shadow, collision and sway come from KINDS.
## The node's origin is where the object touches the ground (for Y-sorting).

const SWAY := preload("res://world/shaders/sway.gdshader")
const ART := "res://assets/art/props/%s.png"

## scale: sprite scale; foot: fraction of the sprite height below the ground point;
## solid: collision radius (float) or box size (Vector2), 0 = walk through;
## sway: sway strength in px (0 = rigid); shadow: shadow width in px (0 = none).
const KINDS := {
	"arbre_rond": {"scale": 0.62, "foot": 0.05, "solid": 16.0, "sway": 1.2, "shadow": 120.0},
	"araucaria": {"scale": 0.62, "foot": 0.03, "solid": 11.0, "sway": 1.5, "shadow": 80.0},
	"fougere_arbre": {"scale": 0.6, "foot": 0.03, "solid": 11.0, "sway": 2.5, "shadow": 90.0},
	"buisson": {"scale": 0.4, "foot": 0.08, "solid": 24.0, "sway": 0.8, "shadow": 96.0},
	"rocher": {"scale": 0.42, "foot": 0.1, "solid": Vector2(96, 34), "sway": 0.0, "shadow": 100.0},
	"cailloux": {"scale": 0.3, "foot": 0.1, "solid": 16.0, "sway": 0.0, "shadow": 50.0},
	"tronc": {"scale": 0.42, "foot": 0.15, "solid": Vector2(104, 30), "sway": 0.0, "shadow": 104.0},
	"ronces": {"scale": 0.34, "foot": 0.05, "solid": 20.0, "sway": 1.5, "shadow": 60.0},
	"hautes_herbes": {"scale": 0.24, "foot": 0.05, "solid": 0.0, "sway": 3.0, "shadow": 0.0},
	"fougeres": {"scale": 0.26, "foot": 0.06, "solid": 0.0, "sway": 3.0, "shadow": 0.0},
	"fleurs_roses": {"scale": 0.2, "foot": 0.06, "solid": 0.0, "sway": 2.0, "shadow": 0.0},
	"fleurs_violettes": {"scale": 0.2, "foot": 0.06, "solid": 0.0, "sway": 2.0, "shadow": 0.0},
	"panneau": {"scale": 0.3, "foot": 0.04, "solid": 8.0, "sway": 0.0, "shadow": 36.0},
	"cloture": {"scale": 0.35, "foot": 0.08, "solid": Vector2(70, 12), "sway": 0.0, "shadow": 0.0},
	"ambre": {"scale": 0.26, "foot": 0.08, "solid": 0.0, "sway": 0.0, "shadow": 22.0},
	"souche": {"scale": 0.3, "foot": 0.12, "solid": 16.0, "sway": 0.0, "shadow": 56.0},
}

@export_enum("arbre_rond", "araucaria", "fougere_arbre", "buisson", "rocher", "cailloux", "tronc", "ronces",
	"hautes_herbes", "fougeres", "fleurs_roses", "fleurs_violettes", "panneau", "cloture", "ambre", "souche")
var kind := "arbre_rond":
	set(value):
		kind = value
		_build()
@export var flip := false:
	set(value):
		flip = value
		_build()

var sprite: Sprite2D
var _shape: CollisionShape2D
var _shadow: Sprite2D


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_build()


func _build() -> void:
	if not is_inside_tree():
		return
	var def: Dictionary = KINDS.get(kind, {})
	if def.is_empty():
		return
	if sprite == null:
		_shadow = Shadow.make(self)
		sprite = Sprite2D.new()
		add_child(sprite)
		_shape = CollisionShape2D.new()
		add_child(_shape)
	var tex: Texture2D = load(ART % kind)
	sprite.texture = tex
	sprite.scale = Vector2.ONE * def["scale"]
	sprite.flip_h = flip
	var h := tex.get_height()
	sprite.offset = Vector2(0, -h / 2.0 + h * def["foot"])
	if def["sway"] > 0.0:
		var mat := ShaderMaterial.new()
		mat.shader = SWAY
		mat.set_shader_parameter("strength", def["sway"])
		mat.set_shader_parameter("push_strength", def["sway"] * 3.0)
		sprite.material = mat
	else:
		sprite.material = null
	Shadow.fit(_shadow, def["shadow"])
	var solid: Variant = def["solid"]
	if solid is Vector2:
		var box := RectangleShape2D.new()
		box.size = solid
		_shape.shape = box
		_shape.position = Vector2(0, -solid.y / 2.0 + 6)
	elif solid > 0.0:
		var circle := CircleShape2D.new()
		circle.radius = solid
		_shape.shape = circle
		_shape.position = Vector2.ZERO
	_shape.disabled = not (solid is Vector2 or solid > 0.0)
