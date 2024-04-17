package window

import "core:fmt"
import "vendor:glfw"
import gl "vendor:OpenGL"
import "core:strings"


// To do key polling, we would need to somehow have the input struct available in the callback


// key_callback :: proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: i32) {
// 	// Exit program on escape pressed
// 	if key == glfw.KEY_ESCAPE {
// 		running = false
// 	}
// }

window_setup_glfw :: proc(app_name: cstring, w, h, glMajV, glMinV: i32) -> (GLFWWinCtxt, bool) {
	glfw.SetErrorCallback(error_callback)

  init := glfw.Init()
	if init == false {
		return GLFWWinCtxt {}, false
	}
  assert(init == true)

  ctxt := GLFWWinCtxt {}

	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, glMajV)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, glMinV)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

	ctxt.window = glfw.CreateWindow(w, h, app_name, nil, nil)
	if ctxt.window == nil {
		return GLFWWinCtxt {}, false
	}

	glfw.MakeContextCurrent(ctxt.window)
	glfw.SwapInterval(0)

  // glfw.SetKeyCallback(ctxt.window, key_callback)

  // load the OpenGL procedures once an OpenGL context has been established
	gl.load_up_to(int(glMajV), int(glMinV), glfw.gl_set_proc_address)

	return ctxt, true
}

window_teardown_glfw :: proc(ctxt: ^GLFWWinCtxt) {
	defer glfw.Terminate();
	if ctxt.window == nil {return}
	defer glfw.DestroyWindow(ctxt.window)
	// if ctxt.gl_ctxt == nil {return}
	// defer SDL.GL_DeleteContext(ctxt.gl_ctxt)
}

window_swap_glfw :: proc(ctxt: ^GLFWWinCtxt) {
	glfw.SwapBuffers(ctxt.window)
}

error_callback :: proc "c" (error: i32, desc: cstring) {
  // fmt.println("Error code", error, string(desc));
}

get_input_glfw :: proc(prev_input: ^AppInput, ctxt: ^GLFWWinCtxt) {
  glfw.PollEvents()

  state := glfw.GetKey(ctxt.window, glfw.KEY_ESCAPE)
  switch (state) {
    case glfw.PRESS:
      prev_input.quit = true
    case glfw.RELEASE:
      prev_input.quit = false
  }

	// // event polling
	// event: SDL.Event
	// for SDL.PollEvent(&event) {
	// 	// #partial switch tells the compiler not to error if every case is not present
	// 	#partial switch event.type {
	// 	case .KEYDOWN:
	// 		#partial switch event.key.keysym.sym {
	// 		case .ESCAPE:
	// 			prev_input.quit = true
	// 		case .UP, .A:
	// 			prev_input.yAxis = 1.0
	// 		case .DOWN, .D:
	// 			// Up takes precedence!
	// 			// if prev_input.yAxis != 0.0 {
	// 			// 	continue
	// 			// }
	// 			prev_input.yAxis = -1.0
	// 		case .LEFT, .S:
	// 			prev_input.xAxis = 1.0
	// 		case .RIGHT, .W:
	// 			// if prev_input.xAxis != 0.0 {
	// 			// 	continue
	// 			// }
	// 			prev_input.xAxis = -1.0
	// 		case .TAB:
	// 			prev_input.tab = true
	// 		case .RETURN:
	// 			// Save current setup
	// 			prev_input.save = true
	// 		// success := entity_list_serialize_json(&entity_list)
	// 		case .C:
	// 			// copy entity
	// 			prev_input.copy = true
	// 		// graphics_copy_entity(&app_info, &entity_list, selected)
	// 		}
	// 	case .KEYUP:
	// 		#partial switch event.key.keysym.sym {
	// 		case .ESCAPE:
	// 			prev_input.quit = false
	// 		case .UP, .A:
	// 			prev_input.yAxis = 0.0
	// 		case .DOWN, .D:
	// 			// Up takes precedence!
	// 			// if prev_input.yAxis != 0.0 {
	// 			// 	continue
	// 			// }
	// 			prev_input.yAxis = 0.0
	// 		case .LEFT, .S:
	// 			prev_input.xAxis = 0.0
	// 		case .RIGHT, .W:
	// 			// if prev_input.xAxis != 0.0 {
	// 			// 	continue
	// 			// }
	// 			prev_input.xAxis = 0.0
	// 		case .TAB:
	// 			prev_input.tab = false
	// 		case .RETURN:
	// 			// Save current setup
	// 			prev_input.save = false
	// 		// success := entity_list_serialize_json(&entity_list)
	// 		case .C:
	// 			// copy entity
	// 			prev_input.copy = false
	// 		// graphics_copy_entity(&app_info, &entity_list, selected)
	// 		}
	// 	case .QUIT:
	// 		// labelled control flow
	// 		prev_input.quit = true
	// 	}
	// }
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
