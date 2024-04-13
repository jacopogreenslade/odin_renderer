package main

import "core:fmt"
import glm "core:math/linalg/glsl"
import "core:strings"
import gl "vendor:OpenGL"
import SDL "vendor:sdl2"

GraphicsApp :: struct {
	shader_program_id: u32,
	uniforms:          gl.Uniforms,
	// These should be tied to entities
	buf_pointers:      []BufPtrs,
	mat_view:          glm.mat4,
	mat_projection:    glm.mat4,
	mat_model:         glm.mat4,
	mesh_list:         [dynamic]Mesh,
	sel_entity_idx:    int,
}

BufPtrs :: struct {
	vao, vbo, ebo: u32,
}

VrtAttrib :: struct {
	idx:        u32,
	size:       i32,
	gl_type:    u32,
	normalized: bool,
	stride:     i32,
	pointer:    uintptr,
}

graphics_app_setup :: proc() -> (GraphicsApp, bool) {
	info := GraphicsApp{}
	// load the OpenGL procedures once an OpenGL context has been established
	gl.load_up_to(GL_VERSION_MAJOR, GL_VERSION_MINOR, SDL.gl_set_proc_address)
	// useful utility procedures that are part of vendor:OpenGl

	// Load the default gl shaders at startup
	program, program_ok := gl.load_shaders_file("./shaders/default.vert", "./shaders/default.frag")
	if !program_ok {
		fmt.eprintln("Failed to create GLSL program")
		return info, false
	}
	// defer gl.DeleteProgram(program)
	info.shader_program_id = program
	gl.UseProgram(info.shader_program_id)

	// Store the uniforms info for the default shaders
	uniforms := gl.get_uniforms_from_program(program)
	info.uniforms = uniforms

	// defer delete(uniforms)
	info.mat_view = glm.mat4LookAt({0, -2, +1}, {0, 0, 0}, {0, 0, 1})
	info.mat_projection = glm.mat4Perspective(45, 1.3, 0.1, 100.0)
	info.mat_model = glm.mat4{0.5, 0, 0, 0, 0, 0.5, 0, 0, 0, 0, 0.5, 0, 0, 0, 0, 1}

	// Needed for avoiding mesh overlap issues
	gl.Enable(gl.DEPTH_TEST)

	// Default selected entity
	info.sel_entity_idx = 1

	return info, true
}

graphics_app_teardown :: proc(app_info: ^GraphicsApp) {
	// use defer to get order right
	defer gl.DeleteProgram(app_info.shader_program_id)
	defer delete(app_info.uniforms)
	// defer graphics_del_ptr_groups(&app_info.buf_pointers)
}

graphics_entity_lst_setup :: proc(app_info: ^GraphicsApp, e_list: ^EntityList) {
	// This will replace the function below
	using e_list

	// This can probably be put in some startup config 
	attributes := []VrtAttrib {
		{0, 3, gl.FLOAT, false, size_of(MVert), offset_of(MVert, pos)},
		{1, 2, gl.FLOAT, false, size_of(MVert), offset_of(MVert, uv)},
		{2, 3, gl.FLOAT, false, size_of(MVert), offset_of(MVert, nor)},
	}


	for entity, i in entities {
		gl.GenVertexArrays(1, &entities[i].vao)
		gl.GenBuffers(1, &entities[i].vbo)
		gl.GenBuffers(1, &entities[i].ebo)
		gl.BindVertexArray(entities[i].vao)
		gl.BindBuffer(gl.ARRAY_BUFFER, entities[i].vbo)
		gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, entities[i].ebo)
		fmt.println("Entity: ", entity.name, entities[i].vao, entities[i].vbo, entities[i].ebo)

		for item in attributes {
			gl.EnableVertexAttribArray(item.idx)
			gl.VertexAttribPointer(
				item.idx,
				item.size,
				item.gl_type,
				item.normalized,
				item.stride,
				item.pointer,
			)
		}

		// Not implemented yet
		mesh, found := mesh_get_by_id(app_info, entity.mesh_id)
		fmt.println("SETUP Mesh found: ", mesh.id, mesh.name, found, len(mesh.vertices))
		if !found {
			// fmt.eprintln("ERROR: Mesh not found: ", entity.mesh_id)
			continue
		}
		gl.BufferData(
			gl.ARRAY_BUFFER,
			len(mesh.vertices) * size_of(mesh.vertices[0]),
			raw_data(mesh.vertices),
			gl.STATIC_DRAW,
		)
		gl.BufferData(
			gl.ELEMENT_ARRAY_BUFFER,
			len(mesh.indices) * size_of(mesh.indices[0]),
			raw_data(mesh.indices),
			gl.STATIC_DRAW,
		)
	}

	// Bind 0, so nothing is bound
	gl.BindBuffer(gl.ARRAY_BUFFER, 0)
	gl.BindVertexArray(0)
}

