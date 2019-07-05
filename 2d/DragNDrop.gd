extends TextureButton

var dragging : bool = false
var originalMouseDelta : Vector2
var dragSpeed : float = 3.0
var restPos : Vector2

export (bool) var enableRestPos = false

func _ready():
	restPos = self.rect_position

func _on_DragNDrop_button_down():
	restPos = self.rect_position
	dragging = true
	originalMouseDelta = get_viewport().get_mouse_position() - self.rect_position
	Global.currentDragNDrop = self

func _on_DragNDrop_button_up():
	dragging = false
	if Global.currentDragNDrop == self:
		Global.currentDragNDrop = null

func _process(delta):
	if dragging:
		var target : Vector2 = get_viewport().get_mouse_position() - originalMouseDelta
		rect_position = interpolatePos(rect_position, target, dragSpeed)
	elif enableRestPos:
		if self.rect_position != restPos:
			rect_position = interpolatePos(rect_position, restPos, dragSpeed)

func interpolatePos(pos, targetPos, speed : float):
	if (pos - targetPos).length() < speed:
		return targetPos
	else:
		return pos -(speed * (pos - targetPos).normalized())