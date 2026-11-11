extends CharacterBody3D

@export var altura_limite_morte: float = -30.0


# --- MOVIMENTAÇÃO ---

@export var velocidade: float = 15.0
@export var forca_pulo: float = 10.0
@export var sensibilidade_mouse: float = 0.002

var gravidade: float = 15.0
var inverter_vertical: bool = false

@export_range(1, 10, 1) var quantidade_pulos: int = 2
var pulos_restantes: int = 2
var estava_no_chao: bool = false


# --- DASH ---

@export var velocidade_dash: float = 30.0
@export var duracao_dash: float = 0.15
@export var recarga_dash: float = 0.25
@export var max_dashes_no_ar: int = 3
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


# --- SISTEMA DE IMUNIDADE ---

@export var tempo_imunidade: float = 2.0

var imune: bool = false
var timer_imunidade: Timer


# --- SISTEMA DE TIRO ---

@export var alcance_tiro: float = 1000.0
@export var dano_tiro: float = 20.0
@export var intervalo_tiro: float = 0.25

var tempo_ate_proximo_tiro: float = 0.0


# --- SOCO / PARRY ---

@export_group("Soco e Parry")

@export var dano_soco: int = 40
@export var alcance_soco: float = 1.8
@export var largura_soco: float = 1.5
@export var altura_soco: float = 1.5
@export var recarga_soco: float = 0.5
@export var atraso_impacto_soco: float = 0.08
## Tempo (em segundos) desde o início do soco em que o parry é possível.
@export var janela_parry: float = 0.2
@export var duracao_hitstop: float = 0.07
@export var cura_ao_matar: int = 25

var soco_ativo: bool = false
var tempo_desde_soco: float = 0.0
var recarga_soco_atual: float = 0.0
var soco_impactou: bool = false
var forma_soco := BoxShape3D.new()


# --- VISUAL DO SOCO (MÃO) ---

@export_group("Visual da Mão")

## Quanto a mão se desloca no soco (espaço do viewmodelMotion).
## Se ela for pro lado errado, inverta o sinal do X.
@export var deslocamento_soco_mao: Vector3 = Vector3(-0.1, 0.05, -0.35)
@export var escala_soco_mao: float = 1.3
@export var duracao_visual_soco: float = 0.25

var posicao_original_mao: Vector3
var escala_original_mao: Vector3
var tempo_visual_soco: float = 0.0


# --- MOVIMENTO VISUAL DAS ARMAS ---

@export_group("Movimento das Armas")

@export var intensidade_balanço_repouso: float = 0.004
@export var velocidade_balanço_repouso: float = 1.2

@export var intensidade_balanço_andando: float = 0.012
@export var velocidade_balanço_andando: float = 5.5

## Quão rápido o balanço de andar entra e sai (repouso <-> andando).
@export var suavidade_balanço: float = 6.0

var tempo_balanço: float = 0.0
var fator_balanço_atual: float = 0.0
var posicao_original_viewmodel: Vector3
var rotacao_original_viewmodel: Vector3


# --- ATRASO AO MOVIMENTAR A CÂMERA ---

@export_group("Atraso das Armas")

## Limite do atraso (vale para os dois eixos).
@export var limite_sway: float = 0.05
## Quanto o atraso reage à velocidade da câmera.
@export var tempo_resposta_sway: float = 0.02
## Se o horizontal parecer maior que o vertical, diminua este valor.
@export var multiplicador_sway_horizontal: float = 0.7
@export var multiplicador_sway_vertical: float = 2.0
@export var intensidade_sway_posicao: float = 0.15
@export var intensidade_sway_rotacao: float = 0.8
@export var suavidade_sway: float = 10.0

var sway_atual: Vector2 = Vector2.ZERO

# Quanto a câmera girou (em radianos) desde o último quadro.
# x = yaw (horizontal), y = pitch (vertical)
var giro_camera_acumulado: Vector2 = Vector2.ZERO


# --- RECUO DA PISTOLA ---

@export_group("Recuo da Pistola")

@export var distancia_recuo: float = 0.045
@export var inclinacao_recuo: float = 2.0
@export var forca_recuo: float = 1.0
@export var recuo_maximo: float = 1.5
@export var velocidade_retorno_recuo: float = 16.0
## Se o cano descer em vez de subir, mude para -1.0.
@export var sentido_giro_recuo: float = 1.0

var recuo_atual: float = 0.0
var posicao_original_arma: Vector3
var basis_original_arma: Basis


# --- REFERÊNCIAS ---

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D

@onready var viewmodel_motion: Node3D = $Head/Camera3D/viewmodelMotion

@onready var mao: Sprite3D = $Head/Camera3D/viewmodelMotion/Mão

@onready var arma: Node3D = $Head/Camera3D/viewmodelMotion/Gun_Revolver

