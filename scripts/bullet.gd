
extends Area3D

@export var speed: float = 120.0
@export var lifetime: float = 3.0
@export var dano: int = 20

var direction: Vector3 = Vector3.ZERO


func configurar(nova_direcao: Vector3, _atirador: CollisionObject3D) -> void:
	direction = nova_direcao.normalized()


func _ready() -> void:
	body_entered.connect(_on_body_entered)

	await get_tree().create_timer(lifetime).timeout

	if is_inside_tree():
		queue_free()


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta


func _on_body_entered(body: Node3D) -> void:
	# Causa dano ao jogador
	if body.is_in_group("player"):
		if body.has_method("receber_dano"):
			body.receber_dano(dano)

		queue_free()
		return

	# Ativa plataformas ou outros alvos especiais
	if body.is_in_group("alvo_ativavel"):
		if body.has_method("ativar_plataforma"):
			body.ativar_plataforma()

	# Destrói a bala ao atingir qualquer objeto
	queue_free()
