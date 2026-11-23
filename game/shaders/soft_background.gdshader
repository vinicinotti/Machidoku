shader_type canvas_item;
varying vec4 base_color;
void vertex() {
    base_color = COLOR;
}
void fragment() {
    // Fixed 3x3 kernel avoids the block pattern of a coarse mip by itself.
    vec2 step_uv = TEXTURE_PIXEL_SIZE * 3.0;
    vec4 soft = textureLod(TEXTURE,UV,1.0) * 0.25;
    soft += textureLod(TEXTURE,UV+vec2(step_uv.x,0.0),1.0) * 0.125;
    soft += textureLod(TEXTURE,UV-vec2(step_uv.x,0.0),1.0) * 0.125;
    soft += textureLod(TEXTURE,UV+vec2(0.0,step_uv.y),1.0) * 0.125;
    soft += textureLod(TEXTURE,UV-vec2(0.0,step_uv.y),1.0) * 0.125;
    soft += textureLod(TEXTURE,UV+step_uv,1.0) * 0.0625;
    soft += textureLod(TEXTURE,UV-step_uv,1.0) * 0.0625;
    soft += textureLod(TEXTURE,UV+vec2(step_uv.x,-step_uv.y),1.0) * 0.0625;
    soft += textureLod(TEXTURE,UV+vec2(-step_uv.x,step_uv.y),1.0) * 0.0625;
    COLOR = base_color * soft;
}
