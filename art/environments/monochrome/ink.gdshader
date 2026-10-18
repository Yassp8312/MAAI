shader_type canvas_item;
uniform float clarity = 0.16;
void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float gray = dot(tex.rgb, vec3(0.2126, 0.7152, 0.0722));
	float center = smoothstep(0.02, 0.25, UV.x) * (1.0 - smoothstep(0.75, 0.98, UV.x));
	float band = smoothstep(0.24, 0.42, UV.y) * (1.0 - smoothstep(0.76, 0.80, UV.y));
	gray = mix(gray, 0.92, center * band * clarity);
	COLOR = vec4(vec3(gray), tex.a);
}
