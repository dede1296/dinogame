// The painted ground of a 3D zone (docs/migration-3d.md, phase 4), shared by both grounds — the
// home-made relief mesh (terrain.gdshader) and Terrain3D's (terrain3d_ground.gdshader) — so they
// paint the very same ground, pixel for pixel: the 2.5D's painted ground (world/view3d/
// ground.gdshader) carried over to a real relief and a wider map. The ground types come from the
// 2.5D zone, one pixel per tile (masks), read at `tile_m` metres per tile; the pictures repeat per
// metre as in the 2.5D (`px` = metres × 48), so up close the grass, the trails and the cliffs look
// the same. Kept: ragged edges (warp), grain, grass patches, the sand, the dark floor of the woods,
// mud and rock, the trails and their rims, wet edges and the dark bed of the water, cliffs on steep
// slopes (their own axis, real size), passing cloud shadows. Left out for now: the cover layers
// (snow…), the tints towards the neighbouring regions, paved squares.

uniform sampler2D grass_tex : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D dirt_tex : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D mud_tex : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D rock_tex : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D cliff_tex : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D noise_tex : repeat_enable, filter_linear;
// one pixel per tile — mask_a: R path, G tall grass, B water, A woods; mask_b: R sand, G mud, B rock
uniform sampler2D mask_a : filter_linear, repeat_disable;
uniform sampler2D mask_b : filter_linear, repeat_disable;
uniform vec2 map_tiles = vec2(120.0, 90.0);
uniform float tile_m = 2.0;             // metres of this zone per tile of the 2.5D one
uniform vec2 zone_origin = vec2(0.0);   // where the zone's corner stands in the world (m): its masks are read from there
uniform float water_level = -100.0;     // no water: far below
// A zone with water at several levels (a remodelled one: its sea, its ponds; ZoneTerrain._water_map):
// the level each point's shore and bed go by, a texel per metre of the zone and its margin.
uniform bool use_water_map = false;
uniform sampler2D water_map : filter_linear, repeat_disable;
uniform vec2 water_map_origin = vec2(0.0);   // zone metres at the first texel's centre
uniform vec2 water_map_texels = vec2(1.0);
uniform float cliff_repeat = 2.2;       // metres per repeat of the cliff picture
uniform vec3 grass_tint : source_color = vec3(1.0);
// The bed under the water: the colour the water lends it (a clear blue-green on the coast, a murky
// green in the marsh), how dark it goes at the bottom, and how deep that takes (m).
uniform vec3 bed_tint : source_color = vec3(0.72, 0.88, 0.86);
uniform float bed_shade : hint_range(0.0, 1.0) = 0.62;
uniform float bed_depth_m = 0.7;
uniform bool clouds = true;
uniform vec2 wind = vec2(0.3, 0.12);    // m/s

float noise(vec2 p) {
	return texture(noise_tex, p).r;
}

vec3 cliff_face(vec2 w, float h, float side) {
	vec3 face_z = texture(cliff_tex, vec2(w.x, -h) / cliff_repeat).rgb;
	vec3 face_x = texture(cliff_tex, vec2(w.y, -h) / cliff_repeat).rgb;
	return mix(face_z, face_x, side);
}

// The colour of the ground at `world` (m). `face` is the up-facing normal of the drawn face itself
// (from the screen derivatives): the cliffs follow the real steepness of what is on screen, not
// the smoothed normals used for the light.
vec3 ground_colour(vec3 world, vec3 face) {
	vec2 px = world.xz * 48.0;   // the 2D pixel scale, so the 2D look carries over
	vec2 tile = (world.xz - zone_origin) / tile_m;   // (the pictures repeat on the world's grid: no seam between zones)
	vec2 warp = vec2(noise(px / 210.0), noise(px / 210.0 + vec2(0.37, 0.61))) - 0.5;
	float grain = noise(px / 70.0) - 0.5;
	vec2 at = (tile + warp * 0.9) / map_tiles;   // ragged edges, in tiles (they scale with the map)
	vec4 a = texture(mask_a, at);
	vec4 b = texture(mask_b, at);

	float patches = noise(px / 900.0);
	vec3 grass = texture(grass_tex, px / 320.0).rgb * grass_tint * mix(0.84, 1.1, patches);
	grass = mix(grass, grass * vec3(0.78, 0.86, 0.72), smoothstep(0.3, 0.7, a.g));   // tall grass
	vec3 dirt = texture(dirt_tex, px / 256.0).rgb;
	float sandy = smoothstep(0.35, 0.65, b.r + grain * 0.3);
	grass = mix(grass, dirt * vec3(1.18, 1.08, 0.82) + 0.06, sandy);
	grass = mix(grass, grass * vec3(0.55, 0.66, 0.5), smoothstep(0.3, 0.7, a.a));    // under the woods
	if (b.g > 0.01) {
		grass = mix(grass, texture(mud_tex, px / 300.0).rgb * mix(0.9, 1.06, patches), smoothstep(0.3, 0.6, b.g + grain * 0.3));
	}
	if (b.b > 0.01) {
		grass = mix(grass, texture(rock_tex, px / 340.0).rgb * mix(0.88, 1.06, patches), smoothstep(0.3, 0.6, b.b + grain * 0.3));
	}
	float p = a.r + grain * 0.22;
	float path = smoothstep(0.46, 0.56, p);
	float rim = smoothstep(0.32, 0.48, p) * (1.0 - path);
	vec3 col = mix(grass, dirt, path);
	col *= 1.0 - rim * 0.22;

	// The water's edge, from the real height: wet sand just above the water, then the bed below it.
	// The bed keeps its own sand and pebbles — it is only cooled and dimmed by the water over it
	// (bed_tint, bed_shade, set per zone by zone_terrain.gd from the zone's own water colour), so
	// the bottom still shows through in the shallows instead of going black.
	float h = world.y;
	float level = water_level;
	if (use_water_map) {
		level = textureLod(water_map, (world.xz - zone_origin - water_map_origin + 0.5) / water_map_texels, 0.0).r;
	}
	float wet = smoothstep(level + 0.2, level + 0.02, h + grain * 0.04);
	col = mix(col, dirt * vec3(0.92, 0.86, 0.72) * 0.78, wet);
	float sunk = smoothstep(level, level - bed_depth_m, h);
	col = mix(col, col * bed_tint * mix(1.0, bed_shade, sunk), sunk);

	// cliffs: the earth wall on the wall's own axis, at its real size, greyer than the trails.
	float rock = smoothstep(0.35, 0.6, 1.0 - face.y);
	if (rock > 0.0) {
		float side = smoothstep(0.3, 0.7, abs(face.x) / (abs(face.x) + abs(face.z) + 0.0001));
		vec3 cliff = cliff_face(world.xz, h, side);
		float lum = dot(cliff, vec3(0.3, 0.55, 0.15));
		cliff = mix(cliff, vec3(lum) * vec3(1.0, 0.95, 0.9), 0.4) * 0.82;
		cliff *= mix(0.78, 1.0, smoothstep(-0.2, 0.9, fract(h / 1.2 + 0.001)));
		col = mix(col, cliff, rock);
	}
	if (clouds) {
		float cloud = noise((world.xz - wind * TIME) / 23.0);
		col *= 1.0 - 0.16 * smoothstep(0.55, 0.75, cloud);
	}
	return col;
}

// The up-facing normal of the drawn face at `world`, from the screen derivatives.
vec3 face_normal(vec3 world) {
	vec3 n = normalize(cross(dFdy(world), dFdx(world)));
	return n.y < 0.0 ? -n : n;
}
