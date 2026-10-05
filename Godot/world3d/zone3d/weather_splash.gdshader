// The splashes of the rain on the ground (WeatherRain): a flat ring that spreads out and fades where a
// drop lands, in the cartoon's flat white. Like weather_rain.gdshader it is all worked out on the GPU
// from the zone's height map: each splash lives in a cycle of its own (a few tenths of a second of
// ring, then a pause), and at each new cycle it lands somewhere else in the box around Chloé, on
// the ground (or the pond's surface) of that spot.
// Per instance (INSTANCE_CUSTOM): x = its seed, y = its phase in the cycle, z = how long its cycle
// is (0..1), w = its rank (0..1): it only shows while `density` is above it.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix;

uniform sampler2D height_tex : filter_linear, repeat_disable;
uniform vec2 height_origin = vec2(0.0);
uniform vec2 height_size = vec2(1.0);
uniform sampler2D cover_tex : filter_linear, repeat_disable;   // R: under a tree's crown (0–1)
uniform vec3 center = vec3(0.0);
uniform float box = 22.0;
uniform float density : hint_range(0.0, 1.0) = 0.5;
uniform float life = 0.32;          // how long a ring lasts (s)
uniform float ring_size = 0.5;      // its largest diameter (m)
uniform vec4 color : source_color = vec4(0.95, 0.98, 1.0, 1.0);

varying float v_age;
varying float v_fade;

vec2 hash22(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.xx + p3.yz) * p3.zy);
}

void vertex() {
	vec4 c = INSTANCE_CUSTOM;
	float period = 0.45 + c.z * 0.5;
	float cycle = TIME / period + c.y * 17.0;
	float age = fract(cycle) * period;
	vec2 col = hash22(vec2(c.x * 91.7, floor(cycle) * 0.754 + c.x * 13.1)) * box;
	float half_box = box * 0.5;
	vec2 rel = mod(col - center.xz + vec2(half_box), vec2(box)) - vec2(half_box);
	vec2 at = center.xz + rel;
	float ground = textureLod(height_tex, (at - height_origin + vec2(0.5)) / height_size, 0.0).r;
	// under a crown no ring, except now and then along its rim: the drip line (water running off the leaves)
	float cover = textureLod(cover_tex, (at - height_origin) / height_size, 0.0).r;
	float dripping = step(0.5, cover) * step(cover, 0.85) * step(fract(c.x * 37.1), 0.3);
	float open = 1.0 - step(0.5, cover);
	float alive = step(age, life) * step(c.w, density) * max(open, dripping);
	v_age = age / life;
	v_fade = 1.0 - smoothstep(0.55, 1.0, length(rel) / half_box);
	float size = ring_size * (0.7 + 0.5 * fract(c.x * 13.7));
	vec3 world = vec3(at.x, ground + 0.035, at.y) + vec3(VERTEX.x * size, 0.0, VERTEX.z * size);
	POSITION = alive > 0.5 ? PROJECTION_MATRIX * (VIEW_MATRIX * vec4(world, 1.0)) : vec4(0.0, 0.0, -2.0, 1.0);
}

void fragment() {
	float r = length(UV - vec2(0.5)) * 2.0;
	float grow = 1.0 - pow(1.0 - v_age, 2.5);                  // fast at first, then slows
	float radius = mix(0.12, 0.95, grow);
	float width = mix(0.2, 0.08, v_age);
	float ring = smoothstep(radius - width, radius - width * 0.4, r) * (1.0 - smoothstep(radius - width * 0.2, radius, r));
	// a small pop at the very middle as the drop lands
	float pop = (1.0 - smoothstep(0.0, 0.3, v_age)) * (1.0 - smoothstep(0.0, 0.22, r));
	float a = max(ring * (1.0 - v_age), pop * 0.8);
	if (a < 0.02) {
		discard;
	}
	ALBEDO = color.rgb;
	ALPHA = color.a * a * v_fade;
}
