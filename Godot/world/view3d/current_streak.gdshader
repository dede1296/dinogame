// A streak of water rushing along a current (SeaFeatures): a thin line of light lying along
// `flow`, always turned towards the camera around it, fading at both ends. Drawn on particles:
// each one's colour (its fade) comes in COLOR.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled, skip_vertex_transform;

uniform vec3 flow = vec3(1.0, 0.0, 0.0);
uniform float streak_length = 0.9;
uniform float streak_width = 0.045;
uniform vec4 colour : source_color = vec4(0.8, 0.95, 1.0, 0.7);

void vertex() {
	vec3 centre = MODEL_MATRIX[3].xyz;
	vec3 axis = normalize(flow);
	vec3 to_cam = normalize(CAMERA_POSITION_WORLD - centre);
	vec3 side = normalize(cross(axis, to_cam));
	vec3 world = centre + axis * VERTEX.y * streak_length + side * VERTEX.x * streak_width;
	VERTEX = (VIEW_MATRIX * vec4(world, 1.0)).xyz;
	NORMAL = vec3(0.0, 0.0, 1.0);
}

void fragment() {
	float along = 1.0 - abs(UV.y * 2.0 - 1.0);
	float across = 1.0 - abs(UV.x * 2.0 - 1.0);
	ALBEDO = colour.rgb * COLOR.rgb;
	ALPHA = clamp(smoothstep(0.0, 0.7, along) * smoothstep(0.0, 0.9, across) * COLOR.a * colour.a, 0.0, 1.0);
}
