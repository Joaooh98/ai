## Pipeline de evaluation
O cálculo das métricas entra depois da execução do modelo, não durante a geração da resposta. O fluxo é: rodar o prompt, capturar os outputs, alinhar cada output ao example correspondente do dataset e transformar essa comparação em contagens que o LangSmith consegue registrar. Como o LangSmith não calcula automaticamente essas métricas nesse cenário, o pipeline precisa devolver os scores já prontos.

## `extractPredict` e `extractExpected`
`extractPredict` é a função que normaliza e extrai do output do modelo apenas a estrutura comparável que interessa para a avaliação, como a lista de findings previstos. `extractExpected` faz a mesma operação do lado do dataset, convertendo o ground truth em uma estrutura com o mesmo formato lógico. Essas duas funções existem para evitar comparar objetos brutos incompatíveis, como texto livre de um lado e labels estruturados do outro.

## Pareamento posicional com `zip`
O uso de `zip` faz o pareamento entre output previsto e example esperado pela posição, assumindo que ambos estão na mesma ordem e têm o mesmo comprimento. Isso simplifica o loop de evaluation porque cada iteração já recebe o par correto de itens para comparação. Se a ordem estiver desalinhada ou houver diferença de tamanho entre as listas, o cálculo inteiro fica contaminado, então esse é um ponto crítico do pipeline.

## Transformando findings em conjuntos comparáveis
Retomando o cenário de code review em Go, os findings previstos e esperados precisam virar coleções comparáveis antes do cálculo. A operação central é tratar os itens de forma que interseção e diferença representem acertos e erros de classificação. Sem essa etapa, não há como derivar TP, FP e FN de maneira consistente.

## Interseção para true positives
True positives surgem da interseção entre o conjunto previsto e o conjunto esperado. Se o modelo retornou `bug` e `error`, e o esperado era `bug` e `crash`, a interseção contém apenas `bug`, que conta como acerto. Essa escolha funciona porque a interseção preserva somente os itens presentes nos dois lados.

## Diferença para false positives
False positives aparecem na diferença entre o previsto e o esperado. No mesmo exemplo, `error` foi retornado pelo modelo, mas não estava no ground truth daquele registro, então ele entra como excesso indevido. Essa operação captura exatamente o que o prompt acusou sem respaldo no dataset.

## Diferença para false negatives
False negatives vêm da diferença inversa: esperado menos previsto. Se o dataset esperava `error` e o modelo não trouxe esse item, então esse finding foi perdido e precisa entrar como FN. Esse cálculo mede a parte do ground truth que ficou descoberta pela resposta do modelo.

## Tratamento de denominador zero
O pipeline precisa tratar explicitamente casos em que os denominadores das fórmulas ficam zerados. Quando `TP + FP` é zero, a precision não pode ser calculada pela divisão direta; o mesmo cuidado vale para recall e, por consequência, para F1. Retornar `0` nesses casos evita exceções em runtime e mantém a evaluation executável em lotes inteiros, inclusive em exemplos vazios ou respostas sem findings.

## Retorno em dicionário com `score` e `comment`
O formato de retorno precisa ser compatível com a integração de evaluation, por isso cada métrica é devolvida como um dicionário com nome, `score` e `comment`. `score` carrega o valor numérico calculado, enquanto `comment` registra contexto útil para auditoria, depuração ou leitura no LangSmith. Em vez de retornar apenas um número solto, o pipeline produz uma estrutura que já serve tanto para processamento quanto para inspeção humana.

## Leitura prática do resultado
Precision, recall e F1 já foram definidos anteriormente; aqui o ponto novo é como alimentá-los corretamente a partir dos findings extraídos. Se a extração, o pareamento ou a comparação estiverem errados, a fórmula continua correta, mas o score deixa de representar o comportamento real do prompt. Em evaluation comparativa, a confiabilidade da métrica depende mais da qualidade desse pipeline do que da fórmula em si.

## video aula explicada e apresenta com esse arquivo .../prompts/mba-ia-prompt-engineering/7-evaluation/2-precision/metrics.py

