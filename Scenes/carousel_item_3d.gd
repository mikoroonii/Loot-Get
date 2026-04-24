class_name carousel_item_3d extends Node3D

var Item: CollectibleItem

var holo_strengths: Dictionary[int, float] = {
	1: 0.0,
	2: 0.0,
	3: 0.0,
	4: 0.1,
	5: 0.4
}

func _ready() -> void:
	var mat: Material = StandardMaterial3D.new()
	var svt: Texture = $SubViewport.get_texture()
	mat.albedo_texture = svt
	mat.emission_texture = svt
	mat.emission_enabled = true
	mat.texture_repeat = false
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	#mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	$MeshInstance3D.material_override = mat
	
	$SubViewport/CarouselItem.item = Item
	


func set_item(new_item: CollectibleItem) -> void:
	Item = new_item
	var om: ShaderMaterial = load("res://Assets/materials/holo.material").duplicate()
	if new_item: om.set_shader_parameter("effect_intensity", holo_strengths[new_item.rarity])
	print(holo_strengths[new_item.rarity])
	$MeshInstance3D.material_overlay = om
	$SubViewport/CarouselItem.item = new_item
