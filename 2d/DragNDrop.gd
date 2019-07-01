extends TextureButton

var dragging : bool = false
var originalMouseDelta : Vector2
var dragSpeed : float = INF

func _on_DragNDrop_button_down():
	dragging = true
	originalMouseDelta = get_viewport().get_mouse_position() - self.rect_position

func _on_DragNDrop_button_up():
	dragging = false

func _process(delta):
	if dragging:
		var target : Vector2 = get_viewport().get_mouse_position() - originalMouseDelta
		if (rect_position - target).length() < dragSpeed:
			rect_position = target
		else:
			rect_position -= dragSpeed * (rect_position - target).normalized()
