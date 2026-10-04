shader_type spatial;
// The water of a 3D zone (docs/migration-3d.md, phase 4): one sheet at the 2.5D's water level, seen
// only where the ground is dug below it (ponds, the sea). Its shade comes from the depth of the bed
// (the 2.5D relief, HeightMap.height_texture, in tiles): clear and green-blue at the shore, deep
// blue further out, small moving ripples and a light rim at the shore.

render_mode cull_disabled, depth_draw_always, specular_schlick_ggx;

uniform sampler2D ground_height : filter_linear, repeat_disable;
uniform vec2 height_origin = vec2(-10.0);   // tiles
uniform float height_res = 2.0;             // samples per tile
uniform vec2 height_texels = vec2(2.0);
uniform float tile_m = 2.0;
uniform float water_level = -0.425;
uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform vec3 shallow : source_color = vec3(0.35, 0.62, 0.58);
uniform vec3 deep : source_color = vec3(0.08, 0.28, 0.42);

varying vec3 world;

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float ground_at(vec2 w) {
	vec2 t = w / tile_m;
	return textureLod(ground_height, ((t - height_origin) * height_res + 0.5) / height_texels, 0.0).r;
}

void fragment() {
	float depth = water_level - ground_at(world.xz);
	if (depth < -0.02) {
		discard;   // ground above the water here
	}
	float d = clamp(depth / 0.9, 0.0, 1.0);
	vec2 flow = vec2(TIME * 0.02, TIME * 0.013);
	float r1 = texture(noise_tex, world.xz / 9.0 + flow).r;
	float r2 = texture(noise_tex, world.xz / 4.0 - flow * 1.7).r;
	float ripple = r1 * 0.6 + r2 * 0.4;
	vec3 col = mix(shallow, deep, smoothstep(0.0, 1.0, d));
	col *= mix(0.92, 1.08, ripple);
	float rim = 1.0 - smoothstep(0.0, 0.08, depth);
	col = mix(col, vec3(0.86, 0.92, 0.86), rim * 0.55);
	ALBEDO = col;
	ROUGHNESS = 0.08;
	METALLIC = 0.0;
	SPECULAR = 0.6;
	NORMAL_MAP = normalize(vec3(r1 - 0.5, r2 - 0.5, 1.6)) * 0.5 + 0.5;
	ALPHA = mix(0.55, 0.9, d) + rim * 0.2;
}
