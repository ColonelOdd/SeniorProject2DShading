import std.stdio;
import sdl_abstraction;
import bindbc.sdl;
import std.stdint;

// got to put 
import camera;
import linear;

// the vertex input layout
struct Vertex
{
    float x, y, z;      //vec3 position
    float u, v;   //vec2 texture coordinates
    float nx, ny, nz; // vec3 normal
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
    string bmp_file_path;
    string norm_file_path;
    size_t num_triangles;
}

/// Setup triangle with OpenGL buffers
// Mesh LoadSTLFile(string mesh){
//     Mesh m;
//     // Geometry Data
//     Vertex[] mVertexData =
//         [];
//     // Load and parse an STL file.
//     import std.string;
//     // Split it up line by line
//     string[] lines = splitLines(mesh);
//     string mCase = "facet";
//     int counter = 0;
//     import std.algorithm;
//     import std.format;
//     float[3] color;
//     foreach(line; lines)
//     {
//         // Scanf for coordinates if line starts with facet normal
//         switch (mCase){
//             case "facet":
//                 if (startsWith(line.strip(), "facet normal"))
//                 {
//                     line.strip().formattedRead("facet normal %f %f %f", color[0], color[1], color[2]);
//                     mCase = "vertex";
//                 }
//                 break;
//             case "vertex":
//                 if (startsWith(line.strip(), "vertex"))
//                 {
//                     float[3] vertex;
//                     line.strip().formattedRead("vertex %f %f %f", vertex[0], vertex[1], vertex[2]);
//                     mVertexData ~= Vertex(x: vertex[0], y: vertex[1], z: vertex[2], r: color[0], g: color[1], b: color[2], a: 1.0f);
//                     counter++;
//                 }

//                 if (counter == 3)
//                 {
//                     counter = 0;
//                     mCase = "facet";
//                 }
//                 break;
//             default:
//                 break;
//         }
//         // Each triangle will have one color? On paper?
        
//     }
//     m.points = mVertexData;
//     m.num_triangles = m.points.length / 3;

//     return m;
// }


Mesh MakeOBJ(string filepath){
    // Load and parse an OBJ file.
    import std.file;
    import std.conv;
    const bytes = read(filepath);
    string file_string = cast(string) bytes;
    import std.string;
    // Split it up line by line
    string[] lines = splitLines(file_string);
    //string mCase = "facet";
    import std.algorithm;
    import std.format;
    float[] mVertexData = [];
    float[] mTextureData = [];
    float[] mNormalData = [];
    uint[] mIndexData = [];
    uint[] mIndexTextureData = [];
    uint[] mIndexNormalData = [];
    // Mesh announcement
    string str_mtl_file;
    foreach(line; lines)
    {
        float[3] mCoordinate;
        // Scanf for coordinates if line starts with facet normal
        if (startsWith(line.strip(), "mtllib "))
        {
            line.strip().formattedRead("mtllib %s", str_mtl_file);
        }
        else if (startsWith(line.strip(), "v "))
        {
            line.strip().formattedRead("v %f %f %f", mCoordinate[0], mCoordinate[1], mCoordinate[2]);
            foreach (v; mCoordinate) {
                mVertexData ~= v;
            }
        }
        else if (startsWith(line.strip(), "vt "))
        {
            line.strip().formattedRead("vt %f %f", mCoordinate[0], mCoordinate[1]);
            mTextureData ~= mCoordinate[0];
            mTextureData ~= mCoordinate[1];
        }
        else if (startsWith(line.strip(), "vn "))
        {
            line.strip().formattedRead("vn %f %f %f", mCoordinate[0], mCoordinate[1], mCoordinate[2]);
            foreach (vn; mCoordinate) {
                mNormalData ~= vn;
            }
        }
        else if (startsWith(line.strip(), "f "))
        {
            import std.regex;
            // Leveraging regex to read ambigious number of floats into face (even though should be three for this example)
            auto re = regex(r"(\d+)/(\d+)/(\d+)");
            auto matches = matchAll(line, re);
            
            // Iterate over the matches and parse the floats
            foreach (m; matches) {
                int p = to!int(m.captures[1]);
                int t = to!int(m.captures[2]);
                int n = to!int(m.captures[3]);
                mIndexData ~= p - 1;
                mIndexNormalData ~= n - 1;
                mIndexTextureData ~= t - 1;
            }
        }
    }
    Mesh m;
    // Geometry Data
    
    writeln("Vertices counted: ", mVertexData.length);
    writeln("VTs counted: ", mTextureData.length);
    writeln("VNs counted: ", mNormalData.length);
    writeln("Vertex indices: ", mIndexData.length);
    writeln("Texture indices: ", mIndexTextureData.length);  
    writeln("Normal indices: ", mIndexNormalData.length);
    Vertex[] mMultiVertex = [];
    for(size_t i=0; i < mIndexData.length; i++){
        // fill the buffer
        uint index = mIndexData[i];
        uint textureindex = mIndexTextureData[i];
        uint normalindex = mIndexNormalData[i]; 
        mMultiVertex ~= Vertex(x: mVertexData[index * 3], y: mVertexData[index * 3 + 1], z: mVertexData[index * 3 + 2], 
                        u: mTextureData[textureindex * 2], v: 1.0f - mTextureData[textureindex * 2 + 1], 
                        nx: mNormalData[normalindex * 3], ny: mNormalData[normalindex * 3 + 1], nz: mNormalData[normalindex * 3 + 2]);
    }

    // Return constructed mesh
    import std.algorithm;
    import std.format;
    auto lastSlash = filepath.lastIndexOf('/');
    string directoryPath = filepath[0 .. lastSlash + 1];
    string[] paths = MTL_reader(directoryPath ~ str_mtl_file);
    m.bmp_file_path = paths[0];
    m.norm_file_path = paths[1];
    m.points = mMultiVertex;
    m.num_triangles = m.points.length / 3;
    return m;
}

