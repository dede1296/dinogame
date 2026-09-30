// The zone's ground in 3D, drawn as flat grid chunks raised by the height texture (see
// HeightMap): the 2D look (grass, paths, tall-grass patches) on the relief;
// wet sand at the water's edge and a dark bed under it (from the real height, so it fits
// the water exactly); a painted earth wall on steep slopes (cliffs), mapped on the wall's
// own axis at its real size; soft cloud shadows drifting over it all; up to three cover layers
// (snow, sand…) dosed tile by tile, with a ragged edge, so that one zone passes softly into the
// next.
shader_type spatial;
render_mode specular_disabled;

// Every material that tiles (grass, earth, paving, cliff, mud, rock, sand, and the cover layers)
// lives in ONE stack of textures, one layer each (MAT_*, filled by WorldView._ground_materials).
// The web only promises 16 texture units per shader, engine included, and these twelve took most
// of them: the ground then refused to compile and no zone had any ground at all (30/09).
uniform sampler2DArray materials : source_color, repeat_enable, filter_linear_mipmap;
const float MAT_GRASS = 0.0;
const float MAT_DIRT = 1.0;
const float MAT_PAVED = 2.0;
const float MAT_CLIFF = 3.0;
const float MAT_MUD = 4.0;
const float MAT_ROCK = 5.0;
const float MAT_SAND = 6.0;
const float MAT_COVER = 7.0;
const float MAT_COVER_PATH = 8.0;
const float MAT_COVER1 = 9.0;
const float MAT_COVER2 = 10.0;
const float MAT_COVER_CLIFF = 11.0;
// Paving (cobbles…) replaces the dirt inside paved_rect (tiles: x, y, w, h; w = 0: nowhere).
uniform vec4 paved_rect = vec4(0.0);
uniform sampler2D terrain_mask : filter_linear, repeat_disable;
// R = sand, G = forest floor, B = mud, A = rock (same layout as terrain_mask).
uniform sampler2D terrain_mask2 : filter_linear, repeat_disable;
// The Marais' mud ("vase": dark, with puddles, terrain_mask2.b), the Désert's canyon rock
// (cracked plates, terrain_mask2.a) and its dunes' sand are layers of the stack above.
uniform bool sand_picture = false;
// The sand is ice (a cold zone): no warm hollows as between dunes.
uniform bool sand_is_ice = false;
// A zone's own shade of grass (the Marais: olive), and of its cliffs (the Désert: warm).
uniform vec3 grass_tint : source_color = vec3(1.0);
uniform vec3 cliff_tint = vec3(1.0);
// Near an edge leading to a zone of other colours (WorldView.TINT_BLEND): each edge (x: axis 0/1,
// y: its line in tiles, z: 1/-1 towards the inside), the neighbour's grass and cliff tints; half
// and half at the edge, this zone's own tint_blend tiles inside.
uniform int tint_edge_count = 0;
uniform float tint_blend = 12.0;
uniform vec4 tint_edges[4];
uniform vec3 edge_grass[4] : source_color;
uniform vec3 edge_cliff[4];
// The tops of raised ground darker (walls paved like the floor, the temple's): 0 = none.
uniform float top_shade = 0.0;
// The tops of raised ground are walls (the ice caves): the cliff's picture on them too, seen from
// above, so the walls read as masses of ice apart from the floor.
uniform bool wall_tops = false;
// The ground's heights (HeightMap.height_texture), in the zone's own coordinates.
uniform sampler2D height_tex : filter_linear, repeat_disable;
uniform vec2 height_origin = vec2(-10.0);
uniform float height_res = 2.0;
uniform vec2 height_texels = vec2(2.0);
uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform vec2 map_tiles = vec2(40.0, 26.0);
uniform float water_level = -100.0;    // no water: far below
uniform float cliff_repeat = 2.2;      // metres per repeat of the cliff texture
uniform bool clouds = true;
uniform bool plain = false;            // indoors: an even floor, no patches, no cloud shadows
uniform float wetness = 0.0;           // rain: darker, glossier ground
uniform vec2 wind = vec2(0.3, 0.12);   // m/s
// Layers laid over the ground (Region.covers(): 0–1 per tile, their doses packed in cover_mask's
// R, G, B, read like terrain_mask), in their order. The first: its picture, a trodden trail on
// the paths, the cliffs under it (snowy rock); the others: their picture only. Not over the
// water, nor over the ice ("sand") of a cold zone (cover_spares_sand: it shows through).
uniform int cover_count = 0;
uniform sampler2D cover_mask : filter_linear, repeat_disable;
uniform bool cover_cliff = false;
uniform bool cover_spares_sand = false;

