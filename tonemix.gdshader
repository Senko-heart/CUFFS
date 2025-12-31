shader_type canvas_item;

uniform sampler2D old_tone_tables;
uniform bool old_yuv_filter;
uniform sampler2D tone_tables;
uniform bool yuv_filter;
uniform float t;

vec4 tonemapping(vec4 color, sampler2D tables, bool yuv) {
	if (yuv) {
		mat3 rgb2yuv = mat3(
			vec3(0.299, 0.587, 0.114),
			vec3(-0.168736, -0.331264, 0.5),
			vec3(0.5, -0.418688, -0.081312)
		);
		color.brg *= rgb2yuv;
		color.yx += vec2(0.5, 0.5);
	}
	color.r = texture(tables, vec2(color.r, 0)).r;
	color.g = texture(tables, vec2(color.g, 0)).g;
	color.b = texture(tables, vec2(color.b, 0)).b;
	color.a = texture(tables, vec2(color.a, 0)).a;
	if (yuv) {
		color.yx -= vec2(0.5, 0.5);
		mat3 yuv2rgb = mat3(
			vec3(1.0, 0.0, 1.402),
			vec3(1.0, -0.344136, -0.714136),
			vec3(1.0, 1.772, 0.0)
		);
		color.brg *= yuv2rgb;
	}
	return color;
}

void fragment() {
	vec4 target_color = tonemapping(COLOR, tone_tables, yuv_filter);
	if (t < 1.0) {
		vec4 old_color = tonemapping(COLOR, old_tone_tables, old_yuv_filter);
		COLOR = mix(old_color, target_color, t);
	} else {
		COLOR = target_color;
	}
}
