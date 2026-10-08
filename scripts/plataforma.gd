extends StaticBody3D

@onready var collision = $CollisionShape3D
@onready var mesh = $MeshInstance3D

var material = StandardMaterial3D.new()


func _ready():
	collision.disabled = true

	mesh.set_surface_override_material(0, material)

	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.4


func ativar_plataforma():
	call_deferred("_ativar_colisao")


func _ativar_colisao():
	collision.disabled = false
	material.albedo_color.a = 1.0
