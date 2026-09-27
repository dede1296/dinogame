// Flood water filling a passage (world/flood.gd): a block of water standing on the floor,
// `height` metres high (it lowers as the water drains away). Its top ripples like the ponds'
// water, with a line of foam along its edges; its sides are darker towards the floor, a
// brighter band just under the surface.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform vec4 shallow : source_color = vec4(0.34, 0.62, 0.62, 1.0);
uniform vec4 deep : source_color = vec4(0.06, 0.21, 0.3, 1.0);
uniform vec4 foam : source_color = vec4(0.94, 0.97, 0.9, 1.0);
uniform vec2 half_size = vec2(2.0, 1.5);   // metres, the block seen from above
uniform float height = 1.0;                // metres of water now

varying vec3 world;
varying vec3 local;
varying float top;

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	local = VERTEX;
	top = NORMAL.y > 0.5 ? 1.0 : 0.0;
}

void fragment() {
	vec2 flow = world.xz / 3.3 + vec2(TIME * 0.02, TIME * 0.013);
	float n1 = texture(noise_tex, flow).r;
	float n2 = texture(noise_tex, flow * 2.3 - vec2(TIME * 0.03, 0.0)).r;
	vec3 col;
	float alpha;
	if (top > 0.5) {
		// The surface, flush with the floor: dark and opaque while the water is deep (the
		// floor is far below), clearer as it drains; foam lapping along its edges.
		float deepness = smoothstep(0.05, 0.9, height);
		col = mix(shallow.rgb, deep.rgb, deepness * (0.85 + 0.3 * (n1 - 0.5)));
		vec2 edge = half_size - abs(local.xz);
		float from_edge = min(edge.x, edge.y);
		float lap = 0.12 + 0.05 * sin(TIME * 1.4 + (world.x + world.z) * 1.3) + 0.04 * n2;
		float froth = 1.0 - smoothstep(0.0, lap, from_edge);
		col = mix(col, foam.rgb, froth * 0.75);
		alpha = max(mix(0.3, 0.95, deepness), froth * 0.9);
	} else {
		// The sides: from the floor (dark) up to just under the surface (brighter), foam on top.
		float up = clamp(local.y + 0.5, 0.0, 1.0);   // 0 at the floor, 1 at the surface
		col = mix(deep.rgb * 0.8, shallow.rgb, pow(up, 2.0) * 0.8 + 0.1 * (n1 - 0.5));
		float line = smoothstep(1.0 - 0.06 / max(height, 0.06), 1.0, up + 0.02 * sin(TIME * 2.0 + world.x * 3.0));
		col = mix(col, foam.rgb, line * 0.8);
		alpha = 0.88;
	}
	ALBEDO = col;
	ALPHA = alpha;
	ROUGHNESS = 0.08;
	SPECULAR = 0.6;
	NORMAL_MAP = vec3(0.5 + (n1 - 0.5) * 0.4, 0.5 + (n2 - 0.5) * 0.4, 1.0);
}
