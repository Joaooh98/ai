## Summary Evaluator e leitura agregada
`Summary Evaluator` agrega os resultados de vários registros em uma métrica consolidada do experimento, em vez de expor apenas avaliações isoladas por item. Isso é útil quando a decisão depende do comportamento global do prompt sobre o dataset, como no code review com precision, recall e F1. No LangSmith, essa abordagem permite ler rapidamente o perfil de cada política de prompt sem inspecionar manualmente os 10 exemplos. O valor agregado não substitui auditoria detalhada, mas acelera a comparação operacional entre variantes.

## Pipeline de execução do experimento
Retomando o cenário de code review em Go, a variável experimental continua sendo o prompt: conservador, agressivo ou balanceado. O script carrega o prompt escolhido, reutiliza uma função compartilhada para conectar inputs, LLM e integração com OpenAI via LangSmith, e extrai do ground truth os `expectedFindings` com tipo e severidade. Esses dados alimentam `extractExpected` e a função de cálculo de `PrecisionRecallF1`, que consolida os acertos e erros do experimento. A execução é disparada com `evaluate`, que roda o modelo sobre o dataset e registra os resultados no LangSmith.

## Como interpretar o experimento conservador
No experimento conservador, a leitura agregada mostrou precision muito alta, recall muito baixo e F1 baixo. Esse padrão indica um sistema seletivo: ele evita emitir alertas errados, mas deixa passar muitos bugs reais. Operacionalmente, isso faz sentido quando o custo de investigar falsos positivos é alto, mas se torna inadequado quando cobertura é prioridade. O ponto principal não é o número isolado, e sim o formato do comportamento que ele revela.

## Como interpretar o experimento agressivo
No experimento agressivo, o código permanece igual e apenas o prompt muda, o que isola a causa da diferença nas métricas. O resultado observado foi o inverso do conservador: precision baixa, recall mais alto e F1 ainda baixo. Isso mostra uma política mais permissiva, que recupera mais casos reais ao custo de introduzir mais ruído. A comparação lado a lado deixa explícito o trade-off já conhecido entre cobertura e confiabilidade dos alertas.

## Como interpretar o experimento balanceado
O prompt balanceado produziu um F1 significativamente maior do que os outros dois, porque reduziu o desequilíbrio entre precision e recall. Ele não maximizou nenhuma métrica isoladamente, mas entregou uma combinação mais útil para comparação global. Quando o objetivo é escolher uma política geral de revisão, esse tipo de resultado costuma ser mais valioso do que extremos com uma métrica excelente e outra muito degradada. O F1, aqui, funciona como critério de ordenação prática entre políticas concorrentes.

## Variabilidade experimental em LLMs
Resultados com LLMs não são perfeitamente estáveis, mesmo quando a estrutura do experimento parece idêntica. Mudanças de momento de execução, versão de modelo ou pequenas variações internas de geração podem deslocar as métricas observadas. Por isso, um único run não deve ser tratado como verdade definitiva sobre a qualidade do prompt. A leitura correta é probabilística: o experimento sugere tendência, não certeza absoluta.

## Repetição e tamanho do dataset
Confiabilidade experimental exige repetir o mesmo experimento mais de uma vez e usar datasets maiores. Repetição ajuda a distinguir padrão consistente de flutuação ocasional do modelo, enquanto mais exemplos reduzem a influência desproporcional de casos individuais sobre a média agregada. Com apenas 10 registros, pequenas mudanças já alteram bastante precision, recall e F1. A decisão de produto fica mais segura quando o comportamento se mantém sob repetição e em amostras mais amplas.

## Leitura operacional no LangSmith
A interface do LangSmith permite acompanhar iterações, execuções e métricas resumidas do experimento sem entrar registro por registro. Isso acelera a comparação entre versões como `conservative`, `aggressive` e `balanced`, especialmente quando o objetivo é decidir qual política seguir. Ainda assim, a leitura agregada só é confiável porque o dataset, o ground truth e o pipeline de extração permanecem constantes entre os testes. Sem esse controle, diferenças numéricas poderiam refletir mudança nos dados, e não no prompt.