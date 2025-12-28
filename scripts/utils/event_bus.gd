extends Node

signal answer_option(name:String, message:String, title:String, reputation_points:int, time:int, answer_id:int)
signal message_answered(answer_id:int)

signal create_message(name:String, message:String, sender:GameData.Sender, time:int)

signal create_answer(name:String, title:String, message:String, answer_id:int)
signal storage_answer(name:String, message:String, title:String, reputation_points:int, answer_id:int)
signal delete_answers(name:String)
