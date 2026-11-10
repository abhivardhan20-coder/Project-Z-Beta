shader_type sky;

uniform sampler2D cloud_density : repeat_enable, filter_linear_mipmap;

void sky() {
	float height = max(EYEDIR.y, 0.0);
	vec3 horizon = vec3(0.61, 0.67, 0.71);
	vec3 zenith = vec3(0.13, 0.24, 0.39);
	vec3 air = mix(horizon, zenith, pow(height, 0.49));
	vec2 uv = EYEDIR.xz / (0.43 + height) * 0.54;
	float coarse = texture(cloud_density, uv + vec2(0.18, 0.27)).r;
	float fine = texture(cloud_density, uv * 2.7 - vec2(0.06, 0.14)).r;
	float clouds = smoothstep(0.43, 0.69, coarse * 0.78 + fine * 0.22);
	vec3 cloud_color = mix(vec3(0.39, 0.44, 0.51), vec3(0.80, 0.80, 0.75), fine);
	COLOR = mix(air, cloud_color, clouds * smoothstep(0.0, 0.18, height) * 0.83);
	if (EYEDIR.y < 0.0) {
		COLOR = mix(horizon, vec3(0.25, 0.30, 0.30), -EYEDIR.y);
	}
}