string[] MTL_reader(string filepath){
    // You can erase all of this code, or otherwise add the parsing of your OBJ
    // file here.
    // Load and parse an STL file.
    import std.file;
    import std.conv;
    const bytes = read(filepath);
    string file_string = cast(string) bytes;
    import std.string;
    // Split it up line by line
    string[] lines = splitLines(file_string);
    //string mCase = "facet";
    import std.algorithm;
    import std.format;

    // Read in MTL map
    string mtl;
    // Grab the directory 
    auto lastSlash = filepath.lastIndexOf('/');
    string directoryPath = filepath[0 .. lastSlash + 1];
    string normalPath = directoryPath;
    bool found_mtl = false;
    foreach(line; lines)
    {
        if (startsWith(line.strip(), "map_Kd ") && !found_mtl)
        {
            line.strip().formattedRead("map_Kd %s", mtl);
            directoryPath ~= mtl;
            found_mtl = true;
        }
        else if (startsWith(line.strip(), "map_Bump "))
        {
            line.strip().formattedRead("map_Bump %s", mtl);
            normalPath ~= mtl;
        }
    }
    import std.stdio;
    writeln(directoryPath);
    writeln(normalPath);
    return [directoryPath, normalPath];
}



/// Simple struct for loading image/pixel data in PPM format.
struct PPM{

		int mWidth;
		int mHeight;
		int mRange;
		ubyte[] mPixels;

        void ConvertRGBtoRGBA(){
            // Convert RGB to RGBA
            ubyte[] rgbaPixels = new ubyte[mWidth * mHeight * 4];
            size_t srcIdx = 0;
            size_t dstIdx = 0;

            for (int i = 0; i < mWidth * mHeight; i++) {
                rgbaPixels[dstIdx++] = mPixels[srcIdx++]; // R
                rgbaPixels[dstIdx++] = mPixels[srcIdx++]; // G
                rgbaPixels[dstIdx++] = mPixels[srcIdx++]; // B
                rgbaPixels[dstIdx++] = 255;                        // A (fully opaque)
            }

            mPixels = rgbaPixels;
        }

		// Simple PPM image loader
		ubyte[] LoadPPMImage(string filename){
            import std.file, std.conv, std.algorithm, std.range, std.stdio, std.file;
				if(!filename.exists){
						assert(0,"file does not exist:"~filename);
				}

				auto f = File(filename);

				int counter=0;
				bool foundMagicNumber = false;
				bool foundDimensions  = false;
				bool foundRange	= false;
				foreach(line ; f.byLine()){
						if(line.startsWith("#")){
							continue;
						}
						if(foundMagicNumber == false){
							foundMagicNumber=true;
							if(!line.startsWith("P3")){
								writeln("ERROR! Ill formed PPM image");
							}
								continue;
						}
						if(foundDimensions==false){
							foundDimensions = true;
							char[][] dims = line.split();
							mWidth = dims[0].to!int;
							mHeight= dims[1].to!int;
								continue;
						}	
						if(foundRange == false){
								foundRange = true;
								mRange = line.split()[0].to!int;
								continue;
						}
					
						// Handle any whitespace formatting
						char[][] tokens = line.split;
						foreach(token ; tokens){
							mPixels ~= token.to!ubyte;
						}
				}

                // Flip the image pixels from image space to screen space
				//				result = result.reverse;
				//mPixels = mPixels.reverse;
				// Swizzle the bytes back to RGB order	
				// for(int i = 0; i < mPixels.length; i+=3){
				// 	//rgb.reverse;
				// 	auto temp = mPixels[i];
				// 	mPixels[i] = mPixels[i+2];
				// 	mPixels[i+2] = temp; 
				// }
                
                
                // NOW convert to RGBA
                ubyte[] rgbaPixels = new ubyte[mWidth * mHeight * 4];
                size_t srcIdx = 0;
                size_t dstIdx = 0;
                
                for (int i = 0; i < mWidth * mHeight; i++) {
                    rgbaPixels[dstIdx++] = mPixels[srcIdx++]; // R
                    rgbaPixels[dstIdx++] = mPixels[srcIdx++]; // G
                    rgbaPixels[dstIdx++] = mPixels[srcIdx++]; // B
                    rgbaPixels[dstIdx++] = 255;               // A
                }
                
                mPixels = rgbaPixels;
                
                return mPixels;

		}

}

struct UniformBuffer
{
    mat4 uModel;
    mat4 uView;
    mat4 uProjection;
};

align(16) struct Light{
	float[4] mColor=[1.0,1.0,1.0, 0.0];
	float[4] mPosition=[0.1,0.1,0.1, 0.0];
	float 	 mAmbientIntensity=1.5f;
	float 	 mSpecularIntensity=0.2f;
	float 	 mSpecularExponent=32.0f;
}

// clean up, from SDL GPU by example
SDL_GPUTextureFormat GetSupportedDepthFormat(SDL_GPUDevice* mGPUDevice)
{
  SDL_GPUTextureFormat[] possibleFormats = [
    SDL_GPU_TEXTUREFORMAT_D32_FLOAT_S8_UINT,
    SDL_GPU_TEXTUREFORMAT_D24_UNORM_S8_UINT,
    SDL_GPU_TEXTUREFORMAT_D32_FLOAT,
    SDL_GPU_TEXTUREFORMAT_D24_UNORM,
    SDL_GPU_TEXTUREFORMAT_D16_UNORM,
  ];

  for (size_t i = 0; i < possibleFormats.length; ++i) {
    if (SDL_GPUTextureSupportsFormat(mGPUDevice,
      possibleFormats[i],
      SDL_GPU_TEXTURETYPE_2D,
      SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET))
    {
      return possibleFormats[i];
    }
  }

  return SDL_GPU_TEXTUREFORMAT_INVALID;
}


struct GraphicsApp{
    // Essential
    SDL_AppResult mGameIsRunning= SDL_APP_CONTINUE;
    SDL_Window* mWindow;
    SDL_GPUDevice* mGPUDevice;
    // Buffers
    SDL_GPUBuffer* mVertexBuffer;
    SDL_GPUTransferBuffer* mTransferBuffer;
    // Texture Mode
    SDL_GPUTexture* mTexture;
    SDL_GPUSampler* mSampler;
    // Normal Mode
    SDL_GPUTexture* mNormal;
    SDL_GPUSampler* mSamplerNormal;

    // Pipeline
    SDL_GPUGraphicsPipeline* mGraphicsPipeline;

    // Abstract mCamera defined
    Camera mCamera;
    UniformBuffer cameraUniform;

    // Light
    Light mLight;

