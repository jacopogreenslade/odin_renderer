#version 330 core

in vec4 v_color;
in vec2 v_uv;

uniform sampler2D u_texture;

out vec4 o_color;

void main() {
	o_color = texture(u_texture, v_uv) * v_color; 
}

// #version 330 core
// out vec4 FragColor;
  
// in vec3 ourColor;
// in vec2 TexCoord;

// uniform sampler2D ourTexture;

// void main()
// {
//     FragColor = texture(ourTexture, TexCoord);
// }