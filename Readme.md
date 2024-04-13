# OpenGL Odin App

## Create a 3d editor in odin

## Features
- mesh import .obj files
- textures, normal maps
- basic ligting: point, spot, etc.
- hot reloading of assets and code

### Handling objects and persisting a scene
Assuming there's only 1 scene, we should add serialization for Objects and handle loading and saving.
- On add mesh to asset folder
  - use `mesh_from_obj_file` to create Mesh
  - store `.yak` file for easy loading of Mesh next time
- At startup
  - Check for serialized objects
  - If there are any, load them

### Shader uniforms and Odin maps fun fact
Fun fact: When a uniform is not used in a shader it gets auto-removed by openGL! This bit me in the ass on this project. I had succeeded in rotating the vertices of my mesh using a rotation matrix called `u_rotation` which simply rotated them along the y axis and had rotated the normals with it too. Like so:

```glsl
  ...
uniform mat4 u_rotation; 

void main() {
  vec4 rotatedNormals = vec4(a_normal, 1.0);
  rotatedNormals = u_rotation*rotatedNormals;
  ...
```

Now I was trying to apply the entity rotation to it's normals, to allow for directional lighting. The code was simple enough: add a new uniform for entity rotation (as a matrix), and the normals vector by it
```glsl
  ...
// uniform mat4 u_rotation; // This uniform was a previous experiment to rotate verices
uniform mat4 u_ent_rot;

void main() {
  vec4 rotatedNormals = vec4(a_normal, 1.0);
  // rotatedNormals = u_rotation*rotatedNormals;
  rotatedNormals = u_ent_rot*rotatedNormals;
  ...
```

But this caused a WILD artifact! It looked as if we were inside a mesh somehow... And by chance I found that adding the old uniform `u_rotation` back into the calculation, somehow the artifact was fixed. Weird!
```glsl
  ...
uniform mat4 u_rotation; 
uniform mat4 u_ent_rot;

void main() {
  vec4 rotatedNormals = vec4(a_normal, 1.0);
  rotatedNormals = u_rotation*u_ent_rot*rotatedNormals; 
  // entity first old rot second
  ...
```

At first I thought this could be an issue with data casting. So I tried various iterations of vec3, vec4, surrounding the calculation in mat4() casts. But nothing made a difference!

I eventually noticed that it was not the multiplication of the `u_rotation` matrix with the normals that made a difference but it's inclusion in ANY calculation at all:

```glsl
  ...
uniform mat4 u_rotation; 
uniform mat4 u_ent_rot;

void main() {
  vec4 rotatedNormals = vec4(a_normal, 1.0);
  rotatedNormals = u_ent_rot*rotatedNormals; 
  // didn't connect this to anything, but adding it fixed the artifact
  vec4 unrelatedVector = u_rotation*vec4(a_normal, 1.0);
  ...
```

This tipped me off, and after googling I figured out that when not used `glsl uniforms are automatically removed from the shader`! In other words, not using a uniform is equivalent to removing it.

This leads me to `Odin` maps! 

In `ginger bill`'s openGL example, he makes use of some convenience methods (`Odin/vendor/OpenGL/helpers.odin`) which automatically extract UniformInfo structs from a GL Shader Program and store them in a `map` for convenience.

Now in `Odin`, structs are values. So when you are trying to retrieve a value and it is not found or doesn't exist, you will be returned a `zerio` value, which is nonetheless a `VALID VALUE`! So this means the following:

```

// the Vertex shader has the uniform "u_rotation" but doesn't use it! 
program, program_ok := gl.load_shaders_file("./shader.vert", "./shader.frag")

// !!! Somewhere in the background openGL has removed unused code from your shader!!!

// Get the uniform info from the shader program and put them in a map
uniforms :map[UniformInfo] = gl.get_uniforms_from_program(program)

// We get the "u_rotation" uniform, and it returns a ZERO VALUE, with bad nonexistant information in it
u_rot := uniforms["u_rotation"]

fmt.println(u_rot.location)
// Shader location 0

// we now apply the uniform to the shader, but we're operating on a invalid ZERO VALUE. This ends up overriding whatever uniform is currently at index 0!
grot := glm.identity(glm.mat4)
gl.UniformMatrix4fv(app_info.uniforms["u_rotation"].location, 1, false, &grot[0, 0])
```

Because the `u_rotation` uniform overrides the 0 location, which in my case is the `u_mvp` uniform or Model View Projection matrix, the projection is messed up and the artifact occurs!!!

Luckily, the solution ended up being really simple: one look at the odin documentation revealed that map retrieval also returns a second return value which indicates success. So the new uniform apply code looks like this:

```
u_rotation, ok := app_info.uniforms["u_rotation"]
if ok {
  rot := glm.identity(glm.mat4)
  gl.UniformMatrix4fv(app_info.uniforms["u_rotation"].location, 1, false, &rot[0, 0])
} else {
  fmt.println("No such uniform: u_rotation")
}
```

Gotta be careful about those zero values!