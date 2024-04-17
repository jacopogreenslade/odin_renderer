package main

import "core:fmt"
import glm "core:math/linalg/glsl"
import "core:time"
import gl "vendor:OpenGL"
import SDL "vendor:sdl2"
import window "window"

WINDOW_WIDTH :: 854
WINDOW_HEIGHT :: 480

GL_VERSION_MAJOR :: 3
GL_VERSION_MINOR :: 3

main :: proc() {

	ctxt, win_ok := window.window_setup_glfw(
		"3D APP",
		WINDOW_WIDTH,
		WINDOW_HEIGHT,
		GL_VERSION_MAJOR,
		GL_VERSION_MINOR,
	)
	defer window.window_teardown_glfw(&ctxt)
	if !win_ok {
		fmt.println("Error. Exiting...")
		return
	}

	fmt.println("Created window.")

	app_info, ok := graphics_app_setup()
	if !ok {
		fmt.println("ERROR creating gl app")
		return
	}
	defer graphics_app_teardown(&app_info)

	fmt.println("Made app.")

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

	input := window.AppInput{}

	dt_now := time.tick_now()

	loop: for {
		duration := time.tick_since(start_tick)
		t := f32(time.duration_seconds(duration))

		// Time since last frame
		dt := f32(time.duration_seconds(time.tick_since(dt_now)))
		dt_now = time.tick_now()

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

		prevInput := input
		window.get_input_glfw(&input, &ctxt)
		// process_input(&input, &app_info, &entity_list, selected)

		if !prevInput.quit && input.quit {
			break loop
		}

		if !prevInput.tab && input.tab {
			app_info.sel_entity_idx = (app_info.sel_entity_idx + 1) % len(entity_list.entities)
			selected = &entity_list.entities[app_info.sel_entity_idx]
			fmt.println("Selected entity", selected.name)
		}

		if !prevInput.save && input.save {
			entity_list_serialize_json(&entity_list)
		}

		if !prevInput.copy && input.copy {
			graphics_copy_entity(&app_info, &entity_list, selected)
		}

		selected.rotation[0] += 20 * input.xAxis * dt
		selected.rotation[1] += 20 * input.yAxis * dt

		// graphics_mesh_list_render(&app_info, mesh_list, t)
		graphics_entity_lst_render(&app_info, &entity_list, t)

		window.window_swap_glfw(&ctxt)
	}
}
