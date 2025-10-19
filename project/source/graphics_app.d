import std.stdio;
import sdl_abstraction;
import bindbc.sdl;
import std.stdint;

// the vertex input layout
struct Vertex
{
    float x, y, z;      //vec3 position
    float r, g, b, a;   //vec4 color
};

struct Triangle 
{
    Vertex[3] triangle_vertices;      //3 vec3 
};

// // a list of vertices
// static Vertex vertices[]
// {
//     {0.0f, 0.5f, 0.0f, 1.0f, 0.0f, 0.0f, 1.0f},     // top vertex
//     {-0.5f, -0.5f, 0.0f, 1.0f, 1.0f, 0.0f, 1.0f},   // bottom left vertex
//     {0.5f, -0.5f, 0.0f, 1.0f, 0.0f, 1.0f, 1.0f}     // bottom right vertex
// };

struct Mesh{
    Vertex[] points;
    size_t num_triangles;
}

/// Setup triangle with OpenGL buffers
Mesh LoadSTLFile(string mesh){
    Mesh m;
    // Geometry Data
    Vertex[] mVertexData =
        [];
    // Load and parse an STL file.
    import std.string;
    // Split it up line by line
    string[] lines = splitLines(mesh);
    string mCase = "facet";
    int counter = 0;
    import std.algorithm;
    import std.format;
    float[3] color;
    foreach(line; lines)
    {
        // Scanf for coordinates if line starts with facet normal
        switch (mCase){
            case "facet":
                if (startsWith(line.strip(), "facet normal"))
                {
                    line.strip().formattedRead("facet normal %f %f %f", color[0], color[1], color[2]);
                    mCase = "vertex";
                }
                break;
            case "vertex":
                if (startsWith(line.strip(), "vertex"))
                {
                    float[3] vertex;
                    line.strip().formattedRead("vertex %f %f %f", vertex[0], vertex[1], vertex[2]);
                    mVertexData ~= Vertex(x: vertex[0], y: vertex[1], z: vertex[2], r: color[0], g: color[1], b: color[2], a: 1.0f);
                    counter++;
                }

                if (counter == 3)
                {
                    counter = 0;
                    mCase = "facet";
                }
                break;
            default:
                break;
        }
        // Each triangle will have one color? On paper?
        
    }
    m.points = mVertexData;
    m.num_triangles = m.points.length / 3;

    return m;
}


struct GraphicsApp{
    // Essential
    SDL_AppResult mGameIsRunning= SDL_APP_CONTINUE;
    SDL_Window* mWindow;
    SDL_GPUDevice* mGPUDevice;
    // Buffers
    SDL_GPUBuffer* mVertexBuffer;
    SDL_GPUTransferBuffer* mTransferBuffer;

    // Pipeline
    SDL_GPUGraphicsPipeline* mGraphicsPipeline;

    Vertex[] vertices = 
        [Vertex(x: 0.0f, y: 0.5f, z: 0.0f, r: 1.0f, g: 0.0f, b: 0.0f, a: 1.0f),     // top vertex
        Vertex(x: -0.5f, y: -0.5f, z: 0.0f, r: 1.0f, g: 1.0f, b: 0.0f, a: 1.0f),   // bottom left vertex
        Vertex(x: 0.5f, y: -0.5f, z: 0.0f, r: 1.0f, g: 0.0f, b: 1.0f, a: 1.0f),
        
        Vertex(x: -0.8f, y: 0.8f, z: 0.0f, r: 0.0f, g: 1.0f, b: 0.0f, a: 1.0f),
        Vertex(x: -0.3f, y: 0.8f, z: 0.0f, r: 0.0f, g: 0.0f, b: 1.0f, a: 1.0f),
        Vertex(x: -0.55f, y: 0.3f, z: 0.0f, r: 1.0f, g: 1.0f, b: 1.0f, a: 1.0f), 
        
        Vertex(x: 0.8f, y: 0.8f, z: 0.0f, r: 0.0f, g: 1.0f, b: 0.0f, a: 1.0f),
        Vertex(x: 0.3f, y: 0.8f, z: 0.0f, r: 0.0f, g: 0.0f, b: 1.0f, a: 1.0f),
        Vertex(x: 0.55f, y: 0.3f, z: 0.0f, r: 1.0f, g: 1.0f, b: 1.0f, a: 1.0f)];     // bottom right vertex
    

    int mScreenWidth = 640;
    int mScreenHeight = 480;

