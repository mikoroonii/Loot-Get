class_name UIManager extends Node

func transition(animatein: bool) -> bool:
	var tween = get_tree().create_tween()
	var finalval: float
	if animatein:
		finalval = 0.5
	else:
		finalval = 0
	
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(%SubViewportContainer.material, "shader_parameter/aperture", finalval, 1.0)
	await tween.finished
	tween.kill()
	return true


func show_message(msg: String, time: float) -> void:
	var panel: Control = $"../../../CenterContainer/Panel"
	var label: Label = $"../../../CenterContainer/Panel/AutoSizeLabel"
	
	label.text = msg
	
	var tween: Tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_property(panel, "custom_minimum_size", Vector2(480, 80), 1.0)
	tween.tween_interval(time)
	tween.tween_property(panel, "custom_minimum_size", Vector2(0, 0), 1.0)
