// A sheet of water over the dug-in ground (ponds, coves). It reads the ground's height to
// know how deep it is everywhere: clear and light in the shallows, dark and opaque in the
// deep, with a line of foam lapping exactly along the shore.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform sampler2D ground_height : filter_linear, repeat_disable;
uniform vec2 height_origin = vec2(-10.0);
uniform float height_res = 2.0;
uniform vec2 height_texels = vec2(241.0);
uniform float water_level = -0.42;
uniform vec4 shallow : source_color = vec4(0.36, 0.64, 0.62, 1.0);
uniform vec4 deep : source_color = vec4(0.07, 0.22, 0.32, 1.0);
uniform vec4 foam : source_color = vec4(0.95, 0.97, 0.9, 1.0);
// Near an edge leading to a zone whose water is of another colour (WorldView.TINT_BLEND): its
// shades, half and half at the edge (see ground.gdshader's tint_edges).
uniform int tint_edge_count = 0;
uniform float tint_blend = 12.0;
uniform vec4 tint_edges[4];
uniform vec4 edge_shallow[4] : source_color;
uniform vec4 edge_deep[4] : source_color;

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

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

float ground_at(vec2 w) {
	vec2 uv = ((w - height_origin) * height_res + 0.5) / height_texels;
	return texture(ground_height, uv).r;
}

void fragment() {
	if (clipped(world)) {
		discard;
	}
	float depth = water_level - ground_at(world - zone_offset);
	vec2 flow = world / 3.3 + vec2(TIME * 0.02, TIME * 0.013);
	float n1 = texture(noise_tex, flow).r;
	float n2 = texture(noise_tex, flow * 2.3 - vec2(TIME * 0.03, 0.0)).r;
	float d = clamp(depth / 0.45, 0.0, 1.0);
	vec3 light = shallow.rgb;
	vec3 dark = deep.rgb;
	vec2 local = world - zone_offset;
	for (int i = 0; i < tint_edge_count; i++) {
		vec4 e = tint_edges[i];
		float k = 0.5 * (1.0 - smoothstep(0.0, tint_blend, ((e.x < 0.5 ? local.x : local.y) - e.y) * e.z));
		light = mix(light, edge_shallow[i].rgb, k);
		dark = mix(dark, edge_deep[i].rgb, k);
	}
	vec3 col = mix(light, dark, smoothstep(0.0, 1.0, d) * (0.85 + 0.3 * (n1 - 0.5)));
	// Foam lapping the shore: a thin band where the water is shallowest, breathing slowly.
	float lap = 0.05 + 0.035 * sin(TIME * 1.4 + (world.x + world.y) * 1.3) + 0.03 * n2;
	float froth = 1.0 - smoothstep(0.0, lap, depth);
	froth *= 0.55 + 0.45 * smoothstep(0.35, 0.7, texture(noise_tex, world / 1.2 + vec2(TIME * 0.04)).r);
	col = mix(col, foam.rgb, froth * 0.8);
	ALBEDO = col;
	ALPHA = max(mix(0.3, 0.86, d), froth * 0.85);
	ROUGHNESS = 0.06;
	SPECULAR = 0.7;
	NORMAL_MAP = vec3(0.5 + (n1 - 0.5) * 0.5, 0.5 + (n2 - 0.5) * 0.5, 1.0);
}
