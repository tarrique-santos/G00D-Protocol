extends CharacterBody3D
## Olho robô gigante: não se move, só rotaciona para encarar o jogador.
## Tem vida, recebe dano (tiro, soco e laser refletido no parry) e mostra
## uma barra de vida no topo da tela.
## Ataques: rajada reta, feixe em "W", feixe em "M", varredura horizontal (pular!)
## e, se o jogador chegar muito perto, um giro de 360° com o feixe.

signal attack_started(attack_name: String)
signal vida_mudou(atual: int, maxima: int)
signal morreu

# Pontos do desenho "W" em coordenadas normalizadas (-1..1).
# O "M" é o mesmo desenho com o Y invertido.
const W_POINTS: Array[Vector2] = [
	Vector2(-1.0, 1.0),
	Vector2(-0.5, -1.0),
	Vector2(0.0, 0.3),
	Vector2(0.5, -1.0),
	Vector2(1.0, 1.0),
]

@export_group("Vida")
@export var nome_chefe := "OLHO GIGANTE"
@export var vida_maxima := 500
@export var mostrar_barra := true
## Desloca a barra em pixels. X positivo = direita, Y positivo = para baixo.
@export var barra_deslocamento := Vector2.ZERO
## Encosta a barra no canto direito da tela em vez de centralizar.
@export var barra_ancorar_direita := false

@export_group("Alvo")
@export var player_group := "player"
## Altura somada à posição do jogador para mirar (0 se a origem dele já é o centro).
@export var aim_height := 1.0
## Nó de onde saem os lasers (Marker3D na pupila). Se vazio, procura "Muzzle".
@export var muzzle: Node3D

@export_group("Rotação")
@export var turn_speed := 2.0
## Marque se o olho estiver de costas (frente do modelo em +Z).
@export var model_faces_back := true

@export_group("Laser (tiros)")
## Opcional: só use se a cena tiver o script laser.gd (LaserVermelho) no root.
@export var laser_scene: PackedScene
@export var laser_speed := 25.0
@export var laser_damage := 10.0
@export var laser_size := 2.0

@export_group("Ataques")
@export var time_between_attacks := 2.5
@export var windup_time := 0.6

@export_subgroup("Rajada reta")
@export var burst_count := 5
@export var burst_interval := 0.18

@export_subgroup("Desenho W / M")
## Tamanho do desenho na altura do jogador.
@export var pattern_width := 12.0
@export var pattern_height := 6.0
## true = feixe contínuo reto. false = sequência de tiros (versão antiga).
@export var pattern_as_beam := true
## Só usados se pattern_as_beam for false:
@export var pattern_shots := 17
@export var pattern_interval := 0.07

@export_subgroup("Feixe contínuo (W / M)")
## Tempo com o feixe fino de aviso, antes de começar a varrer e causar dano.
@export var beam_windup := 0.5
## Tempo que o feixe leva para desenhar o W/M inteiro.
@export var beam_duration := 1.8
@export var beam_range := 120.0
@export var beam_thickness := 0.6
@export var beam_damage := 25
## Intervalo mínimo entre danos enquanto o feixe está no jogador.
@export var beam_tick := 0.25
@export var beam_color := Color(1.0, 0.1, 0.1)

@export_subgroup("Giro de 360° (jogador muito perto)")
## Se o jogador chegar a esta distância, o chefe faz o giro.
@export var spin_trigger_radius := 10.0
## Tempo mínimo entre dois giros.
@export var spin_cooldown := 6.0
## Tempo que o olho leva para se erguer antes de bater para baixo.
@export var spin_windup := 0.7
## Tempo que o giro completo leva.
@export var spin_duration := 1.4
@export var spin_damage := 30

@export_subgroup("Varredura horizontal (exige pulo)")
## Altura do feixe acima do chão. O jogador precisa estar acima disso para escapar.
@export var sweep_height := 1.0
## Tempo com o feixe fino de aviso, parado no ponto de partida.
@export var sweep_windup := 0.8
## Tempo de uma volta completa.
@export var sweep_duration := 2.6
## Quantas voltas o feixe dá (1.5 = passa duas vezes no mesmo lado).
@export var sweep_rotations := 1.0
## Ângulo (graus) entre o ponto de partida e o jogador. Menor = chega mais rápido.
@export var sweep_start_offset := 120.0
## Distância do centro do chefe até onde o feixe começa.
@export var sweep_inner_radius := 3.0
@export var sweep_damage := 25
@export var sweep_color := Color(1.0, 0.55, 0.1)