graphics_entity_lst_render :: proc(app_info: ^GraphicsApp, e_list: ^EntityList, t: f32) {
	using e_list
	// Leaving this here so we can update the camera later
	u_transform := app_info.mat_projection * app_info.mat_view * app_info.mat_model
	// TODO: Not sure if these belong in the generic renderer...
	// matrix types in Odin are stored in column-major format but written as you'd normal write them
	gl.UniformMatrix4fv(app_info.uniforms["u_transform"].location, 1, false, &u_transform[0, 0])

	u_rotation, ok := app_info.uniforms["u_rotation"]
	if ok {
		grot := glm.identity(glm.mat4)
		gl.UniformMatrix4fv(app_info.uniforms["u_rotation"].location, 1, false, &grot[0, 0])
	} else {
		fmt.println("No such uniform", "u_rotation", u_rotation)
	}

	gl.Viewport(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)
	BACKGROUND_COLOR := glm.vec4{0.5, 0.7, 1.0, 1.0}

	// Set background
	gl.ClearColor(
		BACKGROUND_COLOR[0],
		BACKGROUND_COLOR[1],
		BACKGROUND_COLOR[2],
		BACKGROUND_COLOR[3],
	)
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

	for entity in entities {
		mesh, found := mesh_get_by_id(app_info, entity.mesh_id) // currently need it only for the indices
		// fmt.println("Mesh found: ", mesh.id, mesh.name, found)
		if !found {
			fmt.eprintln("ERROR: Mesh not found: ", entity.mesh_id)
			continue
		}
		// Update the uniforms for this particular enitity in the shader
		pos := glm.mat4Translate(entity.position)
		gl.UniformMatrix4fv(app_info.uniforms["u_ent_pos"].location, 1, false, &pos[0, 0])

		// mat4Rotate gives a rotation about the Axis v (vec), by radians r (f32)
		q :=
			glm.quatAxisAngle(glm.vec3{1, 0, 0}, glm.radians_f32(entity.rotation[0])) *
			glm.quatAxisAngle(glm.vec3{0, 1, 0}, glm.radians_f32(entity.rotation[1])) *
			glm.quatAxisAngle(glm.vec3{0, 0, 1}, glm.radians_f32(entity.rotation[2]))
		ent_rot := glm.mat4FromQuat(q)
		// if entity.name == "Cube" {
		// 	v := glm.vec4 { 2.0 , 4.0 , 6.0 , 1.0 }
		// 	fmt.println("vector - rot", ent_rot, "identity", grot, "multiply", grot*ent_rot)
		// 	fmt.println("mat - rot", ent_rot*v, "identity", grot*v, "multiply", grot*ent_rot*v)
		// }
		gl.UniformMatrix4fv(app_info.uniforms["u_ent_rot"].location, 1, true, &ent_rot[0, 0])

		scl := glm.mat4Scale(entity.scale)
		gl.UniformMatrix4fv(app_info.uniforms["u_ent_scl"].location, 1, false, &scl[0, 0])
		
		// Bind vao and draw
		gl.BindVertexArray(entity.vao)
		gl.DrawElements(gl.TRIANGLES, i32(len(mesh.indices)), gl.UNSIGNED_SHORT, nil)
	}
	gl.BindVertexArray(0)
}

graphics_del_ptr_group :: proc(buf: ^BufPtrs, i: i32) {
	gl.DeleteVertexArrays(i, &buf.vao)
	gl.DeleteBuffers(i, &buf.vbo)
	gl.DeleteBuffers(i, &buf.ebo)
}

graphics_del_ptr_groups :: proc(buf_pointers: ^[]BufPtrs) {
	for _, i in buf_pointers {
		graphics_del_ptr_group(&buf_pointers[i], i32(i))
	}
}

graphics_del_entity_ptr_groups :: proc(e_list: ^EntityList) {
	using e_list
	for _, i in entities {
		gl.DeleteVertexArrays(1, &entities[i].vao)
		gl.DeleteBuffers(1, &entities[i].vbo)
		gl.DeleteBuffers(1, &entities[i].ebo)
	}
}

graphics_load_new_assets :: proc(app_info: ^GraphicsApp, e_list: ^EntityList, fnames: []string) {
	el := EntityList{}
	defer delete(el.entities)

	// For now we add a new entity for every new imported
	// mesh. Leter we might want to decouple these
	for name, i in fnames {
		mesh, err := mesh_from_obj_file(name)
		fmt.println("Mesh name ", mesh.name)
		append(&el.entities, Entity{mesh_name = strings.to_lower(mesh.name), mesh_id = mesh.id})
		append(&app_info.mesh_list, mesh)
	}

	fmt.println("Running setup again to update buffers and load new assets")
	// Create vaos etc for new entities
	graphics_entity_lst_setup(app_info, &el)
	// Finally add new entities to entity_list
	append(&e_list.entities, ..el.entities[:])
}

graphics_copy_entity :: proc(app_info: ^GraphicsApp, e_list: ^EntityList, e: ^Entity) {
	el := EntityList{}
	defer delete(el.entities)

	// For now we add a new entity for every new imported
	// mesh. Leter we might want to decouple these
	fmt.println("Copyting", e.name, "...")
	mesh, ok := mesh_get_by_id(app_info, e.mesh_id)
	append(&el.entities, Entity{
		mesh_name = e.mesh_name,
		name=strings.concatenate({e.mesh_name, "(1)"}),
		mesh_id = mesh.id,
		position = e.position,
		rotation = e.rotation,
		scale = e.scale,
	})
	append(&app_info.mesh_list, mesh)

	fmt.println("Run setup to create vaos etc...")
	// Create vaos etc for new entities
	graphics_entity_lst_setup(app_info, &el)
	// Finally add new entities to entity_list
	append(&e_list.entities, ..el.entities[:])
}

mesh_get_by_id :: proc(app_info: ^GraphicsApp, mesh_id: u32) -> (Mesh, bool) {
	for m in app_info.mesh_list {
		if m.id == mesh_id {
			return m, true
		}
	}
	return Mesh{}, false
}
