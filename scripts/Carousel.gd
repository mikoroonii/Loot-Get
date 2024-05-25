extends Node3D

var startspeed: float = 10
var friction: float = 0.2
var rotating: bool = false
var resourceArray = []
var speed_scale = 0
var itemScene = preload("res://scenes/Item.tscn")
var liveItems = []
var slowing: bool = false
var rarity = null
var stopped = false
signal reveal(resource, item)
var username: String = ""
# Called when the node enters the scene tree for the first time.
func _ready():
	randomizeValues()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("DEBUG Roll"):
		call_deferred("resetCarousel")
	if slowing && Engine.time_scale > 0.02:
		Engine.time_scale -= friction * delta

func randomizeValues():
	startspeed = randf_range(4, 5)
	friction = randf_range(0.3, 0.4)
	#startspeed = 1
	#friction = 1
	speed_scale = startspeed
	Engine.time_scale = startspeed
	

func progressCarousel():
	slowing = true
	if rotating:
		$Timer.wait_time = 0.1
		$Timer.start()
		$AudioStreamPlayer.play()
		var itemInstance = itemScene.instantiate()
		add_child(itemInstance)
		itemInstance.connect("markDelete", deleteitem)
		var rand = randi_range(0, 95)
		if rand in range(0, 30):
			itemInstance.ResourceVar = resourceArray[0].pick_random()
			itemInstance.rarity = 1
		elif rand in range(30, 55):
			itemInstance.ResourceVar = resourceArray[1].pick_random()
			itemInstance.rarity = 2
		elif rand in range(55, 75):
			itemInstance.ResourceVar = resourceArray[2].pick_random()
			itemInstance.rarity = 3
		elif rand in range(75, 90):
			itemInstance.ResourceVar = resourceArray[3].pick_random()
			itemInstance.rarity = 4
		elif rand in range(90, 96):
			itemInstance.ResourceVar = resourceArray[4].pick_random()
			itemInstance.rarity = 5
		else:
			print('error with RNG. Value was ' + str(rand))
		itemInstance.icon()
		liveItems.append(itemInstance)

		for i in liveItems:
			if rotating:
				i.progressAnim()







		
		


func _on_timer_timeout():
	if rotating:
		progressCarousel()
	if Engine.time_scale <= 0.025 && !stopped:
			rotating = false
			print('done')
			slowing = false
			Engine.time_scale = 1
			for i in liveItems:
				i.stop()
			$DoneWait.start()
			
		
func deleteitem(item):
	liveItems.erase(item)
	item.queue_free()
	
func resetCarousel():
	randomizeValues()
	rotating = false
	for i in liveItems:
		i.queue_free()
	liveItems.clear()


		


func _on_done_wait_timeout():
	if !stopped:
		for i in liveItems:
			stopped = true
			if i.animProgress == 3:
				reveal.emit(i.ResourceVar, i, username)
				liveItems.erase(i)
				Engine.time_scale = 1
				i.reveal()
				pass # Replace with function body.
