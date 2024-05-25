extends Node
class_name UserResource

@export var Username: String
var timer := Timer.new()
@export var cooldown: int

func _ready():
	add_child(timer)
