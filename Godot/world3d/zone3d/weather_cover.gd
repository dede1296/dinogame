class_name WeatherCover
extends RefCounted
## Where the rain does not reach: under the crowns of the trees (docs/migration-3d.md). Reads the trees
## Scatter3D has sown (kind, place, size) and draws each crown as a soft disc into one small texture
## over the whole zone (R: under a crown, 0–1, soft at the rim; G: how high the leaves reach, m / 16),
## which the rain shaders sample: no streak below the leaves, no ring on the ground under them.
## The crown's size is taken from the model's own box, so a taller tree shelters a wider disc.

const TREES: Array[String] = ["arbre_rond", "araucaria", "fougere_arbre"]
const TEXEL_M := 0.5            # metres per pixel
const CROWN_SHARE := 0.42       # of a model's widest side: the crown's radius (the leaves, not the twigs)
const RIM_M := 0.7              # the soft rim (m)
const FALLBACK_RADIUS_M := 2.2  # a tree drawn as a picture: no model to measure
const FALLBACK_TOP_M := 5.0
const HEIGHT_UNIT_M := 16.0     # G is metres / this


## The cover texture over `origin` and `size` (m, as the height map's), for the trees of `scatter`.
static func build(scatter: Scatter3D, origin: Vector2, size: Vector2) -> ImageTexture:
	var img := Image.create(ceili(size.x / TEXEL_M), ceili(size.y / TEXEL_M), false, Image.FORMAT_RG8)
	if scatter != null:
		for kind in TREES:
			var meshes: Array = scatter.meshes_of(kind)
			var crown := Vector2(FALLBACK_RADIUS_M, FALLBACK_TOP_M)   # radius, top of the leaves (m) at size 1
			if not meshes.is_empty():
				var box: AABB = (meshes[0] as Mesh).get_aabb()
				crown = Vector2(maxf(box.size.x, box.size.z) * CROWN_SHARE, box.end.y)
			for it: Array in scatter.placed(kind):
				_disc(img, origin, Vector2((it[0] as Vector3).x, (it[0] as Vector3).z), crown.x * float(it[2]), crown.y * float(it[2]))
	return ImageTexture.create_from_image(img)


## One crown: 1 inside, falling to 0 over RIM_M at its edge; never lowering what another crown gave.
static func _disc(img: Image, origin: Vector2, at: Vector2, radius: float, top_m: float) -> void:
	var reach := radius + RIM_M
	var from := Vector2i(floori((at.x - reach - origin.x) / TEXEL_M), floori((at.y - reach - origin.y) / TEXEL_M))
	var to := Vector2i(ceili((at.x + reach - origin.x) / TEXEL_M), ceili((at.y + reach - origin.y) / TEXEL_M))
	for y in range(maxi(from.y, 0), mini(to.y, img.get_height() - 1) + 1):
		for x in range(maxi(from.x, 0), mini(to.x, img.get_width() - 1) + 1):
			var p := origin + (Vector2(x, y) + Vector2(0.5, 0.5)) * TEXEL_M
			var inside := clampf((radius + RIM_M * 0.5 - p.distance_to(at)) / RIM_M, 0.0, 1.0)
			if inside <= 0.0:
				continue
			var old := img.get_pixel(x, y)
			img.set_pixel(x, y, Color(maxf(old.r, inside), maxf(old.g, clampf(top_m / HEIGHT_UNIT_M, 0.0, 1.0)), 0.0))
