class_name DataManager extends Node

var basedir = OS.get_user_data_dir()

signal data_loaded(success: bool)

func load_config() -> bool:
	load_items()
	var success: bool = false
	var config_path: String = basedir + "/config/config.json"
	var json = JSON.new()
	var file = FileAccess.open(config_path, FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		file.close()

		var error = json.parse(json_text)
		if error == OK:
			var data_received = json.data
			
			var tc: userConfig.TwitchDataClass = userConfig.TwitchDataClass.new(data_received[0].channel, data_received[0].user, data_received[0].cooldown, data_received[0].prefixes)
			var temp_config: userConfig = userConfig.new(tc, data_received[1].weights)
			GameManager.config = temp_config
			success = true
		else:
			print("JSON Parse Error: ", json.get_error_message(), " in ", json_text)
	else:
		pass
		#TODO: Generate default config
	data_loaded.emit(success)
	return success

func update_user_data(chatter: VSTChatter):
	
	var data_dir: String = basedir + "/data/"
	var data_path: String = data_dir + chatter.login + ".cfg"
	if not DirAccess.dir_exists_absolute(data_dir):
		DirAccess.make_dir_recursive_absolute(data_dir)
	
	var cfg = ConfigFile.new()
	cfg.load(data_path)
	
	cfg.set_value("user", "display_name", chatter.tags.display_name)
	cfg.set_value("user", "color", chatter.tags.color_hex)
	cfg.set_value("user", "last_message", chatter.message)
	
	var err = cfg.save(data_path)
	if err == OK:
		pass
	else:
		printerr("Failed to save file at: ", data_path)

func update_user_command_data(chatter: VSTChatter, command: String):
	var data_dir: String = basedir + "/data/"
	var data_path: String = data_dir + chatter.login + ".cfg"
	if not DirAccess.dir_exists_absolute(data_dir):
		DirAccess.make_dir_recursive_absolute(data_dir)
	
	var cfg = ConfigFile.new()
	cfg.load(data_path)
	cfg.set_value("command - " + command, "last_used", Time.get_unix_time_from_system())
	cfg.set_value("command - " + command, "total_used", cfg.get_value("command - " + command, "total_used", 0) + 1)
	
	var err = cfg.save(data_path)
	if err == OK:
		pass
	else:
		printerr("Failed to save file at: ", data_path)

func load_items():
	var rarities: Dictionary = {
		"common": 1,
		"uncommon": 2,
		"rare": 3,
		"epic": 4,
		"legendary": 5
	}
	
	var data_dir: String = basedir + "/items/"
	for i in rarities:
		var folders: Array = DirAccess.get_directories_at(data_dir + "/" + i)
		for f in folders:
			var item_resource = CollectibleItem.new()
			var jsonText: = FileAccess.get_file_as_string(data_dir + "/" + i + "/" + f + "/" + f + ".json")
			var jsonDict = JSON.parse_string(jsonText)
			if jsonDict:
				item_resource.name = jsonDict[0].name
				item_resource.description = jsonDict[0].description
				var image = Image.new()
				image.load(data_dir + "/" + i + "/" + f + "/icon.png")
				item_resource.icon = ImageTexture.create_from_image(image)
				item_resource.rarity = rarities[i]
				item_resource.mesh = ObjParse.from_path(data_dir + "/" + i + "/" + f + "/" + f + ".obj", data_dir + "/" + i + "/" + f + "/" + f + ".mtl")
				item_resource.value_min = jsonDict[0].valuemin
				item_resource.value_max = jsonDict[0].valuemax
				item_resource.tags.assign(jsonDict[0].tags)
				GameManager.items.append(item_resource)

class InventoryItem extends RefCounted:

	var item: CollectibleItem
	var value: int
	var time: float

	func _init(p_item: CollectibleItem = null, p_value: int = 0, p_time: float = 0.0) -> void:
		item = p_item
		value = p_value
		time = p_time

	func to_dict() -> Dictionary:
		return {
			"item_name": item.name if item else "",
			"value": value,
			"time": time
		}

	static func from_dict(data: Dictionary) -> InventoryItem:
		var loaded_item: CollectibleItem = null
		var target_name: String = data.get("item_name", "")
		
		for game_item in GameManager.items:
			if game_item.name == target_name:
				loaded_item = game_item
				break
				
		return InventoryItem.new(loaded_item, data.get("value", 0), data.get("time", 0.0))
		

func give_item(chatter: VSTChatter, item: CollectibleItem, value: int) -> void:
	var data_dir: String = basedir + "/data/"
	var data_path: String = data_dir + chatter.login + ".cfg"
	
	if not DirAccess.dir_exists_absolute(data_dir):
		DirAccess.make_dir_recursive_absolute(data_dir)
	
	var invitem: InventoryItem = InventoryItem.new(item, value, Time.get_unix_time_from_system())
	
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(data_path)
	
	var empty_array: Array[Dictionary] = []
	var items_data: Array = cfg.get_value("inventory", "items", empty_array)
	
	items_data.append(invitem.to_dict())
	cfg.set_value("inventory", "items", items_data)
	
	var err: int = cfg.save(data_path)
	if err != OK:
		printerr("Failed to save file at: ", data_path)

func get_balance(user: String) -> int:
	var balance: int = 0
	
	for item in get_inventory(user):
		balance += item.value
	
	return balance

func get_inventory(user: String) -> Array[InventoryItem]:
	var inventory: Array[InventoryItem] = []
	var data_path: String = basedir + "/data/" + user + ".cfg"
	
	if not FileAccess.file_exists(data_path):
		return inventory
		
	var cfg: ConfigFile = ConfigFile.new()
	var err: int = cfg.load(data_path)
	
	if err != OK:
		printerr("Failed to load file at: ", data_path)
		return inventory
		
	var empty_array: Array[Dictionary] = []
	var items_data: Array = cfg.get_value("inventory", "items", empty_array)
	
	for item_dict: Dictionary in items_data:
		var inv_item: InventoryItem = InventoryItem.from_dict(item_dict)
		if inv_item.item != null:
			inventory.append(inv_item)
			
	return inventory

func get_command_info(user: String, command: String) -> Dictionary:
	var data_path: String = basedir + "/data/" + user + ".cfg"
	var command_info: Dictionary = {
		"totaluses": 0,
		"lastused": 0.0,
		"timesinceused": 0.0
	}
	if not FileAccess.file_exists(data_path):
		return command_info
		
	var cfg: ConfigFile = ConfigFile.new()
	var err: int = cfg.load(data_path)
	
	if err != OK:
		printerr("Failed to load file at: ", data_path)
		return command_info
	else:
		command_info.totaluses = cfg.get_value("command - " + command, "total_used")
		command_info.lastused = cfg.get_value("command - " + command, "last_used")
		command_info.timesinceused = Time.get_unix_time_from_system() - float(cfg.get_value("command - " + command, "last_used"))
		
		return command_info
