package window

import "vendor:glfw"
import SDL "vendor:sdl2"


SDLWinCtxt :: struct {
	name:         string,
	window:       ^SDL.Window,
	gl_ctxt:      SDL.GLContext,
}

GLFWWinCtxt :: struct {
	name:         string,
	window:       glfw.WindowHandle,
	// gl_ctxt: glfw.GLContext,
}

AppInput :: struct {
	xAxis: f32,
	yAxis: f32,
	save:  bool,
	copy:  bool,
	quit:  bool,
	tab:   bool,
}
