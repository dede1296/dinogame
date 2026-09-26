// Painted ground of a region, drawn in one pass from the region's terrain layer.
// terrain_mask has one pixel per tile (R = path, G = tall grass, B = water); sampled with
// linear filtering and warped by noise, its edges become soft organic shapes.
shader_type canvas_item;

uniform sampler2D grass_tex : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D dirt_tex : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D terrain_mask : filter_linear;
uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform vec2 map_tiles = vec2(40.0, 26.0);
uniform float tile_px = 48.0;
// World pixels covered by one repeat of the ground textures.
uniform float texture_px = 320.0;
uniform vec4 water_deep : source_color = vec4(0.13, 0.38, 0.47, 1.0);
uniform vec4 water_shallow : source_color = vec4(0.33, 0.62, 0.62, 1.0);
uniform vec4 foam : source_color = vec4(0.93, 0.95, 0.86, 1.0);

varying vec2 world;

void vertex() {
	world = VERTEX;
}

float noise(vec2 p) {
	return texture(noise_tex, p).r;
}

void fragment() {
	vec2 tile = world / tile_px;
	vec2 warp = vec2(noise(world / 210.0), noise(world / 210.0 + vec2(0.37, 0.61))) - 0.5;
	float grain = noise(world / 70.0) - 0.5;
	vec4 m = texture(terrain_mask, (tile + warp * 0.9) / map_tiles);

	// Grass, with large lighter/darker patches so the texture repeat does not show.
	float patches = noise(world / 900.0);
	vec3 grass = texture(grass_tex, world / texture_px).rgb * mix(0.84, 1.1, patches);
	// Lusher, darker ground under the tall grass.
	grass = mix(grass, grass * vec3(0.78, 0.86, 0.72), smoothstep(0.3, 0.7, m.g));

	// Dirt paths with a slightly darker trodden rim.
	vec3 dirt = texture(dirt_tex, world / (texture_px * 0.8)).rgb;
	float p = m.r + grain * 0.22;
	float path = smoothstep(0.46, 0.56, p);
	float rim = smoothstep(0.32, 0.48, p) * (1.0 - path);
	vec3 col = mix(grass, dirt, path);
	col *= 1.0 - rim * 0.22;

	// Water: depth from the mask, animated ripples, a foam line and a wet dark shore.
	float wv = m.b + grain * 0.12;
	float water = smoothstep(0.48, 0.53, wv);
	float depth = smoothstep(0.5, 0.95, wv);
	vec2 flow = world / 160.0 + vec2(TIME * 0.02, TIME * 0.013);
	float ripple = noise(flow) * 0.6 + noise(flow * 2.3 - vec2(TIME * 0.03, 0.0)) * 0.4;
	vec3 wcol = mix(water_shallow.rgb, water_deep.rgb, depth);
	wcol += smoothstep(0.62, 0.8, ripple) * 0.12;
	float glint = smoothstep(0.83, 0.9, noise(world / 45.0 + vec2(TIME * 0.05, -TIME * 0.04)));
	wcol += glint * 0.35 * depth;
	float shore = smoothstep(0.36, 0.48, wv) * (1.0 - water);
	col *= 1.0 - shore * 0.3;
	float foam_line = smoothstep(0.47, 0.5, wv) * (1.0 - smoothstep(0.52, 0.56, wv));
	foam_line *= 0.55 + 0.45 * sin(TIME * 1.6 + (world.x + world.y) * 0.05);
	col = mix(col, wcol, water);
	col = mix(col, foam.rgb, foam_line * 0.7);

	COLOR = vec4(col, 1.0);
}
