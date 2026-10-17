shader_type canvas_item;
render_mode unshaded;
uniform float breath = 0.0;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f*f*(3.0-2.0*f);
	return mix(mix(hash(i), hash(i+vec2(1,0)), f.x), mix(hash(i+vec2(0,1)), hash(i+vec2(1,1)), f.x), f.y);
}
void fragment() {
	vec2 uv = UV;
	float fibers = noise(uv * vec2(510.0, 760.0));
	float cloud = noise(uv * 4.0 + vec2(breath * 0.015, 0.0));
	float edge = smoothstep(0.22, 0.8, distance(uv, vec2(0.48,0.46)));
	vec3 paper = mix(vec3(0.943, 0.924, 0.868), vec3(0.785, 0.794, 0.734), edge * 0.42 + cloud * 0.12);
	paper += (fibers - 0.5) * 0.028;
	float light = exp(-length((uv - vec2(0.37,0.3)) * vec2(1.4,1.0)) * 3.0);
	paper += light * 0.028;
	COLOR = vec4(paper, 1.0);
}
