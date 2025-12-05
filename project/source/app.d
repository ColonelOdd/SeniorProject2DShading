import graphics_app;
import bindbc.sdl;
import std.stdio;

struct ModelButton
{
    SDL_FRect rect;
    string modelPath;
    string label;
    SDL_Color color;
    SDL_Color hoverColor;
    bool isHovered;
	SDL_Texture * thumb;
}

void main()
{
    // Initialize SDL
    if (SDL_Init(SDL_INIT_VIDEO) < 0)
    {
        writeln("SDL could not initialize! SDL_Error: ", SDL_GetError());
        return;
    }

    // Create launcher window
    SDL_Window* window = SDL_CreateWindow("Model Launcher - Select a Model",
        1920, 1080, SDL_WINDOWPOS_CENTERED || SDL_WINDOWPOS_CENTERED|| SDL_WINDOW_RESIZABLE);

    if (window == null)
    {
        writeln("Window could not be created! SDL_Error: ", SDL_GetError());
        SDL_Quit();
        return;
    }

    SDL_Renderer* renderer = SDL_CreateRenderer(window, null);
    
    if (renderer == null)
    {
        writeln("Renderer could not be created! SDL_Error: ", SDL_GetError());
        SDL_DestroyWindow(window);
        SDL_Quit();
        return;
    }

    // Define the three model buttons
	int buttonWidth = 800;
	int buttonHeight = 200;
	int spacing = 50;

	int startX = (1920 - buttonWidth) / 2;
	int startY = 150;

    ModelButton[3] buttons = [
        ModelButton(
            SDL_FRect(x: startX, y: startY, w: buttonWidth, h: buttonHeight),
            "assets/Norn/Norn2.obj",
            "Model 1: Norn",
            SDL_Color(r: 70, g: 130, b: 180, a: 255),
            SDL_Color(r: 100, g: 160, b: 210, a: 255),
            false,
			SDL_CreateTextureFromSurface(renderer, SDL_LoadBMP("assets/thumb/Norn.bmp"))
        ),
        ModelButton(
            SDL_FRect(x: startX, y: startY + 1 * (buttonHeight + spacing), w: buttonWidth, h: buttonHeight),
            "assets/Horus/Horus.obj",  // Change to your actual path
            "Model 2: Horus",
            SDL_Color(r: 240, g: 220, b:  80, a: 255),
            SDL_Color(r: 255, g: 245, b: 130, a: 255),
            false,
			SDL_CreateTextureFromSurface(renderer, SDL_LoadBMP("assets/thumb/Horus.bmp"))
        ),
        ModelButton(
            SDL_FRect(x: startX, y: startY + 2 * (buttonHeight + spacing), w: buttonWidth, h: buttonHeight),
            "assets/Baal/Baal.obj",  // Change to your actual path
            "Model 3: Baal",
            SDL_Color(r: 205, g: 92, b: 92, a: 255),
            SDL_Color(r: 235, g: 122, b: 122, a: 255),
            false,
			SDL_CreateTextureFromSurface(renderer, SDL_LoadBMP("assets/thumb/Baal.bmp"))
        )
    ];

    // Load a font (SDL_ttf) - or skip if you don't have SDL_ttf
    // For simplicity, we'll just draw colored rectangles with the model name as window title

    bool running = true;
    SDL_Event event;

    while (running)
    {
        while (SDL_PollEvent(&event))
        {
            if (event.type == SDL_EVENT_QUIT)
            {
                running = false;
            }
            else if (event.type == SDL_EVENT_MOUSE_MOTION)
            {
                float mouseX = event.motion.x;
                float mouseY = event.motion.y;
                
                // Update hover state
                foreach (ref button; buttons)
                {
                    button.isHovered = (mouseX >= button.rect.x && 
                                      mouseX <= button.rect.x + button.rect.w &&
                                      mouseY >= button.rect.y && 
                                      mouseY <= button.rect.y + button.rect.h);
                }
            }
            else if (event.type == SDL_EVENT_MOUSE_BUTTON_DOWN)
            {
                if (event.button.button == SDL_BUTTON_LEFT)
                {
                    float mouseX = event.button.x;
                    float mouseY = event.button.y;
                    
                    // Check which button was clicked
                    foreach (button; buttons)
                    {
                        if (mouseX >= button.rect.x && 
                            mouseX <= button.rect.x + button.rect.w &&
                            mouseY >= button.rect.y && 
                            mouseY <= button.rect.y + button.rect.h)
                        {
                            writeln("Launching: ", button.label);
                            
                            // Launch the graphics app with selected model
                            GraphicsApp app = GraphicsApp(1920, 1080, button.modelPath);
                            app.Loop();
                        }
                    }
                }
            }
            else if (event.type == SDL_EVENT_KEY_DOWN)
            {
                // Allow keyboard shortcuts
                if (event.key.scancode == SDL_SCANCODE_1)
                {
                    GraphicsApp app = GraphicsApp(1920, 1080, buttons[0].modelPath);
                    app.Loop();
                }
                else if (event.key.scancode == SDL_SCANCODE_2)
                {
                    GraphicsApp app = GraphicsApp(1920, 1080, buttons[1].modelPath);
                    app.Loop();
					
                }
                else if (event.key.scancode == SDL_SCANCODE_3)
                {
                    GraphicsApp app = GraphicsApp(1920, 1080, buttons[2].modelPath);
                    app.Loop();
                }
                else if (event.key.scancode == SDL_SCANCODE_ESCAPE)
                {
                    running = false;
                }
            }
        }

        // Clear screen with dark background
        SDL_SetRenderDrawColor(renderer, 30, 30, 40, 255);
        SDL_RenderClear(renderer);

        // Draw buttons
        foreach (button; buttons)
        {
            SDL_Color buttonColor = button.isHovered ? button.hoverColor : button.color;
            SDL_SetRenderDrawColor(renderer, buttonColor.r, buttonColor.g, buttonColor.b, buttonColor.a);
            SDL_RenderFillRect(renderer, &button.rect);
            
            // Draw border
            SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
            SDL_RenderRect(renderer, &button.rect);

			if (button.thumb != null)
			{
				SDL_FRect thumbRect;
				thumbRect.x = button.rect.x + 10;
				thumbRect.y = button.rect.y + 10;
				thumbRect.w = button.rect.w - 20;
				thumbRect.h = button.rect.h - 20;
				SDL_RenderTexture(renderer, button.thumb, null, &thumbRect);
			}
        }

        // Draw title text (simplified - just a rectangle at top)
        SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
        SDL_FRect titleRect = SDL_FRect(x: (1920 - 400) / 2.0, y: 50, w: 400, h: 50);
        SDL_RenderRect(renderer, &titleRect);

        SDL_RenderPresent(renderer);
        SDL_Delay(16); // ~60 FPS
    }

    // Cleanup
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
}