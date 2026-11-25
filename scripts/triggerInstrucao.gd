
extends Area3D

enum TipoInstrucao {
	SETOR_CONTENCAO,
	MOVIMENTACAO,
	COMBATE,
	OBJETIVO,
	PARRY,
	CURA,
	OBJETOS_DESTRUTIVEIS
}

@export var tipo_instrucao: TipoInstrucao = TipoInstrucao.MOVIMENTACAO
@export var tempo_exibicao: float = 8.5

var ativado: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return

	if ativado:
		return

	ativado = true
	exibir_instrucao()


func exibir_instrucao() -> void:
	match tipo_instrucao:

		TipoInstrucao.SETOR_CONTENCAO:
			Mensagem.mostrar_mensagem(
				"SETOR DE CONTENÇÃO",
				"ELIMINE TODAS AS AMEAÇAS",
				"Sua nave colidiu com uma estrutura ocupada por aliens e robôs. Elimine todos os inimigos para continuar sua jornada contra Evil.",
				tempo_exibicao
			)

		TipoInstrucao.MOVIMENTACAO:
			Mensagem.mostrar_mensagem(
				"PROTOCOLO DE MOVIMENTAÇÃO",
				"DOMINE SUA MOBILIDADE",
				"Utilize ESPAÇO para pular e SHIFT para executar um dash. Combine os dois movimentos para alcançar locais mais distantes, desviar de ataques e explorar a estrutura.",
				6
			)

		TipoInstrucao.COMBATE:
			Mensagem.mostrar_mensagem(
				"SISTEMA DE COMBATE",
				"NEUTRALIZE OS HOSTIS",
				"Utilize o BOTÃO ESQUERDO DO MOUSE para disparar sua arma. Mire nos inimigos e elimine todas as ameaças que encontrar pelo caminho.",
				6
			)

		TipoInstrucao.PARRY:
			Mensagem.mostrar_mensagem(
				"SISTEMA DE PARRY",
				"REVIDE OS ATAQUES",
				"Utilize o BOTÃO DIREITO DO MOUSE no momento certo para rebater os projéteis inimigos e devolvê-los contra seus atacantes.",
				6
			)

		TipoInstrucao.CURA:
			Mensagem.mostrar_mensagem(
				"SISTEMA DE RECUPERAÇÃO",
				"RECUPERE SUA INTEGRIDADE",
				"Encontre os itens de cura espalhados pela estrutura para recuperar seus pontos de vida. Fique atento: sobreviver é essencial para concluir a missão.",
				6
			)

		TipoInstrucao.OBJETOS_DESTRUTIVEIS:
			Mensagem.mostrar_mensagem(
				"ESTRUTURAS DESTRUTÍVEIS",
				"IDENTIFIQUE OBJETOS FRÁGEIS",
				"Algumas estruturas e objetos podem ser destruídos com disparos. Atire utilizando o BOTÃO ESQUERDO DO MOUSE para revelar possíveis caminhos e interagir com o ambiente.",
				6
			)

		TipoInstrucao.OBJETIVO:
			Mensagem.mostrar_mensagem(
				"OBJETIVO ATUALIZADO",
				"AVANCE PELA ESTRUTURA",
				"Continue explorando a instalação. Elimine as ameaças que encontrar pelo caminho.",
				tempo_exibicao
			)
