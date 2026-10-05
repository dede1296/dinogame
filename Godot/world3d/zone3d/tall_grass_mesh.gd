class_name TallGrassMesh
extends RefCounted
## The mesh of ONE tuft of tall grass (docs/migration-3d.md): a handful of curved blades fanning out
## from a point, 1 m tall at scale 1 (TallGrass3D scales each tuft to 0.8–1.3 and sets it down by
## the thousand in MultiMeshes). Each blade is a tapering strip bending outwards as it rises, ending
## in a point. Per vertex: UV.x across the blade (0–1), UV.y up it (0 foot, 1 tip: the shader bends
## by it), a normal leaning out of the tuft (so the tuft shades like a rounded clump, not a pile
## of flat ribbons). The same recipe at two detail levels: near (many blades) and far (a few, wider).

const HEIGHT_M := Vector2(0.72, 1.0)     # a blade's height (m) at tuft scale 1
const WIDTH_M := Vector2(0.055, 0.085)   # at its foot
const SPREAD_M := 0.2                    # how far from the tuft's middle a blade starts
const LEAN := Vector2(0.1, 0.34)         # how far its tip leans out, in heights
const FOOT_FLARE := 1.6                  # the blade stays wide to a third of its height, then tapers to the point


## `blades` blades in `segments` rows each; `widen` thickens them (the far version has fewer).
static func build(blades: int, segments: int, widen: float, seed_value: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for b in blades:
		var around := (float(b) + rng.randf_range(-0.3, 0.3)) / blades * TAU
		var out := Vector3(cos(around), 0.0, sin(around))
		var foot := out * rng.randf_range(0.03, SPREAD_M)
		var height := rng.randf_range(HEIGHT_M.x, HEIGHT_M.y)
		var lean := out * rng.randf_range(LEAN.x, LEAN.y) * height
		var width := rng.randf_range(WIDTH_M.x, WIDTH_M.y) * widen
		# its width runs across the way it leans, turned a little so no two blades face alike
		var across := out.cross(Vector3.UP).rotated(Vector3.UP, rng.randf_range(-0.5, 0.5))
		var first := verts.size()
		for s in segments:
			var t := float(s) / segments
			var centre := foot + lean * t * t + Vector3.UP * height * t
			var half := width * 0.5 * minf(FOOT_FLARE * (1.0 - t), 1.0)
			var normal := (out * (0.35 + 0.5 * t) + Vector3.UP * 0.9).normalized()
			for side in 2:
				verts.append(centre + across * half * (1.0 if side == 1 else -1.0))
				normals.append(normal)
				uvs.append(Vector2(float(side), t))
		verts.append(foot + lean + Vector3.UP * height)   # the tip
		normals.append((out * 0.85 + Vector3.UP * 0.9).normalized())
		uvs.append(Vector2(0.5, 1.0))
		for s in segments - 1:
			var i := first + s * 2
			indices.append_array([i, i + 1, i + 2, i + 1, i + 3, i + 2])
		var last := first + (segments - 1) * 2
		indices.append_array([last, last + 1, last + 2])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
