shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;

void fragment() {
	vec2 uv = UV * vec2(52.0, 16.0);
	float wire_a = abs(fract(uv.x + uv.y) - 0.5);
	float wire_b = abs(fract(uv.x - uv.y) - 0.5);
	float wire = min(wire_a,wire_b);
	ALBEDO = vec3(0.26,0.31,0.29);
	METALLIC = 0.52;
	ROUGHNESS = 0.61;
	ALPHA = 1.0 - smoothstep(0.060,0.105,wire);
	ALPHA_SCISSOR_THRESHOLD = 0.31;
}
