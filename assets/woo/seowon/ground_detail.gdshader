shader_type canvas_item;
// 월하의 서원 바닥: 베이크한 색·조명 위에 1:1 결 타일을 얹어
// 줌 1.90에서도 돌결·잔디결이 뭉개지지 않게 한다.
// 타일은 거울 반복(mirror)을 서로 다른 배율로 두 번 곱해 대칭 무늬를 지운다.
uniform sampler2D mask_tex : filter_linear, repeat_disable;
uniform sampler2D grass_tex : filter_linear, repeat_disable;
uniform sampler2D stone_tex : filter_linear, repeat_disable;
uniform sampler2D yard_tex : filter_linear, repeat_disable;
uniform vec2 world_size = vec2(3400.0, 2600.0);
uniform float grass_tile = 200.0;
uniform float stone_tile = 180.0;
uniform float strength = 0.80;

vec2 mirror_uv(vec2 uv) {
	vec2 m = mod(uv, 2.0);
	return mix(m, 2.0 - m, step(1.0, m));
}

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	vec4 mask = texture(mask_tex, UV);
	vec2 w = UV * world_size;
	vec3 g1 = texture(grass_tex, mirror_uv(w / grass_tile)).rgb * 2.0;
	vec3 g2 = texture(grass_tex, mirror_uv(w / (grass_tile * 0.61) + vec2(0.43, 0.17))).rgb * 2.0;
	vec3 s1 = texture(stone_tex, mirror_uv(w / stone_tile + vec2(0.37, 0.19))).rgb * 2.0;
	vec3 s2 = texture(stone_tex, mirror_uv(w / (stone_tile * 0.53) + vec2(0.13, 0.61))).rgb * 2.0;
	vec3 y1 = texture(yard_tex, mirror_uv(w / (stone_tile * 1.4) + vec2(0.71, 0.53))).rgb * 2.0;
	vec3 grass = mix(vec3(1.0), g1 * g2, 0.65);
	vec3 stone = mix(vec3(1.0), s1 * s2, 0.55);
	vec3 yard = mix(vec3(1.0), y1, 0.40);
	vec3 detail = mix(grass, yard, mask.g);
	detail = mix(detail, stone, mask.r);
	vec3 col = base.rgb * mix(vec3(1.0), detail, strength);
	COLOR = vec4(col, 1.0);
}
