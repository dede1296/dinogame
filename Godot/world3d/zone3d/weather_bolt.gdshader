// A bolt of lightning (WeatherLightning): ribbons turned to the camera, a white core and a pale blue
// halo around it (the vertex colour), added to the sky, no fog (it is seen through the storm), as bright
// as the flash is. The ribbon's edges are soft: UV.x = 0 on one side, 1 on the other.
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, fog_disabled;

uniform float intensity : hint_range(0.0, 2.0) = 1.0;

void fragment() {
	float side = 1.0 - pow(abs(UV.x * 2.0 - 1.0), 1.6);
	ALBEDO = COLOR.rgb * intensity;
	ALPHA = clamp(COLOR.a * side * intensity, 0.0, 1.0);
}
