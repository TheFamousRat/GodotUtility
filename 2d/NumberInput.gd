extends LineEdit

export (bool) var allowFloats = false
export (bool) var allowNegative = false
export (int, 0, 12) var intPartMaxLen = 5
export (int, 0, 12) var fracPartMaxLen = 5

signal numberUpdated

var prevText : String

func get_number() -> float:
	return str2var(self.text)

func _on_NumberInput_text_changed(new_text):
	var savedCaretPos : int = self.caret_position
	var changedText : bool = true

	var intPart : String = ""
	var fracPart : String = ""
	var dotPos : int = new_text.find(".")

	intPart = new_text.substr(0,dotPos)
	fracPart = new_text.substr(dotPos + 1, new_text.length() - dotPos)

	if !allowNegative and intPart.find("-") != -1:
		intPart = intPart.substr(1,intPart.length() - 1)

	if dotPos == -1:
		intPart = fracPart
		fracPart = ""

	if intPart == "":
		intPart = "0"
	elif intPart == "-":
		intPart = "-0"

	if (intPart == "" or intPart.is_valid_integer()) and (fracPart == "" or fracPart.is_valid_integer()) and intPart.length() <= intPartMaxLen + int(intPart.find("-") != -1) and fracPart.length() <= fracPartMaxLen:

		if !allowFloats:
			fracPart = ""
			self.text = intPart
		else:
			self.text = intPart + "." + fracPart

		prevText = self.text
	else:
		changedText = false

	if !changedText:
		self.text = prevText
		savedCaretPos -= 1
	else:
		emit_signal("numberUpdated", get_number())

	self.caret_position = savedCaretPos
