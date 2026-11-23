shader_type canvas_item;
// One quad, no texture reads, no time uniform: rounded moulded tile with bevel.
uniform vec4 sector : source_color = vec4(1.0,0.8,0.2,1.0);
uniform vec2 extent = vec2(96.0);
float rounded_box(vec2 p, vec2 half_size, float radius) {
    vec2 q = abs(p) - half_size + radius;
    return length(max(q,0.0)) + min(max(q.x,q.y),0.0) - radius;
}
void fragment() {
    vec4 tint = COLOR;
    vec2 p = UV * extent;
    vec2 half_size = (extent - vec2(4.0,8.0)) * 0.5;
    vec2 center = vec2(extent.x * 0.5,extent.y * 0.5 - 2.0);
    float radius = min(min(extent.x,extent.y)*0.19,19.0);
    vec2 local = p-center;
    float d = rounded_box(local,half_size,radius);
    float shadow_d = rounded_box(local-vec2(0.0,3.2),half_size,radius);
    float face = 1.0-smoothstep(-0.65,0.65,d);
    float shadow = (1.0-smoothstep(-0.5,0.8,shadow_d))*0.75;
    vec2 q = abs(local)-half_size+radius;
    vec2 normal = normalize(max(q,vec2(0.001))*sign(local+vec2(0.0001)));
    float lit_edge = dot(normal,normalize(vec2(-0.35,-0.95)));
    vec3 color = sector.rgb*(1.02-UV.y*0.055);
    color = mix(color,vec3(1.0,1.0,0.94),pow(1.0-UV.y,5.0)*0.26);
    float bevel = smoothstep(-6.0,-0.7,d);
    vec3 edge = sector.rgb*(0.87+lit_edge*0.22);
    edge = mix(edge,vec3(1.0,1.0,0.91),max(lit_edge,0.0)*0.28);
    color = mix(color,edge,bevel);
    float line = (1.0-smoothstep(0.3,1.1,abs(d+3.0)))*max(0.0,lit_edge)*0.56;
    color = mix(color,vec3(1.0,1.0,0.95),line);
    vec3 result = mix(sector.rgb*0.47,color,face);
    COLOR = vec4(result,max(face,shadow))*tint;
}
