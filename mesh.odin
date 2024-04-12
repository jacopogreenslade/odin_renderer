package main

import "core:fmt"
import glm "core:math/linalg/glsl"
import "core:encoding/json"
import "core:strconv"
import "core:strings"
import "core:io"
import "core:os"
import "core:math/rand"

// struct declaration
Mesh :: struct {
	name:     string,
	vertices: []MVert,
	indices:  []u16,
	id :      u32,
}

MVert :: struct {
	pos: glm.vec3,
	uv:  glm.vec2,
	nor: glm.vec3,
}

MError :: enum {
	FileError,
	None,
}

// OBJ specific utility for keeping counts during processing
Idxs :: struct {
	v:       u16,
	vt:      u16,
	vn:      u16,
	verts:   u16,
	indices: u16,
}

/**
* 
*/
mesh_from_obj_file :: proc(fname: string) -> (Mesh, MError) {
	fpath := strings.concatenate([] string { ASSETS_FOLDER_PATH, fname})
	
	// Read the whole file
	data, ok := os.read_entire_file(fpath, context.allocator)
	if !ok {
		// could not read file
		return Mesh{}, MError.FileError
	}
	defer delete(data, context.allocator)

	// Get a string iterator
	it := string(data)

	
	// Vertex list is going to be shorter, because of indexing
	counts := Idxs{}
	
	for line in strings.split_lines_iterator(&it) {
		spl_line := strings.split(line, " ", context.allocator)
		switch (spl_line[0]) {
			case "v":
			counts.v += 1
			case "vt":
				counts.vt += 1
				case "vn":
			counts.vn += 1
			case "f":
				// Each face has 3 verts
				counts.verts += 3
			}
		}
		
		// fmt.println("Lengths", counts)
		
		v := make([]glm.vec3, counts.v);defer delete(v)
		vt := make([]glm.vec2, counts.vt);defer delete(vt)
		vn := make([]glm.vec3, counts.vn);defer delete(vn)
		// We copy this at the end so it's fine to delete
		verts := make([]MVert, counts.verts) //defer delete(verts)
		// We will also generate indices
		indices := make([]u16, counts.verts) //defer delete(indices)
		
		// v: [dynamic]glm.vec3;defer delete(v)
		// vt: [dynamic]glm.vec2;defer delete(vt)
		// vn: [dynamic]glm.vec3;defer delete(vn)
		// verts: [dynamic]MVert;defer delete(verts)
	// Initialize the mesh
	mesh := Mesh{}
		
	indxs := Idxs{}
	it = string(data)
	for line in strings.split_lines_iterator(&it) {
		// process line
		// fmt.println(line)
		spl_line := strings.split(line, " ", context.allocator)

		// We should assume these are in order!
		switch (strings.to_lower(spl_line[0])) {
		case "o":
			fmt.println("Object: ", spl_line)
			mesh.name = spl_line[1]
		case "v":
			fmt.println("Vertex: ", spl_line)
			x1, _ := strconv.parse_f32(spl_line[1])
			x2, _ := strconv.parse_f32(spl_line[2])
			x3, _ := strconv.parse_f32(spl_line[3])
			v[indxs.v] = glm.vec3{x1, x2, x3}
			fmt.println("Vertex: ", v[indxs.v])
			indxs.v += 1
		case "vt":
			fmt.println("Texture UV: ", spl_line)
			x1, _ := strconv.parse_f32(spl_line[1])
			x2, _ := strconv.parse_f32(spl_line[2])
			// append(&vt, glm.vec2{x1, x2})
			vt[indxs.vt] = glm.vec2{x1, x2}
			indxs.vt += 1
		case "vn":
			fmt.println("Normal: ", spl_line)
			x1, _ := strconv.parse_f32(spl_line[1])
			x2, _ := strconv.parse_f32(spl_line[2])
			x3, _ := strconv.parse_f32(spl_line[3])
			// append(&vn, glm.vec3{x1, x2, x3})
			vn[indxs.vn] = glm.vec3{x1, x2, x3}
			indxs.vn += 1
		case "f":
			fmt.println("Faces: ", spl_line)
			// Defines the relationships between all of the above and each face is a triagle:
			// f v1/vt1/vn1 v2/vt2/vn2 v3/vt3/vn3
			// NOTE: we won't actually use Face info, but rather the vert mapping inside
			for i in 1 ..= 3 {
				v_info := strings.split(spl_line[i], "/", context.allocator)
				v_i, _ := strconv.parse_uint(v_info[0])
				vt_i, _ := strconv.parse_uint(v_info[1])
				vn_i, _ := strconv.parse_uint(v_info[2])
				fmt.println("Vert:", v_i, vt_i, vn_i)
				// NOTE: indices are 1 based 
				v_i -= 1;vt_i -= 1;vn_i -= 1
				// TODO: Only add if doesn't exist.
				mv := MVert{v[v_i], vt[vt_i], vn[vn_i]}

				if i, ok := mvert_array_indexof(&verts, &mv); ok {
					indices[indxs.indices] = i
				} else {
					verts[indxs.verts] = MVert{v[v_i], vt[vt_i], vn[vn_i]}
					indices[indxs.indices] = indxs.verts
					indxs.verts += 1
				}
				// Always add to indices
				indxs.indices += 1
			}
		}
	}
					
	mesh.indices = indices
	mesh.vertices = verts[:indxs.verts]

	r : rand.Rand;
	mesh.id = u32(rand.uint32() * 10);


	// Save the obj for easy reloading
	mesh_serialize_json(&mesh)

	// assert(len(o.vertices) == 6)
	fmt.printfln("Lengths verts %d, indices %d", len(mesh.vertices), len(mesh.indices))
	return mesh, MError.None
}


mvert_array_indexof :: proc(arr: ^[]MVert, el: ^MVert) -> (u16, bool) {
	for item, i in arr {
		if item == el^ {
			return u16(i), true
		}
	}
	return 666, false
}

obj_delete :: proc(obj: ^Mesh) {
	delete(obj.indices)
	delete(obj.vertices)
}

// main :: proc() {
// 	obj, err := mesh_from_obj_file("./cube.obj")
//   fmt.println(obj)
// }