    /// Setup OpenGL and any libraries
    this(int width, int height, string mesh){
        mScreenWidth = width;
        mScreenHeight = height;
        
        import std.file;
        import std.conv;
        const bytes = read(mesh);
        const file_string = cast(string) bytes;
        vertices = LoadSTLFile(file_string).points;

        // Create an application window using SDL
        mWindow = SDL_CreateWindow("Senior Project", mScreenWidth, mScreenHeight, SDL_WINDOW_RESIZABLE);

        // GPU device
        mGPUDevice = SDL_CreateGPUDevice(SDL_GPU_SHADERFORMAT_SPIRV, false, null);
        if (mGPUDevice != null)
        {
            SDL_ClaimWindowForGPUDevice(mGPUDevice, mWindow);
        }
        else
        {
            writeln("Error in creation of GPU device");
            mGameIsRunning= SDL_APP_FAILURE;
        }

        // load the vertex shader code
        size_t vertexCodeSize; 
        void* vertexCode = SDL_LoadFile("pipelines/basic/vertex.spv", &vertexCodeSize);
        //debugging
        if (vertexCode == null)
        {
            writeln("ERROR: Failed to load vertex shader file!");
            mGameIsRunning = SDL_APP_FAILURE;
            return;
        }

        // create the vertex shader
        SDL_GPUShaderCreateInfo vertexInfo;
        vertexInfo.code = cast(uint8_t*) vertexCode;
        vertexInfo.code_size = vertexCodeSize;
        vertexInfo.entrypoint = "main";
        vertexInfo.format = SDL_GPU_SHADERFORMAT_SPIRV;
        vertexInfo.stage = SDL_GPU_SHADERSTAGE_VERTEX;
        vertexInfo.num_samplers = 0;
        vertexInfo.num_storage_buffers = 0;
        vertexInfo.num_storage_textures = 0;
        vertexInfo.num_uniform_buffers = 0;

        SDL_GPUShader* mVertexShader = SDL_CreateGPUShader(mGPUDevice, &vertexInfo);

        // debugging
        if (mVertexShader == null)
        {
            writeln("ERROR: Failed to create vertex shader!");
            mGameIsRunning = SDL_APP_FAILURE;
            return;
        }

        // free the file
        SDL_free(vertexCode);

        // load the fragment shader code
        size_t fragmentCodeSize; 
        void* fragmentCode = SDL_LoadFile("pipelines/basic/fragment.spv", &fragmentCodeSize);
        if (fragmentCode == null)
        {
            writeln("ERROR: Failed to load frag shader file!");
            mGameIsRunning = SDL_APP_FAILURE;
            return;
        }

        // create the fragment shader
        SDL_GPUShaderCreateInfo fragmentInfo;
        fragmentInfo.code = cast(uint8_t*)fragmentCode;
        fragmentInfo.code_size = fragmentCodeSize;
        fragmentInfo.entrypoint = "main";
        fragmentInfo.format = SDL_GPU_SHADERFORMAT_SPIRV;
        fragmentInfo.stage = SDL_GPU_SHADERSTAGE_FRAGMENT;
        fragmentInfo.num_samplers = 0;
        fragmentInfo.num_storage_buffers = 0;
        fragmentInfo.num_storage_textures = 0;
        fragmentInfo.num_uniform_buffers = 0;

        SDL_GPUShader* mFragShader = SDL_CreateGPUShader(mGPUDevice, &fragmentInfo);
        // debugging
        if (mFragShader == null)
        {
            writeln("ERROR: Failed to create frag shader!");
            mGameIsRunning = SDL_APP_FAILURE;
            return;
        }

        // free the file
        SDL_free(fragmentCode);

        // create the vertex buffer
        SDL_GPUBufferCreateInfo bufferInfo = SDL_GPUBufferCreateInfo.init;
        bufferInfo.size = cast(uint) (vertices.length * Vertex.sizeof);
        bufferInfo.usage = SDL_GPU_BUFFERUSAGE_VERTEX;
        mVertexBuffer = SDL_CreateGPUBuffer(mGPUDevice, &bufferInfo);

        // create a transfer buffer to upload to the vertex buffer
        SDL_GPUTransferBufferCreateInfo transferInfo = SDL_GPUTransferBufferCreateInfo.init;
        transferInfo.size = cast(uint) (vertices.length * Vertex.sizeof);
        transferInfo.usage = SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD;
        mTransferBuffer = SDL_CreateGPUTransferBuffer(mGPUDevice, &transferInfo);

        // fill the transfer buffer
        Vertex* data = cast(Vertex*) SDL_MapGPUTransferBuffer(mGPUDevice, mTransferBuffer, false);
        SDL_memcpy(data, cast(void*)vertices, vertices.length * Vertex.sizeof);

        // unmap the pointer when you are done updating the transfer buffer
        SDL_UnmapGPUTransferBuffer(mGPUDevice, mTransferBuffer);

        SDL_GPUGraphicsPipelineCreateInfo pipelineInfo = SDL_GPUGraphicsPipelineCreateInfo.init;

        // bind shaders
        pipelineInfo.vertex_shader = mVertexShader;
        pipelineInfo.fragment_shader = mFragShader;
        // draw triangles
        pipelineInfo.primitive_type = SDL_GPU_PRIMITIVETYPE_TRIANGLELIST;

        // describe the vertex buffers
        SDL_GPUVertexBufferDescription[1] vertexBufferDesctiptions;
        vertexBufferDesctiptions[0] = SDL_GPUVertexBufferDescription.init;
        vertexBufferDesctiptions[0].slot = 0;
        vertexBufferDesctiptions[0].input_rate = SDL_GPU_VERTEXINPUTRATE_VERTEX;
        vertexBufferDesctiptions[0].instance_step_rate = 0;
        vertexBufferDesctiptions[0].pitch = Vertex.sizeof;

        pipelineInfo.vertex_input_state.num_vertex_buffers = 1;
        pipelineInfo.vertex_input_state.vertex_buffer_descriptions = vertexBufferDesctiptions.ptr;

        // describe the vertex attribute
        SDL_GPUVertexAttribute[2] vertexAttributes;

        // a_position
        vertexAttributes[0] = SDL_GPUVertexAttribute.init;
        vertexAttributes[0].buffer_slot = 0; // fetch data from the buffer at slot 0
        vertexAttributes[0].location = 0; // layout (location = 0) in shader
        vertexAttributes[0].format = SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3; //vec3
        vertexAttributes[0].offset = 0; // start from the first byte from current buffer position

        // a_color
        vertexAttributes[1] = SDL_GPUVertexAttribute.init;
        vertexAttributes[1].buffer_slot = 0; // use buffer at slot 0
        vertexAttributes[1].location = 1; // layout (location = 1) in shader
        vertexAttributes[1].format = SDL_GPU_VERTEXELEMENTFORMAT_FLOAT4; //vec4
        vertexAttributes[1].offset = float.sizeof * 3; // 4th float from current buffer position

        pipelineInfo.vertex_input_state.num_vertex_attributes = 2;
        pipelineInfo.vertex_input_state.vertex_attributes = vertexAttributes.ptr;

        // describe the color target
        SDL_GPUColorTargetDescription[1] colorTargetDescriptions;
        colorTargetDescriptions[0] = SDL_GPUColorTargetDescription.init;
        colorTargetDescriptions[0].blend_state.enable_blend = true;
        colorTargetDescriptions[0].blend_state.color_blend_op = SDL_GPU_BLENDOP_ADD;
        colorTargetDescriptions[0].blend_state.alpha_blend_op = SDL_GPU_BLENDOP_ADD;
        colorTargetDescriptions[0].blend_state.src_color_blendfactor = SDL_GPU_BLENDFACTOR_SRC_ALPHA;
        colorTargetDescriptions[0].blend_state.dst_color_blendfactor = SDL_GPU_BLENDFACTOR_ONE_MINUS_SRC_ALPHA;
        colorTargetDescriptions[0].blend_state.src_alpha_blendfactor = SDL_GPU_BLENDFACTOR_SRC_ALPHA;
        colorTargetDescriptions[0].blend_state.dst_alpha_blendfactor = SDL_GPU_BLENDFACTOR_ONE_MINUS_SRC_ALPHA;
        colorTargetDescriptions[0].format = SDL_GetGPUSwapchainTextureFormat(mGPUDevice, mWindow);

        pipelineInfo.target_info.num_color_targets = 1;
        pipelineInfo.target_info.color_target_descriptions = colorTargetDescriptions.ptr;

        // create the pipeline
        mGraphicsPipeline = SDL_CreateGPUGraphicsPipeline(mGPUDevice, &pipelineInfo);
        if (mGraphicsPipeline == null)
        {
            writeln("ERROR: Failed to create graphics pipeline!");
            mGameIsRunning = SDL_APP_FAILURE;
            return;
        }

        // Free the shaders
        SDL_ReleaseGPUShader(mGPUDevice, mVertexShader);
        SDL_ReleaseGPUShader(mGPUDevice, mFragShader);

        //SDL_GPUCommandBuffer* commandBuffer = SDL_AcquireGPUCommandBuffer(mGPUDevice);
        
        //SDL_SubmitGPUCommandBuffer(commandBuffer);

    }

