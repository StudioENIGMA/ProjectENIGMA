extends HBoxContainer

var answer_options : Array[Dictionary] = []

func _ready() -> void:
	EventBus.answer_option.connect(on_answer_option)
	EventBus.clean_answers.connect(on_answers_cleaned)

func on_answers_cleaned() -> void:
	for node in self.get_children():
			node.queue_free()	

func on_answer_option(name : String, message : String, title : String, reputation_points : int, time : int, answer_id : int) -> void:
	answer_options.push_front({"name" : name, "message" : message, "title": title, "reputation_points" : reputation_points, "time" : time, "answer_id" : answer_id})

func _process(delta: float) -> void:
	for answer_option in answer_options:
		if answer_option.time <= GameData.now():
			EventBus.create_answer.emit(answer_option.name, answer_option.title, answer_option.message, answer_option.answer_id)
			answer_options.erase(answer_option)
			if answer_option.time >= -1:
				EventBus.storage_answer.emit(answer_option.name, answer_option.message, answer_option.title, answer_option.reputation_points, answer_option.answer_id)	
