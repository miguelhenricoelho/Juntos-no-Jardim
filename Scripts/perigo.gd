extends Node2D
class_name Perigo

# Cada obstáculo usa uma imagem simples. A fase decide quando ele tira uma vida.
const IMAGEM_GALHO = preload("res://Assets/Objetos/obstaculo_galho.svg")
const PASSARO_ASA_CIMA = preload("res://Assets/Objetos/obstaculo_passaro.svg")
const PASSARO_ASA_BAIXO = preload("res://Assets/Objetos/obstaculo_passaro_2.svg")
const IMAGEM_POCA = preload("res://Assets/Objetos/obstaculo_poca.svg")

@export var tipo: String = "galho"
@export var alcance: float = 55.0
@export var caminho: float = 0.0
@export var velocidade: float = 0.0
var inicio: Vector2
var sentido: float = 1.0
var imagem: Sprite2D
var tempo: float = 0.0

# Escolhe a imagem certa quando o obstáculo entra na fase.
func _ready() -> void:
	inicio = position
	imagem = Sprite2D.new()
	if tipo == "galho":
		imagem.texture = IMAGEM_GALHO
		# Galho um pouco menor; o deslocamento mantém a base encostada no chão.
		imagem.scale = Vector2(0.85, 0.85)
		imagem.position.y = 26.0 * (1.0 - 0.85)
	elif tipo == "passaro":
		imagem.texture = PASSARO_ASA_CIMA
		imagem.scale = Vector2(0.72, 0.72)
	else:
		imagem.texture = IMAGEM_POCA
		# Desce só o desenho: o espelho d'água fica no nível da grama e a cova entra na terra.
		# A posição do obstáculo (e a área que tira vida) continua a mesma.
		imagem.position.y = 42.0
	add_child(imagem)

# Somente o pássaro se move, indo e voltando no mesmo trecho.
func _process(delta: float) -> void:
	if tipo != "passaro":
		return
	tempo += delta
	position.x += velocidade * sentido * delta
	# Bate na ponta do caminho e volta, sem teletransportar.
	if position.x > inicio.x + caminho:
		position.x = inicio.x + caminho
		sentido = -1.0
	elif position.x < inicio.x - caminho:
		position.x = inicio.x - caminho
		sentido = 1.0
	# Troca entre dois desenhos para bater as asas e sobe/desce levemente.
	imagem.texture = PASSARO_ASA_CIMA if int(tempo * 7.0) % 2 == 0 else PASSARO_ASA_BAIXO
	position.y = inicio.y + sin(tempo * 5.0) * 5.0
	# A imagem acompanha o sentido do voo.
	imagem.flip_h = sentido < 0.0
