shader_type canvas_item;

uniform sampler2D alpha_texture;
uniform float t;
uniform float r;

void fragment() {
	float a = texture(alpha_texture, UV).a;
	COLOR.a *= clamp(1.0 + a * r - (1.0 + r) * t, 0.0, 1.0);
}
