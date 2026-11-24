extends CharacterBody2D
class_name Personagem

# CharacterBody2D é o tipo de nó que se move e colide com o cenário.
# Este é o molde dos seis personagens: o movimento é igual; cada cena escolhe seus desenhos.
# @export deixa os valores ajustáveis no Inspetor. J1/J2 escolhe as teclas.
# A força do pulo é negativa porque subir diminui o Y na tela.
# Aumentamos o impulso para o salto alcançar plataformas mais altas.
@export_range(1, 2, 1) var jogador: int = 1
@export var velocidade: float = 260.0
@export var forca_pulo: float = -640.0
@export var gravidade: float = 1350.0
@export var vidas: int = 2

# @onready procura os nós filhos quando a cena já está pronta.
@onready var animacao: AnimatedSprite2D = $Animacao
@onready var som_pulo: AudioStreamPlayer = $SomPulo
@onready var som_pouso: AudioStreamPlayer = $SomPouso

# Estas variáveis guardam os nomes das ações de controle, não as teclas.
# StringName é o tipo usado pelo Godot para identificar essas ações.
var esquerda: StringName
var direita: StringName
var pular: StringName
var interagir: StringName
# Tempo curto sem dano evita perder as duas vidas no mesmo toque.
var protegido_ate: int = 0

# _ready roda uma vez quando o personagem entra na cena.
# A função separa as ações de J1 e J2 e cadastra as teclas de cada um.
func _ready() -> void:
	# Nomes diferentes impedem que uma tecla mova os dois jogadores.
	if jogador == 1:
		esquerda = &"j1_esquerda"
		direita = &"j1_direita"
		pular = &"j1_pular"
		interagir = &"j1_interagir"
		registrar_tecla(esquerda, KEY_A)
		registrar_tecla(direita, KEY_D)
		registrar_tecla(pular, KEY_W)
		registrar_tecla(pular, KEY_SPACE)
		registrar_tecla(interagir, KEY_E)
	else:
		esquerda = &"j2_esquerda"
		direita = &"j2_direita"
		pular = &"j2_pular"
		interagir = &"j2_interagir"
		registrar_tecla(esquerda, KEY_LEFT)
		registrar_tecla(direita, KEY_RIGHT)
		registrar_tecla(pular, KEY_UP)
		registrar_tecla(interagir, KEY_SHIFT)

# InputMap é a lista de controles do Godot: liga "j1_pular", por exemplo, à tecla W.
# Cria a ação se faltar, monta o evento da tecla e evita cadastrá-la duas vezes.
# physical_keycode considera a posição da tecla no teclado.
func registrar_tecla(nome: StringName, tecla: Key) -> void:
	if not InputMap.has_action(nome):
		InputMap.add_action(nome)
	var evento := InputEventKey.new()
	evento.physical_keycode = tecla
	if not InputMap.action_has_event(nome, evento):
		InputMap.action_add_event(nome, evento)

# _physics_process roda a cada atualização da física; delta é o tempo entre elas.
# Primeiro calcula o movimento, depois a colisão, e por fim escolhe a animação.
func _physics_process(delta: float) -> void:
	# Guarda se estava no chão para detectar um pouso após o movimento.
	var estava_no_chao := is_on_floor()

	# A gravidade aumenta a velocidade para baixo quando está no ar.
	# O pulo só começa no chão; soltar cedo deixa 70% do impulso e faz um salto menor.
	if not estava_no_chao:
		velocity.y += gravidade * delta
	if estava_no_chao and Input.is_action_just_pressed(pular):
		velocity.y = forca_pulo
		som_pulo.play()
	if Input.is_action_just_released(pular) and velocity.y < 0.0:
		velocity.y *= 0.70

	# get_axis lê as duas ações: -1 para esquerda, 1 para direita, 0 sem tecla.
	# move_toward aproxima a velocidade do valor desejado, suavizando o movimento.
	var direcao := Input.get_axis(esquerda, direita)
	if direcao != 0.0:
		velocity.x = move_toward(velocity.x, direcao * velocidade, 1700.0 * delta)
		animacao.flip_h = direcao < 0.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, 1900.0 * delta)

	# Aplica a velocidade e respeita chão e paredes; depois detecta o pouso.
	move_and_slide()
	if not estava_no_chao and is_on_floor():
		som_pouso.play()

	# A velocidade vertical escolhe as três poses do pulo: subida, topo e descida.
	# No chão, a velocidade horizontal escolhe entre andar e ficar parado.
	if not is_on_floor():
		if animacao.animation != &"pular":
			animacao.stop()
			animacao.animation = &"pular"
		if velocity.y < -180.0:
			animacao.frame = 0
		elif velocity.y < 180.0:
			animacao.frame = 1
		else:
			animacao.frame = 2
	elif absf(velocity.x) > 15.0:
		# A animação de andar acompanha a velocidade, com limite de 0,5 a 1.
		animacao.speed_scale = clampf(absf(velocity.x) / velocidade, 0.5, 1.0)
		animacao.play("andar")
	else:
		animacao.speed_scale = 1.0
		animacao.play("parado")

	# Retorno provisório para quem cair da cena; cada jogador volta a um X diferente.
	if global_position.y > 820.0:
		global_position = Vector2(260.0 if jogador == 1 else 380.0, 592.0)
		velocity = Vector2.ZERO

# A fase chama esta função quando um galho, pássaro ou poça encosta no jogador.
# Retorna true quando a vida realmente foi perdida.
func perder_vida() -> bool:
	if Time.get_ticks_msec() < protegido_ate:
		return false
	vidas -= 1
	protegido_ate = Time.get_ticks_msec() + 1200
	return true

# Informa se já passou o curto tempo de proteção depois de um dano.
func pode_receber_dano() -> bool:
	return Time.get_ticks_msec() >= protegido_ate
