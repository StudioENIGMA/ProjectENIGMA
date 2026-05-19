extends Node

var api: ModLoaderAPI


func _on_mod_load(mod_api: ModLoaderAPI) -> void:
	api = mod_api
	api.info("ativo — valores em R$ serão substituídos por expressões matemáticas extremas")
	api.hook("post_data_load", _on_data_loaded)


func _on_data_loaded(roots: Dictionary) -> void:
	var rewritten := 0
	var message_roots: Array = roots.get("messages", [])
	for thread in message_roots:
		if typeof(thread) != TYPE_DICTIONARY:
			continue
		var branches: Dictionary = thread.get("branches", {})
		for branch_name in branches.keys():
			for msg in branches[branch_name]:
				if typeof(msg) != TYPE_DICTIONARY:
					continue
				if _rewrite_message_object(msg):
					rewritten += 1
	api.info("aplicado em %d mensagens" % rewritten)


func _rewrite_message_object(msg: Dictionary) -> bool:
	var changed := false
	if msg.has("text") and typeof(msg["text"]) == TYPE_STRING:
		var new_text := _substitute_money(msg["text"])
		if new_text != msg["text"]:
			msg["text"] = new_text
			changed = true
	if msg.has("choices") and typeof(msg["choices"]) == TYPE_ARRAY:
		for choice in msg["choices"]:
			if typeof(choice) != TYPE_DICTIONARY:
				continue
			if choice.has("player_text") and typeof(choice["player_text"]) == TYPE_STRING:
				var new_choice := _substitute_money(choice["player_text"])
				if new_choice != choice["player_text"]:
					choice["player_text"] = new_choice
					changed = true
	return changed


# Matches "R$ 58", "R$ 58,90", "R$ 5.000", "R$ 5.000,00", "R$58,90", etc.
func _substitute_money(text: String) -> String:
	var rx := RegEx.new()
	rx.compile("R\\$\\s*([\\d.]+)(,(\\d+))?")
	var matches := rx.search_all(text)
	if matches.is_empty():
		return text

	var result := text
	# Process in reverse so earlier indices remain valid after each substitution
	matches.reverse()
	for m in matches:
		var int_str: String = m.get_string(1)
		var int_part: int = int(int_str.replace(".", ""))
		var dec_part: String = m.get_string(3)

		var expr: String
		if dec_part != "":
			expr = "R$ %s,%s" % [_express_int(int_part), dec_part]
		else:
			expr = "R$ %s" % _express_int(int_part)

		result = result.substr(0, m.get_start()) + expr + result.substr(m.get_end())
	return result


# Returns an expression equivalent to n, but n itself NEVER appears
# literally in the rendered string. The player has to actually compute
# something to find out the value. Salt values are derived deterministically
# from n via hash-style arithmetic, so the same amount always renders the
# same way across reloads.
func _express_int(n: int) -> String:
	if n == 0:
		return "(cos(π/2) · 47)"

	var seed_val: int = abs(n)
	var idx: int = seed_val % 6

	var salt_a: int = ((seed_val * 31) % 947) + 137
	var salt_b: int = ((seed_val * 67) % 1117) + 211

	match idx:
		0:
			# (a + b) where a + b = n
			# Switch to subtractive form when salt_a >= n to avoid a negative term
			if salt_a >= n:
				return "(%d − %d)" % [salt_a, salt_a - n]
			return "(%d + %d)" % [salt_a, n - salt_a]
		1:
			# (a − b) where a − b = n, a = n + b
			return "(%d − %d)" % [n + salt_b, salt_b]
		2:
			# (∫_a^b dx) where b − a = n
			return "(∫_%d^%d dx)" % [salt_a, salt_a + n]
		3:
			# (Σᵢ₌ₐ^b 1) where b − a + 1 = n
			return "(Σᵢ₌%d^%d 1)" % [salt_a, salt_a + n - 1]
		4:
			# ((a · b) − c) where a·b − c = n.
			# a, b scaled to roughly sqrt(n) so the multiplication is non-trivial
			# regardless of how big n is.
			var sqrt_n: int = int(sqrt(float(max(1, n))))
			var base: int = sqrt_n + 17
			var a: int = base + (seed_val % 31) + 3
			var b: int = base + ((seed_val * 7) % 37) + 5
			var c: int = a * b - n
			return "((%d · %d) − %d)" % [a, b, c]
		5:
			# ((a + b) − c) where a + b − c = n.
			# Need a + b > n so c stays positive; scale up if salt sum is too small.
			var a5: int = salt_a
			var b5: int = salt_b
			if a5 + b5 <= n:
				var scale: int = (n / (a5 + b5)) + 2
				a5 *= scale
				b5 *= scale
			return "((%d + %d) − %d)" % [a5, b5, a5 + b5 - n]
	return str(n)