// A neighbour zone shown beyond this one's edge: its local coordinates are world - zone_offset,
// and only keep_rect is drawn (x, y, w, h in world tiles; w = 0: everything). Where a
// neighbour is shown, this zone's own ground and water are cut away (holes).
uniform vec2 zone_offset = vec2(0.0);
uniform vec4 keep_rect = vec4(0.0);
uniform vec4 holes[4];
uniform int hole_count = 0;

bool clipped(vec2 w) {
	if (keep_rect.z > 0.0 && (w.x < keep_rect.x || w.y < keep_rect.y || w.x > keep_rect.x + keep_rect.z || w.y > keep_rect.y + keep_rect.w)) {
		return true;
	}
	for (int i = 0; i < hole_count; i++) {
		vec4 h = holes[i];
		if (w.x >= h.x && w.y >= h.y && w.x <= h.x + h.z && w.y <= h.y + h.w) {
			return true;
		}
	}
	return false;
}

varying vec2 world;
varying float height;
varying vec3 wnormal;
varying float hollow;   // how much higher the ground around is (the foot of a cliff): 0–1
// The grass and cliff tints here, blended towards the neighbours' near the edges (per vertex: the
// blend spreads over tint_blend tiles, the ground's vertices are much closer).
varying vec3 grass_col;
varying vec3 cliff_col;

float h_at(vec2 w) {
	vec2 uv = ((w - zone_offset - height_origin) * height_res + 0.5) / height_texels;
	return textureLod(height_tex, uv, 0.0).r;
}

// How much of the neighbour's colour at `local` (tiles), near edge `e` (see tint_edges).
float edge_weight(vec2 local, vec4 e) {
	float d = ((e.x < 0.5 ? local.x : local.y) - e.y) * e.z;
	return 0.5 * (1.0 - smoothstep(0.0, tint_blend, d));
}

void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	grass_col = grass_tint;
	cliff_col = cliff_tint;
	for (int i = 0; i < tint_edge_count; i++) {
		float k = edge_weight(w.xz - zone_offset, tint_edges[i]);
		grass_col = mix(grass_col, edge_grass[i], k);
		cliff_col = mix(cliff_col, edge_cliff[i], k);
	}
	float h = h_at(w.xz);
	VERTEX.y = h;
	float e = 0.5 / height_res;
	vec3 n = normalize(vec3(h_at(w.xz - vec2(e, 0.0)) - h_at(w.xz + vec2(e, 0.0)), 2.0 * e,
		h_at(w.xz - vec2(0.0, e)) - h_at(w.xz + vec2(0.0, e))));
	NORMAL = n;
	float r = 0.8;
	float around = (h_at(w.xz + vec2(r, 0.0)) + h_at(w.xz - vec2(r, 0.0))
		+ h_at(w.xz + vec2(0.0, r)) + h_at(w.xz - vec2(0.0, r))) * 0.25;
	hollow = clamp((around - h) / 1.2, 0.0, 1.0);
	world = w.xz;
	height = h;
	wnormal = n;
}

float noise(vec2 p) {
	return texture(noise_tex, p).r;
}


// How covered the ground is here by a layer, from the dose `c` of its tile: x = the layer lying
// (patches first, then the whole carpet, a ragged soft edge: two scales of noise, never the
// tiles' squares; `salt` moves the patches of each layer apart); y = a light veil of it (frost,
// blown sand) already where the patches start.
vec2 cover_amount(float c, vec2 px, float grain, float salt) {
	float edge = c + (noise(px / 170.0 + salt) - 0.5) * 0.45 + grain * 0.25;
	return vec2(smoothstep(0.43, 0.57, edge), smoothstep(0.02, 0.55, c) * 0.28);
}

