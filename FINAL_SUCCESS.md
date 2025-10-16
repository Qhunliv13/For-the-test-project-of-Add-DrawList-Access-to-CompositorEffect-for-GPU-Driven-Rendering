# Compute Shader Direct Rendering Demo

Date: 2025-10-15

## Usage

### 1. Creating a CompositorEffect

Create a GDScript file extending CompositorEffect:

```gdscript
extends CompositorEffect

func _init():
    access_draw_list = true
    effect_callback_type = EFFECT_CALLBACK_TYPE_POST_TRANSPARENT
    enabled = true
```

### 2. Setting up GPU Resources

```gdscript
func setup():
    var rd = RenderingServer.get_rendering_device()
    
    # Create storage buffer for compute shader output
    var buffer_size = vertex_count * 16
    var buffer_data = PackedByteArray()
    buffer_data.resize(buffer_size)
    vertex_buffer = rd.storage_buffer_create(buffer_size, buffer_data)
    
    # Create compute shader
    var compute_file = load("res://compute.glsl")
    var compute_spirv = compute_file.get_spirv()
    compute_shader = rd.shader_create_from_spirv(compute_spirv)
    compute_pipeline = rd.compute_pipeline_create(compute_shader)
    
    # Create render shader
    var render_file = load("res://render.glsl")
    var render_spirv = render_file.get_spirv()
    render_shader = rd.shader_create_from_spirv(render_spirv)
    
    # Create camera uniform buffer (256 bytes for 4 matrices)
    var camera_size = 16 * 4 * 4
    camera_uniform_buffer = rd.uniform_buffer_create(camera_size)
```

### 3. Updating Camera Matrices

```gdscript
func update_buffers(render_data: RenderData):
    render_data.copy_camera_matrices_to_buffer(camera_uniform_buffer)
```

### 4. Rendering Callback

```gdscript
func _render_callback(callback_type: int, render_data: RenderData):
    var draw_list = render_data.get_current_draw_list()
    var framebuffer = render_data.get_current_framebuffer()
    
    if draw_list == -1:
        return
    
    var rd = RenderingServer.get_rendering_device()
    
    # Execute compute shader
    var compute_list = rd.compute_list_begin()
    rd.compute_list_bind_compute_pipeline(compute_list, compute_pipeline)
    rd.compute_list_bind_uniform_set(compute_list, compute_uniform_set, 0)
    rd.compute_list_dispatch(compute_list, vertex_count, 1, 1)
    rd.compute_list_end()
    
    # Render
    rd.draw_list_bind_render_pipeline(draw_list, render_pipeline)
    rd.draw_list_bind_uniform_set(draw_list, render_uniform_set, 0)
    rd.draw_list_bind_uniform_set(draw_list, camera_uniform_set, 1)
    rd.draw_list_bind_vertex_array(draw_list, vertex_array)
    rd.draw_list_draw(draw_list, false, 1)
```

### 5. Attaching to Camera

```gdscript
var compositor = Compositor.new()
var effect = MyCompositorEffect.new()
compositor.compositor_effects = [effect]

var camera = get_node("Camera3D")
camera.compositor = compositor
```

## Shader Setup

### Compute Shader (compute.glsl)

```glsl
#[compute]
#version 450

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

layout(set = 0, binding = 0, std430) buffer VertexBuffer {
    vec4 positions[];
} vertex_data;

void main() {
    uint vertex_id = gl_GlobalInvocationID.x;
    vertex_data.positions[vertex_id] = vec4(...);
}
```

### Render Shader (render.glsl)

```glsl
#[vertex]
#version 450

layout(set = 0, binding = 0, std430) buffer VertexBuffer {
    vec4 positions[];
} vertex_data;

layout(set = 1, binding = 0, std140) uniform CameraData {
    mat4 projection_matrix;
    mat4 inv_projection_matrix;
    mat4 inv_view_matrix;
    mat4 view_matrix;
} camera_data;

void main() {
    vec4 world_pos = vertex_data.positions[gl_VertexIndex];
    gl_Position = camera_data.projection_matrix * camera_data.view_matrix * world_pos;
}

#[fragment]
#version 450

layout(location = 0) out vec4 frag_color;

void main() {
    frag_color = vec4(1.0);
}
```

## Notes

- Use EFFECT_CALLBACK_TYPE_POST_TRANSPARENT for final screen output
- Depth testing requires depth_compare_operator = COMPARE_OP_GREATER_OR_EQUAL (Reverse-Z)
- Camera matrix buffer size must be exactly 256 bytes (16 floats * 4 matrices)

