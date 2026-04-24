extends Node3D

var playing: bool = false
var currentChatter: VSTChatter
var world_scene: PackedScene = load("res://Scenes/world.tscn") 


func _ready() -> void:
	var qm: Node = get_parent().get_node_or_null("QueueManager")
	if qm and qm.has_method("register_world"):
		qm.register_world(self)


func play(chatter: VSTChatter) -> void:
	
	var datam: DataManager = get_parent().get_node_or_null("DataManager")
	if datam:
		datam.update_user_command_data(chatter, "spin")
	
	var uim: UIManager = get_parent().get_node_or_null("UIManager")
	if uim:
		await uim.transition(true)
	
	playing = true
	currentChatter = chatter
	
	$"../UIManager".show_message(chatter.tags.display_name + " is spinning...", 5.0)
	
	await $CarouselSpinner.spin()


func _on_revealer_revealed(item: CollectibleItem) -> void:
	var value: int = randi_range(item.value_min, item.value_max)
	
	VerySimpleTwitch.send_chat_message(currentChatter.tags.display_name + " got a " + item.name + " worth $" + str(value) + "!")
	
	var datam: DataManager = get_parent().get_node_or_null("DataManager")
	if datam:
		datam.give_item(currentChatter, item, value)
		$"../UIManager".show_message(currentChatter.tags.display_name + " got a " + item.name + " worth $" + str(value) + "!", 5.0)
	
	await get_tree().create_timer(8).timeout
	var uim: UIManager = get_parent().get_node_or_null("UIManager")
	if uim:
		await uim.transition(false)
	
	var new_world: Node = world_scene.instantiate()
	var game_root: Node = get_parent()
	game_root.call_deferred("add_child", new_world)
	
	queue_free()
