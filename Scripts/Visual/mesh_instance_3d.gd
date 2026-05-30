extends MeshInstance3D

@export var color: Color = Color(0.78, 0.55, 0.30, 1.0)
@export var roughness: float = 0.78


func _ready() -> void:
	if mesh == null:
		return

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	set_surface_override_material(0, mat)