    // Depth Texture info
    SDL_GPUTexture* depthTexture = null;
    SDL_GPUTextureFormat depthFormat;
    uint depthWidth = 0;
    uint depthHeight = 0;

    Vertex[] vertices = [];
        // [Vertex(x: 0.0f, y: 0.5f, z: 0.0f, r: 1.0f, g: 0.0f, b: 0.0f, a: 1.0f),     // top vertex
        // Vertex(x: -0.5f, y: -0.5f, z: 0.0f, r: 1.0f, g: 1.0f, b: 0.0f, a: 1.0f),   // bottom left vertex
        // Vertex(x: 0.5f, y: -0.5f, z: 0.0f, r: 1.0f, g: 0.0f, b: 1.0f, a: 1.0f),
        
        // Vertex(x: -0.8f, y: 0.8f, z: 0.0f, r: 0.0f, g: 1.0f, b: 0.0f, a: 1.0f),
        // Vertex(x: -0.3f, y: 0.8f, z: 0.0f, r: 0.0f, g: 0.0f, b: 1.0f, a: 1.0f),
        // Vertex(x: -0.55f, y: 0.3f, z: 0.0f, r: 1.0f, g: 1.0f, b: 1.0f, a: 1.0f), 
        
        // Vertex(x: 0.8f, y: 0.8f, z: 0.0f, r: 0.0f, g: 1.0f, b: 0.0f, a: 1.0f),
        // Vertex(x: 0.3f, y: 0.8f, z: 0.0f, r: 0.0f, g: 0.0f, b: 1.0f, a: 1.0f),
        // Vertex(x: 0.55f, y: 0.3f, z: 0.0f, r: 1.0f, g: 1.0f, b: 1.0f, a: 1.0f)];     // bottom right vertex
    

    int mScreenWidth = 640;
    int mScreenHeight = 480;

