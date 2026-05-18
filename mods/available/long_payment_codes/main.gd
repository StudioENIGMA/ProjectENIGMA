extends Node

const TARGET_LENGTH := 30
const CHARSET := "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

var api: ModLoaderAPI
var _code_remap: Dictionary = {}
var _word_boundary_cache: Dictionary = {}


func _on_mod_load(mod_api: ModLoaderAPI) -> void:
	api = mod_api
	api.info("ativo — códigos de transação serão alongados para %d chars" % TARGET_LENGTH)
	api.hook("post_data_load", _on_data_loaded)


func _on_data_loaded(roots: Dictionary) -> void:
	_code_remap.clear()
	_word_boundary_cache.clear()

	_lengthen_codes_in_dict(roots.get("pix", {}))
	_lengthen_codes_in_dict(roots.get("tickets", {}))

	var rewritten_threads := _rewrite_messages(roots.get("messages", []))

	api.info("alongados %d códigos; atualizadas referências em %d/%d threads de mensagens" % [
		_code_remap.size(), rewritten_threads, roots.get("messages", []).size()
	])


func _lengthen_codes_in_dict(dict: Dictionary) -> void:
	if dict.is_empty():
		return
	var originals: Array = dict.keys()
	for code in originals:
		var long_code: String = _make_long_code(code)
		_code_remap[code] = long_code
		dict[long_code] = dict[code]
		dict.erase(code)


func _make_long_code(original: String) -> String:
	var result: String = original
	var seed_val: int = original.hash()
	if seed_val < 0:
		seed_val = -seed_val
	while result.length() < TARGET_LENGTH:
		seed_val = (seed_val * 1103515245 + 12345) & 0x7FFFFFFF
		result += CHARSET[seed_val % CHARSET.length()]
	return result.substr(0, TARGET_LENGTH)


func _rewrite_messages(message_roots: Array) -> int:
	var modified_count := 0
	for thread in message_roots:
		if typeof(thread) != TYPE_DICTIONARY:
			continue
		var branches: Dictionary = thread.get("branches", {})
		var touched := false
		for branch_name in branches.keys():
			var messages: Array = branches[branch_name]
			for msg in messages:
				if typeof(msg) != TYPE_DICTIONARY:
					continue
				if _rewrite_message_object(msg):
					touched = true
		if touched:
			modified_count += 1
	return modified_count


func _rewrite_message_object(msg: Dictionary) -> bool:
	var any_change := false

	if msg.has("text") and typeof(msg["text"]) == TYPE_STRING:
		var new_text: String = _apply_remap(msg["text"])
		if new_text != msg["text"]:
			msg["text"] = new_text
			any_change = true

	if msg.has("choices") and typeof(msg["choices"]) == TYPE_ARRAY:
		for choice in msg["choices"]:
			if typeof(choice) != TYPE_DICTIONARY:
				continue
			if choice.has("player_text") and typeof(choice["player_text"]) == TYPE_STRING:
				var new_choice_text: String = _apply_remap(choice["player_text"])
				if new_choice_text != choice["player_text"]:
					choice["player_text"] = new_choice_text
					any_change = true

	return any_change


# Substitutes original codes with long ones using word-boundary RegEx
# to avoid clobbering codes that happen to appear inside larger words/numbers.
func _apply_remap(text: String) -> String:
	var result: String = text
	for orig_code in _code_remap.keys():
		if not (orig_code in result):
			continue
		var regex: RegEx = _get_boundary_regex(orig_code)
		result = regex.sub(result, _code_remap[orig_code], true)
	return result


func _get_boundary_regex(code: String) -> RegEx:
	if _word_boundary_cache.has(code):
		return _word_boundary_cache[code]
	var rx := RegEx.new()
	# \b matches word boundary; works for both alphanumeric PIX and numeric tickets
	rx.compile("\\b" + _regex_escape(code) + "\\b")
	_word_boundary_cache[code] = rx
	return rx


func _regex_escape(s: String) -> String:
	const SPECIAL := ".\\+*?[^]$(){}=!<>|:-/"
	var out := ""
	for ch in s:
		if ch in SPECIAL:
			out += "\\" + ch
		else:
			out += ch
	return out
