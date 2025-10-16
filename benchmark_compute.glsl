#[compute]
#version 450

layout(local_size_x = 64, local_size_y = 1, local_size_z = 1) in;

layout(set = 0, binding = 0, std430) buffer VertexBuffer {
    vec4 positions[];
} vertex_data;

layout(set = 0, binding = 1, std430) buffer ColorBuffer {
    vec4 colors[];
} color_data;

layout(set = 0, binding = 2, std430) buffer ParamsBuffer {
    uint sphere_count;
    uint vertices_per_sphere;
    float time;
    float padding;
} params;

const float PI = 3.14159265359;
const float TAU = 6.28318530718;

vec3 get_sphere_vertex(uint local_id, uint sphere_id) {
    uint rings = 4;
    uint sectors = 8;
    
    uint ring = local_id / sectors;
    uint sector = local_id % sectors;
    
    float theta = float(ring) / float(rings) * PI;
    float phi = float(sector) / float(sectors) * TAU;
    
    float x = sin(theta) * cos(phi) * 0.3;
    float y = cos(theta) * 0.3;
    float z = sin(theta) * sin(phi) * 0.3;
    
    float angle = float(sphere_id) / float(params.sphere_count) * TAU;
    float radius = 10.0;
    float height = sin(angle * 5.0) * 3.0;
    
    float sphere_x = cos(angle) * radius;
    float sphere_z = sin(angle) * radius;
    float sphere_y = height;
    
    return vec3(x + sphere_x, y + sphere_y, z + sphere_z);
}

vec3 get_sphere_color(uint sphere_id) {
    return vec3(0.0, 0.0, 1.0);
}

void main() {
    uint vertex_id = gl_GlobalInvocationID.x;
    uint total_vertices = params.sphere_count * params.vertices_per_sphere;
    
    if (vertex_id >= total_vertices) {
        return;
    }
    
    uint sphere_id = vertex_id / params.vertices_per_sphere;
    uint local_id = vertex_id % params.vertices_per_sphere;
    
    vec3 pos = get_sphere_vertex(local_id, sphere_id);
    vec3 color = get_sphere_color(sphere_id);
    
    vertex_data.positions[vertex_id] = vec4(pos, 1.0);
    color_data.colors[vertex_id] = vec4(color, 1.0);
}

