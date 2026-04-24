class_name TwitchManager extends Node

signal command_activated(message_parts: Array[String], chatter: VSTChatter)

func _on_data_loader_data_loaded(_success: bool) -> void:
	VerySimpleTwitch.get_token_and_login_chat()
	VerySimpleTwitch.chat_message_received.connect(chat)


func chat(chatter: VSTChatter):
	
	## Log user data
	$"../DataManager".update_user_data(chatter)
	
	## Handle commands
	var isCommand: bool = false
	for prefix in GameManager.config.TwitchConfig.prefixes:
		if chatter.message.begins_with(prefix):
			isCommand = true
	if isCommand:
		var truncated = chatter.message.substr(1)
		var message_parts = truncated.split(" ", false)
		handleCommand(message_parts, chatter)
		
func handleCommand(message_parts, chatter):
	#print_rich("[b]" + chatter.tags.display_name + "[/b]")
	#for part in message_parts:
		#print(part)
	
	
	
	var command_success: bool = false
	
	match message_parts[0]:
		"spin":
			command_success = true
		"ping":
			VerySimpleTwitch.send_chat_message("Pong!")
			command_success = true
		"balance", "money", "dosh":
			VerySimpleTwitch.send_chat_message(chatter.tags.display_name + ", You have $" + str($"../DataManager".get_balance(chatter.login)))
			command_success = true
	if command_success:
		command_activated.emit(message_parts, chatter)
		$"../DataManager".update_user_command_data(chatter, message_parts[0])