    /// Setup any libraries
    this(int width, int height, string mesh){
        mScreenWidth = width;
        mScreenHeight = height;
        
        import std.file;
        import std.conv;
        //const bytes = read(mesh);
        // const file_string = cast(string) bytes;

        Mesh m = MakeOBJ(mesh);
        vertices = m.points;
        //vertices = LoadSTLFile(file_string).points;

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

        // Create a camera
		mCamera = new Camera(width, height);

        // load the vertex shader code
        size_t vertexCodeSize; 
        void* vertexCode = SDL_LoadFile("pipelines/normal/vertex.spv", &vertexCodeSize);
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
        vertexInfo.num_uniform_buffers = 1;

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
        void* fragmentCode = SDL_LoadFile("pipelines/normal/fragment.spv", &fragmentCodeSize);
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
        fragmentInfo.num_samplers = 1;
        fragmentInfo.num_storage_buffers = 0;
        fragmentInfo.num_storage_textures = 0;
        fragmentInfo.num_uniform_buffers = 2;

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
        SDL_GPUVertexAttribute[3] vertexAttributes;

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
        vertexAttributes[1].format = SDL_GPU_VERTEXELEMENTFORMAT_FLOAT2; //vec2
        vertexAttributes[1].offset = float.sizeof * 3; // 4th float from current buffer position

        // a_normal
        vertexAttributes[2] = SDL_GPUVertexAttribute.init;
        vertexAttributes[2].buffer_slot = 0; // fetch data from the buffer at slot 0
        vertexAttributes[2].location = 2; // layout (location = 0) in shader
        vertexAttributes[2].format = SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3; //vec3
        vertexAttributes[2].offset = float.sizeof * 5; // start from the first byte from current buffer position

        pipelineInfo.vertex_input_state.num_vertex_attributes = 3;
        pipelineInfo.vertex_input_state.vertex_attributes = vertexAttributes.ptr;

        // describe the color target
        SDL_GPUColorTargetDescription[2] colorTargetDescriptions;
        colorTargetDescriptions[0] = SDL_GPUColorTargetDescription.init;
        colorTargetDescriptions[0].blend_state.enable_blend = false;
        colorTargetDescriptions[0].blend_state.color_blend_op = SDL_GPU_BLENDOP_ADD;
        colorTargetDescriptions[0].blend_state.alpha_blend_op = SDL_GPU_BLENDOP_ADD;
        colorTargetDescriptions[0].blend_state.src_color_blendfactor = SDL_GPU_BLENDFACTOR_SRC_ALPHA;
        colorTargetDescriptions[0].blend_state.dst_color_blendfactor = SDL_GPU_BLENDFACTOR_ONE_MINUS_SRC_ALPHA;
        colorTargetDescriptions[0].blend_state.src_alpha_blendfactor = SDL_GPU_BLENDFACTOR_SRC_ALPHA;
        colorTargetDescriptions[0].blend_state.dst_alpha_blendfactor = SDL_GPU_BLENDFACTOR_ONE_MINUS_SRC_ALPHA;
        colorTargetDescriptions[0].format = SDL_GPU_TEXTUREFORMAT_R32G32B32A32_FLOAT;

        colorTargetDescriptions[1] = SDL_GPUColorTargetDescription.init;
        colorTargetDescriptions[1].blend_state.enable_blend = false;
        colorTargetDescriptions[1].blend_state.color_blend_op = SDL_GPU_BLENDOP_ADD;
        colorTargetDescriptions[1].blend_state.alpha_blend_op = SDL_GPU_BLENDOP_ADD;
        colorTargetDescriptions[1].blend_state.src_color_blendfactor = SDL_GPU_BLENDFACTOR_SRC_ALPHA;
        colorTargetDescriptions[1].blend_state.dst_color_blendfactor = SDL_GPU_BLENDFACTOR_ONE_MINUS_SRC_ALPHA;
        colorTargetDescriptions[1].blend_state.src_alpha_blendfactor = SDL_GPU_BLENDFACTOR_SRC_ALPHA;
        colorTargetDescriptions[1].blend_state.dst_alpha_blendfactor = SDL_GPU_BLENDFACTOR_ONE_MINUS_SRC_ALPHA;
        colorTargetDescriptions[1].format = SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM;



        pipelineInfo.target_info.num_color_targets = 2;
        pipelineInfo.target_info.color_target_descriptions = colorTargetDescriptions.ptr;

        // Depth Buffer Addition
        depthFormat = GetSupportedDepthFormat(mGPUDevice);
        pipelineInfo.target_info.depth_stencil_format = depthFormat;
        pipelineInfo.target_info.has_depth_stencil_target = true;
        pipelineInfo.primitive_type = SDL_GPU_PRIMITIVETYPE_TRIANGLELIST;
        pipelineInfo.rasterizer_state.front_face = SDL_GPU_FRONTFACE_CLOCKWISE;
        pipelineInfo.rasterizer_state.cull_mode = SDL_GPU_CULLMODE_NONE;

        pipelineInfo.depth_stencil_state.compare_op = SDL_GPU_COMPAREOP_LESS_OR_EQUAL;

        pipelineInfo.depth_stencil_state.enable_depth_test = true;
        pipelineInfo.depth_stencil_state.enable_depth_write = true;

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
        
        // Texture loading...
        import std.string;
        PPM surface = PPM.init;
        surface.LoadPPMImage(m.bmp_file_path);
        //surface.ConvertRGBtoRGBA();
        // ubyte[] testPixels = [
        //     255, 0, 0, 255,    // Red
        //     0, 255, 0, 255,    // Green
        //     0, 0, 255, 255,    // Blue
        //     255, 255, 0, 255   // Yellow
        // ];

        // Create texture data
        SDL_GPUTextureCreateInfo  textureInfo = SDL_GPUTextureCreateInfo(type : SDL_GPU_TEXTURETYPE_2D,
            format : SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM,
            width : surface.mWidth,
            height : surface.mHeight,
            layer_count_or_depth : 1,
            num_levels : 1,
            usage : SDL_GPU_TEXTUREUSAGE_SAMPLER);
        mTexture = SDL_CreateGPUTexture(mGPUDevice, &textureInfo);
        
        // Upload texture data via transfer buffer
        SDL_GPUTransferBufferCreateInfo texTransferInfo = SDL_GPUTransferBufferCreateInfo.init;
        texTransferInfo.size = surface.mWidth * surface.mHeight * 4; // RGBA
        texTransferInfo.usage = SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD;
        SDL_GPUTransferBuffer* mTexTransferBuffer  = SDL_CreateGPUTransferBuffer(mGPUDevice, &texTransferInfo);

        // Copy surface data to transfer buffer
        void* texData = SDL_MapGPUTransferBuffer(mGPUDevice, mTexTransferBuffer, false);
        SDL_memcpy(texData, cast(void*) surface.mPixels, surface.mWidth * surface.mHeight * 4);
        SDL_UnmapGPUTransferBuffer(mGPUDevice, mTexTransferBuffer);

        // Create sampler 
        SDL_GPUSamplerCreateInfo  samplerInfo = SDL_GPUSamplerCreateInfo(min_filter : SDL_GPU_FILTER_NEAREST,
            mag_filter : SDL_GPU_FILTER_NEAREST,
            mipmap_mode : SDL_GPU_SAMPLERMIPMAPMODE_NEAREST,
            address_mode_u : SDL_GPU_SAMPLERADDRESSMODE_REPEAT,
            address_mode_v : SDL_GPU_SAMPLERADDRESSMODE_REPEAT,
            address_mode_w : SDL_GPU_SAMPLERADDRESSMODE_REPEAT);
        mSampler = SDL_CreateGPUSampler(mGPUDevice, &samplerInfo);

        // Get a command buffer to upload the texture
        SDL_GPUCommandBuffer* commandBuffer = SDL_AcquireGPUCommandBuffer(mGPUDevice);
        SDL_GPUCopyPass* texCopyPass = SDL_BeginGPUCopyPass(commandBuffer);

        // Set up the texture upload
        SDL_GPUTextureTransferInfo TexTransferInfo = SDL_GPUTextureTransferInfo.init;
        TexTransferInfo.transfer_buffer = mTexTransferBuffer;
        TexTransferInfo.offset = 0;
        TexTransferInfo.pixels_per_row = surface.mWidth;  
        TexTransferInfo.rows_per_layer = surface.mHeight; 

        SDL_GPUTextureRegion textureRegion = SDL_GPUTextureRegion.init;
        textureRegion.texture = mTexture;
        textureRegion.w = surface.mWidth;
        textureRegion.h = surface.mHeight;
        textureRegion.x = 0;  
        textureRegion.y = 0;  
        textureRegion.z = 0;  
        textureRegion.d = 1;

        // Upload the texture
        SDL_UploadToGPUTexture(texCopyPass, &TexTransferInfo, &textureRegion, false);

        // End copy pass and submit
        SDL_EndGPUCopyPass(texCopyPass);
        SDL_SubmitGPUCommandBuffer(commandBuffer);
        SDL_WaitForGPUIdle(mGPUDevice); 

        writeln("Creating texture: ", surface.mWidth, "x", surface.mHeight);
        writeln("Texture region: ", textureRegion.w, "x", textureRegion.h);
        writeln("Transfer buffer pixels_per_row: ", TexTransferInfo.pixels_per_row);

        // Clean up the texture transfer buffer after upload
        SDL_ReleaseGPUTransferBuffer(mGPUDevice, mTexTransferBuffer);
        //SDL_ReleaseGPUTransferBuffer(mGPUDevice, mNormTransferBuffer);

        // Set up basic light
        mLight = Light.init;
        mLight.mAmbientIntensity = 1.0f;

        CreateOutliner();
    }

    // used in second render pass to add an outline
    SDL_GPUTexture* mPositionTexture;
    SDL_GPUTexture* mColorTexture;
    SDL_GPUSampler* mPositionSampler;
    SDL_GPUSampler* mColorSampler;
    SDL_GPUTexture* mNoiseTexture;
    SDL_GPUSampler* mNoiseSampler;

    SDL_GPUBuffer* mQuadVertexBuffer;
    SDL_GPUBuffer* mQuadIndexBuffer;


