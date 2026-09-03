## Organização do experimento
Retomando o cenário de code review em Go, o dataset continua sendo a base do experimento: cada input contém um trecho de código e o ground truth define o output esperado para comparação. O ponto novo não está na estrutura dos dados, mas em como o prompt passa a funcionar como política de decisão. Em vez de pedir apenas “analise o código”, o prompt define o quanto o modelo deve suspeitar, o quanto deve se conter e quais tipos de evidência são suficientes para reportar um problema.

## Prompt agressivo
Um prompt agressivo instrui o modelo a reportar qualquer indício de erro, mesmo quando a evidência é fraca ou a possibilidade é remota. Essa política existe para maximizar cobertura: perder um bug é considerado pior do que gerar alertas indevidos. No code review, isso desloca o comportamento do modelo para uma postura de suspeita constante, aumentando a chance de capturar mais bugs reais, mas também de introduzir mais falsos positivos.

## Prompt conservador
Um prompt conservador impõe um limiar de decisão alto: o modelo só deve reportar o que puder sustentar com certeza muito forte. A utilidade dessa política aparece quando o custo de investigar falso positivo é alto e a confiabilidade dos findings precisa ser máxima. No exemplo, restringir o escopo a poucas vulnerabilidades críticas e exigir certeza explícita torna o modelo seletivo, reduz o ruído e tende a favorecer precision, ainda que alguns bugs reais deixem de ser reportados.

## Prompt balanceado
Um prompt balanceado não tenta maximizar apenas um lado do trade-off; ele organiza o julgamento por categorias e define critérios diferentes para cada uma. No code review em Go, segurança, robustez/performance e qualidade de código recebem prioridades próprias porque não exigem o mesmo nível de evidência nem têm o mesmo custo de erro. O resultado é uma política intermediária: o modelo continua útil para cobertura, mas com freios explícitos para evitar acusações fracas ou estilísticas demais.

## Few-shot por categoria
Few-shot, neste contexto, não serve apenas para mostrar formato de resposta; ele calibra o padrão de decisão esperado em cada classe de problema. Ao incluir exemplos de falhas de segurança, gargalos de performance, problemas de N+1, verbosidade excessiva ou nomes inadequados, o prompt ensina o que conta como finding relevante dentro daquele experimento. Isso reduz ambiguidade e aproxima o comportamento do modelo da política desejada, especialmente quando as categorias têm fronteiras diferentes.

## Checklist por categoria
A checklist transforma uma instrução genérica de revisão em um procedimento observável. Em vez de depender de uma noção vaga de “qualidade”, o modelo recebe uma lista de tipos de erro que deve procurar em cada categoria. Essa estrutura melhora consistência entre execuções, facilita auditoria do prompt e ajuda a deslocar o comportamento do modelo de forma controlada, porque cada item da checklist funciona como um lembrete operacional do que merece atenção.

## Regras de confiança mínimas
Definir confiança mínima, como exigir 80% ou mais para reportar um finding, cria um limiar explícito de emissão de alertas. Esse mecanismo é especialmente útil no prompt balanceado, porque evita que o modelo reporte hipóteses fracas apenas por associação superficial. Quando combinado com regras específicas por categoria — análise mais profunda em segurança, padrões claros em robustez, exclusão de borderline cases em qualidade — o prompt passa a codificar uma política de risco, não apenas uma instrução textual.

## Calibração do prompt como estratégia
Calibrar um prompt significa ajustar instruções, exemplos, categorias e critérios de confiança para deslocar deliberadamente o perfil de erro do modelo. Isso conecta diretamente o design do prompt às métricas já conhecidas: um texto mais permissivo tende a aumentar cobertura, um texto mais restritivo tende a aumentar confiabilidade, e um texto balanceado tenta preservar utilidade nos dois lados. Em avaliação comparativa, o prompt deixa de ser redação e passa a ser instrumento de engenharia experimental.

## Passo a passo de implementação
Comece com o mesmo código em Go e o mesmo ground truth para todas as variantes, porque a comparação só é válida quando o prompt é a variável experimental. Em seguida, escreva três versões: uma agressiva, instruindo o modelo a suspeitar de tudo; uma conservadora, limitando o reporte a casos de alta certeza; e uma balanceada, separando categorias, exemplos e regras de confiança. Execute cada prompt sobre o mesmo dataset, colete os findings no formato esperado e compare como cada política desloca o comportamento do modelo em relação às métricas já estabelecidas.