extends Node

class_name Instrument

enum TYPE {
	SYNTH,
	MODULATED_SYNTH,
	CHORD_SYNTH,
	BASS
}

@export var instrument : String
@export var type : TYPE = TYPE.SYNTH
@export var state : bool = false
@export var stems : Array[AudioStream]
