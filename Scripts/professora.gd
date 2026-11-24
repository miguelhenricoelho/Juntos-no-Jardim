extends Node2D
class_name Professora

# Node2D posiciona a professora no cenário; ela não precisa da física do personagem.
# O Timer conta os segundos entre um aceno e outro.
@export var intervalo_aceno: float = 4.0
@onready var animacao: AnimatedSprite2D = $Animacao
@onready var temporizador: Timer = $Temporizador

# _ready roda ao entrar na cena: começa parada e liga o fim do Timer ao aceno.
func _ready() -> void:
	animacao.play("parada")
	temporizador.wait_time = intervalo_aceno
	temporizador.timeout.connect(acenar_por_um_momento)
	temporizador.start()

# Toca o aceno, espera 1,2 segundo e volta à pose parada.
# is_inside_tree evita alterar a cena se a professora já tiver sido removida.
func acenar_por_um_momento() -> void:
	animacao.play("acenando")
	await get_tree().create_timer(1.2, false).timeout
	if is_inside_tree():
		animacao.play("parada")
