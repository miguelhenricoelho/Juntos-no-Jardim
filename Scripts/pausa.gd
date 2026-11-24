extends CanvasLayer

# Liga os três botões do menu de pausa.
func _ready() -> void:
	$Tela/Painel/Continuar.pressed.connect(_pausar.bind(false))
	$Tela/Painel/Reiniciar.pressed.connect(_reiniciar)
	$Tela/Painel/Menu.pressed.connect(_menu)

# Esc abre ou fecha a pausa, desde que a fase ainda esteja acontecendo.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo() and not get_parent().concluida:
		_pausar(not get_tree().paused)
		get_viewport().set_input_as_handled()

# Só esta interface continua processando enquanto a árvore está pausada.
func _pausar(abrir: bool) -> void:
	get_tree().paused = abrir
	$Tela.visible = abrir
	if abrir:
		$Tela/Painel/Continuar.grab_focus()
	else:
		$Tela/Painel/Continuar.release_focus()

# Recarrega apenas a fase atual; o cronômetro total continua.
func _reiniciar() -> void:
	_pausar(false)
	get_tree().reload_current_scene()

# Fecha a pausa e volta para o menu principal.
func _menu() -> void:
	_pausar(false)
	get_tree().change_scene_to_file("res://Cenas/menu.tscn")
