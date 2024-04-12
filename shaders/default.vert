#version 330 core

layout(location=0) in vec3 a_position;
layout(location=1) in vec2 a_uv;
layout(location=2) in vec3 a_normal;

out vec4 v_color;

uniform mat4 u_ent_pos;
uniform mat4 u_ent_rot;
uniform mat4 u_ent_scl;
uniform mat4 u_transform;
uniform mat4 u_rotation;

void main() {
	gl_Position = u_transform * u_ent_pos * u_ent_scl * u_ent_rot * vec4(a_position, 1.0);
	vec4 rotatedNormals = u_rotation*u_ent_rot*vec4(a_normal, 1.0);
	float d = dot(vec3(rotatedNormals), vec3( 0.5, -1.0, 0.5));
	vec3 col = d * vec3(0.8, 0.8, 0.8);
	v_color = vec4(col, 1.0);
}
