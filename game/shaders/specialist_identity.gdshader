shader_type canvas_item;
uniform vec4 sector_color : source_color = vec4(1.0, 0.8, 0.2, 1.0);
uniform vec4 atlas_rect = vec4(0.0, 0.0, 0.2, 0.5);
uniform float clothing_hue = 0.09;
uniform bool warm_clothing = true;
uniform bool revealed = true;
uniform bool flat_pending = false;
uniform float pending_tint;
varying vec4 vertex_color;

vec3 rgb_to_hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + 0.00001)), d / (q.x + 0.00001), q.x);
}

void vertex() { vertex_color = COLOR; }

void fragment() {
    vec4 portrait = texture(TEXTURE, UV);
    vec2 local_uv = (UV - atlas_rect.xy) / atlas_rect.zw;
    vec3 hsv = rgb_to_hsv(portrait.rgb);
    float hue_distance = abs(hsv.x - clothing_hue);
    hue_distance = min(hue_distance, 1.0 - hue_distance);
    float chroma = smoothstep(0.16, 0.34, hsv.y) * smoothstep(0.10, 0.26, hsv.z);
    // Helmet crown excludes the face. Highly saturated brims extend the mask.
    float helmet = 1.0 - smoothstep(0.31, 0.335, local_uv.y);
    helmet = max(helmet, (1.0 - smoothstep(0.37, 0.40, local_uv.y)) * smoothstep(0.72, 0.85, hsv.y));
    float clothes = smoothstep(0.74, 0.78, local_uv.y) * (1.0 - smoothstep(0.07, 0.12, hue_distance));
    // Orange PPE shares skin hues: protect the central neck explicitly.
    if (warm_clothing) {
        clothes *= max(smoothstep(0.17, 0.23, abs(local_uv.x - 0.5)), smoothstep(0.84, 0.88, local_uv.y));
    }
    float mask = clamp(max(helmet, clothes) * chroma, 0.0, 1.0);
    vec3 dyed = sector_color.rgb * (0.24 + hsv.z * 0.88) + vec3(pow(hsv.z, 7.0) * 0.16);
    portrait.rgb = mix(portrait.rgb, dyed, mask);
    if (!revealed) {
        float lighting = 0.75 + dot(portrait.rgb, vec3(0.299, 0.587, 0.114)) * 0.35;
        portrait = vec4(sector_color.rgb * 0.50 * lighting, portrait.a * 0.80);
        if (flat_pending) {
            portrait = vec4(sector_color.rgb * pending_tint,step(0.12,portrait.a));
        }
    }
    COLOR = portrait * vertex_color;
}
