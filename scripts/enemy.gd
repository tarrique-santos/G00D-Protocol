
extends CharacterBody3D

const SPEED := 2.5
const MAX_HEALTH := 3
const GRAVITY := 18.0

var health := MAX_HEALTH
var attack_timer := 0.0
var attack_interval := 1.2

func _physics_process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player")

	if player == null:
		return

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0

	var distance := global_position.distance_to(
		player.global_position
	)

	if distance > 2.0:
		var direction := player.global_position - global_position
		direction.y = 0.0
		direction = direction.normalized()

		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED

		if direction.length() > 0.0:
			$MeshInstance3D.look_at(
				global_position + direction,
				Vector3.UP
			)
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED * 5.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, SPEED * 5.0 * delta)

		attack_timer -= delta

		if attack_timer <= 0.0:
			attack_timer = attack_interval
			print("O inimigo atacou o G00D!")

	move_and_slide()

func take_damage(amount: int) -> void:
	health -= amount

	if health <= 0:
		queue_free()