    SDL_GPUGraphicsPipeline* mOutlinerPipeline;
    // creates an outline
    void CreateOutliner()
    {   
        // PASS 1: Textures of the scene

        // Create position texture (stores fragment positions)
        SDL_GPUTextureCreateInfo positionTexInfo = SDL_GPUTextureCreateInfo(type : SDL_GPU_TEXTURETYPE_2D,
            format : SDL_GPU_TEXTUREFORMAT_R32G32B32A32_FLOAT,
            width : mScreenWidth,
            height : mScreenHeight,
            layer_count_or_depth : 1,
            num_levels : 1,
            usage : SDL_GPU_TEXTUREUSAGE_COLOR_TARGET | SDL_GPU_TEXTUREUSAGE_SAMPLER);
        mPositionTexture = SDL_CreateGPUTexture(mGPUDevice, &positionTexInfo);

        // Create color texture (stores lit scene colors) 
        SDL_GPUTextureCreateInfo colorTexInfo = SDL_GPUTextureCreateInfo(type : SDL_GPU_TEXTURETYPE_2D,
            format : SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM,
            width : mScreenWidth,
            height : mScreenHeight,
            layer_count_or_depth : 1,
            num_levels : 1,
            usage : SDL_GPU_TEXTUREUSAGE_COLOR_TARGET | SDL_GPU_TEXTUREUSAGE_SAMPLER);
        mColorTexture = SDL_CreateGPUTexture(mGPUDevice, &colorTexInfo);

        // Create samplers for these framebuffers
        SDL_GPUSamplerCreateInfo samplerInfo = SDL_GPUSamplerCreateInfo(min_filter : SDL_GPU_FILTER_LINEAR,
            mag_filter : SDL_GPU_FILTER_LINEAR,
            mipmap_mode : SDL_GPU_SAMPLERMIPMAPMODE_LINEAR,
            address_mode_u : SDL_GPU_SAMPLERADDRESSMODE_CLAMP_TO_EDGE,
            address_mode_v : SDL_GPU_SAMPLERADDRESSMODE_CLAMP_TO_EDGE,
            address_mode_w : SDL_GPU_SAMPLERADDRESSMODE_CLAMP_TO_EDGE);
       
        mPositionSampler = SDL_CreateGPUSampler(mGPUDevice, &samplerInfo);
        mColorSampler = SDL_CreateGPUSampler(mGPUDevice, &samplerInfo);

        // read in noise now
        import std.string;
        PPM surface = PPM.init;
        surface.LoadPPMImage("assets/color-noise.ppm");
        // Create texture data for noise
        SDL_GPUTextureCreateInfo  textureInfo = SDL_GPUTextureCreateInfo(type : SDL_GPU_TEXTURETYPE_2D,
            format : SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM,
            width : surface.mWidth,
            height : surface.mHeight,
            layer_count_or_depth : 1,
            num_levels : 1,
            usage : SDL_GPU_TEXTUREUSAGE_SAMPLER);
        mNoiseTexture = SDL_CreateGPUTexture(mGPUDevice, &textureInfo);
        
        // Upload texture data via transfer buffer
        SDL_GPUTransferBufferCreateInfo texTransferInfo = SDL_GPUTransferBufferCreateInfo.init;
        texTransferInfo.size = surface.mWidth * surface.mHeight * 4; // RGBA
        texTransferInfo.usage = SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD;
        SDL_GPUTransferBuffer* mTexTransferBuffer  = SDL_CreateGPUTransferBuffer(mGPUDevice, &texTransferInfo);

        // Copy surface data to transfer buffer
        void* texData = SDL_MapGPUTransferBuffer(mGPUDevice, mTexTransferBuffer, false);
        SDL_memcpy(texData, cast(void*) surface.mPixels, surface.mWidth * surface.mHeight * 4);
        SDL_UnmapGPUTransferBuffer(mGPUDevice, mTexTransferBuffer);

        // Create sampler 
        mNoiseSampler = SDL_CreateGPUSampler(mGPUDevice, &samplerInfo);

        // Get a command buffer to upload the texture
        SDL_GPUCommandBuffer* commandBuffer = SDL_AcquireGPUCommandBuffer(mGPUDevice);
        SDL_GPUCopyPass* texCopyPass = SDL_BeginGPUCopyPass(commandBuffer);

        // Set up the texture upload
        SDL_GPUTextureTransferInfo TexTransferInfo = SDL_GPUTextureTransferInfo.init;
        TexTransferInfo.transfer_buffer = mTexTransferBuffer;
        TexTransferInfo.offset = 0;
        TexTransferInfo.pixels_per_row = surface.mWidth;  
        TexTransferInfo.rows_per_layer = surface.mHeight; 

        SDL_GPUTextureRegion textureRegion = SDL_GPUTextureRegion.init;
        textureRegion.texture = mNoiseTexture;
        textureRegion.w = surface.mWidth;
        textureRegion.h = surface.mHeight;
        textureRegion.x = 0;  
        textureRegion.y = 0;  
        textureRegion.z = 0;  
        textureRegion.d = 1;

        // Upload the texture
        SDL_UploadToGPUTexture(texCopyPass, &TexTransferInfo, &textureRegion, false);

        // End copy pass and submit
        SDL_EndGPUCopyPass(texCopyPass);
        SDL_SubmitGPUCommandBuffer(commandBuffer);
        SDL_WaitForGPUIdle(mGPUDevice); 

        // PASS 2: Outliner, to the screen!

        // PART 1: Create the shaders!
        // load the vertex shader code
        size_t vertexCodeSize; 
        void* vertexCode = SDL_LoadFile("pipelines/outliner/vertex.spv", &vertexCodeSize);
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
        void* fragmentCode = SDL_LoadFile("pipelines/outliner/fragment.spv", &fragmentCodeSize);
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
        fragmentInfo.num_samplers = 3;
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

        /*
         PART 2: Vertex/Index Buffers to draw the texture across the screen
        */
        float[] quadVertices = [
            // positions        // texCoords
            -1.0f,  1.0f, 0.0f,  0.0f, 1.0f,  // Top-left
            -1.0f, -1.0f, 0.0f,  0.0f, 0.0f,  // Bottom-left
            1.0f, -1.0f, 0.0f,  1.0f, 0.0f,  // Bottom-right
            1.0f,  1.0f, 0.0f,  1.0f, 1.0f   // Top-right
        ];

        uint[] quadIndices = [
            0, 1, 2,  // First triangle
            0, 2, 3   // Second triangle
        ];


        // create the vertex buffer
        SDL_GPUBufferCreateInfo vertexbufferInfo = SDL_GPUBufferCreateInfo.init;
        vertexbufferInfo.size = cast(uint) (quadVertices.length * float.sizeof);
        vertexbufferInfo.usage = SDL_GPU_BUFFERUSAGE_VERTEX;
        mQuadVertexBuffer = SDL_CreateGPUBuffer(mGPUDevice, &vertexbufferInfo);

        // create a transfer buffer to upload to the vertex buffer
        SDL_GPUTransferBufferCreateInfo vertextransferInfo = SDL_GPUTransferBufferCreateInfo.init;
        vertextransferInfo.size = cast(uint) (quadVertices.length * float.sizeof);
        vertextransferInfo.usage = SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD;
        SDL_GPUTransferBuffer* mQuadTransferBuffer = SDL_CreateGPUTransferBuffer(mGPUDevice, &vertextransferInfo);

        // fill the transfer buffer
        void* quad_data = SDL_MapGPUTransferBuffer(mGPUDevice, mQuadTransferBuffer, false);
        SDL_memcpy(quad_data, cast(void*)quadVertices, quadVertices.length * float.sizeof);

        // unmap the pointer when you are done updating the transfer buffer
        SDL_UnmapGPUTransferBuffer(mGPUDevice, mQuadTransferBuffer);

        // upload to GPU
        SDL_GPUCommandBuffer* uploadCmd = SDL_AcquireGPUCommandBuffer(mGPUDevice);
        SDL_GPUCopyPass* copyPass = SDL_BeginGPUCopyPass(uploadCmd);
        SDL_GPUTransferBufferLocation transferLoc;
        transferLoc.transfer_buffer = mQuadTransferBuffer;
        transferLoc.offset = 0;
        SDL_GPUBufferRegion bufferRegion;
        bufferRegion.buffer = mQuadVertexBuffer;
        bufferRegion.offset = 0;
        bufferRegion.size = cast(uint) (quadVertices.length * float.sizeof);
        SDL_UploadToGPUBuffer(copyPass, &transferLoc, &bufferRegion, false);
        SDL_EndGPUCopyPass(copyPass);
        SDL_SubmitGPUCommandBuffer(uploadCmd);
        SDL_WaitForGPUIdle(mGPUDevice);
        SDL_ReleaseGPUTransferBuffer(mGPUDevice, mQuadTransferBuffer);

        // create the index buffer
        SDL_GPUBufferCreateInfo indexbufferInfo = SDL_GPUBufferCreateInfo.init;
        indexbufferInfo.size = cast(uint) (quadIndices.length * uint.sizeof);
        indexbufferInfo.usage = SDL_GPU_BUFFERUSAGE_INDEX;
        mQuadIndexBuffer = SDL_CreateGPUBuffer(mGPUDevice, &indexbufferInfo);

        // create a transfer buffer to upload to the index buffer
        SDL_GPUTransferBufferCreateInfo indextransferInfo = SDL_GPUTransferBufferCreateInfo.init;
        indextransferInfo.size = cast(uint) (quadIndices.length * uint.sizeof);
        indextransferInfo.usage = SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD;
        SDL_GPUTransferBuffer* mQuadIndTransferBuffer = SDL_CreateGPUTransferBuffer(mGPUDevice, &indextransferInfo);

        // fill the transfer buffer
        void* index_data = SDL_MapGPUTransferBuffer(mGPUDevice, mQuadIndTransferBuffer, false);
        SDL_memcpy(index_data, cast(void*)quadIndices, quadIndices.length * uint.sizeof);

        // unmap the pointer when you are done updating the transfer buffer
        SDL_UnmapGPUTransferBuffer(mGPUDevice, mQuadIndTransferBuffer);

        // upload to GPU
        uploadCmd = SDL_AcquireGPUCommandBuffer(mGPUDevice);
        copyPass = SDL_BeginGPUCopyPass(uploadCmd);
        transferLoc.transfer_buffer = mQuadIndTransferBuffer;
        transferLoc.offset = 0;
        bufferRegion.buffer = mQuadIndexBuffer;
        bufferRegion.offset = 0;
        bufferRegion.size = cast(uint) (quadIndices.length * uint.sizeof);
        SDL_UploadToGPUBuffer(copyPass, &transferLoc, &bufferRegion, false);
        SDL_EndGPUCopyPass(copyPass);
        SDL_SubmitGPUCommandBuffer(uploadCmd);
        SDL_WaitForGPUIdle(mGPUDevice);
        SDL_ReleaseGPUTransferBuffer(mGPUDevice, mQuadIndTransferBuffer);

        /*
         PART 3: Create the pipeline
        */
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
        vertexBufferDesctiptions[0].pitch = 5 * float.sizeof;

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
        vertexAttributes[1].format = SDL_GPU_VERTEXELEMENTFORMAT_FLOAT2; //vec2
        vertexAttributes[1].offset = float.sizeof * 3; // 4th float from current buffer position

        pipelineInfo.vertex_input_state.num_vertex_attributes = 2;
        pipelineInfo.vertex_input_state.vertex_attributes = vertexAttributes.ptr;

        // describe the color target
        SDL_GPUColorTargetDescription[1] colorTargetDescriptions;
        colorTargetDescriptions[0] = SDL_GPUColorTargetDescription.init;
        colorTargetDescriptions[0].blend_state.enable_blend = false;
        colorTargetDescriptions[0].blend_state.color_blend_op = SDL_GPU_BLENDOP_ADD;
        colorTargetDescriptions[0].blend_state.alpha_blend_op = SDL_GPU_BLENDOP_ADD;
        colorTargetDescriptions[0].blend_state.src_color_blendfactor = SDL_GPU_BLENDFACTOR_SRC_ALPHA;
        colorTargetDescriptions[0].blend_state.dst_color_blendfactor = SDL_GPU_BLENDFACTOR_ONE_MINUS_SRC_ALPHA;
        colorTargetDescriptions[0].blend_state.src_alpha_blendfactor = SDL_GPU_BLENDFACTOR_SRC_ALPHA;
        colorTargetDescriptions[0].blend_state.dst_alpha_blendfactor = SDL_GPU_BLENDFACTOR_ONE_MINUS_SRC_ALPHA;
        colorTargetDescriptions[0].format = SDL_GetGPUSwapchainTextureFormat(mGPUDevice, mWindow);

        pipelineInfo.target_info.num_color_targets = 1;
        pipelineInfo.target_info.color_target_descriptions = colorTargetDescriptions.ptr;

        // No depth buffer this time
        pipelineInfo.target_info.has_depth_stencil_target = false;
        pipelineInfo.primitive_type = SDL_GPU_PRIMITIVETYPE_TRIANGLELIST;
        pipelineInfo.rasterizer_state.front_face = SDL_GPU_FRONTFACE_CLOCKWISE;
        pipelineInfo.rasterizer_state.cull_mode = SDL_GPU_CULLMODE_NONE;

        mOutlinerPipeline = SDL_CreateGPUGraphicsPipeline(mGPUDevice, &pipelineInfo);

        // Free the shaders
        SDL_ReleaseGPUShader(mGPUDevice, mVertexShader);
        SDL_ReleaseGPUShader(mGPUDevice, mFragShader);
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
                else if(event.key.scancode == SDL_SCANCODE_DOWN){
                    writeln("Down!");
                    mCamera.MoveBackward();
                }
                else if(event.key.scancode == SDL_SCANCODE_UP){
                    writeln("Up!");
                    mCamera.MoveForward();
                }
                else if(event.key.scancode == SDL_SCANCODE_LEFT){
                    writeln("Left!");
                    mCamera.MoveLeft();
                }
                else if(event.key.scancode== SDL_SCANCODE_RIGHT){
                    writeln("Right!");
                    mCamera.MoveRight();
                }
                else if(event.key.scancode == SDL_SCANCODE_A){
                    writeln("Ascend!");
                    mCamera.MoveUp();
                }
                else if(event.key.scancode == SDL_SCANCODE_Z){
                    writeln("Descend!");
                    mCamera.MoveDown();
                }
                else if(event.key.scancode == SDL_SCANCODE_SPACE){
                    writeln("|| DEBUGGING... ||");
                    writeln("Eye");
                    writeln(mCamera.mEyePosition);
                    writeln("View Matrix");
                    writeln(mCamera.mViewMatrix);
                    writeln("View Matrix for (GPU)");
                    writeln(cameraUniform.uView);
                    writeln("Projection Matrix");
                    writeln(mCamera.mProjectionMatrix);
                    writeln("Projection Matrix for (GPU)");
                    writeln(cameraUniform.uProjection);
                }
            }
        }
        // Retrieve the mouse position
        float mouseX,mouseY;
        SDL_GetMouseState(&mouseX,&mouseY);
        mCamera.MouseLook(mouseX,mouseY);
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

        // add camera buffers
        cameraUniform.uModel = mCamera.mModelMatrix;
        cameraUniform.uView = mCamera.mViewMatrix;
        cameraUniform.uProjection = mCamera.mProjectionMatrix;
        SDL_PushGPUVertexUniformData(commandBuffer, 0, &cameraUniform, cameraUniform.sizeof);

        SDL_PushGPUVertexUniformData(commandBuffer, 1, &mCamera.mEyePosition, vec3.sizeof);

        // add light information
        import std.math;
        static float inc = 0.0f;
        float radius = 2.0f;
        inc+=0.01;
        mLight.mPosition = [mCamera.mEyePosition[0], mCamera.mEyePosition[1], mCamera.mEyePosition[2], 0.0f];
        //mLight.mPosition = [radius*cos(inc),0.0f,radius*sin(inc), 0.0f];
        SDL_PushGPUFragmentUniformData(commandBuffer, 0, &mLight, mLight.sizeof);

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
            

        // end the frame early if a swapchain texture is not available
        if (swapchainTexture == null)
        {
            SDL_SubmitGPUCommandBuffer(commandBuffer);
        }
        
        // retrieve depthtexture 
        if (depthWidth != width || depthHeight != height)
        {
            if (depthTexture != null)
            {
                SDL_ReleaseGPUTexture(mGPUDevice, depthTexture);
            }
            SDL_GPUTextureCreateInfo depthTextureInfo = SDL_GPUTextureCreateInfo(type : SDL_GPU_TEXTURETYPE_2D,
                format : depthFormat,
                width : width,
                height : height,
                layer_count_or_depth : 1,
                num_levels : 1,
                usage : SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET);
            
            depthTexture = SDL_CreateGPUTexture(mGPUDevice, &depthTextureInfo);
            depthWidth = width;
            depthHeight = height;
        }
        
        // Create the color target
        SDL_GPUColorTargetInfo[2] colorTargetInfo;

        // holding position info first
        colorTargetInfo[0] = SDL_GPUColorTargetInfo.init;
        colorTargetInfo[0].clear_color = SDL_FColor(r: 0.0f, g: 0.0f, b: 0.0f, a: 0.0f);
        colorTargetInfo[0].load_op = SDL_GPU_LOADOP_CLEAR;
        colorTargetInfo[0].store_op = SDL_GPU_STOREOP_STORE;
        colorTargetInfo[0].texture = mPositionTexture;
        colorTargetInfo[0].cycle = false;
        
        // then color info
        colorTargetInfo[1] = SDL_GPUColorTargetInfo.init;
        colorTargetInfo[1].clear_color = SDL_FColor(r: 147/255.0f, g: 202/255.0f, b: 237/255.0f, a: 255/255.0f);
        colorTargetInfo[1].load_op = SDL_GPU_LOADOP_CLEAR;
        colorTargetInfo[1].store_op = SDL_GPU_STOREOP_STORE;
        colorTargetInfo[1].texture = mColorTexture;
        colorTargetInfo[1].cycle = false;
        
        // Depth buffer
        SDL_GPUDepthStencilTargetInfo depthStencilTargetInfo = SDL_GPUDepthStencilTargetInfo.init;
        depthStencilTargetInfo.texture = depthTexture;
        depthStencilTargetInfo.clear_depth = 1.0f;
        depthStencilTargetInfo.clear_stencil = 0;
        depthStencilTargetInfo.load_op = SDL_GPU_LOADOP_CLEAR;
        depthStencilTargetInfo.store_op = SDL_GPU_STOREOP_DONT_CARE;
        depthStencilTargetInfo.stencil_load_op = SDL_GPU_LOADOP_CLEAR;
        depthStencilTargetInfo.stencil_store_op = SDL_GPU_STOREOP_DONT_CARE;
        depthStencilTargetInfo.cycle = true;

        // PASS 1: Scene

        // begin a render pass to capture the scene
        SDL_GPURenderPass* scenePass = SDL_BeginGPURenderPass(commandBuffer, colorTargetInfo.ptr, 2, &depthStencilTargetInfo);

        // bind the graphics pipeline
        SDL_BindGPUGraphicsPipeline(scenePass, mGraphicsPipeline);

        // Bind texture and sampler
        SDL_GPUTextureSamplerBinding textureSamplerBinding = SDL_GPUTextureSamplerBinding.init;
        textureSamplerBinding.texture = mTexture;
        textureSamplerBinding.sampler = mSampler;
        SDL_BindGPUFragmentSamplers(scenePass, 0, &textureSamplerBinding, 1);

        // bind the vertex buffer
        SDL_GPUBufferBinding[1] bufferBindings;
        bufferBindings[0] = SDL_GPUBufferBinding.init;
        bufferBindings[0].buffer = mVertexBuffer; // index 0 is slot 0 in this example
        bufferBindings[0].offset = 0; // start from the first byte

        SDL_BindGPUVertexBuffers(scenePass, 0, bufferBindings.ptr, 1); // bind one buffer starting from slot 0
        
        // issue a draw call
        SDL_DrawGPUPrimitives(scenePass, cast(uint) vertices.length, 1, 0, 0);
        
        // end the initial scene pass
        SDL_EndGPURenderPass(scenePass);

        // PASS 2 : Outliner!
        SDL_GPUColorTargetInfo screenTarget = SDL_GPUColorTargetInfo.init;
        screenTarget.clear_color = SDL_FColor(r: 245/255.0f, g: 135/255.0f, b: 66/255.0f, a: 255/255.0f);
        screenTarget.load_op = SDL_GPU_LOADOP_CLEAR;
        screenTarget.store_op = SDL_GPU_STOREOP_STORE;
        screenTarget.texture = swapchainTexture;

        // begin a render pass to do outlining
        SDL_GPURenderPass* renderPass = SDL_BeginGPURenderPass(commandBuffer, &screenTarget, 1, null);

        SDL_BindGPUGraphicsPipeline(renderPass, mOutlinerPipeline);

        // Bind position and color textures as samplers
        SDL_GPUTextureSamplerBinding[3] textureSamplers;
        textureSamplers[0].texture = mPositionTexture;
        textureSamplers[0].sampler = mPositionSampler;
        textureSamplers[1].texture = mColorTexture;
        textureSamplers[1].sampler = mColorSampler;
        textureSamplers[2].texture = mNoiseTexture;
        textureSamplers[2].sampler = mNoiseSampler;
        SDL_BindGPUFragmentSamplers(renderPass, 0, textureSamplers.ptr, 3);

        // Bind quad buffers
        SDL_GPUBufferBinding quadVertexBinding;
        quadVertexBinding.buffer = mQuadVertexBuffer;
        quadVertexBinding.offset = 0;
        SDL_BindGPUVertexBuffers(renderPass, 0, &quadVertexBinding, 1);

        SDL_GPUBufferBinding quadIndexBinding;
        quadIndexBinding.buffer = mQuadIndexBuffer;
        quadIndexBinding.offset = 0;
        SDL_BindGPUIndexBuffer(renderPass, &quadIndexBinding, SDL_GPU_INDEXELEMENTSIZE_32BIT);

        SDL_DrawGPUIndexedPrimitives(renderPass, 6, 1, 0, 0, 0);

        // end the initial scene pass
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

