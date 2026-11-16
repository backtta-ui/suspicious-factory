shader_type canvas_item;
// Keep source registration intact: cover crown pixels instead of squeezing the hair.
uniform vec4 source_uv;
uniform vec4 target_rect;
uniform float seat = -100.0;
uniform bool hood = false;
uniform bool front = false;
uniform bool headwear = false;
uniform bool rear = false;
varying vec4 tint;
void vertex(){tint=COLOR;}
void fragment(){
 vec4 c=texture(TEXTURE,UV);
 vec2 p=target_rect.xy+(UV-source_uv.xy)/source_uv.zw*target_rect.zw;
 if(headwear){
  // The hood opening must expose both eyes. Face masks deliberately have no opening.
  if(hood && !rear && p.y> -33.8 && p.y< -25.0 && abs(p.x)<6.8) c.a=0.0;
  // Front-facing chin straps must not appear over the back of the head.
  if(rear && !hood && p.y>seat) c.a=0.0;
 }else{
  if(p.y<seat || (hood && abs(p.x)>7.6 && p.y< -23.0)) c.a=0.0;
  // Separate bangs from long back tresses; protect the eyes, cheeks and neck.
  if(front && p.y> -33.5 && abs(p.x)<7.4) c.a=0.0;
  if(front && p.y> -23.0) c.a=0.0;
 }
 COLOR=tint*vec4(c.rgb,c.a*smoothstep(.2,.65,c.a));
}
