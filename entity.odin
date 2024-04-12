package main

import "core:encoding/json"
import "core:fmt"
import "core:io"
import glm "core:math/linalg/glsl"
import "core:os"

Entity :: struct {
	position:  glm.vec3,
	name:      string,
	rotation:  glm.vec3,
	scale:     glm.vec3,

	// Maybe use this to get mesh?
	mesh_name: string,
	mesh_id: 	u32,
	using buffers: BufPtrs,
	// mesh: add mesh id
}

EntityList :: struct {
  name:     string,
  entities: [dynamic]Entity,
}
