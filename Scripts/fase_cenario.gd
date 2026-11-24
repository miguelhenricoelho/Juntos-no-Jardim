extends Node2D
const Perigo = preload("res://Scripts/perigo.gd")
const TelaGameOver = preload("res://Cenas/game_over.tscn")
# Regras das três fases: tarefas da dupla, câmera e troca de cena.
@export var indice: int = 1
@export_file("*.tscn") var proxima_fase: String = ""
const DISTANCIA_MAXIMA: float = 880.0
const LIMITES_DAS_FASES: Array[float] = [0.0, 40.0, 45.0, 50.0]
var concluida: bool = false
# Estes valores marcam o que a dupla já fez na fase atual.
var flores: int = 0
var regador: bool = false
var plantados: int = 0
var regados: int = 0
var perdeu: bool = false
var tempo_restante: float = 0.0
var pontos_iniciais: Array[Vector2] = []
var perigos: Array[Perigo] = []
@onready var jogadores: Array[CharacterBody2D] = [$Personagens/Jogador1, $Personagens/Jogador2]
@onready var camera: Camera2D = $Camera
@onready var saida: Area2D = $AreaDeSaida
@onready var fade: ColorRect = $Interface/Fade
@onready var interface: CanvasLayer = $Interface
var texto_vidas: Label
var texto_tempo: Label
# Quem ficou sem vidas espera aqui até o colega doar uma vida.
var caido: CharacterBody2D = null
var aviso_vida: Label
var tela_game_over: Control

# Prepara a câmera, liga os botões e clareia a tela.
func _ready() -> void:
	# Mantém o som ligado também depois de trocar de fase.
	AudioServer.set_bus_mute(0, false)
	AudioServer.set_bus_volume_db(0, 0.0)
	# Cada fase busca seu próprio limite: 40, 45 ou 50 segundos.
	tempo_restante = LIMITES_DAS_FASES[indice]
	# Depois de um Game Over, o cronômetro volta ao valor do início desta fase.
	TempoJogo.entrar_na_fase(scene_file_path)
	_process(0.0)
	camera.reset_smoothing()
	camera.force_update_scroll()
	$Interface/Conclusao/Recomecar.pressed.connect(_recomecar)
	if indice == 3:
		$Interface/Conclusao/VoltarMenu.pressed.connect(_voltar_menu)
	create_tween().tween_property(fade, "color:a", 0.0, 0.35)
	for jogador in jogadores:
		pontos_iniciais.append(jogador.global_position)
	_criar_interface_vidas()
	_criar_interface_tempo()
	_criar_aviso_vida()
	_criar_perigos()

func _process(delta: float) -> void:
	# A câmera acompanha o meio da dupla e respeita as bordas do mapa.
	var centro: float = (jogadores[0].position.x + jogadores[1].position.x) / 2.0
	# Enquanto um colega está caído, a câmera acompanha somente quem continua em jogo.
	if caido:
		centro = _outro(caido).position.x
	camera.position.x = clampf(centro, 640.0, camera.limit_right - 640.0)
	_atualizar_interface_vidas()
	_atualizar_interface_tempo()
	_atualizar_limite_da_fase(delta)

# Cada fase tem seu próprio limite de tempo.
# A contagem para durante diálogos e pausa, mas o tempo total não é zerado.
func _atualizar_limite_da_fase(delta: float) -> void:
	if concluida or perdeu or not is_physics_processing():
		return
	tempo_restante -= delta
	if tempo_restante <= 0.0:
		tempo_restante = 0.0
		_mostrar_derrota_por_tempo()

# A cada passo da física, verifica as tarefas, a distância entre colegas e a saída.
func _physics_process(_delta: float) -> void:
	if concluida or perdeu:
		return
	var ana: CharacterBody2D = jogadores[0]
	var joao: CharacterBody2D = jogadores[1]
	if indice == 1:
		_coletar(ana, joao)
	elif indice == 2:
		_plantar(ana, joao)
	_verificar_perigos()
	_compartilhar_vida(ana, joao)
	if caido:
		_doar_vida_ao_caido()
		return
	var separados: bool = absf(ana.position.x - joao.position.x) > DISTANCIA_MAXIMA
	# Só interrompe quem se afasta; o colega parado não é arrastado.
	if separados:
		# Descobre qual jogador está de cada lado.
		var esquerda: CharacterBody2D = ana if ana.position.x < joao.position.x else joao
		var direita: CharacterBody2D = joao if esquerda == ana else ana
		if direita.velocity.x > 0.0:
			direita.position.x = esquerda.position.x + DISTANCIA_MAXIMA
			direita.velocity.x = 0.0
		if esquerda.velocity.x < 0.0:
			esquerda.position.x = direita.position.x - DISTANCIA_MAXIMA
			esquerda.velocity.x = 0.0
	# A fase termina somente quando a tarefa acabou e os dois estão na saída.
	# call_deferred deixa a troca de fase para depois desta atualização da física.
	if saida.overlaps_body(ana) and saida.overlaps_body(joao) and _tarefa_pronta():
		_terminar.call_deferred()