@onready var ponto_disparo: Marker3D = $Head/Camera3D/viewmodelMotion/Gun_Revolver/PontoDisparo

@onready var som_tiro: AudioStreamPlayer = $SomTiro

@onready var fogo_disparo: GPUParticles3D = $Head/Camera3D/viewmodelMotion/Gun_Revolver/PontoDisparo/FogoDisparo


# --- CONFIGURAÇÕES DO JOGADOR ---

func carregar_configuracoes_jogador() -> void:
	var config := ConfigFile.new()

	var resultado = config.load("user://g00d_config.cfg")

	if resultado != OK:
		print("Configurações não encontradas. Usando valores padrão.")
		return

	var valor_sensibilidade: float = config.get_value(
		"gameplay",
		"sensibilidade",
		50.0
	)

	sensibilidade_mouse = valor_sensibilidade / 25000.0

	inverter_vertical = config.get_value(
		"gameplay",
		"inverter_vertical",
		false
	)

	print("Sensibilidade carregada: ", sensibilidade_mouse)
	print("Inversão vertical: ", inverter_vertical)


func _ready() -> void:
	add_to_group("player")
	get_tree().call_group("hud", "show")

	carregar_configuracoes_jogador()

	vida_atual = vida_maxima
	pulos_restantes = quantidade_pulos

	# Guardar transformações originais
	posicao_original_viewmodel = viewmodel_motion.position
	rotacao_original_viewmodel = viewmodel_motion.rotation

	posicao_original_arma = arma.position
	basis_original_arma = arma.basis

	posicao_original_mao = mao.position
	escala_original_mao = mao.scale

	# Área de detecção do soco
	forma_soco.size = Vector3(largura_soco, altura_soco, alcance_soco)

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Criar timer de imunidade
	timer_imunidade = Timer.new()
	timer_imunidade.one_shot = true
	timer_imunidade.wait_time = tempo_imunidade
	timer_imunidade.timeout.connect(_fim_imunidade)
	add_child(timer_imunidade)

	# Imunidade inicial
	iniciar_imunidade()

	print("Vida do jogador: ", vida_atual, "/", vida_maxima)


# --- PROCESSAMENTO VISUAL ---

func _process(delta: float) -> void:
	tempo_ate_proximo_tiro = maxf(tempo_ate_proximo_tiro - delta, 0.0)

	atualizar_sway_armas(delta)
	atualizar_movimento_armas(delta)
	atualizar_recuo_arma(delta)
	atualizar_mao_soco(delta)


# --- BALANÇO DAS ARMAS ---

func atualizar_movimento_armas(delta: float) -> void:
	var velocidade_horizontal := Vector2(
		velocity.x,
		velocity.z
	).length()

	var fator_alvo := clampf(
		velocidade_horizontal / velocidade,
		0.0,
		1.0
	)

	# No ar, a arma não balança como se estivesse andando
	if not is_on_floor():
		fator_alvo = 0.0

	fator_balanço_atual = lerpf(
		fator_balanço_atual,
		fator_alvo,
		1.0 - exp(-suavidade_balanço * delta)
	)

	var intensidade := lerpf(
		intensidade_balanço_repouso,
		intensidade_balanço_andando,
		fator_balanço_atual
	)

	var velocidade_balanço := lerpf(
		velocidade_balanço_repouso,
		velocidade_balanço_andando,
		fator_balanço_atual
	)

	tempo_balanço += delta * velocidade_balanço

	# Movimento em "8": vertical na frequência cheia, lateral na metade
	var balanço := Vector3(
		cos(tempo_balanço * 0.5) * intensidade * 0.6,
		sin(tempo_balanço) * intensidade,
		0.0
	)

	# O sway (atraso da câmera) já vem suavizado, então é somado direto
	var deslocamento_sway := Vector3(
		-sway_atual.x * intensidade_sway_posicao,
		sway_atual.y * intensidade_sway_posicao,
		0.0
	)

	viewmodel_motion.position = posicao_original_viewmodel + balanço + deslocamento_sway

	var rotacao_alvo := rotacao_original_viewmodel

	rotacao_alvo.x += sway_atual.y * intensidade_sway_rotacao
	rotacao_alvo.y += sway_atual.x * intensidade_sway_rotacao

	viewmodel_motion.rotation = rotacao_alvo


# --- ATRASO DA CÂMERA ---

func atualizar_sway_armas(delta: float) -> void:
	if delta <= 0.0:
		return

	# Velocidade de giro da câmera (rad/s), vinda direto do mouse
	var velocidade_giro := giro_camera_acumulado / delta
	giro_camera_acumulado = Vector2.ZERO

	var sway_alvo := Vector2(
		-velocidade_giro.x * tempo_resposta_sway * multiplicador_sway_horizontal,
		-velocidade_giro.y * tempo_resposta_sway * multiplicador_sway_vertical
	)

	sway_alvo.x = clampf(sway_alvo.x, -limite_sway, limite_sway)
	sway_alvo.y = clampf(sway_alvo.y, -limite_sway, limite_sway)

	var fator_suavidade := 1.0 - exp(-suavidade_sway * delta)
	sway_atual = sway_atual.lerp(sway_alvo, fator_suavidade)


