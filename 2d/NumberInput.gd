extends LineEdit

export (bool) var allowFloats = false
export (bool) var allowNegative = false

func _on_NumberInput_text_changed(new_text):
	if new_text.begins_with(".") and allowFloats:
		self.text = "0" + new_text
		self.caret_position += 1
	elif new_text != str(str2var(new_text)) and (new_text != "-" or !allowNegative) and (!new_text.ends_with(".") and !allowFloats):
		self.text = str(str2var(new_text))
		self.caret_position = self.text.length()