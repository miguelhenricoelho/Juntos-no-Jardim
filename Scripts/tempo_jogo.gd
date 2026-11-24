extends Node

# Este nó continua existindo quando o jogo troca de fase.
var segundos: float = 0.0
var rodando: bool = false
# Tempo marcado quando a dupla entrou na fase atual, usado depois de um Game Over.
var segundos_inicio_fase: float = 0.0
var fase_marcada: String = ""
var derrota_pendente: bool = false
# Tempo de cada fase concluída, na ordem em que a dupla jogou. A tela final soma tudo.
var tempos_fases: Array[float] = []

# Soma o tempo apenas enquanto existe uma partida em andamento.
func _process(delta: float) -> void:
	if rodando:
		segundos += delta

# Uma partida nova começa do zero.
func iniciar() -> void:
	segundos = 0.0
	rodando = true
	segundos_inicio_fase = 0.0
	fase_marcada = ""
	derrota_pendente = false
	tempos_fases.clear()

# Chamado por cada fase ao abrir. Depois de um Game Over, volta ao tempo
# que estava marcado quando a dupla entrou nesta fase.
func entrar_na_fase(caminho: String) -> void:
	if derrota_pendente and caminho == fase_marcada:
		segundos = segundos_inicio_fase
		rodando = true
	elif caminho != fase_marcada:
		fase_marcada = caminho
		segundos_inicio_fase = segundos
	derrota_pendente = false
	# Entrar numa fase sempre significa que há uma partida em andamento.
	rodando = true

# Guarda quanto a dupla levou na fase que acabou de concluir.
func concluir_fase() -> void:
	tempos_fases.append(maxf(segundos - segundos_inicio_fase, 0.0))

# Soma de todas as fases concluídas.
func total() -> float:
	var soma := 0.0
	for t in tempos_fases:
		soma += t
	return soma

# No Game Over, a contagem para e a próxima tentativa recomeça do início da fase.
func registrar_derrota() -> void:
	if rodando:
		rodando = false
		derrota_pendente = true

# Só é chamado quando a última fase realmente termina.
func finalizar() -> void:
	rodando = false

# Ao voltar ao menu, a partida atual deixa de existir.
func cancelar() -> void:
	rodando = false

# Converte os segundos para um texto simples, como 02:35.
func formatar(valor: float = -1.0) -> String:
	var total := int(segundos if valor < 0.0 else valor)
	var minutos := int(total / 60)
	var segundos_restantes := total % 60
	return "%02d:%02d" % [minutos, segundos_restantes]
