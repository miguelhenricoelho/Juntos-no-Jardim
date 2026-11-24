extends Node2D
const FALAS: Array[String] = [
	"Ah, que bom que vocês chegaram! Estava mesmo precisando de uma ajudinha!",
	"Hoje teremos um grande evento com a nossa turma! Preparamos uma surpresa no jardim, mas aconteceu um imprevisto...",
	"Alguns materiais ficaram espalhados e nem tudo está pronto. Precisamos organizar o jardim antes que os colegas cheguem!",
	"Pelo caminho, vocês vão conhecer lugares diferentes, encontrar obstáculos e descobrir o que ainda precisa ser preparado.",
	"Esta missão precisa dos dois! Às vezes, um vai ajudar o outro. Juntos, vocês vão descobrir novas soluções.",
	"Conversem, tenham paciência e trabalhem em equipe. Quando ajudamos uns aos outros, os desafios ficam mais fáceis!",
	"Conto com vocês para deixar nosso jardim lindo e pronto para receber a turma. Boa sorte nessa aventura!"
]
@export var encerramento: bool = false
const FALAS_FINAIS: Array[String] = [
	"Vocês conseguiram! Que alegria ver nosso jardim prontinho para receber a turma!",
	"Eu sabia que podia contar com vocês! Mesmo com tantos obstáculos pelo caminho, vocês não desistiram.",
	"E sabem o que foi mais importante? Vocês aprenderam que ajudar um ao outro faz toda a diferença!",
	"Cada um teve seu papel, mas foi trabalhando juntos que vocês conseguiram completar essa missão.",
	"Muito obrigada, meus queridos! Agora estamos prontos para receber nossos colegas e aproveitar esse dia tão especial!"
]
const ACOES = ["dialogo_avancar", "j1_pular", "j2_pular", "ui_accept"]
var aguardando_soltar: bool = false
@onready var falas: Array[String] = FALAS_FINAIS if encerramento else FALAS
var pagina: int = 0
var concluido: bool = false
@onready var fase: Node2D = get_parent()
@onready var painel: Panel = $Interface/Painel

# Liga o botão da caixa de diálogo à função que troca as falas.
func _ready() -> void:
	$Interface/Painel/Avancar.pressed.connect(_avancar)

func _physics_process(_delta: float) -> void:
	# A conversa só começa quando os dois alunos estão na área.
	if concluido or painel.visible:
		return
	for jogador in fase.jogadores:
		if not $Proximidade.overlaps_body(jogador) or (encerramento and not fase.saida.overlaps_body(jogador)):
			return
	# Bloqueia temporariamente a fase e os movimentos, sem mudar seus scripts.
	fase.set_physics_process(false)
	for jogador in fase.jogadores:
		jogador.velocity = Vector2.ZERO
		jogador.set_physics_process(false)
		jogador.animacao.play("parado")
	aguardando_soltar = _confirmacao_pressionada()
	painel.show()
	_mostrar_fala()
	$Interface/Painel/Avancar.grab_focus()

# Só aceita outra confirmação depois que os botões forem soltos.
static func _confirmacao_pressionada() -> bool:
	for acao in ACOES:
		# A ação pode ainda não existir quando uma tela é testada isoladamente.
		if InputMap.has_action(acao) and Input.is_action_pressed(acao):
			return true
	return Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

func _process(_delta: float) -> void:
	# Libera o próximo clique somente depois de soltar o botão anterior.
	if not _confirmacao_pressionada():
		aguardando_soltar = false

# Permite avançar com teclado, além do botão visível na tela.
func _input(event: InputEvent) -> void:
	if not painel.visible or get_tree().paused:
		return
	for acao in ACOES:
		if event.is_action(acao):
			# Consome antes do botão da interface para não confirmar duas vezes.
			get_viewport().set_input_as_handled()
			if event.is_action_pressed(acao) and not event.is_echo():
				_avancar()
			elif event.is_action_released(acao) and not _confirmacao_pressionada():
				aguardando_soltar = false
			return

func _mostrar_fala() -> void:
	$Interface/Painel/Fala.text = falas[pagina]
	$Interface/Painel/Pagina.text = "%d / %d" % [pagina + 1, falas.size()]
	# Na última página, troca o texto do botão. Nas outras, mostra "Continuar".
	if pagina == falas.size() - 1:
		$Interface/Painel/Avancar.text = "Concluir" if encerramento else "Vamos juntos!"
	else:
		$Interface/Painel/Avancar.text = "Continuar"

# Avança uma fala; ao terminar, devolve o controle ou abre a tela final.
func _avancar() -> void:
	if not painel.visible or get_tree().paused or aguardando_soltar:
		return
	aguardando_soltar = true
	pagina += 1
	if pagina < falas.size():
		_mostrar_fala()
	else:
		# Conclui uma vez por tentativa e devolve o controle à dupla.
		concluido = true
		painel.hide()
		if encerramento:
			# A última fala encerra a contagem antes de abrir a tela final.
			TempoJogo.concluir_fase()
			TempoJogo.finalizar()
			get_tree().change_scene_to_file("res://Cenas/fim.tscn")
			return
		fase.set_physics_process(true)
		for jogador in fase.jogadores:
			jogador.set_physics_process(true)
