extends Control
const Dialogo = preload("res://Scripts/dialogo_professora.gd")
const NOMES_FASES: Array[String] = ["Galeria", "Estufa", "Bosque"]
const CORES_PETALAS: Array[Color] = [Color("e79aa0"), Color("b7a3d6"), Color("f2cf6b"), Color("f6efdc"), Color("a6b97d")]

const PASSARO_ASA_CIMA = preload("res://Assets/Objetos/obstaculo_passaro.svg")
const PASSARO_ASA_BAIXO = preload("res://Assets/Objetos/obstaculo_passaro_2.svg")
# Pássaros do jogo sobrevoando o jardim: posição inicial, velocidade (negativa = para a esquerda) e escala.
const BANDO: Array = [
	[Vector2(230, 48), 62.0, 0.56],
	[Vector2(780, 70), 48.0, 0.46],
	[Vector2(1150, 168), -55.0, 0.6],
	[Vector2(150, 236), -70.0, 0.5],
	[Vector2(1050, 300), 58.0, 0.44],
]
# Colegas da turma e a professora, parados em pé em volta do cartão.
# Nome, posição dos pés, escala e se olha para a esquerda (todos viram para o centro).
const TURMA: Array = [
	["lucas", Vector2(62, 690), 0.74, false],
	["professora", Vector2(176, 702), 1.15, false],
	["julia", Vector2(292, 692), 0.74, false],
	["sofia", Vector2(1040, 692), 0.74, true],
	["pedro", Vector2(1190, 690), 0.74, true],
]

var petalas: Array[Dictionary] = []
var passaros: Array[Dictionary] = []
var relogio: float = 0.0

# Mostra o tempo total (soma das fases) e conecta os dois botões da tela.
func _ready() -> void:
	get_tree().paused = false
	_mostrar_tempo()
	$Painel/Voltar.pressed.connect(_voltar)
	$Painel/JogarNovamente.pressed.connect(_jogar_novamente)
	$Painel/Voltar.disabled = true
	$Painel/JogarNovamente.disabled = true
	_criar_passaros()
	_criar_turma()
	_criar_petalas()
	_animar_entrada()
	$SomVitoria.play()

# Soma o tempo de todas as fases e mostra quanto cada uma levou.
func _mostrar_tempo() -> void:
	var tempos: Array[float] = TempoJogo.tempos_fases
	# Cada fase é arredondada para segundos inteiros, e o total é a soma exata delas.
	var total := 0.0
	for i in tempos.size():
		var segundos_fase := roundf(tempos[i])
		total += segundos_fase
		var nome := NOMES_FASES[i] if i < NOMES_FASES.size() else "Fase %d" % (i + 1)
		$Painel/CaixaTempo/Fases.add_child(_criar_etiqueta(nome, TempoJogo.formatar(segundos_fase)))
	if tempos.is_empty():
		total = TempoJogo.segundos
	$Painel/CaixaTempo/Tempo.text = TempoJogo.formatar(total)

# Etiqueta pequena com o nome da fase e o tempo dela.
func _criar_etiqueta(nome: String, tempo: String) -> PanelContainer:
	var caixa := PanelContainer.new()
	caixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fundo := StyleBoxFlat.new()
	fundo.bg_color = Color(0.98, 0.96, 0.886)
	fundo.border_color = Color(0.82, 0.84, 0.68)
	fundo.set_border_width_all(2)
	fundo.set_corner_radius_all(14)
	fundo.content_margin_left = 12
	fundo.content_margin_right = 12
	fundo.content_margin_top = 4
	fundo.content_margin_bottom = 5
	caixa.add_theme_stylebox_override("panel", fundo)
	var texto := Label.new()
	texto.text = "%s  %s" % [nome, tempo]
	texto.add_theme_font_override("font", preload("res://Assets/Fontes/Nunito-Interface.tres"))
	texto.add_theme_font_size_override("font_size", 16)
	texto.add_theme_color_override("font_color", Color(0.3, 0.42, 0.35))
	caixa.add_child(texto)
	return caixa

# O cartão sobe de leve e o selo aparece com um pequeno salto.
func _animar_entrada() -> void:
	var painel: Panel = $Painel
	var selo: TextureRect = $Painel/Selo
	var destino := painel.position
	painel.position.y += 24.0
	painel.modulate.a = 0.0
	selo.pivot_offset = selo.size / 2.0
	selo.scale = Vector2(0.6, 0.6)
	var entrada := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	entrada.tween_property(painel, "position", destino, 0.5)
	entrada.tween_property(painel, "modulate:a", 1.0, 0.4)
	entrada.tween_property(selo, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_BACK).set_delay(0.2)