@export_group("Proximidade")
@export var contact_radius := 6.0
@export var contact_damage := 20
@export var contact_cooldown := 0.8
@export var contact_ignore_height := true
## Mostra o raio de contato (vermelho) e o raio do giro (amarelo).
@export var show_contact_radius := false

# "morto" e "vida_atual" têm esses nomes de propósito: o seu jogador lê os dois
# para saber se o inimigo morreu (e curar ao matar).
var vida_atual: int
var morto := false

var _player: Node3D
var _contact_timer := 0.0
var _spin_cd := 0.0
var _spinning := false
var _barra: BarraVidaBoss
var _flash_mat: StandardMaterial3D


func _ready() -> void:
	vida_atual = vida_maxima

	if muzzle == null:
		muzzle = get_node_or_null("Muzzle")
	if muzzle == null:
		muzzle = self
	if show_contact_radius:
		_make_debug_sphere(contact_radius, Color(1.0, 0.2, 0.2, 0.15))
		_make_debug_sphere(spin_trigger_radius, Color(1.0, 0.9, 0.2, 0.08))

	if mostrar_barra:
		_barra = BarraVidaBoss.new()
		_barra.nome_boss = nome_chefe
		_barra.deslocamento = barra_deslocamento
		_barra.ancorar_direita = barra_ancorar_direita
		add_child(_barra)
		_barra.atualizar(vida_atual, vida_maxima)

	_attack_loop()


func _physics_process(delta: float) -> void:
	if morto:
		return

	_spin_cd = maxf(_spin_cd - delta, 0.0)

	var p := _get_player()
	if p == null:
		return

	# Durante o giro quem controla a rotação é o ataque, não o "olhar para o jogador"
	if not _spinning:
		_face(p.global_position + Vector3.UP * aim_height, delta)
	_check_contact(p, delta)


# ---------------------------------------------------------------- Vida

## Chamado pelo tiro e pelo soco do jogador, e pelo laser refletido no parry.
func receber_dano(quantidade: int, _causa: String = "") -> void:
	if morto or quantidade <= 0:
		return

	vida_atual = maxi(vida_atual - quantidade, 0)
	vida_mudou.emit(vida_atual, vida_maxima)
	if _barra:
		_barra.atualizar(vida_atual, vida_maxima)

	if vida_atual <= 0:
		_morrer()
	else:
		_flash_dano()


func _morrer() -> void:
	morto = true  # tem que ser a primeira coisa: o jogador checa logo após o golpe
	morreu.emit()

	set_physics_process(false)
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)

	if _barra:
		_barra.fechar()

	# Encolhe e some
	var tw := create_tween()
	tw.tween_property(self, "scale", scale * 0.01, 1.2) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_callback(queue_free)


## Pisca em branco por um instante ao levar dano.
func _flash_dano() -> void:
	if _flash_mat == null:
		_flash_mat = StandardMaterial3D.new()
		_flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_flash_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_flash_mat.albedo_color = Color(1.0, 1.0, 1.0, 0.6)

	var malhas := find_children("*", "MeshInstance3D", true, false)
	for m in malhas:
		(m as MeshInstance3D).material_overlay = _flash_mat

	await get_tree().create_timer(0.07).timeout

	for m in malhas:
		if is_instance_valid(m):
			(m as MeshInstance3D).material_overlay = null


# ---------------------------------------------------------------- Rotação

func _face(target: Vector3, delta: float) -> void:
	var dir := target - global_position
	if dir.length() < 0.01:
		return
	dir = dir.normalized()
	var up := Vector3.UP
	if absf(dir.dot(up)) > 0.99:
		up = Vector3.RIGHT
	var target_basis := Basis.looking_at(dir, up)
	if model_faces_back:
		target_basis = target_basis * Basis(Vector3.UP, PI)

	# Gira preservando a escala do nó (antes ela era zerada para 1).
	var escala := global_basis.get_scale()
	var rotacao := global_basis.orthonormalized().slerp(
		target_basis, clampf(turn_speed * delta, 0.0, 1.0))
	global_basis = rotacao * Basis.from_scale(escala)


# ---------------------------------------------------------------- Proximidade

