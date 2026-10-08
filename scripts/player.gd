
extends CharacterBody3D

const SPEED := 6.0
const JUMP_VELOCITY := 5.0
const MOUSE_SENSITIVITY := 0.003
const GRAVITY := 18.0

const MAX_FUEL := 1.5
const JETPACK_FORCE := 12.0

var fuel := MAX_FUEL
var jetpack_active := false

@onready var camera_pivot: Node3D = $CameraPivot

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		camera_pivot.rotation.y -= event.relative.x * MOUSE_SENSITIVITY
		camera_pivot.rotation.x -= event.relative.y * MOUSE_SENSITIVITY
		camera_pivot.rotation.x = clampf(
			camera_pivot.rotation.x,
			deg_to_rad(-55),
			deg_to_rad(65)
		)

	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event is InputEventMouseButton:
		if event.pressed:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	elif velocity.y < 0.0:
		velocity.y = 0.0
		fuel = MAX_FUEL

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	jetpack_active = (
		Input.is_action_pressed("jetpack")
		and fuel > 0.0
		and not is_on_floor()
	)

	if jetpack_active:
		velocity.y = minf(velocity.y + JETPACK_FORCE * delta, 7.0)
		fuel = maxf(fuel - delta, 0.0)

	var input_dir := Input.get_vector(
		"move_left", "move_right", "move_forward", "move_back"
	)

	var forward := -camera_pivot.global_basis.z
	var right := camera_pivot.global_basis.x

	forward.y = 0.0
	right.y = 0.0
	forward = forward.normalized()
	right = right.normalized()

	var direction := right * input_dir.x - forward * input_dir.y
	direction = direction.normalized()

	if direction.length() > 0.0:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED

		var target_angle := atan2(direction.x, direction.z)
		$Visual.rotation.y = lerp_angle(
			$Visual.rotation.y,
			target_angle,
			10.0 * delta
		)
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED * 5.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, SPEED * 5.0 * delta)

	move_and_slide()