    ~this(){
        // Release buffers
        SDL_ReleaseGPUBuffer(mGPUDevice, mVertexBuffer);
        SDL_ReleaseGPUTransferBuffer(mGPUDevice, mTransferBuffer);
        // Release the pipeline
        SDL_ReleaseGPUGraphicsPipeline(mGPUDevice, mGraphicsPipeline);
        // Destroy our GPU device
        SDL_DestroyGPUDevice(mGPUDevice);
        // Destroy our window
        SDL_DestroyWindow(mWindow);
        // report based on message
        if (mGameIsRunning == SDL_APP_FAILURE)
        {
            writeln("Error encountered, exiting...");
        }
        else
        {
            writeln("Expected exit");
        }
    }

    /// Handle input
    void Input(){
        // Store an SDL Event
        SDL_Event event;
        while(SDL_PollEvent(&event)){
            if(event.type == SDL_EVENT_WINDOW_CLOSE_REQUESTED){
                writeln("Exit event triggered (probably clicked 'x' at top of the window)");
                mGameIsRunning= SDL_APP_SUCCESS;
            }
            if(event.type == SDL_EVENT_KEY_DOWN){
                if(event.key.scancode == SDL_SCANCODE_ESCAPE){
                    writeln("Pressed escape key and now exiting...");
                    mGameIsRunning= SDL_APP_SUCCESS;
                }
            }
        }
    }


