shader_type spatial;

uniform sampler2D earth : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D turf : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
varying vec3 world;

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 grit = texture(earth, world.xz / 5.0).rgb;
	vec3 lawn = texture(turf, world.xz / 2.0).rgb;
	float patches = sin(world.x * 0.23 + sin(world.z * 0.14)) * cos(world.z * 0.28);
	float grain = 0.83 + grit.g * 0.44 + patches * 0.06;
	ALBEDO = mix(COLOR.rgb * grain, lawn * vec3(0.70,0.72,0.57), 0.66);
	ROUGHNESS = 0.93;
}
