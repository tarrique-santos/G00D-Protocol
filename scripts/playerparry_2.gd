
extends CharacterBody3D

# --- MOVIMENTAÇÃO ---

@export var velocidade: float = 12.0
@export var forca_pulo: float = 6
@export var sensibilidade_mouse: float = 0.002

var gravidade: float = 9.8


# --- SISTEMA DE TIRO ---

@export var cena_tiro: PackedScene

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var ponto_disparo: Marker3D = $Head/Camera3D/PontoDisparo


func _ready() -> void:
	# Captura o mouse para o FPS
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	# --- CÂMERA COM MOUSE ---

	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			rotate_y(-event.relative.x * sensibilidade_mouse)

			head.rotate_x(-event.relative.y * sensibilidade_mouse)

			# Limita a rotação vertical da câmera
			head.rotation.x = clamp(
				head.rotation.x,
				deg_to_rad(-85.0),
				deg_to_rad(85.0)
			)

	# --- LIBERAR E RECUPERAR O MOUSE ---

	if event is InputEventKey:
		if event.pressed and not event.echo:
			if event.keycode == KEY_ESCAPE:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event is InputEventMouseButton:
		if event.pressed:
			# Clique esquerdo dispara
			if event.button_index == MOUSE_BUTTON_LEFT:
				if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
					atirar()

			# Clique esquerdo também captura o mouse novamente
			elif Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	# --- GRAVIDADE ---

	if not is_on_floor():
		velocity.y -= gravidade * delta

	# --- PULO ---

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = forca_pulo

	# --- MOVIMENTAÇÃO WASD ---

	var input_dir := Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
        "move_backward"
	)

	# Movimento relativo à direção do player
	var direcao := transform.basis * Vector3(
		input_dir.x,
		0.0,
		input_dir.y
	)

	direcao.y = 0.0
	direcao = direcao.normalized()

	if direcao != Vector3.ZERO:
		velocity.x = direcao.x * velocidade
		velocity.z = direcao.z * velocidade
	else:
		velocity.x = move_toward(
			velocity.x, 0.0, velocidade
		)
		velocity.z = move_toward(
			velocity.z, 0.0, velocidade
		)

	# Aplica o movimento e as colisões
	move_and_slide()


# --- FUNÇÃO DE DISPARO ---




# --- DISPARO INSTANTÂNEO ---

@export var alcance_tiro: float = 1000.0
@export var dano_tiro: float = 10.0


func atirar() -> void:
	# Origem e direção da mira
	var origem = camera.global_position
	var direcao = -camera.global_transform.basis.z.normalized()
	var destino = origem + direcao * alcance_tiro

	# Prepara o raio de detecção
	var consulta = PhysicsRayQueryParameters3D.create(
		origem,
		destino
	)

	# Impede o tiro de acertar o próprio jogador
	consulta.exclude = [get_rid()]

	# Verifica o que está na linha de tiro
	var espaco = get_world_3d().direct_space_state
	var resultado = espaco.intersect_ray(consulta)

	# Se não acertou nada, encerra o disparo
	if resultado.is_empty():
		return

	var alvo = resultado["collider"]
	if resultado.is_empty():
		print("Tiro: não acertou nada!")
		return
	print("Tiro acertou: ", resultado["collider"].name)

	# Ativa plataformas ou alvos especiais
	if alvo.is_in_group("alvo_ativavel"):
		if alvo.has_method("ativar_plataforma"):
			alvo.ativar_plataforma()

	# Aplica dano se o alvo tiver um método para recebê-lo
	if alvo.has_method("receber_dano"):
		alvo.receber_dano(dano_tiro)
	
