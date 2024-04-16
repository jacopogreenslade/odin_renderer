package main

import "core:fmt"
import SDL "vendor:sdl2"

GL_VERSION_MAJOR :: 3
GL_VERSION_MINOR :: 3

WINDOW_WIDTH :: 854
WINDOW_HEIGHT :: 480

WinCtxt :: struct {
	name:    string,
	window:  ^SDL.Window,
	gl_ctxt: SDL.GLContext,
}

window_setup_sdl :: proc(app_name: cstring) -> (WinCtxt, bool) {
	i := SDL.Init({.VIDEO})
	if i != 0 {
		fmt.println("Failed to initialize SDL.")
		return WinCtxt{}, false
	}

	ctxt := WinCtxt{}

	ctxt.window = SDL.CreateWindow(
		app_name,
		SDL.WINDOWPOS_UNDEFINED,
		SDL.WINDOWPOS_UNDEFINED,
		WINDOW_WIDTH,
		WINDOW_HEIGHT,
		{.OPENGL},
	)
	if ctxt.window == nil {
		fmt.eprintln("Failed to create window.")
		return WinCtxt{}, false
	}
	// defer SDL.DestroyWindow(window)

	SDL.GL_SetAttribute(.CONTEXT_PROFILE_MASK, i32(SDL.GLprofile.CORE))
	SDL.GL_SetAttribute(.CONTEXT_MAJOR_VERSION, GL_VERSION_MAJOR)
	SDL.GL_SetAttribute(.CONTEXT_MINOR_VERSION, GL_VERSION_MINOR)

	ctxt.gl_ctxt = SDL.GL_CreateContext(ctxt.window)
	if ctxt.gl_ctxt == nil {
		fmt.println("Failed to create GL context.")
		return WinCtxt{}, false
	}
	// defer SDL.GL_DeleteContext(gl_context)
	return ctxt, true
}

window_teardown_sdl :: proc(ctxt: ^WinCtxt) {
	defer SDL.Quit()
	if ctxt.window == nil {return}
	defer SDL.DestroyWindow(ctxt.window)
	if ctxt.gl_ctxt == nil {return}
	defer SDL.GL_DeleteContext(ctxt.gl_ctxt)
}

window_swap_sdl :: proc(ctxt: ^WinCtxt) {
	SDL.GL_SwapWindow(ctxt.window)
}

AppInput :: struct {
	xAxis: f32,
	yAxis: f32,
	save:  bool,
	copy:  bool,
	quit:  bool,
	tab: 	 bool,
}

get_input_sdl :: proc(prev_input: ^AppInput) {
	// event polling
	event: SDL.Event
	for SDL.PollEvent(&event) {
		// #partial switch tells the compiler not to error if every case is not present
		#partial switch event.type {
		case .KEYDOWN:
			#partial switch event.key.keysym.sym {
			case .ESCAPE:
				prev_input.quit = true
			case .UP, .A:
				prev_input.yAxis = 1.0
			case .DOWN, .D:
				// Up takes precedence!
				// if prev_input.yAxis != 0.0 {
				// 	continue
				// }
				prev_input.yAxis = -1.0
			case .LEFT, .S:
				prev_input.xAxis = 1.0
			case .RIGHT, .W:
				// if prev_input.xAxis != 0.0 {
				// 	continue
				// }
				prev_input.xAxis = -1.0
			case .TAB:
				prev_input.tab = true
			case .RETURN:
				// Save current setup
				prev_input.save = true
				// success := entity_list_serialize_json(&entity_list)
			case .C:
				// copy entity
				prev_input.copy = true
				// graphics_copy_entity(&app_info, &entity_list, selected)
			}
		case .KEYUP:
			#partial switch event.key.keysym.sym {
			case .ESCAPE:
				prev_input.quit = false
			case .UP, .A:
				prev_input.yAxis = 0.0
			case .DOWN, .D:
				// Up takes precedence!
				// if prev_input.yAxis != 0.0 {
				// 	continue
				// }
				prev_input.yAxis = 0.0
			case .LEFT, .S:
				prev_input.xAxis = 0.0
			case .RIGHT, .W:
				// if prev_input.xAxis != 0.0 {
				// 	continue
				// }
				prev_input.xAxis = 0.0
			case .TAB:
				prev_input.tab = false
			case .RETURN:
				// Save current setup
				prev_input.save = false
				// success := entity_list_serialize_json(&entity_list)
			case .C:
				// copy entity
				prev_input.copy = false
				// graphics_copy_entity(&app_info, &entity_list, selected)
			}
		case .QUIT:
			// labelled control flow
			prev_input.quit = true
		}
	}
}

	// // event polling
		// event: SDL.Event
		// for SDL.PollEvent(&event) {
		// 	// #partial switch tells the compiler not to error if every case is not present
		// 	#partial switch event.type {
		// 	case .KEYDOWN:
		// 		#partial switch event.key.keysym.sym {
		// 		case .ESCAPE:
		// 			// labelled control flow
		// 			break loop
		// 		case .UP:
		// 			selected.rotation[0] += 2;
		// 		case .DOWN:
		// 			selected.rotation[0] -= 2;
		// 		case .LEFT:
		// 			selected.rotation[1] += 2;
		// 		case .RIGHT:
		// 			selected.rotation[1] -= 2;
		// 		case .A:
		// 			selected.position[0] -= 0.1;
		// 		case .D:
		// 			selected.position[0] += 0.1;
		// 		case .S:
		// 			selected.position[2] -= 0.1;
		// 		case .W:
		// 			selected.position[2] += 0.1;
		// 		case .Q:
		// 			selected.position[1] -= 0.1;
		// 		case .E:
		// 			selected.position[1] += 0.1;
		// 		case .TAB:
		// 			app_info.sel_entity_idx = (app_info.sel_entity_idx + 1) % len(entity_list.entities)
		// 			selected = &entity_list.entities[app_info.sel_entity_idx]
		// 			fmt.println("Selected entity", selected.name)
		// 		case .RETURN:
		// 			// Save current setup
		// 			success := entity_list_serialize_json(&entity_list)
		// 		case .C:
		// 			// copy entity
		// 			graphics_copy_entity(&app_info, &entity_list, selected)
		// 		}
		// 		case .QUIT:
		// 			// labelled control flow
		// 			break loop
		// 		}
		// }
