
extends CharacterBody3D

# --- MOVIMENTAÇÃO ---

@export var velocidade: float = 15.0
@export var forca_pulo: float = 10.0
@export var sensibilidade_mouse: float = 0.002

var gravidade: float = 15.0

@export_range(1, 10, 1) var quantidade_pulos: int = 2
var pulos_restantes: int = 2


# --- DASH ---

@export var velocidade_dash: float = 30.0
@export var duracao_dash: float = 0.15
@export var recarga_dash: float = 0.25
@export var max_dashes_no_ar: int = 2
@export var tempo_recarga_dash_chao: float = 0.5

var tempo_dash: float = 0.0
var tempo_recarga: float = 0.0
var tempo_recuperacao_dash: float = 0.0
var direcao_dash: Vector3 = Vector3.ZERO
var dashes_usados_no_ar: int = 0


# --- SISTEMA DE VIDA ---

@export var vida_maxima: int = 100
var vida_atual: int
var morto: bool = false


# --- SISTEMA DE TIRO ---

@export var alcance_tiro: float = 1000.0
@export var dano_tiro: float = 20.0


# --- REFERÊNCIAS ---

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var ponto_disparo: Marker3D = $Head/Camera3D/PontoDisparo
@onready var som_tiro: AudioStreamPlayer = $SomTiro
@onready var fogo_disparo: GPUParticles3D = $Head/Camera3D/Gun_Revolver/PontoDisparo/FogoDisparo


func _ready() -> void:
	vida_atual = vida_maxima
	pulos_restantes = quantidade_pulos
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	print("Vida do jogador: ", vida_atual, "/", vida_maxima)


func _unhandled_input(event: InputEvent) -> void:
	if morto:
		return

	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			rotate_y(-event.relative.x * sensibilidade_mouse)
			head.rotate_x(-event.relative.y * sensibilidade_mouse)
			head.rotation.x = clamp(
				head.rotation.x,
				deg_to_rad(-85.0),
				deg_to_rad(85.0)
			)

	if event is InputEventKey:
		if event.pressed and not event.echo:
			if event.keycode == KEY_ESCAPE:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event is InputEventMouseButton:
		if event.pressed:
			if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			elif event.button_index == MOUSE_BUTTON_LEFT:
				atirar()


func _physics_process(delta: float) -> void:
	if morto:
		return

	# --- RESTAURAR PULOS NO CHÃO ---

	if is_on_floor():
		pulos_restantes = quantidade_pulos

	# --- RECARGA GRADUAL DOS DASHES ---

	if is_on_floor():
		if dashes_usados_no_ar > 0:
			tempo_recuperacao_dash -= delta

			if tempo_recuperacao_dash <= 0.0:
				dashes_usados_no_ar -= 1
				tempo_recuperacao_dash = tempo_recarga_dash_chao
		else:
			tempo_recuperacao_dash = 0.0
	else:
		tempo_recuperacao_dash = tempo_recarga_dash_chao

	# --- GRAVIDADE ---

	if not is_on_floor():
		velocity.y -= gravidade * delta

	# --- PULO ---

	if Input.is_action_just_pressed("jump") and pulos_restantes > 0:
		velocity.y = forca_pulo
		pulos_restantes -= 1

	# --- DIREÇÃO DO MOVIMENTO ---

	var input_dir := Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_backward"
	)

	var direcao_movimento := transform.basis * Vector3(
		input_dir.x,
		0.0,
		input_dir.y
	)

	direcao_movimento.y = 0.0
	direcao_movimento = direcao_movimento.normalized()

	# --- TEMPOS DO DASH ---

	tempo_dash = maxf(tempo_dash - delta, 0.0)
	tempo_recarga = maxf(tempo_recarga - delta, 0.0)

	# --- ATIVAR DASH ---

	if (
		Input.is_action_just_pressed("dash")
		and tempo_recarga <= 0.0
		and tempo_dash <= 0.0
	):
		var esta_no_ar := not is_on_floor() or velocity.y > 0.0

		if not esta_no_ar or dashes_usados_no_ar < max_dashes_no_ar:
			if direcao_movimento != Vector3.ZERO:
				direcao_dash = direcao_movimento
			else:
				direcao_dash = -camera.global_transform.basis.z
				direcao_dash.y = 0.0
				direcao_dash = direcao_dash.normalized()

			tempo_dash = duracao_dash
			tempo_recarga = recarga_dash

			if esta_no_ar:
				dashes_usados_no_ar += 1

	# --- EXECUTAR DASH ---

	if tempo_dash > 0.0:
		velocity.x = direcao_dash.x * velocidade_dash
		velocity.z = direcao_dash.z * velocidade_dash
	else:
		# --- MOVIMENTAÇÃO NORMAL ---

		if direcao_movimento != Vector3.ZERO:
			velocity.x = direcao_movimento.x * velocidade
			velocity.z = direcao_movimento.z * velocidade
		else:
			velocity.x = move_toward(
				velocity.x, 0.0, velocidade
			)
			velocity.z = move_toward(
				velocity.z, 0.0, velocidade
			)

	move_and_slide()


# --- RECEBER DANO ---

func receber_dano(quantidade: int) -> void:
	if morto or quantidade <= 0:
		return

	vida_atual = max(vida_atual - quantidade, 0)

	print("Jogador recebeu ", quantidade, " de dano!")
	print("Vida restante: ", vida_atual, "/", vida_maxima)

	if vida_atual <= 0:
		morrer()


# --- MORTE ---

func morrer() -> void:
	if morto:
		return

	morto = true
	velocity = Vector3.ZERO
	print("O jogador morreu!")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


# --- ATIRAR ---

func atirar() -> void:
	if morto:
		return

	# Efeito visual do disparo
	fogo_disparo.restart()
	fogo_disparo.emitting = true

	# Som do tiro
	if som_tiro.stream != null:
		som_tiro.play()

	# Calcula a trajetória do tiro
	var origem = camera.global_position
	var direcao_tiro = -camera.global_transform.basis.z.normalized()
	var destino = origem + direcao_tiro * alcance_tiro

	var consulta = PhysicsRayQueryParameters3D.create(
		origem,
		destino
	)

	consulta.exclude = [get_rid()]

	var espaco = get_world_3d().direct_space_state
	var resultado = espaco.intersect_ray(consulta)

	if resultado.is_empty():
		print("Tiro: não acertou nada!")
		return

	var alvo = resultado["collider"]
	print("Tiro acertou: ", alvo.name)

	# Ativa plataformas
	if alvo.is_in_group("alvo_ativavel"):
		if alvo.has_method("ativar_plataforma"):
			alvo.ativar_plataforma()

	# Causa dano
	if alvo.has_method("receber_dano"):
		alvo.receber_dano(int(dano_tiro))
