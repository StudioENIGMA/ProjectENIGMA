extends Node

# External use (control.gd, etc)
enum App {STORE = 0, BROWSER = 1, FAKE_SHOP = 2, MESSAGES = 3, SETTINGS = 4, EMAIL = 5}

signal send_notification(app: App, content: String, title: String, time: float)
signal receive_message(name : String, message : String, time : int)
signal answer_option(name : String, message : String, title : String, reputation_points : int, time : int, answer_id : int)
signal message_answered(answer_id : int)

# Internal use (Message App Internal Logic)
enum Sender {ME = 0, OTHER = 1}

signal create_message(name : String, message : String, sender : Sender, time : String)

signal create_answer(name : String, title : String, message : String, answer_id : int)
signal storage_answer(name : String, message : String, title : String, reputation_points : int, answer_id : int)
signal delete_answers(name : String)
signal clean_answers()