# Monta os desafios de cada fase. Os desenhos ficam no script Perigo, para não lotar as cenas.
func _criar_perigos() -> void:
	if indice == 1:
		# O chão tem três alturas diferentes; cada galho encosta no seu trecho.
		_adicionar_perigo("galho", Vector2(950, 518))
		_adicionar_perigo("galho", Vector2(2200, 550))
		_adicionar_perigo("galho", Vector2(3100, 582))
	elif indice == 2:
		# A altura acompanha o terreno para o pássaro passar na altura dos jogadores.
		_adicionar_perigo("passaro", Vector2(1250, 475), 210.0, 150.0)
		_adicionar_perigo("passaro", Vector2(2700, 475), 230.0, 165.0)
		_adicionar_perigo("passaro", Vector2(3700, 540), 190.0, 155.0)
		# Este voa mais alto, sobre o chão baixo entre os dois primeiros: acerta quem pula.
		_adicionar_perigo("passaro", Vector2(2080, 410), 170.0, 140.0)
	elif indice == 3:
		# Cada poça acompanha a altura exata do trecho onde foi colocada.
		# A primeira fica fora da plataforma para realmente exigir um pulo.
		_adicionar_perigo("poca", Vector2(1250, 552))
		_adicionar_perigo("poca", Vector2(2430, 552))
		_adicionar_perigo("poca", Vector2(3550, 552))

# Cria um obstáculo, define sua posição e o coloca no cenário.
func _adicionar_perigo(tipo: String, local: Vector2, caminho := 0.0, velocidade := 0.0) -> void:
	var perigo := Perigo.new()
	perigo.tipo = tipo
	perigo.position = local
	perigo.caminho = caminho
	perigo.velocidade = velocidade
	# Fica na frente do chão, mas atrás dos personagens.
	perigo.z_as_relative = false
	perigo.z_index = 5
	$ObjetosCenario.add_child(perigo)
	perigos.append(perigo)

# Galhos e poças são pulados. O pássaro só acerta quem estiver na altura do voo.
func _verificar_perigos() -> void:
	for jogador in jogadores:
		if jogador.vidas <= 0 or not jogador.pode_receber_dano():
			continue
		for perigo in perigos:
			var perto_x := absf(jogador.global_position.x - perigo.global_position.x) < perigo.alcance
			var perto_y: bool
			if perigo.tipo == "passaro":
				# O ponto do personagem fica nos pés; o corpo ocupa 86 pixels para cima.
				# Assim, quem está na plataforma passa acima da faixa do pássaro.
				var topo_jogador := jogador.global_position.y - 86.0
				var centro_passaro := perigo.global_position.y + 8.0
				perto_y = jogador.global_position.y > centro_passaro - 18.0 and topo_jogador < centro_passaro + 18.0
			else:
				# Galhos e poças só atingem quem estiver perto do chão.
				perto_y = jogador.global_position.y > perigo.global_position.y - 45.0
			if perto_x and perto_y:
				_tirar_vida(jogador)
				break

# Um aperta E e o outro Shift. Quem tem duas vidas pode entregar uma ao colega que tem uma.
func _compartilhar_vida(ana: CharacterBody2D, joao: CharacterBody2D) -> void:
	if ana.global_position.distance_to(joao.global_position) > 100.0:
		return
	if Input.is_action_just_pressed(ana.interagir) and ana.vidas == 2 and joao.vidas == 1:
		ana.vidas -= 1
		joao.vidas += 1
	elif Input.is_action_just_pressed(joao.interagir) and joao.vidas == 2 and ana.vidas == 1:
		joao.vidas -= 1
		ana.vidas += 1

