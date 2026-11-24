extends Control

# Tela de derrota da fase. A fase decide a mensagem e o que cada botão faz.
signal recomecar
signal voltar_menu

@onready var cartao: Panel = $Cartao
@onready var mensagem: Label = $Cartao/Mensagem
@onready var botao_recomecar: Button = $Cartao/Recomecar
@onready var botao_menu: Button = $Cartao/Menu

func _ready() -> void:
	botao_recomecar.pressed.connect(func() -> void: recomecar.emit())
	botao_menu.pressed.connect(func() -> void: voltar_menu.emit())
	hide()

# Mostra a tela com uma entrada suave: o fundo escurece e o cartão sobe um pouco.
func abrir(texto: String, com_menu: bool) -> void:
	mensagem.text = texto
	botao_menu.visible = com_menu
	$Cartao/Dica.visible = not com_menu
	show()
	modulate.a = 0.0
	cartao.pivot_offset = cartao.size / 2.0
	cartao.scale = Vector2(0.94, 0.94)
	var posicao_final := cartao.position
	cartao.position.y += 18.0
	var entrada := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	entrada.tween_property(self, "modulate:a", 1.0, 0.28)
	entrada.tween_property(cartao, "scale", Vector2.ONE, 0.34)
	entrada.tween_property(cartao, "position", posicao_final, 0.34)
	botao_recomecar.grab_focus()