// Lays a layer of picture `lay` over `col` by the amounts `a` (cover_amount).
vec3 lay_cover(vec3 col, vec3 lay, vec2 a) {
	return mix(mix(col, lay, a.y), lay, a.x);
}

// A cliff's face from `tex` at `w` (world, m), `h` high, on the wall's own axis (x or z), at its
// real size.
vec3 cliff_face(float layer, vec2 w, float h, float side) {
	vec3 face_z = texture(materials, vec3(vec2(w.x, -h) / cliff_repeat, layer)).rgb;
	vec3 face_x = texture(materials, vec3(vec2(w.y, -h) / cliff_repeat, layer)).rgb;
	return mix(face_z, face_x, side);
}

void fragment() {
	if (clipped(world)) {
		discard;
	}
	vec2 local = world - zone_offset;
	vec2 px = world * 48.0;   // the 2D pixel scale, so the 2D look carries over
	vec2 warp = vec2(noise(px / 210.0), noise(px / 210.0 + vec2(0.37, 0.61))) - 0.5;
	float grain = noise(px / 70.0) - 0.5;
	vec4 m = texture(terrain_mask, (local + warp * 0.9) / map_tiles);

	float patches = noise(px / 900.0);
	vec3 grass = texture(materials, vec3(px / 320.0, MAT_GRASS)).rgb * grass_col * (plain ? 1.0 : mix(0.84, 1.1, patches));
	grass = mix(grass, grass * vec3(0.78, 0.86, 0.72), smoothstep(0.3, 0.7, m.g));

	vec3 dirt = texture(materials, vec3(px / 256.0, MAT_DIRT)).rgb;
	if (paved_rect.z > 0.0) {
		vec2 d = max(paved_rect.xy - local, local - (paved_rect.xy + paved_rect.zw));
		float inside = 1.0 - smoothstep(-0.4, 0.4, max(d.x, d.y) + grain * 0.6);
		dirt = mix(dirt, texture(materials, vec3(px / 256.0, MAT_PAVED)).rgb, inside);
	}
	// Sand (beaches) and the dark mossy floor under the woods.
	vec4 m2 = texture(terrain_mask2, (local + warp * 0.9) / map_tiles);
	float sandy = smoothstep(0.35, 0.65, m2.r + grain * 0.3);
	vec3 sand_col = dirt * vec3(1.18, 1.08, 0.82) + 0.06;
	if (sand_picture) {
		// Dunes: the ripples of the picture, broad lighter and darker drifts over them, the
		// hollows between the dunes warmer and darker, their crests pale.
		sand_col = texture(materials, vec3(px / 300.0, MAT_SAND)).rgb * mix(0.88, 1.06, patches) * mix(0.95, 1.03, noise(px / 520.0));
		if (!sand_is_ice) {
			sand_col *= mix(vec3(0.9, 0.83, 0.74), vec3(1.05), smoothstep(0.0, 1.2, height));
		}
		// A sandy land: no grass under the edges of the rock, the mud, the trails.
		sandy = max(sandy, smoothstep(0.15, 0.5, m2.r + m2.b + m2.a + grain * 0.2));
	}
	grass = mix(grass, sand_col, sandy);
	grass = mix(grass, grass * vec3(0.55, 0.66, 0.5), smoothstep(0.3, 0.7, m2.g));
	if (m2.b > 0.01) {
		float muddy = smoothstep(0.3, 0.6, m2.b + grain * 0.3);
		grass = mix(grass, texture(materials, vec3(px / 300.0, MAT_MUD)).rgb * (plain ? 1.0 : mix(0.9, 1.06, patches)), muddy);
	}
	if (m2.a > 0.01) {
		float rocky = smoothstep(0.3, 0.6, m2.a + grain * 0.3);
		grass = mix(grass, texture(materials, vec3(px / 340.0, MAT_ROCK)).rgb * (plain ? 1.0 : mix(0.88, 1.06, patches)), rocky);
	}
	float p = m.r + grain * 0.22;
	float path = smoothstep(0.46, 0.56, p);
	float rim = smoothstep(0.32, 0.48, p) * (1.0 - path);
	vec3 col = mix(grass, dirt, path);
	float covered = 0.0;   // the first layer lying here (the cliffs follow it)
	if (cover_count > 0) {
		vec3 doses = texture(cover_mask, (local + warp * 0.9) / map_tiles).rgb;
		float shade = plain ? 1.0 : mix(0.93, 1.04, patches);
		vec2 a = cover_amount(doses.r, px, grain, 0.0);
		covered = a.x;
		if (doses.r > 0.0) {
			vec3 lay = texture(materials, vec3(px / 320.0, MAT_COVER)).rgb * shade;
			col = lay_cover(col, mix(lay, texture(materials, vec3(px / 256.0, MAT_COVER_PATH)).rgb, path * a.x), a);
		}
		if (cover_count > 1 && doses.g > 0.0) {
			col = lay_cover(col, texture(materials, vec3(px / 320.0, MAT_COVER1)).rgb * shade, cover_amount(doses.g, px, grain, 0.31));
		}
		if (cover_count > 2 && doses.b > 0.0) {
			col = lay_cover(col, texture(materials, vec3(px / 320.0, MAT_COVER2)).rgb * shade, cover_amount(doses.b, px, grain, 0.67));
		}
		if (cover_spares_sand) {
			// A cold zone's ice shows through: straight from the snow to the ice, no ground between.
			col = mix(col, sand_col, sandy);
		}
	}
	col *= 1.0 - rim * 0.22 * (1.0 - covered * 0.5);

	// Water's edge, from the real height: wet sand just above the water, dark bed below.
	float wet = smoothstep(water_level + 0.2, water_level + 0.02, height + grain * 0.04);
	vec3 sand = dirt * vec3(0.92, 0.86, 0.72);
	col = mix(col, sand * 0.78, wet);
	col = mix(col, vec3(0.05, 0.15, 0.16), 0.85 * smoothstep(water_level, water_level - 0.35, height));

	// Cliffs: the earth wall texture on the wall's own axis (x or z), at its real size.
	vec3 n = normalize(wnormal);
	float slope = 1.0 - n.y;
	float rock = smoothstep(0.35, 0.6, slope);
	if (rock > 0.0) {
		float side = smoothstep(0.3, 0.7, abs(n.x) / (abs(n.x) + abs(n.z) + 0.0001));
		vec3 face = cliff_face(MAT_CLIFF, world, height, side);
		if (cover_cliff && covered > 0.0) {
			face = mix(face, cliff_face(MAT_COVER_CLIFF, world, height, side), covered);
		}
		// Rock, not earth: greyer and darker than the paths, so the two never mix up.
		float lum = dot(face, vec3(0.3, 0.55, 0.15));
		face = mix(face, vec3(lum) * vec3(1.0, 0.95, 0.9), 0.4) * 0.82 * cliff_col;
		// A little darker towards the foot, in the shade of the overhang.
		face *= mix(0.78, 1.0, smoothstep(-0.2, 0.9, fract(height / 1.2 + 0.001)));
		col = mix(col, face, rock);
	}
	float top = smoothstep(0.45, 1.0, height) * (1.0 - rock);
	if (wall_tops) {
		vec3 mass = texture(materials, vec3(world / cliff_repeat, MAT_CLIFF)).rgb;
		float lum = dot(mass, vec3(0.3, 0.55, 0.15));
		col = mix(col, mix(mass, vec3(lum), 0.4) * 0.82 * cliff_tint, top);
	}
	// Walls paved like the floor: their tops darker than the rooms (not their lit faces).
	col *= 1.0 - top_shade * top;
	// The ground at the foot of a wall is in its shade: a dark line marks where the wall stands.
	col *= 1.0 - 0.45 * smoothstep(0.05, 0.5, hollow) * (1.0 - rock * 0.5);

	if (clouds && !plain) {
		float cloud = noise((world - wind * TIME) / 23.0);
		col *= 1.0 - 0.16 * smoothstep(0.55, 0.75, cloud);
	}
	col *= 1.0 - 0.22 * wetness;
	ALBEDO = col;
	ROUGHNESS = mix(0.95, 0.55, wetness);
}
