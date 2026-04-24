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
	var mat = StandardMaterial3D.new()
	mat.emission = colors[item.rarity - 1]
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 12
	$CPUParticles3D.material_override = mat
	await get_tree().create_timer(2.5).timeout
	$AudioStreamPlayer3D.play()
	$crate/AnimationPlayer.play("ArmatureAction_001")
	reveal_begun.emit()
	await get_tree().create_timer(0.8).timeout
	$CPUParticles3D.emitting = true
	$AnimationPlayer.play("item_appear")
	revealed.emit(item)
