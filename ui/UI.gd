extends Control

var opentime: float = 3

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	$AnimationPlayer.speed_scale = (1 / opentime) / Engine.time_scale

func openbar(text):
	$CanvasLayer/Panel/Label.text = text
	$AnimationPlayer.play("openBar")
func opennameandbar(text, title, price):
	$CanvasLayer/Panel/Label.text = text
	$CanvasLayer/NamePanel/Name.text = title
	$CanvasLayer/NamePanel/Price.text = price
	$AnimationPlayer.play("openNameAndBar")
func closebar():
	$AnimationPlayer.play_backwards("openBar")
func closenameandbar():
	$AnimationPlayer.play_backwards("openNameAndBar")


func _on_animation_player_animation_finished(_anim_name):
	pass # Replace with function body.


func _on_timer_timeout():
	closebar()
	pass # Replace with function body.
