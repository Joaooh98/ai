## Recall e cobertura dos positivos reais
Recall mede a capacidade de encontrar os positivos que realmente existem. Retomando o cenário de classificação de bugs, a pergunta agora não é se os alertas emitidos são confiáveis, mas quantos bugs reais foram capturados pelo sistema. Essa métrica existe porque um classificador pode parecer bom por errar pouco nos positivos retornados e, ainda assim, deixar passar casos importantes. Um recall alto indica cobertura alta dos bugs reais.

## False negative
False negative é o erro em que um caso realmente positivo não é identificado pelo modelo. No exemplo de bugs, se existem 10 bugs reais e o sistema encontra apenas 7, os 3 restantes são false negatives. Esse erro importa porque representa falha de detecção: o problema existe, mas o sistema não o trouxe para análise. Em contextos operacionais, false negatives costumam ser caros porque bugs reais seguem adiante sem tratamento.

## Diferença prática entre false positive e false negative
A distinção central entre as métricas está no tipo de erro que cada uma penaliza. Precision, já definida anteriormente, cai quando o sistema acusa bug onde não havia bug; recall cai quando havia bug e o sistema não encontrou. Essa diferença muda a pergunta de avaliação: uma métrica mede confiabilidade dos positivos retornados, a outra mede cobertura dos positivos existentes. Separar esses dois erros evita interpretar um sistema “cuidadoso” como bom quando ele apenas deixa muitos casos passarem.

## Fórmula do recall
A fórmula do recall é `TP / (TP + FN)`. O numerador contém os bugs reais encontrados corretamente, e o denominador representa todos os bugs reais que deveriam ter sido encontrados, tanto os detectados quanto os perdidos. Por isso, recall não depende de quantos positivos incorretos o modelo retornou, e sim de quantos positivos reais ele deixou escapar. A métrica responde diretamente à pergunta: entre os casos positivos existentes, qual fração foi recuperada?

## Sensibilidade do sistema
Recall pode ser lido como uma medida de sensibilidade do sistema a casos positivos. Um sistema mais sensível tende a sinalizar mais itens como bug para reduzir a chance de deixar bugs reais passarem. Esse comportamento melhora a cobertura, mas frequentemente aumenta o risco de incluir itens incorretos entre os positivos retornados. Sensibilidade alta, portanto, costuma deslocar o sistema em direção a mais recall e potencialmente menos precision.

## Efeito do prompt no comportamento de classificação
Em Prompt Engineering, o texto do prompt altera o comportamento de decisão do modelo mesmo sem mudar pesos ou arquitetura. Um prompt mais fechado pode parecer bom porque acusa menos bugs indevidos, mas também pode falhar em encontrar bugs reais importantes, reduzindo o recall. Já um prompt mais agressivo tende a ampliar a cobertura e encontrar mais positivos reais, ao custo de possivelmente introduzir mais falsos alarmes. O efeito prático do prompt é deslocar o ponto de equilíbrio entre cobertura e confiabilidade.

## Trade-off entre recall e precision
Retomando a comparação com precision, as duas métricas observam lados diferentes do mesmo sistema de classificação. Quando o modelo é ajustado para encontrar quase tudo, o recall sobe, mas a precision pode cair porque mais itens duvidosos entram como positivos. Quando o comportamento fica mais restritivo, a precision tende a melhorar, mas o recall pode piorar porque alguns bugs reais deixam de ser marcados. Esse trade-off é a base para interpretar prompts conservadores, agressivos e balanceados nas comparações posteriores.

## Leitura prática da métrica
Um recall alto significa que poucos casos reais escaparam; um recall baixo significa que muitos positivos verdadeiros ficaram para trás. No exemplo citado, encontrar 9 de 10 bugs implica que apenas 1 escapou, o que caracteriza boa cobertura. A leitura correta da métrica sempre depende do custo de perder casos reais no domínio analisado. Quando deixar um bug passar é mais grave do que investigar um alerta extra, recall ganha prioridade na avaliação.