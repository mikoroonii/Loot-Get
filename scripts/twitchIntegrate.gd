extends Node

# Your client id. You can share this publicly. Default is my own client_id.
# Please do not ship your project with my client_id, but feel free to test with it.
# Visit https://dev.twitch.tv/console/apps/create to create a new application.
# You can then find your client id at the bottom of the application console.
# DO NOT SHARE THE CLIENT SECRET. If you do, regenerate it.
@export var client_id : String = "9x951o0nd03na7moohwetpjjtds0or"
# The name of the channel we want to connect to.
@export var channel : String
# The username of the bot account.
@export var username : String

var id : TwitchIDConnection
var api : TwitchAPIConnection
var irc : TwitchIRCConnection
var eventsub : TwitchEventSubConnection

var cmd_handler : GIFTCommandHandler = GIFTCommandHandler.new()

var iconloader : TwitchIconDownloader

signal queueSpin

var event_queue = []

var directory_path = null

var cooldown: int = 0

func _ready() -> void:
	print(Time.get_unix_time_from_system())
	var file_path = OS.get_executable_path()
	var separator = "/"  # Adjust separator for your OS ("\" for Windows)
	var parts = file_path.split(separator)

	# Remove the last element (game.exe)
	# Remove the last element (game.exe) using remove_at
	parts.remove_at(parts.size() - 1)
	# Join the remaining parts back into a path
	directory_path = separator.join(parts)
	var file = FileAccess.open(directory_path + "/config.json", FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	channel = data[0].channel
	username = data[0].user
	cooldown = data[0].cooldown
	# We will login using the Implicit Grant Flow, which only requires a client_id.
	# Alternatively, you can use the Authorization Code Grant Flow or the Client Credentials Grant Flow.
	# Note that the Client Credentials Grant Flow will only return an AppAccessToken, which can not be used
	# for the majority of the Twitch API or to join a chat room.
	var auth : ImplicitGrantFlow = ImplicitGrantFlow.new()
	# For the auth to work, we need to poll it regularly.
	get_tree().process_frame.connect(auth.poll) # You can also use a timer if you don't want to poll on every frame.

	# Next, we actually get our token to authenticate. We want to be able to read and write messages,
	# so we request the required scopes. See https://dev.twitch.tv/docs/authentication/scopes/#twitch-access-token-scopes
	var token : UserAccessToken = await(auth.login(client_id, ["chat:read", "chat:edit"]))
	if (token == null):
		# Authentication failed. Abort.
		return

	# Store the token in the ID connection, create all other connections.
	id = TwitchIDConnection.new(token)
	irc = TwitchIRCConnection.new(id)
	api = TwitchAPIConnection.new(id)
	iconloader = TwitchIconDownloader.new(api)
	# For everything to work, the id connection has to be polled regularly.
	get_tree().process_frame.connect(id.poll)

	# Connect to the Twitch chat.
	if(!await(irc.connect_to_irc(username))):
		# Authentication failed. Abort.
		return
	# Request the capabilities. By default only twitch.tv/commands and twitch.tv/tags are used.
	# Refer to https://dev.twitch.tv/docs/irc/capabilities/ for all available capapbilities.
	irc.request_capabilities()
	# Join the channel specified in the exported 'channel' variable.
	irc.join_channel(channel)

	# Add a helloworld command.
	cmd_handler.add_command("spin", commandSpin)
	# The helloworld command can now also be executed with "hello"!
	cmd_handler.add_alias("spinwheel", "spin")
	# Add a list command that accepts between 1 and infinite args.
	cmd_handler.add_command("score", userCheckScore)
	# We also have to forward the messages to the command handler to handle them.
	irc.chat_message.connect(cmd_handler.handle_command)
	# If you also want to accept whispers, connect the signal and bind true as the last arg.
	irc.whisper_message.connect(cmd_handler.handle_command.bind(true))

	# This part of the example only works if GIFT is logged in to your broadcaster account.
	# If you are, you can uncomment this to also try receiving follow events.
	# Don't forget to also add the 'moderator:read:followers' scope to your token.
#	eventsub = TwitchEventSubConnection.new(api)
#	await(eventsub.connect_to_eventsub())
#	eventsub.event.connect(on_event)
#	var user_ids : Dictionary = await(api.get_users_by_name([username]))
#	if (user_ids.has("data") && user_ids["data"].size() > 0):
#		var user_id : String = user_ids["data"][0]["id"]
#		eventsub.subscribe_event("channel.follow", "2", {"broadcaster_user_id": user_id, "moderator_user_id": user_id})


func on_event(type : String, data : Dictionary) -> void:
	match(type):
		"channel.follow":
			print("%s followed your channel!" % data["user_name"])

class EmoteLocation extends RefCounted:
	var id : String
	var start : int
	var end : int

	func _init(emote_id, start_idx, end_idx):
		self.id = emote_id
		self.start = start_idx
		self.end = end_idx

	static func smaller(a : EmoteLocation, b : EmoteLocation):
		return a.start < b.start



func commandSpin(cmd_info : CommandInfo) -> void:
	var data = handle_user_file(cmd_info.sender_data.user)
	if (Time.get_unix_time_from_system() - data[0].lastSpin) > cooldown:
		print('Cooldown Over! Spinning and resetting cooldown!')
		editField(cmd_info.sender_data.user, "lastSpin", Time.get_unix_time_from_system())
		queueSpin.emit(cmd_info.sender_data.user)
		irc.chat(cmd_info.sender_data.user + ", you're queued up!")
	else:
		irc.chat("Hey, "+ cmd_info.sender_data.user + ", You're on cooldown! Please wait " + str(int(cooldown - (Time.get_unix_time_from_system() - data[0].lastSpin))) + " seconds!")
	


func handle_user_file(localuservar):
	var default_content = [
		{
		"username": localuservar,
		"lastSpin": 0,
		"totalScore": 0,
		"items": []
	}
	]
	var file_path = directory_path + "/userdata/" + localuservar + ".json"
	if not FileAccess.file_exists(file_path):
		print('User doesnt have any data! Making a default JSON.')
		var filewrite = FileAccess.open(file_path, FileAccess.WRITE)
		filewrite.store_string(JSON.stringify(default_content))
		pass
	var file = FileAccess.open(file_path, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	
	return data
	
func editField(localuservar, field, newvalue):
	var file_path = directory_path + "/userdata/" + localuservar + ".json"
	var file = FileAccess.open(file_path, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	data[0][field] = newvalue
	var filewrite = FileAccess.open(file_path, FileAccess.WRITE)
	filewrite.store_string(JSON.stringify(data))
	
func addField(localuservar, field, value):
	var file_path = directory_path + "/userdata/" + localuservar + ".json"
	var file = FileAccess.open(file_path, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	data[0][field] += value
	var filewrite = FileAccess.open(file_path, FileAccess.WRITE)
	filewrite.store_string(JSON.stringify(data))

func addScore(resource, item, username):
	irc.chat(username + ' just opened up a ' + resource.name + ' worth ' + item.itemvalue + '!')
	addField(username, "totalScore", int(item.itemvalue.replace("$", "")))
	appendItem(username, resource.name)

func userCheckScore(cmd_info : CommandInfo) -> void:
	var data = handle_user_file(cmd_info.sender_data.user)
	irc.chat('@' + cmd_info.sender_data.user + ', you currently have $' + str(data[0].totalScore))

func appendItem(localuservar, item):
	var file_path = directory_path + "/userdata/" + localuservar + ".json"
	var file = FileAccess.open(file_path, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	data[0].items.append(item)
	var filewrite = FileAccess.open(file_path, FileAccess.WRITE)
	filewrite.store_string(JSON.stringify(data))
