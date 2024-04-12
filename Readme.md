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