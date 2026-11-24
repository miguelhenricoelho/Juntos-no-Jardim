# Menu principal e pause — 04/11/2026

Base: Juntos-no-Jardim-Cenarios-2 - atualizado.zip. A cópia de trabalho desta entrega está em Juntos-no-Jardim-Menu-Pause. O ZIP recebido e a versão original do grupo não foram modificados.

## Visual
Menu estático em 1280 × 720: aproximadamente 40% da composição reservada ao título e às opções, e 60% à dupla e ao jardim. Fundo montado com a escola, árvore, nuvens e planta dos assets existentes, reunidos num SVG. Botões de texto com alteração instantânea de cor e sublinhado de foco. Sem partículas, Tween, AnimationPlayer ou scripts de decoração no menu/pause.

DynaPuff aplicada ao título, opções, título do pause e seus botões; Nunito usada somente nos textos explicativos. Fonte obtida do repositório oficial Google Fonts: https://github.com/google/fonts/tree/main/ofl/dynapuff. Licença OFL incluída em Assets/Fontes/DynaPuff-LICENCA.txt. Acentos portugueses conferidos no Godot.

A ilustração PNG transparente (1536 × 1024) é exclusiva do menu, criada a partir dos sprites de Ana e João. Conserva penteados, roupas, cores características e proporções cartunescas; as poses foram adaptadas para a flor e o regador. É um redesenho, não uma ampliação pixel a pixel. Os sprites usados nas fases permanecem byte a byte iguais aos recebidos.

## Código para explicar em sala
- Scripts/menu.gd: abre a primeira fase, mostra/fecha a ajuda e liga o botão Sair. As posições ficam na cena, não no código.
- Scripts/pausa.gd: Esc alterna SceneTree.paused. Apenas o CanvasLayer da interface usa Process Mode Always, para seus botões continuarem respondendo. Continuar, Reiniciar e Menu sempre removem o pause antes da ação.
- Cenas/pausa.tscn: uma única cena reutilizada pelas três fases. Painel, botões e escurecimento usam nós nativos.
- Assets/Menu/interface.tres: tema compartilhado; evita repetir estilos nos botões.
- Scripts/professora.gd: somente o argumento process_always=false foi acrescentado à espera de 1,2 segundo do aceno, para essa espera também respeitar o pause.

O controlador das fases, a movimentação, as tarefas cooperativas, as colisões, a câmera e os demais nós das fases foram preservados. Em cada fase foi adicionada somente a instância de Pausa. O project.godot recebeu apenas a preservação de proporção da janela. Não foram encontrados ranking, cronômetro de partida ou menu de seleção de personagens nesta versão recebida; nenhuma dessas funções foi inventada ou removida.

## Validação executada
Godot 4.7.2: 41 verificações aprovadas, incluindo navegação por teclado, Como jogar, retorno da ajuda, Jogar, Esc, pausa das posições dos dois jogadores e câmera, interrupção das tarefas, temporizador da professora, bloqueio de R durante pause, Continuar, reinício das três fases e retorno ao menu sem pause residual. Coleta, plantio e rega originais exercitados. Sair foi acionado ao final e encerrou o processo com código 0.

Três capturas reais inspecionadas: menu, ajuda e pause. Dois quadros do menu separados por 60 frames foram comparados e eram idênticos. Testes automatizados de integração; não constituem teste de usabilidade com crianças nem uma partida completa percorrida manualmente.

O ambiente restrito avisou que não podia criar cache em user://. O teste acelerado também registrou recursos ainda referenciados ao encerrar; não impediu a execução nem as verificações. Evidências em testes.json e preservacao.json.

## Abrir
Extraia o ZIP numa pasta nova e abra project.godot. F5 inicia o menu. Durante as fases, Esc abre/fecha o pause; os controles originais permanecem iguais. O cache .godot foi omitido para o Godot regenerá-lo na importação.
