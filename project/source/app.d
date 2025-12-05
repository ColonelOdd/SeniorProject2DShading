import graphics_app;

void main(){
	// Load the SDL library first!
    /*
	This code attempts to load the SDL shared library using
	well-known variations of the library name for the host system.
	*/
	
	//etc.
	// Create graphics app!
	GraphicsApp app = GraphicsApp(960,540, "assets/Norn/Norn2.obj");
    app.Loop();
}
