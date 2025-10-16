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

layout(location = 0) out vec3 color_out;

void main() {
    vec4 world_pos = vertex_data.positions[gl_VertexIndex];
    gl_Position = camera_data.projection_matrix * camera_data.view_matrix * world_pos;
    
    color_out = vec3(0.0, 0.0, 1.0);
}

#[fragment]
#version 450

layout(location = 0) in vec3 color_out;
layout(location = 0) out vec4 frag_color;

void main() {
    frag_color = vec4(color_out, 1.0);
}

