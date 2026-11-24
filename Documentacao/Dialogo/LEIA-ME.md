# Como Jogar e conversa inicial

Trabalho feito sobre a cópia com menu e pause aprovados. O ZIP recebido e o projeto original do grupo não foram alterados. Esta entrega inclui as melhorias aprovadas anteriormente.

## O que mudou
- Como Jogar: DynaPuff em todos os textos, missão em destaque, três blocos de leitura curtos e pequenas flores dos assets existentes. Fala sobre objetivo, exploração e colaboração, sem instruções de teclado. Voltar preservado.
- Professora estática na posição (520,608), usando o sprite original, sem colisão física. A Area2D de proximidade detecta os dois personagens e não bloqueia o caminho.
- Conversa com sete falas: acolhimento, evento da turma, imprevisto, materiais espalhados, exploração e ajuda mútua. Falas aparecem completas, sem animação de escrita ou revelação das soluções.
- Painel inferior com nome da professora, retrato, texto, progresso e botão de confirmação. DynaPuff e tema visual existentes reutilizados.

## Arquivos e lógica para apresentação
Novo Scripts/dialogo_professora.gd: um único script específico para essa conversa. A cada passo, verifica se ambos os jogadores estão dentro da Area2D. Ao abrir, suspende o processamento físico dos jogadores e do controlador da fase. A câmera permanece ativa. Cada confirmação aumenta o índice da fala. No fim, esconde o painel, libera a física e marca a conversa como concluída. Ao reiniciar a cena, esse estado volta ao início.

Nova Cenas/dialogo_professora.tscn: agrupa Sprite2D, Area2D com CollisionShape2D e CanvasLayer com Panel, Label e Button. É instanciada apenas em 01_galeria.tscn.

Cenas/menu.tscn: apenas a parte Ajuda e suas referências decorativas foram alteradas. Scripts/menu.gd e a composição principal permanecem iguais. project.godot: adicionada a ação dialogo_avancar. Nenhum script de personagem, câmera, tarefa ou pause foi alterado nesta rodada.

## Entrada e pause
A confirmação usa dialogo_avancar no Input Map. Há Enter como mapeamento provisório para testes e um botão visual clicável. A futura integração do controle pode emitir essa ação ou mudar seu mapeamento; não há sistema de hardware implementado. Não há nomes de teclas na ajuda ou no diálogo.

O pause aprovado foi preservado integralmente, inclusive seu texto já existente. Durante o pause, a conversa não avança. Continuar mantém os personagens bloqueados até a última fala; Reiniciar permite apresentar a conversa novamente e Menu encerra a tentativa normalmente.

## Testes executados
Godot 4.7.2: 22 testes desta etapa e 41 verificações de regressão aprovados. Incluem aproximação individual de cada jogador, aproximação conjunta, bloqueio de andar/pular, ação abstrata e botão, todas as falas dentro da área de leitura, encerramento, retomada real do movimento, ausência de repetição, reinício e pause durante o diálogo. Testes anteriores confirmam coleta, plantio, rega, navegação, reinício e retorno ao menu.

Capturas reais da ajuda, professora na fase, falas e pause durante a conversa foram inspecionadas. A imagem do menu principal foi comparada pixel a pixel com a entrega aprovada: idêntica. As fases 2 e 3, pause, scripts anteriores e assets continuam byte a byte iguais à base aprovada. Na fase 1 foi acrescentada apenas a instância da conversa.

O ambiente de teste avisou que não podia criar cache em user:// e registrou recursos ainda referenciados no encerramento do teste acelerado. As verificações funcionais passaram; não foi realizado teste de usabilidade com crianças ou hardware físico.

Extraia o ZIP numa pasta nova, abra project.godot e execute. Aproxime os dois alunos da professora no começo da galeria. Os relatórios antigos descrevem entregas anteriores; este documento descreve a rodada atual.
