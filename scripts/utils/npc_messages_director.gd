# res://scripts/story/messages/npc_messages_director.gd
extends Node

signal npc_message_created(
	npc_name: String,
	message: String,
	annex: Dictionary,
	sender: GameData.Sender,
	time: int
)

func send_npc_message(npc_name: String, message: String, annex: Dictionary, time: int) -> void:
	npc_message_created.emit(
		npc_name,
		message,
		annex,
		GameData.Sender.NPC,
		time
	)
