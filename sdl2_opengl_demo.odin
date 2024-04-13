package main

import "core:fmt"
import glm "core:math/linalg/glsl"
import "core:time"
import gl "vendor:OpenGL"
import SDL "vendor:sdl2"

GL_VERSION_MAJOR :: 3
GL_VERSION_MINOR :: 3

WINDOW_WIDTH :: 854
WINDOW_HEIGHT :: 480

main :: proc() {

	SDL.Init({.VIDEO})
	defer SDL.Quit()

	window := SDL.CreateWindow(
		"3D App",
		SDL.WINDOWPOS_UNDEFINED,
		SDL.WINDOWPOS_UNDEFINED,
		WINDOW_WIDTH,
		WINDOW_HEIGHT,
		{.OPENGL},
	)
	if window == nil {
		fmt.eprintln("Failed to create window")
		return
	}
	defer SDL.DestroyWindow(window)

	SDL.GL_SetAttribute(.CONTEXT_PROFILE_MASK, i32(SDL.GLprofile.CORE))
	SDL.GL_SetAttribute(.CONTEXT_MAJOR_VERSION, GL_VERSION_MAJOR)
	SDL.GL_SetAttribute(.CONTEXT_MINOR_VERSION, GL_VERSION_MINOR)

	gl_context := SDL.GL_CreateContext(window)
	defer SDL.GL_DeleteContext(gl_context)
		
	app_info, ok := graphics_app_setup()
	if !ok {
		fmt.println("ERROR creating gl app")
		return
	}
	defer graphics_app_teardown(&app_info)

		// Import obj from file
	// 1. read directory for filenames
	// 2. try loading from premade JSON file
	// 3. if !ok, load from .obj original
	// 4. no.3 creates a JSON file for next time

	// Load the whole entity list, the load the mesh data
	entity_list := entity_list_deserialize()
	// This is too many
	// app_info.mesh_list = make([]Mesh, len(entity_list.entities))
	defer delete(app_info.mesh_list)

	for e, i in entity_list.entities {
		if e.mesh_name != "" {
			m, _ := mesh_deserialize_json(e.mesh_name)
			append(&app_info.mesh_list, m)
			if e.mesh_id == 0 {
				entity_list.entities[i].mesh_id = m.id
			}
		}
	}

	defer delete(entity_list.entities)
	defer graphics_del_entity_ptr_groups(&entity_list)

	// fmt.println("Entity list", entity_list)
	success := entity_list_serialize_json(&entity_list)
	if !success {
		fmt.println("Failed to save Entity List!")
	}

	// graphics_mesh_list_setup(&app_info, mesh_list)
	graphics_entity_lst_setup(&app_info, &entity_list)

	// high precision timer
	start_tick := time.tick_now()
	check_file_time := f32(time.duration_seconds(time.tick_since(start_tick)))
	last_check := start_tick

	// Allows me to move stuff around
	selected := &entity_list.entities[app_info.sel_entity_idx]
	fmt.println("Selected:", selected.name)

	loop: for {
		duration := time.tick_since(start_tick)
		t := f32(time.duration_seconds(duration))

		// Every five seconds, check for new assets
		if check_file_time > 5.0 {
			fmt.println("Check for new assests...")
			
			if fnames, dirty := check_for_new_assets(); dirty {
				defer delete(fnames)
				graphics_load_new_assets(&app_info, &entity_list, fnames)
				success := entity_list_serialize_json(&entity_list)
			}
			last_check = time.tick_now()
		}
		check_file_time = f32(time.duration_seconds(time.tick_since(last_check)))

		// event polling
		event: SDL.Event
		for SDL.PollEvent(&event) {
			// #partial switch tells the compiler not to error if every case is not present
			#partial switch event.type {
			case .KEYDOWN:
				#partial switch event.key.keysym.sym {
				case .ESCAPE:
					// labelled control flow
					break loop
				case .UP:
					selected.rotation[0] += 2;
				case .DOWN:
					selected.rotation[0] -= 2;
				case .LEFT:
					selected.rotation[1] += 2;
				case .RIGHT:
					selected.rotation[1] -= 2;
				case .A:
					selected.position[0] -= 0.1;
				case .D:
					selected.position[0] += 0.1;
				case .S:
					selected.position[2] -= 0.1;
				case .W:
					selected.position[2] += 0.1;
				case .Q:
					selected.position[1] -= 0.1;
				case .E:
					selected.position[1] += 0.1;
				case .TAB:
					app_info.sel_entity_idx = (app_info.sel_entity_idx + 1) % len(entity_list.entities)
					selected = &entity_list.entities[app_info.sel_entity_idx]
					fmt.println("Selected entity", selected.name)
				case .RETURN:
					// Save current setup
					success := entity_list_serialize_json(&entity_list)
				case .C:
					// copy entity
					graphics_copy_entity(&app_info, &entity_list, selected)
				}
				case .QUIT:
					// labelled control flow
					break loop
				}
		}

		// graphics_mesh_list_render(&app_info, mesh_list, t)
		graphics_entity_lst_render(&app_info, &entity_list, t)

		SDL.GL_SwapWindow(window)
	}
}