// ununused code to note pollute graphics app
// Norm Setup time
        // PPM bump_map = PPM.init;
        // bump_map.LoadPPMImage(m.norm_file_path);

        // // Norm
        // SDL_GPUTextureCreateInfo  normalInfo = SDL_GPUTextureCreateInfo(type : SDL_GPU_TEXTURETYPE_2D,
        //     format : SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM,
        //     width : bump_map.mWidth,
        //     height : bump_map.mHeight,
        //     layer_count_or_depth : 1,
        //     num_levels : 1,
        //     usage : SDL_GPU_TEXTUREUSAGE_SAMPLER);
        // mNormal = SDL_CreateGPUTexture(mGPUDevice, &normalInfo);
        
        // // Upload texture data via transfer buffer
        // SDL_GPUTransferBufferCreateInfo normTransferInfo = SDL_GPUTransferBufferCreateInfo.init;
        // normTransferInfo.size = bump_map.mWidth * bump_map.mHeight * 4; // RGBA
        // normTransferInfo.usage = SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD;
        // SDL_GPUTransferBuffer* mNormTransferBuffer  = SDL_CreateGPUTransferBuffer(mGPUDevice, &normTransferInfo);

        // // Copy surface data to transfer buffer
        // void* normData = SDL_MapGPUTransferBuffer(mGPUDevice, mNormTransferBuffer, false);
        // SDL_memcpy(normData, cast(void*) bump_map.mPixels, bump_map.mWidth * bump_map.mHeight * 4);
        // SDL_UnmapGPUTransferBuffer(mGPUDevice, mNormTransferBuffer);

        // // Create sampler 
        // mSamplerNormal = SDL_CreateGPUSampler(mGPUDevice, &samplerInfo);

        // // Set up the texture upload
        // SDL_GPUTextureTransferInfo NormTransferInfo = SDL_GPUTextureTransferInfo.init;
        // NormTransferInfo.transfer_buffer = mNormTransferBuffer;
        // NormTransferInfo.offset = 0;
        // NormTransferInfo.pixels_per_row = bump_map.mWidth;  
        // NormTransferInfo.rows_per_layer = bump_map.mHeight; 

        // SDL_GPUTextureRegion normalRegion = SDL_GPUTextureRegion.init;
        // normalRegion.texture = mNormal;
        // normalRegion.w = bump_map.mWidth;
        // normalRegion.h = bump_map.mHeight;
        // normalRegion.x = 0;  
        // normalRegion.y = 0;  
        // normalRegion.z = 0;  
        // normalRegion.d = 1;

        // // Upload the texture
        // SDL_UploadToGPUTexture(texCopyPass, &NormTransferInfo, &normalRegion, false);


// in render

// Bind normal and sampler
        //SDL_GPUTextureSamplerBinding normalSamplerBinding = SDL_GPUTextureSamplerBinding.init;
        //normalSamplerBinding.texture = mNormal;
        //normalSamplerBinding.sampler = mSamplerNormal;
        //SDL_BindGPUFragmentSamplers(renderPass, 1, &normalSamplerBinding, 1);