# --- RECUO DA PISTOLA ---

func aplicar_recuo() -> void:
	recuo_atual = minf(
		recuo_atual + forca_recuo,
		recuo_maximo
	)


func atualizar_recuo_arma(delta: float) -> void:
	var fator_retorno := 1.0 - exp(
		-velocidade_retorno_recuo * delta
	)

	recuo_atual = lerpf(
		recuo_atual,
		0.0,
		fator_retorno
	)

	# Pistola recua para trás (em direção à câmera)
	arma.position = posicao_original_arma + Vector3(
		0.0,
		0.0,
		distancia_recuo * recuo_atual
	)

	# Cano levanta: gira em torno do eixo X do pai, então não depende
	# da orientação com que o modelo foi importado
	var angulo := deg_to_rad(inclinacao_recuo * recuo_atual) * sentido_giro_recuo

	arma.basis = Basis(Vector3.RIGHT, angulo) * basis_original_arma


# --- VISUAL DA MÃO NO SOCO ---

func atualizar_mao_soco(delta: float) -> void:
	var curva := 0.0

	if soco_ativo:
		tempo_visual_soco += delta
		curva = sin(clampf(tempo_visual_soco / duracao_visual_soco, 0.0, 1.0) * PI)

	mao.position = posicao_original_mao + deslocamento_soco_mao * curva
	mao.scale = escala_original_mao * (1.0 + (escala_soco_mao - 1.0) * curva)


# Placeholder: quando tiver o spritesheet, configure hframes no Sprite3D.
# 0 = mão parada, 1 = soco (ajuste conforme seus frames)
func trocar_sprite_mao(frame: int) -> void:
	if mao.hframes > 1:
		mao.frame = frame


# --- SOCO E PARRY ---

func socar() -> void:
	if morto or recarga_soco_atual > 0.0:
		return

	recarga_soco_atual = recarga_soco
	tempo_desde_soco = 0.0
	tempo_visual_soco = 0.0
	soco_impactou = false
	soco_ativo = true

	trocar_sprite_mao(1)


func atualizar_soco(delta: float) -> void:
	recarga_soco_atual = maxf(recarga_soco_atual - delta, 0.0)

	if not soco_ativo:
		return

	tempo_desde_soco += delta

	var alvos := _consultar_area_soco()

	# Parry: só dentro da janela de tempo
	if tempo_desde_soco <= janela_parry:
		var parry_feito := false

		for resultado in alvos:
			var alvo = resultado["collider"]

			if alvo.is_in_group("projetil") and alvo.has_method("parry"):
				alvo.parry(-camera.global_transform.basis.z)
				parry_feito = true

		if parry_feito:
			_efeito_parry()

	# Dano corpo a corpo: uma vez só, no momento do impacto
	if not soco_impactou and tempo_desde_soco >= atraso_impacto_soco:
		soco_impactou = true

		var ja_atingidos: Array = []

		for resultado in alvos:
			var alvo = resultado["collider"]

			if alvo == self or alvo in ja_atingidos:
				continue
			if alvo.is_in_group("projetil"):
				continue

			if alvo.has_method("receber_dano"):
				alvo.receber_dano(dano_soco)
				ja_atingidos.append(alvo)

				if _inimigo_morreu(alvo):
					curar(cura_ao_matar)

	# Fim do soco
	if tempo_desde_soco > janela_parry + 0.15:
		soco_ativo = false
		trocar_sprite_mao(0)


func _consultar_area_soco() -> Array[Dictionary]:
	var base: Basis = camera.global_transform.basis.orthonormalized()
	var frente: Vector3 = -base.z

	# A caixa começa no jogador e vai até o alcance máximo
	var centro: Vector3 = camera.global_position + frente * (alcance_soco * 0.5)

	var consulta := PhysicsShapeQueryParameters3D.new()
	consulta.shape = forma_soco
	consulta.transform = Transform3D(base, centro)
	consulta.collide_with_areas = true
	consulta.collide_with_bodies = true
	consulta.exclude = [get_rid()]

	return get_world_3d().direct_space_state.intersect_shape(consulta)


func _efeito_parry() -> void:
	print("PARRY!")

	# Hitstop: congela o jogo por um instante pra dar impacto
	Engine.time_scale = 0.05
	await get_tree().create_timer(duracao_hitstop, true, false, true).timeout
	Engine.time_scale = 1.0