func _check_contact(p: Node3D, delta: float) -> void:
	_contact_timer -= delta
	var offset := p.global_position - global_position
	if contact_ignore_height:
		offset.y = 0.0
	if offset.length() <= contact_radius and _contact_timer <= 0.0:
		_contact_timer = contact_cooldown
		_hurt(p, contact_damage)


func _player_too_close() -> bool:
	var p := _get_player()
	return p != null and global_position.distance_to(p.global_position) <= spin_trigger_radius


# ---------------------------------------------------------------- Ataques

func _attack_loop() -> void:
	var last := ""
	while is_inside_tree() and not morto:
		await _wait_next_attack()
		if not is_inside_tree() or morto:
			return
		if _get_player() == null:
			continue

		# Jogador colado no chefe: giro de 360° (respeitando a recarga)
		if _spin_cd <= 0.0 and _player_too_close():
			last = "spin"
		else:
			var options: Array[String] = ["burst", "w", "m", "sweep"]
			options.erase(last)  # não repete o mesmo ataque duas vezes seguidas
			last = options.pick_random()

		attack_started.emit(last)  # use para som/animação de preparação

		# Giro e varredura já têm o próprio aviso (olho se erguendo / feixe fino)
		if last != "spin" and last != "sweep":
			await get_tree().create_timer(windup_time).timeout
			if not is_inside_tree() or morto:
				return

		match last:
			"burst":
				await _attack_burst()
			"w":
				if pattern_as_beam:
					await _attack_beam(false)
				else:
					await _attack_pattern(false)
			"m":
				if pattern_as_beam:
					await _attack_beam(true)
				else:
					await _attack_pattern(true)
			"sweep":
				await _attack_sweep()
			"spin":
				await _attack_spin()


## Espera o intervalo entre ataques, mas sai mais cedo se o jogador colar no chefe.
func _wait_next_attack() -> void:
	var t := 0.0
	while t < time_between_attacks and not morto:
		await get_tree().create_timer(0.1).timeout
		if not is_inside_tree():
			return
		t += 0.1
		if t >= 0.6 and _spin_cd <= 0.0 and _player_too_close():
			return


func _attack_burst() -> void:
	for i in burst_count:
		var p := _get_player()
		if p == null or not is_inside_tree() or morto:
			return
		var aim := p.global_position + Vector3.UP * aim_height
		_fire((aim - muzzle.global_position).normalized())
		await get_tree().create_timer(burst_interval).timeout


## Feixe contínuo e reto que varre o espaço desenhando um W (ou M).
func _attack_beam(inverted: bool) -> void:
	var p := _get_player()
	if p == null:
		return

	# O desenho é travado na posição do jogador no início: dá para desviar.
	var center := p.global_position + Vector3.UP * aim_height
	var forward := (center - muzzle.global_position).normalized()
	var right := forward.cross(Vector3.UP)
	if right.length() < 0.01:
		right = Vector3.RIGHT
	right = right.normalized()
	var up := right.cross(forward).normalized()

	var pts: Array[Vector2] = []
	for v in W_POINTS:
		pts.append(Vector2(v.x, -v.y if inverted else v.y))
	var path := _sample_path(pts, 200)

	var pose := func(t: float, _sweeping: bool) -> Array:
		var s := _path_at(path, t)
		var origin := muzzle.global_position
		var target := center + right * s.x * pattern_width * 0.5 + up * s.y * pattern_height * 0.5
		return [origin, (target - origin).normalized()]

	await _beam_loop(beam_windup, beam_duration, beam_damage, pose, beam_color, 1.0)


