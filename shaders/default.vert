#version 330 core

layout(location=0) in vec3 a_position;
layout(location=1) in vec2 a_uv;
layout(location=2) in vec3 a_normal;

out vec4 v_color;
out vec2 v_uv;


uniform mat4 u_ent_pos;
uniform mat4 u_ent_rot;
uniform mat4 u_ent_scl;
uniform mat4 u_transform;

void main() {
	gl_Position = u_transform * u_ent_pos * u_ent_scl * u_ent_rot * vec4(a_position, 1.0);
	
  vec4 rotatedNormalsA = vec4(a_normal, 1.0);
  rotatedNormalsA = u_ent_rot*rotatedNormalsA;

  vec3 orig = a_normal;

  // vec4 rotatedNormalsB = u_rotation*u_ent_rot*vec4(a_normal, 1.0);

  vec3 col = vec3(0.8);

	float d = dot(vec3(rotatedNormalsA), vec3( 0.5, -1.0, 0.5));
  vec3 v_col = d * col;

  // Send color to frag
	v_color = vec4(v_col, 1);

  // send uv coords to frag
  v_uv = a_uv;
}
