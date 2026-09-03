## Objetividade como condição de uso
Métricas como precision, recall e F1 só fazem sentido quando a tarefa admite verificação objetiva. Isso exige um critério externo claro para decidir se a saída está certa ou errada, em vez de depender de opinião, gosto ou interpretação aberta. Sem essa base, o número calculado parece preciso, mas não representa qualidade real. Em Prompt Engineering, isso define quando uma avaliação quantitativa é válida e quando ela apenas produz falsa confiança.

## Ground truth e validade da métrica
Ground truth é o conjunto de respostas de referência usado para comparar a saída do sistema. Ele funciona como a “verdade operacional” do experimento: sem ele, não há como contar acertos, erros, falsos positivos ou falsos negativos de forma consistente. Por isso, métricas clássicas dependem de um dataset rotulado com critério estável. Se o rótulo não é confiável ou não existe, a métrica perde validade antes mesmo do cálculo.

## Classificação é o cenário mais natural
Essas métricas aparecem com mais força em problemas de classificação, porque a tarefa pede decidir entre categorias observáveis. Retomando o raciocínio de bugs já conhecido, o mesmo vale para casos como identificar se uma mensagem indica usuário bravo ou não. O ponto central não é o domínio, mas a existência de uma regra verificável para marcar cada item. Quando cada exemplo pode ser rotulado de forma consistente, o prompt passa a ser comparável como qualquer outro classificador.

## Prompt como variável experimental
O prompt não é apenas texto de instrução; ele é uma variável que altera o comportamento do sistema. Pequenas mudanças na formulação podem tornar a classificação mais agressiva, mais conservadora ou mais ambígua, deslocando o equilíbrio entre erros e acertos. Isso transforma avaliação em experimento de engenharia: muda-se o prompt, executa-se no mesmo dataset e mede-se o efeito. Sem esse controle, a comparação entre versões vira impressão subjetiva.

## Exemplo prático: detectar usuário bravo
Considere um conjunto grande de conversas em que existe um critério para marcar quando o usuário está bravo. Se o prompt instrui o LLM a procurar sinais como o uso recorrente de uma palavra específica, a saída pode ser comparada com os rótulos esperados do dataset. A partir daí, mede-se quanto o sistema acertou e quanto errou de forma objetiva. Esse tipo de problema é adequado porque a decisão final pode ser tratada como classificação binária.

## Onde a métrica falha
Tarefas como medir o quanto um conteúdo ajudou alguém, o quanto ele é “bom” ou a qualidade de um código em sentido amplo tendem a ser subjetivas demais para esse tipo de métrica. Nesses casos, o problema não está na fórmula, mas na ausência de um critério objetivo e reproduzível para rotular os dados. Se pessoas diferentes discordam estruturalmente sobre a resposta correta, precision, recall e F1 deixam de ser indicadores confiáveis. A avaliação precisa migrar para abordagens qualitativas ou comparativas.

## Leitura prática do F1 nesse contexto
O F1, já definido anteriormente, continua útil como resumo do equilíbrio entre cobertura e confiabilidade. Aqui, o ponto novo é o critério de aplicabilidade: ele só deve orientar decisão quando a tarefa realmente permite contagem objetiva de acertos e erros. Em classificação de bugs, por exemplo, F1 alto indica equilíbrio operacional aceitável; F1 baixo sinaliza que o prompt está perdendo casos relevantes ou gerando ruído excessivo. O número só é interpretável porque existe ground truth para sustentar a comparação.

## Evaluation como disciplina de engenharia
Evaluation em sistemas com LLM cumpre papel análogo ao de testes em software. Ela não existe para “embelezar” o experimento, mas para garantir que mudanças no prompt não degradem o comportamento do sistema ao longo do tempo. Isso exige datasets, critérios de aceitação e comparação entre versões, exatamente como em práticas de qualidade de software. Quando o prompt é sensível a pequenas alterações, avaliar deixa de ser opcional e passa a ser parte do processo de desenvolvimento.