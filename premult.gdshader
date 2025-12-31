shader_type canvas_item;
render_mode blend_premul_alpha;

void fragment() {
	float a = COLOR.a / texture(TEXTURE, UV).a;
	COLOR.rgb *= a;
}
