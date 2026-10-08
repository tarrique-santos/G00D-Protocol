extends Area3D

@export var speed := 120.0
@export var lifetime := 3.0

var direction := Vector3.ZERO


func _ready():
	body_entered.connect(_on_body_entered)

	await get_tree().create_timer(lifetime).timeout
	queue_free()


func _physics_process(delta):
	global_position += direction * speed * delta


func _on_body_entered(body):
	if body.is_in_group("alvo_ativavel"):
		body.ativar_plataforma()

	queue_free()
