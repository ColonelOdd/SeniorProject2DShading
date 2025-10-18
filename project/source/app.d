import graphics_app;

void main(){
	// Load the SDL library first!
    /*
	This code attempts to load the SDL shared library using
	well-known variations of the library name for the host system.
	*/
	
	//etc.
	// Create graphics app!
	GraphicsApp app = GraphicsApp(960,540);
    app.Loop();
}
// SDL_Window* window;

// SDL_AppResult SDL_AppInit()
// {
//     // create a window
//     window = SDL_CreateWindow("Hello, Triangle!", 960, 540, SDL_WINDOW_RESIZABLE);

//     return SDL_APP_CONTINUE;
// }

// SDL_AppResult SDL_AppIterate()
// {
//     return SDL_APP_CONTINUE;
// }

// SDL_AppResult SDL_AppEvent(SDL_Event *event)
// {
//     // close the window on request
//     if (event.type == SDL_EVENT_WINDOW_CLOSE_REQUESTED)
//     {
//         return SDL_APP_SUCCESS;
//     }

//     return SDL_APP_CONTINUE;
// }

// void SDL_AppQuit(SDL_AppResult result)
// {
//     // destroy the window
//     SDL_DestroyWindow(window);
// }