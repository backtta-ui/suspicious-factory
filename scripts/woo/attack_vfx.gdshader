shader_type canvas_item;
render_mode blend_add;
varying vec4 vertex_tint;
void vertex(){vertex_tint=COLOR;}
void fragment(){
 vec4 c=texture(TEXTURE,UV);
 float hi=max(c.r,max(c.g,c.b));float lo=min(c.r,min(c.g,c.b));
 // The authored atlas contains pale gutters: reject neutral pixels locally, never cover the world with a sheet.
 float mask=smoothstep(.08,.28,hi-lo);
 COLOR=vertex_tint*vec4(c.rgb,c.a*mask);
}
