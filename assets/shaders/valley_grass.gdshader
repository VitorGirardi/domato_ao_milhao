shader_type spatial;
render_mode cull_disabled, specular_disabled;
varying float tip;
void vertex(){
 tip=clamp(VERTEX.y*2.4,0.0,1.0);
 vec3 world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 VERTEX.x+=sin(TIME*1.4+world.x*.55+world.z*.3)*tip*.045;
 VERTEX.z+=cos(TIME*.9+world.z*.4)*tip*.025;
}
void fragment(){ALBEDO=mix(vec3(.15,.25,.055),vec3(.25,.36,.09),tip);ROUGHNESS=1.0;}
