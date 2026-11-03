class_name BoletoBarcode
extends Control
## The bar code at the foot of a boleto, drawn from its code
##
## Only a picture: the same code always draws the same bars, and a different code different ones.

const INK := Color(0.09019608, 0.10980392, 0.18039216)
## Widths a bar or a gap can have, in pixels
const WIDTHS := [1.0, 2.0, 3.0]

var _code: String = ""


func setup(code: String) -> void:
	_code = code
	queue_redraw()


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(_code)

	var x := 0.0
	var is_bar := true
	while x < size.x:
		var width: float = WIDTHS[rng.randi_range(0, WIDTHS.size() - 1)]
		if is_bar:
			draw_rect(Rect2(x, 0.0, minf(width, size.x - x), size.y), INK)
		x += width
		is_bar = not is_bar
