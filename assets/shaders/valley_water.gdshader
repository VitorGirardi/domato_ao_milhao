shader_type spatial;
render_mode cull_disabled, specular_disabled;
varying vec3 world_pos;
void vertex(){world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 float x=-42.0+sin(world_pos.z*.065)*2.6;
 float edge=smoothstep(2.2,3.3,abs(world_pos.x-x));
 float ripple=sin(world_pos.z*5.0+world_pos.x*1.7-TIME*1.3)*sin(world_pos.x*2.3+TIME*.6);
 vec3 deep=vec3(.075,.29,.27),shallow=vec3(.24,.46,.35);
 ALBEDO=mix(deep,shallow,edge)+smoothstep(.87,1.0,ripple)*.12;
 ROUGHNESS=.38;
}