func _inimigo_morreu(alvo: Object) -> bool:
	if not is_instance_valid(alvo):
		return true
	if alvo is Node and alvo.is_queued_for_deletion():
		return true
	if "morto" in alvo and alvo.morto:
		return true
	if "vida_atual" in alvo and alvo.vida_atual <= 0:
		return true
	return false


func _unhandled_input(event: InputEvent) -> void:
	if morto:
		return

	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			var giro_yaw: float = -event.relative.x * sensibilidade_mouse

			# Inversão vertical da câmera
			var multiplicador: float = -1.0 if inverter_vertical else 1.0
			var giro_pitch: float = -event.relative.y * sensibilidade_mouse * multiplicador

			rotate_y(giro_yaw)
			head.rotate_x(giro_pitch)

			head.rotation.x = clamp(
				head.rotation.x,
				deg_to_rad(-85.0),
				deg_to_rad(85.0)
			)

			# Alimenta o sway com o giro real da câmera
			giro_camera_acumulado += Vector2(giro_yaw, giro_pitch)

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
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				socar()


func _physics_process(delta: float) -> void:

	if global_position.y <= altura_limite_morte:
		print("Jogador caiu para fora do mapa!")
		morrer("PERDIDO NO VAZIO ESPACIAL")
		return

	if morto:
		return

	atualizar_soco(delta)

	# --- PULOS ---

	if is_on_floor():
		pulos_restantes = quantidade_pulos
	elif estava_no_chao:
		# Saiu de uma beirada sem pular: perde um dos pulos
		pulos_restantes = mini(pulos_restantes, quantidade_pulos - 1)

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

	var input_dir: Vector2 = Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_backward"
	)

	var direcao_movimento: Vector3 = transform.basis * Vector3(
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
		var esta_no_ar: bool = not is_on_floor() or velocity.y > 0.0

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
				velocity.x,
				0.0,
				velocidade
			)

			velocity.z = move_toward(
				velocity.z,
				0.0,
				velocidade
			)

	move_and_slide()

	estava_no_chao = is_on_floor()


# --- RECEBER DANO ---

func receber_dano(
	quantidade: int,
	causa: String = "ELIMINADO EM COMBATE"
) -> void:
	if morto or imune or quantidade <= 0:
		return

	vida_atual = max(vida_atual - quantidade, 0)

	print("Jogador recebeu ", quantidade, " de dano!")
	print("Vida restante: ", vida_atual, "/", vida_maxima)

	if vida_atual <= 0:
		morrer(causa)
		return

	iniciar_imunidade()


# --- CURAR ---

func curar(quantidade: int) -> void:
	if morto or quantidade <= 0:
		return

	var vida_anterior = vida_atual

	vida_atual = min(vida_atual + quantidade, vida_maxima)

	var vida_recuperada = vida_atual - vida_anterior

	if vida_recuperada > 0:
		print("Jogador recuperou ", vida_recuperada, " pontos de vida!")
		print("Vida atual: ", vida_atual, "/", vida_maxima)
	else:
		print("Vida já está completa!")


# --- INICIAR IMUNIDADE ---

func iniciar_imunidade() -> void:
	imune = true
	timer_imunidade.start()

	print("Jogador está imune por ", tempo_imunidade, " segundos!")


# --- FINALIZAR IMUNIDADE ---

func _fim_imunidade() -> void:
	imune = false

	print("Imunidade encerrada! Jogador vulnerável novamente.")


# --- MORTE ---

func morrer(causa: String = "CAUSA DA MORTE DESCONHECIDA") -> void:
	if morto:
		return

	morto = true
	velocity = Vector3.ZERO

	print("O jogador morreu: ", causa)

	get_tree().call_group("hud", "ocultar")

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true

	var tela_gameover = preload("res://scenes/UI/gameOver.tscn").instantiate()
	tela_gameover.definir_causa_morte(causa)

	get_tree().current_scene.add_child(tela_gameover)


# --- ATIRAR ---

func atirar() -> void:
	if morto:
		return

	# Cadência: ignora cliques antes do intervalo
	if tempo_ate_proximo_tiro > 0.0:
		return

	tempo_ate_proximo_tiro = intervalo_tiro

	# Aplicar recuo somente na pistola
	aplicar_recuo()

	# Efeito visual do disparo
	fogo_disparo.restart()
	fogo_disparo.emitting = true

	# Som do tiro
	if som_tiro.stream != null:
		som_tiro.play()

	# Calcula a trajetória do tiro
	var origem: Vector3 = camera.global_position
	var direcao_tiro: Vector3 = -camera.global_transform.basis.z.normalized()
	var destino: Vector3 = origem + direcao_tiro * alcance_tiro

	var consulta := PhysicsRayQueryParameters3D.create(
		origem,
		destino
	)

	consulta.exclude = [get_rid()]

	var espaco := get_world_3d().direct_space_state
	var resultado := espaco.intersect_ray(consulta)

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
