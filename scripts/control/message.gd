extends Resource

class_name Message

# This script is responsible for holding messages information and handling when to send them to the player.
# The control script reads all messages from the current day and creates invisible nodes for each.
# Each message is then instantiated and added to the scene tree, where they will constantly check if they should be sent.

@export var day : int

## Priority of the message.
## Negative values indicate that the message should be sent immediately. The lower the value, the higher the priority.
## Zero values messages are sent immediately after -1 priority values.
## Positive values indicate that the message should be sent after a random delay. Higher values indicate a larger amplitude of random values. Values are normalized to the maximum amplitude defined by GameData.
@export var priority : int

@export var task_type : String
@export var sender : String
@export var text : String
@export var conditions : Dictionary = {}