## Giro de 360° para baixo quando o jogador está muito perto: o olho se ergue,
## depois gira para a frente e para baixo soltando o feixe, num círculo completo
## no plano vertical que passa pelo jogador. Dá para fugir saindo desse plano.
func _attack_spin() -> void:
	var p := _get_player()
	if p == null:
		return

	_spin_cd = spin_cooldown
	_spinning = true

	# Plano vertical do giro: o que contém o chefe e o jogador
	var f_h := p.global_position - global_position
	f_h.y = 0.0
	if f_h.length() < 0.01:
		f_h = Vector3.FORWARD
	f_h = f_h.normalized()
	var axis := f_h.cross(Vector3.UP).normalized()

	var base_basis := Basis.looking_at(f_h, Vector3.UP)
	if model_faces_back:
		base_basis = base_basis * Basis(Vector3.UP, PI)

	var escala := global_basis.get_scale()
	var inicio := global_basis.orthonormalized()
	# Posição inicial do giro: olho apontando para cima
	var erguido := Basis(axis, PI * 0.5) * base_basis

	# 1) Olho se ergue (aviso)
	var t_w := 0.0
	while t_w < spin_windup and not morto:
		await get_tree().physics_frame
		if not is_inside_tree():
			return
		t_w += get_physics_process_delta_time()
		var k := smoothstep(0.0, 1.0, clampf(t_w / spin_windup, 0.0, 1.0))
		global_basis = inicio.slerp(erguido, k) * Basis.from_scale(escala)

	# 2) Giro completo: cima -> frente (jogador) -> baixo -> trás -> cima
	var pose := func(t: float, _sweeping: bool) -> Array:
		var phi := PI * 0.5 - TAU * t
		var rot := Basis(axis, phi)
		global_basis = rot * base_basis * Basis.from_scale(escala)
		return [muzzle.global_position, rot * f_h]

	await _beam_loop(0.25, spin_duration, spin_damage, pose, beam_color, 1.3)

	_spinning = false


## Feixe horizontal rente ao chão que gira em volta do chefe. O jogador precisa
## pular por cima dele quando passar.
func _attack_sweep() -> void:
	var p := _get_player()
	if p == null:
		return

	var chao_y := _floor_y(p)
	var centro := Vector3(global_position.x, chao_y + sweep_height, global_position.z)

	var para_jogador := p.global_position - global_position
	var ang_jogador := atan2(para_jogador.x, para_jogador.z)

	# Sentido aleatório; começa antes do jogador para dar tempo de ver e pular
	var sentido := 1.0 if randf() < 0.5 else -1.0
	var inicio := ang_jogador - sentido * deg_to_rad(sweep_start_offset)

	var pose := func(t: float, _sweeping: bool) -> Array:
		var yaw := inicio + sentido * TAU * sweep_rotations * t
		var dir := Vector3(sin(yaw), 0.0, cos(yaw))
		return [centro + dir * sweep_inner_radius, dir]

	await _beam_loop(sweep_windup, sweep_duration, sweep_damage, pose, sweep_color, 0.7)


## Altura do chão embaixo do jogador (para o feixe rente ao chão).
func _floor_y(p: Node3D) -> float:
	var excluir: Array[RID] = [get_rid()]
	if p is CollisionObject3D:
		excluir.append((p as CollisionObject3D).get_rid())

	var query := PhysicsRayQueryParameters3D.create(
		p.global_position + Vector3.UP * 0.5,
		p.global_position + Vector3.DOWN * 100.0)
	query.exclude = excluir

	var r := get_world_3d().direct_space_state.intersect_ray(query)
	if r.is_empty():
		return p.global_position.y
	return r["position"].y


## Versão antiga: sequência de tiros que desenham o W/M.
func _attack_pattern(inverted: bool) -> void:
	var p := _get_player()
	if p == null:
		return

	var center := p.global_position + Vector3.UP * aim_height
	var forward := (center - muzzle.global_position).normalized()
	var right := forward.cross(Vector3.UP)
	if right.length() < 0.01:
		right = Vector3.RIGHT
	right = right.normalized()
	var up := right.cross(forward).normalized()

	var pts: Array[Vector2] = []
	for v in W_POINTS:
		pts.append(Vector2(v.x, -v.y if inverted else v.y))

	for s in _sample_path(pts, pattern_shots):
		if not is_inside_tree() or morto:
			return
		var target := center \
			+ right * s.x * pattern_width * 0.5 \
			+ up * s.y * pattern_height * 0.5
		_fire((target - muzzle.global_position).normalized())
		await get_tree().create_timer(pattern_interval).timeout


## Distribui "count" pontos igualmente espaçados ao longo da polilinha.
func _sample_path(pts: Array[Vector2], count: int) -> Array[Vector2]:
	var lengths: Array[float] = []
	var total := 0.0
	for i in pts.size() - 1:
		var l := pts[i].distance_to(pts[i + 1])
		lengths.append(l)
		total += l

	var out: Array[Vector2] = []
	for k in count:
		var d := total * float(k) / float(maxi(count - 1, 1))
		var acc := 0.0
		for i in lengths.size():
			if d <= acc + lengths[i] or i == lengths.size() - 1:
				var t := (d - acc) / lengths[i]
				out.append(pts[i].lerp(pts[i + 1], clampf(t, 0.0, 1.0)))
				break
			acc += lengths[i]
	return out


