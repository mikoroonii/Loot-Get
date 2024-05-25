extends Node3D

var itemnamesarray = []
var resourcearray = []

var common = []
var uncommon = []
var rare = []
var epic = []
var legendary = []
var rarities = [common, uncommon, rare, epic, legendary]

var can_run = true

func _process(_delta):
	if Input.is_action_just_pressed("DEBUG Initialize") && can_run:
		spin_carousel("testuser")
	if Input.is_action_just_pressed("DEBUG Roll"):
		get_tree().change_scene_to_file("res://scenes/MainScene.tscn")
	pass
# Called when the node enters the scene tree for the first time.
func _ready():
	
	var file_path = OS.get_executable_path()
	var separator = "/"  # Adjust separator for your OS ("\" for Windows)
	var parts = file_path.split(separator)

	# Remove the last element (game.exe)
# Remove the last element (game.exe) using remove_at
	parts.remove_at(parts.size() - 1)

	# Join the remaining parts back into a path
	var directory_path = separator.join(parts)

	# directory_path will now contain "D:/Games/Game"
	print(directory_path)
	
	dir_contents(directory_path)
	$Carousel.resourceArray = rarities
	TwitchIntegrate.connect("queueSpin", _on_twitch_integrator_queue_spin)
	can_run = true
	process_event_queue()
	


# Called every frame. 'delta' is the elapsed time since the previous frame.

func dir_contents(path):
	var rarityname = null
	for i in rarities:
		match i:
					common:
						rarityname = "common"
					uncommon:
						rarityname = "uncommon"
					rare:
						rarityname = "rare"
					epic:
						rarityname = "epic"
					legendary:
						rarityname = "legendary"
		var dir = DirAccess.open(path)
		dir.make_dir("items")
		dir = DirAccess.open(path + '/items/' + rarityname)

		
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if dir.current_is_dir():
					print("Found directory: " + file_name)
					var resource: ItemResource = ItemResource.new() # create a resource file for loaded item
					resource.objpath = 	path + '/items/' + rarityname + '/' + file_name + '/' + file_name + '.obj' # get obj path
					resource.mtlpath = path + '/items/' + rarityname + '/' + file_name + '/' + file_name + '.mtl' # get mtl path
					resource.iconpath = path + '/items/' + rarityname + '/' + file_name + '/icon.png' # get icon path
					resource.jsonpath = path + '/items/' + rarityname + '/' + file_name + '/' + file_name + '.json' # get json path
					resource.name = file_name
					i.append(resource)
					print("Appending " + str(resource) + " to " + rarityname)
					
					
				else:
					print("Found file: " + file_name)
				file_name = dir.get_next()
		
		else:
			print("An error occurred when trying to access the path.")

func _on_carousel_reveal(resource, item, user):
	if item.json_data[0].tags.has("shiny"):
		pass
	$Animators/AnimationPlayer.play("reveal")
	$crate/AudioStreamPlayer.play()
	$crate/AnimationPlayer.play("ArmatureAction_001")
	$MeshInstance3D.mesh = ObjParse.load_obj(resource.objpath, resource.mtlpath)
	$Animators/MeshSpinner.play("spin")
	$Timers/ResetTimer.start()
	$Ui.opennameandbar(item.json_data[0].description, item.json_data[0].name, item.itemvalue)
	TwitchIntegrate.addScore(resource, item, user)

	pass # Replace with function body.
	
	

func _on_reset_timer_timeout():
	$Animators/CameraIrisAnimate.play_backwards("irisOpen")
	$Timers/SceneReloadTimer.start()
	pass # Replace with function body.


func _on_scene_reload_timer_timeout():
	get_tree().change_scene_to_file("res://scenes/MainScene.tscn")
	can_run = true
	pass # Replace with function body.
	

# TODO: saving each unlock







func _on_twitch_integrator_queue_spin(event_data):
	# Add event to the queue
	TwitchIntegrate.event_queue.append(event_data)
	
	# If this is the only event in the queue, start processing the queue
	if len(TwitchIntegrate.event_queue) == 1 && can_run:
		process_event_queue()

func process_event_queue():
	# If there are events in the queue, process them one by one
	if TwitchIntegrate.event_queue.size() > 0:
		var event_data = TwitchIntegrate.event_queue.pop_front()
		spin_carousel(event_data)
		event_data = null
		can_run = false

#todo - unanonymize the spins

func spin_carousel(user):
	$Animators/CameraIrisAnimate.play("irisOpen")
	$Carousel.username = user
	$Ui.openbar(user + " just opened a Standard Crate!")
	$Carousel.rotating = true
	$Carousel.randomizeValues()
	$Carousel.progressCarousel()
	can_run = false


func _on_spin_timer_timeout():
	process_event_queue()
	pass # Replace with function body.
