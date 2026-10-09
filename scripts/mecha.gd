extends CharacterBody3D

@export var speed := 10.0
@export var gravity := 20.0
@export var jump_force := 12.0
@export var mouse_sensitivity := 0.003
@export var legs_rotation_speed := 8.0
@export var legs_max_angle := 45.0

@export var bullet_scene: PackedScene

@onready var camera_pivot: Node3D = $CameraPivot
@onready var torso: Node3D = $Torso
@onready var legs: Node3D = $Legs
@onready var marker: Marker3D = $Torso/Marker3D

var camera_yaw := 0.0
var camera_pitch := -0.3


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _input(event):
	if event is InputEventMouseMotion:
		camera_yaw -= event.relative.x * mouse_sensitivity
		camera_pitch -= event.relative.y * mouse_sensitivity

		camera_pitch = clamp(camera_pitch, -1.4, 1.4)

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			shoot()


func _process(delta):
	# Câmera acompanha o Player
	camera_pivot.global_position = global_position

	camera_pivot.global_rotation = Vector3(
		camera_pitch,
		camera_yaw,
		0
	)

	# Torso acompanha exatamente a mira
	torso.global_rotation = Vector3(
		camera_pitch,
		camera_yaw,
		0
	)

	# ------------------------------------------------
	# ROTAÇÃO DAS PERNAS
	# ------------------------------------------------

	var input_2d = Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_backward"
	)

	var target_angle := 0.0

	if input_2d.length() > 0.0:

		# Movimento para frente
		if input_2d.y > 0.0:

			# Direção invertida para corrigir
			# a orientação das pernas
			target_angle = atan2(
				-input_2d.x,
				input_2d.y
			)

		# Movimento para trás
		elif input_2d.y < 0.0:

			# Anda de costas, mas as pernas continuam
			# apontadas para frente.
			# O lado é invertido.
			target_angle = input_2d.x * deg_to_rad(legs_max_angle)

		# Movimento somente lateral
		else:

			# Inclinação diagonal invertida
			target_angle = -input_2d.x * deg_to_rad(legs_max_angle)

		target_angle = clamp(
			target_angle,
			-deg_to_rad(legs_max_angle),
			deg_to_rad(legs_max_angle)
		)

	# As pernas seguem o torso suavemente
	var target_rotation = camera_yaw + target_angle

	legs.global_rotation.y = lerp_angle(
		legs.global_rotation.y,
		target_rotation,
		legs_rotation_speed * delta
	)


func _physics_process(delta):
	# Gravidade
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

		# Pulo
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_force

	# Movimento
	var input_2d = Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_backward"
	)

	# Direções relativas à câmera
	var forward = -camera_pivot.global_transform.basis.z
	var right = camera_pivot.global_transform.basis.x

	forward.y = 0
	right.y = 0

	forward = forward.normalized()
	right = right.normalized()

	var direction = (
		forward * input_2d.y +
		right * input_2d.x
	)

	if direction.length() > 0:
		direction = direction.normalized()

	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	move_and_slide()


func shoot():
	if bullet_scene == null:
		return

	$AudioStreamPlayer.play()

	var camera = camera_pivot.get_node("Camera3D")

	var screen_center = get_viewport().get_visible_rect().size / 2

	var ray_origin = camera.project_ray_origin(screen_center)
	var ray_direction = camera.project_ray_normal(screen_center)

	var ray_end = ray_origin + ray_direction * 1000.0

	var query = PhysicsRayQueryParameters3D.create(
		ray_origin,
		ray_end
	)

	query.exclude = [self]

	var result = get_world_3d().direct_space_state.intersect_ray(query)

	var target_position = ray_end

	if result:
		target_position = result.position

	var shoot_direction = (
		target_position - marker.global_position
	).normalized()

	var bullet = bullet_scene.instantiate()

	get_tree().current_scene.add_child(bullet)

	bullet.global_position = marker.global_position
	bullet.direction = shoot_direction