# Tira uma vida e devolve o personagem ao início; com zero, mostra a derrota.
func _tirar_vida(jogador: CharacterBody2D) -> void:
	if not jogador.perder_vida():
		return
	var numero := jogadores.find(jogador)
	# Com zero vidas, o colega pode doar uma vida se ainda tiver pelo menos duas.
	if jogador.vidas <= 0:
		if caido == null and _outro(jogador).vidas >= 2:
			_deixar_caido(jogador)
		else:
			_mostrar_derrota(numero)
		return
	jogador.global_position = pontos_iniciais[numero]
	jogador.velocity = Vector2.ZERO
	# Se quem sobrou ficou com só uma vida, não há como ajudar o colega caído.
	if caido and jogador.vidas < 2:
		_mostrar_derrota(jogadores.find(caido))

func _outro(jogador: CharacterBody2D) -> CharacterBody2D:
	return jogadores[1] if jogador == jogadores[0] else jogadores[0]

# Tira o personagem sem vidas de cena e mostra ao colega como ajudar.
func _deixar_caido(jogador: CharacterBody2D) -> void:
	caido = jogador
	jogador.velocity = Vector2.ZERO
	jogador.set_physics_process(false)
	jogador.hide()
	# Fica longe do cenário para não coletar, plantar nem chegar à saída.
	jogador.global_position = Vector2(-10000.0, -10000.0)
	var nome := "Ana" if jogador == jogadores[0] else "João"
	var ajudante := "João" if jogador == jogadores[0] else "Ana"
	var tecla := "Shift" if jogador == jogadores[0] else "E"
	aviso_vida.text = "%s ficou sem vidas!  %s, aperte %s para dar 1 vida." % [nome, ajudante, tecla]
	aviso_vida.show()

# Quem continua em jogo aperta sua tecla de interagir: perde 1 vida e o colega volta com 1.
func _doar_vida_ao_caido() -> void:
	var ajudante := _outro(caido)
	if ajudante.vidas < 2 or not Input.is_action_just_pressed(ajudante.interagir):
		return
	ajudante.vidas -= 1
	caido.vidas += 1
	# Volta ao lado do colega, com o mesmo tempo curto de proteção usado após um dano.
	caido.global_position = ajudante.global_position
	caido.velocity = Vector2.ZERO
	caido.protegido_ate = Time.get_ticks_msec() + 1200
	caido.show()
	caido.set_physics_process(true)
	caido = null
	aviso_vida.hide()

# Aviso no alto da tela, usado somente enquanto alguém está caído.
func _criar_aviso_vida() -> void:
	aviso_vida = Label.new()
	aviso_vida.position = Vector2(240, 70)
	aviso_vida.size = Vector2(800, 44)
	aviso_vida.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aviso_vida.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	aviso_vida.add_theme_font_size_override("font_size", 21)
	aviso_vida.add_theme_color_override("font_color", Color("315b45"))
	var fundo := StyleBoxFlat.new()
	fundo.bg_color = Color(0.98, 0.96, 0.87, 0.94)
	fundo.border_color = Color(0.65, 0.71, 0.53)
	fundo.set_border_width_all(2)
	fundo.set_corner_radius_all(18)
	aviso_vida.add_theme_stylebox_override("normal", fundo)
	aviso_vida.hide()
	interface.add_child(aviso_vida)

# Esta pequena interface mostra somente as vidas da dupla.
func _criar_interface_vidas() -> void:
	texto_vidas = Label.new()
	texto_vidas.position = Vector2(28, 24)
	texto_vidas.add_theme_font_size_override("font_size", 25)
	texto_vidas.add_theme_color_override("font_color", Color("315b45"))
	interface.add_child(texto_vidas)

func _atualizar_interface_vidas() -> void:
	# Lê as vidas atuais e atualiza somente o texto da tela.
	if texto_vidas:
		texto_vidas.text = "Ana: %d ♥    João: %d ♥" % [jogadores[0].vidas, jogadores[1].vidas]

# O cronômetro aparece no canto direito e usa o mesmo valor nas três fases.
func _criar_interface_tempo() -> void:
	texto_tempo = Label.new()
	texto_tempo.position = Vector2(1080, 24)
	texto_tempo.size = Vector2(170, 40)
	texto_tempo.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	texto_tempo.add_theme_font_size_override("font_size", 25)
	texto_tempo.add_theme_color_override("font_color", Color("315b45"))
	interface.add_child(texto_tempo)

func _atualizar_interface_tempo() -> void:
	# O valor vem do TempoJogo, que não é apagado ao trocar de fase.
	if texto_tempo:
		texto_tempo.text = "Tempo  " + TempoJogo.formatar()

