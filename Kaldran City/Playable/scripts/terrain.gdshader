shader_type spatial;
render_mode cull_back;

uniform sampler2D aggregate : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 grit = texture(aggregate, world_position.xz / 6.0).rgb;
	float detail = mix(1.0, 0.70 + grit.g * 0.70, 0.58);
	ALBEDO = COLOR.rgb * detail;
	ROUGHNESS = 0.93;
}
