@tool
extends CompositorEffect

const SPHERE_COUNT = 20000
const VERTICES_PER_SPHERE = 96

var rd: RenderingDevice
var compute_shader: RID
var compute_pipeline: RID
var render_shader: RID
var render_pipeline: RID

var vertex_buffer: RID
var color_buffer: RID
var params_buffer: RID
var camera_uniform_buffer: RID

var compute_uniform_set: RID
var render_uniform_set: RID
var camera_uniform_set: RID

var dummy_vertex_buffer: RID
var dummy_vertex_array: RID

var initialized: bool = false
var compute_time: float = 0.0
var render_time: float = 0.0

func _init():
	access_draw_list = true
	effect_callback_type = EFFECT_CALLBACK_TYPE_POST_TRANSPARENT
	enabled = true

func setup():
	rd = RenderingServer.get_rendering_device()
	if not rd:
		return false
	
	var total_vertices = SPHERE_COUNT * VERTICES_PER_SPHERE
	
	var vb_size = total_vertices * 16
	var vb_data = PackedByteArray()
	vb_data.resize(vb_size)
	vertex_buffer = rd.storage_buffer_create(vb_size, vb_data)
	
	var cb_size = total_vertices * 16
	var cb_data = PackedByteArray()
	cb_data.resize(cb_size)
	color_buffer = rd.storage_buffer_create(cb_size, cb_data)
	
	var params_data = PackedInt32Array([SPHERE_COUNT, VERTICES_PER_SPHERE, 0, 0])
	params_buffer = rd.storage_buffer_create(16, params_data.to_byte_array())
	
	var compute_file = load("res://benchmark_compute.glsl")
	var compute_spirv = compute_file.get_spirv()
	compute_shader = rd.shader_create_from_spirv(compute_spirv)
	compute_pipeline = rd.compute_pipeline_create(compute_shader)
	
	var compute_uniforms = []
	
	var u_vertex = RDUniform.new()
	u_vertex.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	u_vertex.binding = 0
	u_vertex.add_id(vertex_buffer)
	compute_uniforms.append(u_vertex)
	
	var u_color = RDUniform.new()
	u_color.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	u_color.binding = 1
	u_color.add_id(color_buffer)
	compute_uniforms.append(u_color)
	
	var u_params = RDUniform.new()
	u_params.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	u_params.binding = 2
	u_params.add_id(params_buffer)
	compute_uniforms.append(u_params)
	
	compute_uniform_set = rd.uniform_set_create(compute_uniforms, compute_shader, 0)
	
	var render_file = load("res://benchmark_render.glsl")
	var render_spirv = render_file.get_spirv()
	render_shader = rd.shader_create_from_spirv(render_spirv)
	
	var render_uniforms = []
	
	var u_vertex_render = RDUniform.new()
	u_vertex_render.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	u_vertex_render.binding = 0
	u_vertex_render.add_id(vertex_buffer)
	render_uniforms.append(u_vertex_render)
	
	var u_color_render = RDUniform.new()
	u_color_render.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	u_color_render.binding = 1
	u_color_render.add_id(color_buffer)
	render_uniforms.append(u_color_render)
	
	render_uniform_set = rd.uniform_set_create(render_uniforms, render_shader, 0)
	
	var camera_size = 16 * 4 * 4
	var camera_init = PackedByteArray()
	camera_init.resize(camera_size)
	camera_uniform_buffer = rd.uniform_buffer_create(camera_size, camera_init)
	
	var camera_uniforms = []
	var u_camera = RDUniform.new()
	u_camera.uniform_type = RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER
	u_camera.binding = 0
	u_camera.add_id(camera_uniform_buffer)
	camera_uniforms.append(u_camera)
	
	camera_uniform_set = rd.uniform_set_create(camera_uniforms, render_shader, 1)
	
	var dummy_data = PackedByteArray()
	dummy_data.resize(total_vertices * 16)
	dummy_vertex_buffer = rd.vertex_buffer_create(dummy_data.size(), dummy_data)
	
	var va = RDVertexAttribute.new()
	va.location = 0
	va.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
	va.stride = 16
	va.offset = 0
	var vf = rd.vertex_format_create([va])
	
	dummy_vertex_array = rd.vertex_array_create(total_vertices, vf, [dummy_vertex_buffer])
	
	initialized = true
	return true

func update_buffers(render_data: RenderData):
	if not initialized:
		if not setup():
			return
	
	if not rd:
		return
	
	render_data.copy_camera_matrices_to_buffer(camera_uniform_buffer)

func _render_callback(callback_type: int, render_data: RenderData):
	if not initialized:
		return
	
	var draw_list = render_data.get_current_draw_list()
	var framebuffer = render_data.get_current_framebuffer()
	
	if draw_list == -1:
		return
	
	var compute_start = Time.get_ticks_usec()
	
	var compute_list = rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, compute_pipeline)
	rd.compute_list_bind_uniform_set(compute_list, compute_uniform_set, 0)
	var total_vertices = SPHERE_COUNT * VERTICES_PER_SPHERE
	var dispatch_count = (total_vertices + 63) / 64
	rd.compute_list_dispatch(compute_list, dispatch_count, 1, 1)
	rd.compute_list_end()
	
	var compute_end = Time.get_ticks_usec()
	compute_time = (compute_end - compute_start) / 1000.0
	
	if not render_pipeline.is_valid():
		var fb_fmt = rd.framebuffer_get_format(framebuffer)
		
		var blend = RDPipelineColorBlendState.new()
		for i in range(8):
			var att = RDPipelineColorBlendStateAttachment.new()
			att.enable_blend = true
			att.src_color_blend_factor = RenderingDevice.BLEND_FACTOR_SRC_ALPHA
			att.dst_color_blend_factor = RenderingDevice.BLEND_FACTOR_ONE_MINUS_SRC_ALPHA
			blend.attachments.append(att)
		
		var va = RDVertexAttribute.new()
		va.location = 0
		va.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
		va.stride = 16
		va.offset = 0
		var vf = rd.vertex_format_create([va])
		
		var raster = RDPipelineRasterizationState.new()
		raster.cull_mode = RenderingDevice.POLYGON_CULL_DISABLED
		
		var depth = RDPipelineDepthStencilState.new()
		depth.enable_depth_test = true
		depth.enable_depth_write = true
		depth.depth_compare_operator = RenderingDevice.COMPARE_OP_GREATER_OR_EQUAL
		
		render_pipeline = rd.render_pipeline_create(
			render_shader, fb_fmt, vf,
			RenderingDevice.RENDER_PRIMITIVE_TRIANGLES,
			raster, RDPipelineMultisampleState.new(),
			depth, blend
		)
		
		if not render_pipeline.is_valid():
			return
	
	var render_start = Time.get_ticks_usec()
	
	rd.draw_list_bind_render_pipeline(draw_list, render_pipeline)
	rd.draw_list_bind_uniform_set(draw_list, render_uniform_set, 0)
	rd.draw_list_bind_uniform_set(draw_list, camera_uniform_set, 1)
	rd.draw_list_bind_vertex_array(draw_list, dummy_vertex_array)
	rd.draw_list_draw(draw_list, false, 1)
	
	var render_end = Time.get_ticks_usec()
	render_time = (render_end - render_start) / 1000.0

func get_stats() -> Dictionary:
	return {
		"compute_time": compute_time,
		"render_time": render_time,
		"total_time": compute_time + render_time,
		"sphere_count": SPHERE_COUNT,
		"vertices": SPHERE_COUNT * VERTICES_PER_SPHERE
	}