# Monta a mensagem quando Ana ou João fica sem vidas.
func _mostrar_derrota(numero: int) -> void:
	var nome := "Ana" if numero == 0 else "João"
	_abrir_tela_de_derrota(nome + " ficou sem vidas.\nA dupla perdeu esta tentativa.")

# O limite da fase usa a mesma tela, mas informa que o tempo acabou.
func _mostrar_derrota_por_tempo() -> void:
	_abrir_tela_de_derrota("O tempo da fase acabou.\nA dupla precisa tentar novamente.")

# Para os personagens e reutiliza o mesmo painel para qualquer tipo de derrota.
func _abrir_tela_de_derrota(mensagem: String) -> void:
	if perdeu:
		return
	perdeu = true
	# Para o cronômetro; a próxima tentativa começa do tempo inicial desta fase.
	TempoJogo.registrar_derrota()
	for jogador in jogadores:
		jogador.set_physics_process(false)
	if aviso_vida:
		aviso_vida.hide()
	tela_game_over = TelaGameOver.instantiate()
	interface.add_child(tela_game_over)
	tela_game_over.recomecar.connect(_recomecar)
	tela_game_over.voltar_menu.connect(_voltar_menu)
	# Na última fase o painel antigo também oferecia voltar ao menu.
	tela_game_over.abrir(mensagem, indice == 3)

# Só Ana (J1) pega as três flores. João (J2) pega o regador.
func _coletar(ana: CharacterBody2D, joao: CharacterBody2D) -> void:
	for flor in $Itens/Flores.get_children():
		# Quando Ana chega perto, a flor some e entra na contagem.
		if flor.visible and ana.global_position.distance_to(flor.global_position) < 70.0:
			flor.hide()
			flores += 1
			$SomColeta.play()
	var objeto = $Itens/Regador
	if not regador and joao.global_position.distance_to(objeto.global_position) < 70.0:
		regador = true
		objeto.hide()
		$SomColeta.play()

# Na estufa, Ana planta e João rega cada um dos quatro vasos.
func _plantar(ana: CharacterBody2D, joao: CharacterBody2D) -> void:
	for canteiro in $Itens.get_children():
		# Ana planta; o desenho troca de terra vazia para muda.
		if canteiro.get_node("Vazio").visible and ana.global_position.distance_to(canteiro.global_position) < 85.0:
			canteiro.get_node("Vazio").hide()
			canteiro.get_node("Mudas").show()
			plantados += 1
			$SomPlantar.play()
		# João rega a muda; o desenho troca para flores crescidas.
		if canteiro.get_node("Mudas").visible and joao.global_position.distance_to(canteiro.global_position) < 85.0:
			canteiro.get_node("Mudas").hide()
			canteiro.get_node("Flores").show()
			regados += 1
			$SomRegar.play()

# A saída só funciona depois da tarefa da fase e com os dois jogadores nela.
# Na fase 1 são três flores e o regador; na fase 2 são quatro plantios e quatro regas.
func _tarefa_pronta() -> bool:
	if indice == 1:
		return flores == 3 and regador
	if indice == 2:
		return plantados == 4 and regados == 4
	return true

# Para os movimentos, mostra a conclusão ou escurece a tela e abre a próxima fase.
func _terminar() -> void:
	# No bosque, a conversa com a professora conduz ao encerramento.
	if concluida or indice == 3:
		return
	concluida = true
	# Registra o tempo desta fase para a soma da tela final.
	TempoJogo.concluir_fase()
	for jogador in jogadores:
		jogador.set_physics_process(false)
	if proxima_fase.is_empty():
		$Interface/Conclusao.show()
		$Interface/Conclusao/Recomecar.grab_focus()
		return
	# Escurece a tela antes de trocar de fase.
	await create_tween().tween_property(fade, "color:a", 1.0, 0.3).finished
	if get_tree().change_scene_to_file(proxima_fase) != OK:
		push_error("Não foi possível abrir: " + proxima_fase)
		concluida = false
		fade.color.a = 0.0
		for jogador in jogadores:
			jogador.set_physics_process(true)

# A tecla R reinicia a fase atual.
func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_R:
		get_tree().reload_current_scene()

# Depois de uma derrota, reinicia somente a fase atual.
# O TempoJogo é global, portanto não volta para zero.
func _recomecar() -> void:
	get_tree().reload_current_scene()

# O outro botão da tela final abre o menu principal.
func _voltar_menu() -> void:
	get_tree().change_scene_to_file("res://Cenas/menu.tscn")
