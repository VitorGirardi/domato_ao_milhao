shader_type spatial;
render_mode cull_disabled, specular_disabled;
varying float tip;
varying float variation;
void vertex(){
 tip=clamp(VERTEX.y*4.0,0.0,1.0);
 vec3 world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 variation=sin(world.x*.61+world.z*.42)*.5+.5;
 VERTEX.x+=sin(TIME*1.25+world.x*.45+world.z*.24)*tip*tip*.018;
 VERTEX.z+=cos(TIME*.8+world.z*.35)*tip*tip*.012;
}
void fragment(){
 NORMAL=normalize((VIEW_MATRIX*vec4(0.0,1.0,0.0,0.0)).xyz);
 ALBEDO=mix(vec3(.22,.32,.09),vec3(.29,.39,.13),tip*.65+variation*.25);
 ROUGHNESS=1.0;
}