    /// Update gamestate
    void Update(){
    }

    void Render(){
        // Get the Command Buffer
        SDL_GPUCommandBuffer* commandBuffer = SDL_AcquireGPUCommandBuffer(mGPUDevice);

        // Get the swapchain texture
        SDL_GPUTexture* swapchainTexture;
        uint width, height;
        SDL_WaitAndAcquireGPUSwapchainTexture(commandBuffer, mWindow, &swapchainTexture, &width, &height);


        // end the frame early if a swapchain texture is not available
        if (swapchainTexture == null)
        {
            SDL_SubmitGPUCommandBuffer(commandBuffer);
        }

        // Create the color target
        SDL_GPUColorTargetInfo colorTargetInfo = SDL_GPUColorTargetInfo.init;
        colorTargetInfo.clear_color = SDL_FColor(r: 66/255.0f, g: 135/255.0f, b: 245/255.0f, a: 255/255.0f);
        colorTargetInfo.load_op = SDL_GPU_LOADOP_CLEAR;
        colorTargetInfo.store_op = SDL_GPU_STOREOP_STORE;
        colorTargetInfo.texture = swapchainTexture;

        // begin a render pass
        SDL_GPURenderPass* renderPass = SDL_BeginGPURenderPass(commandBuffer, &colorTargetInfo, 1, null);

        // draw something
        SDL_GPUCopyPass* copyPass = SDL_BeginGPUCopyPass(commandBuffer);

        // where is the data
        SDL_GPUTransferBufferLocation location = SDL_GPUTransferBufferLocation.init;
        location.transfer_buffer = mTransferBuffer;
        location.offset = 0; // start from the beginning

        // where to upload the data
        SDL_GPUBufferRegion region = SDL_GPUBufferRegion.init;
        region.buffer = mVertexBuffer;
        region.size = cast(uint) (vertices.length * Vertex.sizeof); // size of the data in bytes
        region.offset = 0; // begin writing from the first vertex


        // upload the data
        SDL_UploadToGPUBuffer(copyPass, &location, &region, true);

        // end the copy pass
        SDL_EndGPUCopyPass(copyPass);
        
        // bind the graphics pipeline
        SDL_BindGPUGraphicsPipeline(renderPass, mGraphicsPipeline);
        // bind the vertex buffer
        SDL_GPUBufferBinding[1] bufferBindings;
        bufferBindings[0] = SDL_GPUBufferBinding.init;
        bufferBindings[0].buffer = mVertexBuffer; // index 0 is slot 0 in this example
        bufferBindings[0].offset = 0; // start from the first byte

        SDL_BindGPUVertexBuffers(renderPass, 0, bufferBindings.ptr, 1); // bind one buffer starting from slot 0
        

        // issue a draw call
        SDL_DrawGPUPrimitives(renderPass, cast(uint) vertices.length, 1, 0, 0);

        // end the render pass
        SDL_EndGPURenderPass(renderPass);

        // submit the command buffer
        SDL_SubmitGPUCommandBuffer(commandBuffer);
    }

    /// Process 1 frame
    void AdvanceFrame(){
        Input();
        Update();
        Render();
    }

    /// Main application loop
    void Loop(){
        // Run the graphics application loop
        while(mGameIsRunning == SDL_APP_CONTINUE){
            AdvanceFrame();
        }
    }
}