## Ponto do caminho em t (0..1), interpolando entre as amostras.
func _path_at(path: Array[Vector2], t: float) -> Vector2:
	var f := t * float(path.size() - 1)
	var i := int(f)
	if i >= path.size() - 1:
		return path[path.size() - 1]
	return path[i].lerp(path[i + 1], f - float(i))


# ---------------------------------------------------------------- Feixe

## Roda um feixe contínuo. A cada quadro, "pose" recebe (t, varrendo) e devolve
## [origem, direção]. Antes de "varrendo" o feixe é fino e não causa dano (aviso).
func _beam_loop(windup: float, duration: float, damage: int, pose: Callable,
		color: Color, thick: float) -> void:
	var beam := _create_beam(color)
	var elapsed := 0.0
	var tick := 0.0
	var total := windup + duration

	while elapsed < total and not morto:
		await get_tree().physics_frame
		if not is_inside_tree():
			return
		var dt := get_physics_process_delta_time()
		elapsed += dt
		tick -= dt

		var sweeping := elapsed > windup
		var t := clampf((elapsed - windup) / duration, 0.0, 1.0)

		var resultado: Array = pose.call(t, sweeping)
		var origin: Vector3 = resultado[0]
		var dir: Vector3 = resultado[1]

		# O feixe termina onde bate (parede, chão ou jogador).
		var hit := _beam_cast(origin, dir)
		var length := beam_range
		if not hit.is_empty():
			length = origin.distance_to(hit["position"])

		_update_beam(beam, origin, dir, length, thick if sweeping else thick * 0.2)

		if sweeping and tick <= 0.0 and not hit.is_empty():
			var alvo: Object = hit["collider"]
			if alvo is Node and (alvo as Node).is_in_group(player_group):
				tick = beam_tick
				_hurt(alvo as Node, damage)

	beam.queue_free()


func _create_beam(color: Color) -> Node3D:
	var pivot := Node3D.new()

	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(beam_thickness, beam_thickness, 1.0)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 4.0
	box.material = mat
	mi.mesh = box
	mi.position = Vector3(0.0, 0.0, -0.5)  # o feixe se estende no -Z do pivô
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pivot.add_child(mi)

	add_child(pivot)
	return pivot


func _update_beam(beam: Node3D, origin: Vector3, dir: Vector3, length: float, thickness: float) -> void:
	var up := Vector3.UP
	if absf(dir.dot(up)) > 0.99:
		up = Vector3.RIGHT
	var b := Basis.looking_at(dir, up) * Basis.from_scale(Vector3(thickness, thickness, length))
	beam.global_transform = Transform3D(b, origin)


func _beam_cast(origin: Vector3, dir: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(origin, origin + dir * beam_range)
	query.exclude = [get_rid()]  # o feixe não bate no próprio chefe
	return get_world_3d().direct_space_state.intersect_ray(query)


# ---------------------------------------------------------------- Utilidades

func _fire(dir: Vector3) -> void:
	if morto:
		return

	var laser: LaserVermelho
	if laser_scene:
		laser = laser_scene.instantiate() as LaserVermelho
		if laser == null:
			push_error("O root de laser_scene precisa ter o script LaserVermelho")
			return
	else:
		laser = LaserVermelho.new()

	get_tree().current_scene.add_child(laser)
	laser.global_position = muzzle.global_position
	laser.configurar(dir, laser_speed, laser_damage, self, laser_size)


func _hurt(target: Node, amount: int) -> void:
	if target.has_method("receber_dano"):
		target.receber_dano(amount)


func _get_player() -> Node3D:
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group(player_group) as Node3D
	return _player


func _make_debug_sphere(raio: float, cor: Color) -> void:
	var mi := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	# Divide pela escala do nó, para a esfera ter o raio real em metros.
	var r := raio / maxf(global_basis.get_scale().x, 0.001)
	sphere.radius = r
	sphere.height = r * 2.0
	var mat := StandardMaterial3D.new()
	mat.albedo_color = cor
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	sphere.material = mat
	mi.mesh = sphere
	add_child(mi)
