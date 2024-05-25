extends Node3D

@export var ResourceVar: ItemResource
var json_data = null
var animProgress: int = 0
signal markDelete(toDelete)
var rarity
@onready var animplayer = $AnimationPlayer
var active = false
var itemvalue: String = ""
#TODO: Tags for item effects in the json (glitchy, movement, sfx)


# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func initialize():
	pass
func icon():
	jsonfunc()
	$Node3D/Icon/NameLabel.text = json_data[0].name
	$Node3D/Icon/Description.text = json_data[0].description
	itemvalue = '$' + str(randi_range(json_data[0].valuemin, json_data[0].valuemax))
	$Node3D/Icon/Value.text = itemvalue
	match rarity:
		1:
			$Node3D/BGSprite/Indicator.get_material_override().emission = Color(1,0,0,0.5)
			
		2:	
			$Node3D/BGSprite/Indicator.get_material_override().emission = Color(0,1,0,0.5)
		3:
			$Node3D/BGSprite/Indicator.get_material_override().emission = Color(0,0,1,0.5)
		4:
			$Node3D/BGSprite/Indicator.get_material_override().emission = Color(1,1,0,0.5)
		5: 
			$Node3D/BGSprite/Indicator.get_material_override().emission = Color(1,0,1,0.5)

	var image = Image.load_from_file(ResourceVar.iconpath)
	var texture = ImageTexture.create_from_image(image)
	$Node3D/Icon.texture = texture
	
func jsonfunc():
	var file = FileAccess.open(ResourceVar.jsonpath, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	json_data = data

func progressAnim():
	animProgress +=1
	match animProgress:
		1:
			$AnimationPlayer.play("slideIn")
		2:
			$AnimationPlayer.play("popUp")
		3:
			$AnimationPlayer.play("slideOut1")
		4:
			$AnimationPlayer.play("slideOut2")
		5:
			markDelete.emit(self)
			
			
func stop():
	$AnimationPlayer.pause()

func reveal():
	$AnimationPlayer.play("rollaway")
