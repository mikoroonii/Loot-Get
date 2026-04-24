class_name InfiniteSpin extends Node3D

@export var spin: Vector3

func _process(delta):
	rotation += spin * delta
