class_name CaseRevealer extends Node3D

signal revealed(item: CollectibleItem)
signal reveal_begun

const colors = [
	Color.GRAY,
	Color.BLUE,
	Color.GREEN,
	Color.PURPLE,
	Color.GOLD
]

func reveal(item: CollectibleItem):
	reveal_begun.emit()
	
	$Node3D/MeshInstance3D.mesh = item.mesh

	# Particles material
	var mat = StandardMaterial3D.new()
	mat.emission = colors[item.rarity - 1]
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 12

	# Grab existing texture from the mesh's current material
	var existing_mat = item.mesh.surface_get_material(0) as StandardMaterial3D
	var existing_texture = existing_mat.albedo_texture if existing_mat else null

	# Mesh material
	var mesh_mat = StandardMaterial3D.new()
	if existing_texture:
		mesh_mat.albedo_texture = existing_texture  # ✅ carry over the texture

	if item.tags.has("toon"):
		print("TOON IT!")
		mesh_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	if item.tags.has("outline"):
		print("OUTLINE IT!")
		$Node3D/MeshInstance3D.material_overlay = load("res://Assets/materials/outline.tres")

	$Node3D/MeshInstance3D.set_surface_override_material(0, mesh_mat)
	$CPUParticles3D.material_override = mat
	await get_tree().create_timer(2.5).timeout
	$AudioStreamPlayer3D.play()
	$crate/AnimationPlayer.play("ArmatureAction_001")
	reveal_begun.emit()
	await get_tree().create_timer(0.8).timeout
	$CPUParticles3D.emitting = true
	$AnimationPlayer.play("item_appear")
	revealed.emit(item)
