@tool
extends CompositorEffect

var parent_renderer = null

func _init():
	effect_callback_type = EFFECT_CALLBACK_TYPE_PRE_TRANSPARENT
	enabled = true

func set_parent(p):
	parent_renderer = p

func _render_callback(callback_type: int, render_data: RenderData):
	if parent_renderer and parent_renderer.has_method("update_buffers"):
		parent_renderer.update_buffers(render_data)

