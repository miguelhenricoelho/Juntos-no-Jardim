extends Node2D

# Ponte levadiça do bosque, com uma alavanca de cada lado do riacho.
# Erguida, ela vira uma parede e ninguém atravessa. Enquanto alguém SEGURA a tecla
# de interagir perto de uma alavanca, a ponte desce e o colega passa.
# Quem já atravessou segura a alavanca do outro lado para o colega passar também.
const ALAVANCA_SOLTA = preload("res://Assets/Objetos/alavanca_inativa.png")
const ALAVANCA_PUXADA = preload("res://Assets/Objetos/alavanca_ativa.png")

const ANGULO_ERGUIDA: float = deg_to_rad(-82.0)
const VELOCIDADE_GIRO: float = 3.4
const ALCANCE_X: float = 48.0
const ALCANCE_Y: float = 90.0
# Trecho do riacho, em relação à dobradiça: quem cai na água perde uma vida.
const RIACHO_INICIO: float = 40.0
const RIACHO_FIM: float = 296.0

@onready var fase: Node2D = owner
@onready var tabuleiro: AnimatableBody2D = $Tabuleiro
@onready var alavancas: Array[Sprite2D] = [$AlavancaEsquerda, $AlavancaDireita]
@onready var som: AudioStreamPlayer = $SomPonte
var abaixada: bool = false
var dicas: Array[Label] = []

func _ready() -> void:
	tabuleiro.rotation = ANGULO_ERGUIDA
	for alavanca in alavancas:
		dicas.append(_criar_dica(alavanca))

func _physics_process(delta: float) -> void:
	var segurando := false
	for i in alavancas.size():
		var perto: Array[String] = []
		var puxada := false
		for jogador in fase.jogadores:
			if not jogador.visible or not _perto_da_alavanca(jogador, alavancas[i]):
				continue
			perto.append("E" if jogador.jogador == 1 else "Shift")
			# Só funciona com a fase em andamento (sem diálogo, pausa ou derrota).
			if jogador.is_physics_processing() and Input.is_action_pressed(jogador.interagir):
				puxada = true
		alavancas[i].texture = ALAVANCA_PUXADA if puxada else ALAVANCA_SOLTA
		dicas[i].visible = not perto.is_empty() and not puxada
		dicas[i].text = "Segure " + " / ".join(perto)
		segurando = segurando or puxada
	# Não ergue a ponte com alguém em cima dela.
	var descer := segurando or (abaixada and _alguem_na_ponte())
	if descer and not abaixada:
		som.play()
	abaixada = descer
	var alvo := 0.0 if descer else ANGULO_ERGUIDA
	tabuleiro.rotation = move_toward(tabuleiro.rotation, alvo, VELOCIDADE_GIRO * delta)
	_verificar_agua()

func _perto_da_alavanca(jogador: CharacterBody2D, alavanca: Sprite2D) -> bool:
	var base := alavanca.global_position + Vector2(0, 44)
	return absf(jogador.global_position.x - base.x) < ALCANCE_X and absf(jogador.global_position.y - base.y) < ALCANCE_Y

func _alguem_na_ponte() -> bool:
	for jogador in fase.jogadores:
		var local: Vector2 = jogador.global_position - global_position
		if jogador.visible and local.x > -20.0 and local.x < 336.0 and absf(local.y) < 24.0:
			return true
	return false

# Quem desce no riacho perde uma vida, como nos outros obstáculos.
func _verificar_agua() -> void:
	if fase.perdeu or fase.concluida:
		return
	for jogador in fase.jogadores:
		if not jogador.visible or jogador.vidas <= 0 or not jogador.pode_receber_dano():
			continue
		var local: Vector2 = jogador.global_position - global_position
		if local.x > RIACHO_INICIO and local.x < RIACHO_FIM and local.y > 22.0:
			fase._tirar_vida(jogador)

# Plaquinha pequena acima da alavanca, no mesmo estilo do jogo.
func _criar_dica(alavanca: Sprite2D) -> Label:
	var dica := Label.new()
	dica.size = Vector2(150, 30)
	dica.position = alavanca.position + Vector2(-75, -128)
	dica.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dica.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dica.add_theme_font_override("font", preload("res://Assets/Fontes/DynaPuff.ttf"))
	dica.add_theme_font_size_override("font_size", 16)
	dica.add_theme_color_override("font_color", Color("315b45"))
	var fundo := StyleBoxFlat.new()
	fundo.bg_color = Color(0.98, 0.96, 0.87, 0.95)
	fundo.border_color = Color(0.65, 0.71, 0.53)
	fundo.set_border_width_all(2)
	fundo.set_corner_radius_all(14)
	dica.add_theme_stylebox_override("normal", fundo)
	dica.hide()
	add_child(dica)
	return dica
