extends Control

# Prepara o som, liga os botões e seleciona "Jogar".
func _ready() -> void:
	# Se a dupla voltou ao menu, a partida anterior foi cancelada.
	TempoJogo.cancelar()
	AudioServer.set_bus_mute(0, false)
	AudioServer.set_bus_volume_db(0, 0.0)
	$Jogar.pressed.connect(_jogar)
	$ComoJogar.pressed.connect(_ajuda.bind(true))
	$Ajuda/Painel/Voltar.pressed.connect(_ajuda.bind(false))
	$Sair.pressed.connect(get_tree().quit)
	$Jogar.grab_focus()

# Inicia o cronômetro total e abre a primeira fase.
func _jogar() -> void:
	# Jogar inicia a missão diretamente. As instruções ficam em "Como jogar".
	TempoJogo.iniciar()
	get_tree().change_scene_to_file("res://Cenas/Cenarios/01_galeria.tscn")

# A ajuda apenas mostra os comandos; não cria outra cena.
func _ajuda(abrir: bool) -> void:
	$Ajuda.visible = abrir
	for botao in [$Jogar, $ComoJogar, $Sair]:
		botao.disabled = abrir
	if abrir:
		$Ajuda/Painel/Voltar.grab_focus()
	else:
		$ComoJogar.grab_focus()

# Esc fecha a tela de instruções quando ela estiver aberta.
func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and $Ajuda.visible:
		_ajuda(false)
		get_viewport().set_input_as_handled()
