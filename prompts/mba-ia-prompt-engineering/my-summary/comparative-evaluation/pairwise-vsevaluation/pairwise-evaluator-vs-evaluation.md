## Pairwise evaluation como avaliação relativa
Pairwise evaluation é uma forma de avaliar qualidade sem depender de um ground truth absoluto para cada saída. Em vez de perguntar se uma resposta está correta contra uma referência fixa, a comparação pergunta qual de duas respostas para o mesmo input é melhor segundo um critério explícito. Essa mudança é importante quando a decisão útil é relativa, não absoluta. Ela inaugura um novo bloco de avaliação comparativa: comparar variantes entre si, e não apenas medir acertos contra rótulos.

## Diferença entre pairwise evaluation e pairwise evaluator
Pairwise evaluation é o tipo de avaliação; Pairwise Evaluator é o componente que executa esse tipo de julgamento. A distinção importa porque ferramentas como LangSmith nomeiam o mecanismo operacional como evaluator, enquanto o método conceitual continua sendo a avaliação pairwise. Em termos práticos, o primeiro responde à pergunta “que forma de avaliação estou usando?” e o segundo responde “quem aplica essa forma de avaliação?”. Separar método de executor evita confundir estratégia de experimento com implementação da ferramenta.

## Critério de julgamento
A comparação pairwise só é útil quando o critério de julgamento está explícito. Esse critério pode ser correctness, como no exemplo de timeout em HTTP request com Go, mas também pode ser outro atributo comparável, desde que esteja claramente definido. O juiz não decide “qual gostou mais”; ele decide qual saída vence segundo a régua informada. Sem esse critério, a preferência gerada perde valor técnico e fica difícil auditar por que uma resposta ganhou da outra.

## Exemplo: duas respostas para o mesmo input
Retomando a lógica de comparação entre prompts já usada antes, a entrada agora permanece fixa e o foco passa a ser a disputa entre duas saídas. Para o input “como trabalhar com timeout em um HTTP request com Go”, a resposta A usa `context.WithTimeout` e a resposta B usa `time.Sleep`. Se o critério for correctness, a preferência recai sobre a alternativa que implementa timeout de forma correta no contexto da linguagem e da API. O resultado da avaliação não é um score contra ground truth, mas uma escolha entre A e B.

## Fluxo de três chamadas
A avaliação pairwise normalmente envolve três chamadas lógicas. Primeiro, executa-se a opção 1; depois, executa-se a opção 2; por fim, uma terceira chamada recebe as duas respostas e produz o julgamento comparativo. Essa terceira etapa é a do juiz, que consolida as saídas concorrentes e retorna a preferência com base no critério definido. O custo e o desenho do experimento mudam porque a comparação exige gerar as alternativas antes de julgá-las.

## Relação com A/B testing
Pairwise evaluation se aproxima de A/B testing porque ambos comparam alternativas, mas a natureza da comparação é diferente. No pairwise, duas saídas para o mesmo input são julgadas diretamente por um avaliador, geralmente offline e em ambiente controlado; no A/B testing, a comparação acontece online, em produção, observando comportamento real de usuários ou métricas de negócio. Um método não substitui automaticamente o outro. Pairwise serve para decidir preferências de qualidade entre respostas; A/B testing valida impacto operacional no sistema em uso.

## Quando pairwise complementa métricas clássicas
Precision, recall e F1 continuam adequados quando existe ground truth confiável e a tarefa é objetivamente mensurável, como já foi estabelecido. Pairwise entra quando a comparação entre duas saídas é mais natural do que a checagem contra uma resposta única esperada. Isso acontece em cenários em que várias respostas podem ser aceitáveis, mas uma é melhor que a outra segundo um critério definido. Nesses casos, a avaliação relativa complementa a avaliação absoluta e amplia o repertório experimental de prompts.

## Pairwise no LangSmith
No LangSmith, pairwise aparece como um evaluator porque a ferramenta precisa de um componente concreto para aplicar o julgamento comparativo. O ponto central não é a nomenclatura da interface, mas entender que o evaluator operacionaliza uma avaliação relativa entre duas execuções. Essa leitura ajuda a estruturar experimentos corretamente: duas opções são executadas sobre o mesmo input, e o juiz decide a preferência. A partir daí, as próximas iterações podem inspecionar justificativas, versionar prompts e repetir comparações com mais controle.