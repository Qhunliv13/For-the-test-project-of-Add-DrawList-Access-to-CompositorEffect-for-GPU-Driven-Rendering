#[compute]
#version 450

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

layout(set = 0, binding = 0, std430) buffer VertexBuffer {
    vec4 positions[];
} vertex_data;

layout(set = 0, binding = 1, std430) buffer TimeBuffer {
    float time;
} time_data;

void main() {
    uint vertex_id = gl_GlobalInvocationID.x;
    
    if (vertex_id == 0) {
        vertex_data.positions[0] = vec4(0.0, 2.0, 0.0, 1.0);
    } else if (vertex_id == 1) {
        vertex_data.positions[1] = vec4(-2.0, -2.0, 0.0, 1.0);
    } else if (vertex_id == 2) {
        vertex_data.positions[2] = vec4(2.0, -2.0, 0.0, 1.0);
    }
}