# Os mesmos pássaros das fases, batendo as asas e cruzando o céu.
func _criar_passaros() -> void:
	for i in BANDO.size():
		var dados: Array = BANDO[i]
		var passaro := Sprite2D.new()
		passaro.texture = PASSARO_ASA_CIMA
		passaro.scale = Vector2.ONE * dados[2]
		# No jogo o desenho olha para a direita; vira quando voa para a esquerda.
		passaro.flip_h = dados[1] < 0.0
		passaro.position = dados[0]
		$Passaros.add_child(passaro)
		passaros.append({"no": passaro, "altura": dados[0].y, "velocidade": dados[1], "fase": i * 1.7})

func _animar_passaros(delta: float) -> void:
	relogio += delta
	# Os raios do sol giram bem devagar.
	$Sol/Raios.rotation += 0.08 * delta
	for p in passaros:
		var no: Sprite2D = p.no
		var t: float = relogio + p.fase
		no.position.x += p.velocidade * delta
		no.position.y = p.altura + sin(t * 2.2) * 8.0
		no.texture = PASSARO_ASA_CIMA if int(t * 7.0) % 2 == 0 else PASSARO_ASA_BAIXO
		# Saiu de um lado, volta pelo outro.
		if p.velocidade > 0.0 and no.position.x > 1340.0:
			no.position.x = -60.0
		elif p.velocidade < 0.0 and no.position.x < -60.0:
			no.position.x = 1340.0

# Coloca a turma em volta do cartão, usando os desenhos dos personagens do jogo.
# A professora é a mesma imagem usada no diálogo das fases.
func _criar_turma() -> void:
	for dados in TURMA:
		var nome: String = dados[0]
		var sprite := Sprite2D.new()
		if nome == "professora":
			var recorte := AtlasTexture.new()
			recorte.atlas = load("res://Assets/Personagens/professora/professora_spritesheet.png")
			recorte.region = Rect2(112, 24, 112, 224)
			sprite.texture = recorte
			sprite.offset = Vector2(0, -106)
		else:
			sprite.texture = load("res://Assets/Personagens/%s/parado_01.png" % nome)
			sprite.offset = Vector2(0, -116)
		sprite.position = dados[1]
		sprite.scale = Vector2.ONE * dados[2]
		sprite.flip_h = dados[3]
		$Turma.add_child(sprite)

# Pétalas caindo devagar pelo jardim, atrás do cartão.
func _criar_petalas() -> void:
	for i in 26:
		var petala := Polygon2D.new()
		var pontos := PackedVector2Array()
		for k in 10:
			var a := TAU * k / 10.0
			pontos.append(Vector2(cos(a) * 7.0, sin(a) * 4.0))
		petala.polygon = pontos
		petala.color = CORES_PETALAS[i % CORES_PETALAS.size()]
		petala.position = Vector2(randf_range(0, 1280), randf_range(-720, 720))
		$Petalas.add_child(petala)
		petalas.append({
			"no": petala,
			"queda": randf_range(28.0, 60.0),
			"balanco": randf_range(14.0, 34.0),
			"fase": randf_range(0.0, TAU),
			"giro": randf_range(-1.6, 1.6),
		})

func _process(delta: float) -> void:
	_animar_passaros(delta)
	for p in petalas:
		var no: Polygon2D = p.no
		p.fase += delta * 1.4
		no.position.y += p.queda * delta
		no.position.x += cos(p.fase) * p.balanco * delta
		no.rotation += p.giro * delta
		if no.position.y > 740.0:
			no.position = Vector2(randf_range(0, 1280), -20.0)
	# A última confirmação do diálogo não deve acionar o menu também.
	if $Painel/JogarNovamente.disabled and not Dialogo._confirmacao_pressionada():
		$Painel/Voltar.disabled = false
		$Painel/JogarNovamente.disabled = false
		$Painel/JogarNovamente.grab_focus()

# Volta ao menu principal; o próprio menu cancela a partida antiga.
func _voltar() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Cenas/menu.tscn")

# Zera o cronômetro e começa uma partida nova pela fase 1.
func _jogar_novamente() -> void:
	TempoJogo.iniciar()
	get_tree().change_scene_to_file("res://Cenas/Cenarios/01_galeria.tscn")
