extends Label
## Mostra os FPS no HUD quando a opção "Exibir FPS" está ligada nas configurações.
## Anexe este script ao nó Label "FPS" do HUD do jogador.

const ARQUIVO_CONFIG := "user://g00d_config.cfg"

@export var cor_fps := Color("#ff8a00")  # laranja


func _ready() -> void:
	# Permite que a tela de configurações ligue/desligue o FPS ao vivo
	add_to_group("fps_label")

	# Texto laranja com contorno escuro, para ler bem sobre qualquer fundo
	add_theme_color_override("font_color", cor_fps)
	add_theme_color_override("font_outline_color", Color.BLACK)
	add_theme_constant_override("outline_size", 4)

	var config := ConfigFile.new()
	var ativo := false

	if config.load(ARQUIVO_CONFIG) == OK:
		ativo = bool(config.get_value("video", "mostrar_fps", false))

	definir_visivel(ativo)


func definir_visivel(valor: bool) -> void:
	visible = valor
	set_process(valor)


func _process(_delta: float) -> void:
	text = "FPS: %d" % Engine.get_frames_per_second()
