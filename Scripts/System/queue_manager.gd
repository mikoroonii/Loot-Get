extends Node

var queue: Array[VSTChatter] = []
var is_playing: bool = false
var active_world: Node = null


func _on_twitch_manager_command_activated(message_parts: Array[String], chatter: VSTChatter) -> void:
	var command: String = message_parts[0]
	if command.to_lower() == "spin":
		if %DataManager.get_command_info(chatter.login, "spin").timesinceused >= GameManager.config.TwitchConfig.cooldown:
			queue.append(chatter)
			try_start_next()
		else:
			var timeleft: float = GameManager.config.TwitchConfig.cooldown - %DataManager.get_command_info(chatter.login, "spin").timesinceused
			VerySimpleTwitch.send_chat_message(chatter.tags.display_name + ", You need to wait " + str(int(timeleft)) + " seconds before spinning again!")

func try_start_next() -> void:
	if is_playing or queue.is_empty() or active_world == null:
		return
		
	is_playing = true
	if active_world.has_method("play"):
		active_world.play(queue.pop_front())


func register_world(world_node: Node) -> void:
	active_world = world_node
	is_playing = false
	try_start_next()
