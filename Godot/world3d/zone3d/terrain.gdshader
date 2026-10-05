shader_type spatial;
// The ground of a 3D zone on the home-made relief mesh (ZoneTerrain, Kind.MESH; docs/migration-3d.md,
// phase 4). The painting itself is terrain_paint.gdshaderinc, shared with Terrain3D's ground
// (terrain3d_ground.gdshader), so the two grounds look the same.

render_mode cull_back;

#include "res://world3d/zone3d/terrain_paint.gdshaderinc"

varying vec3 world;
varying vec3 wnormal;

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnormal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	// The slope of the cliffs is the face's own (from the screen derivatives): the smooth vertex
	// normals soften a cliff one metre wide into a gentle slope.
	ALBEDO = ground_colour(world, face_normal(world));
	ROUGHNESS = 0.95;
}
