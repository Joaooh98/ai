## Estrutura do experimento
Retomando a comparação pairwise já estabelecida, o experimento agora ganha uma forma concreta: o mesmo código é avaliado por dois prompts concorrentes e uma terceira entidade decide qual resposta é melhor. O objetivo não é medir acerto contra ground truth absoluto, mas comparar duas perspectivas de análise sobre a mesma entrada. Isso permite testar hipóteses de melhoria mesmo quando a qualidade depende de julgamento relativo. O LangSmith entra como ambiente para registrar prompts, dataset, execuções e decisões do juiz.

## Prompt A e Prompt B não são teste A/B de produção
Prompt A e prompt B são apenas rótulos das duas variantes comparadas dentro do experimento controlado. Isso não equivale a teste A/B de produção, porque aqui não há tráfego real de usuários nem métrica de negócio observada em ambiente produtivo. A evidência produzida é comparativa e técnica: qual saída parece melhor segundo um critério explícito. Essa distinção evita interpretar um experimento de avaliação offline como validação de impacto em produto.

## Dois prompts com objetivos diferentes
Os dois prompts não competem por estilo, mas por política de revisão. Um deles prioriza performance e procura sinais como N+1, memory leak, blocking e missing timeouts; o outro prioriza segurança e valida findings sob a ótica de vulnerabilidades. Como ambos recebem o mesmo código, a diferença observada vem da instrução embutida no prompt, não da entrada. O experimento isola exatamente esse efeito: como perspectivas distintas mudam o code review produzido.

## LLM as a Judge
LLM as a judge é o uso de um modelo adicional como árbitro da comparação entre duas saídas. Em vez de pedir ao mesmo prompt que se autoavalie, o experimento define um juiz separado, com papel explícito de técnico imparcial. Esse juiz recebe o código-fonte original, a resposta A e a resposta B, e decide qual revisão é superior segundo as regras fornecidas. A qualidade do experimento depende de o juiz ter instruções claras, auditáveis e alinhadas ao objetivo da comparação.

## Critérios explícitos e papel do juiz
O juiz não deve escolher com base em preferência vaga; ele precisa operar com critérios explícitos. Neste cenário, ele compara dois code reviews olhando o código real, o impacto dos problemas apontados e a natureza dos findings. Se identificar vulnerabilidades críticas reais, escolhe A; se identificar problemas críticos reais de performance, escolhe B. Quando os dois lados encontram problemas de peso equivalente, o resultado correto não é forçar um vencedor, mas registrar empate.

## Tie como resultado válido
`Tie` é um resultado legítimo da avaliação pairwise, não um erro do processo. Ele representa a situação em que as duas respostas têm mérito equivalente segundo o critério adotado, ou em que nenhuma supera claramente a outra. Permitir empate evita introduzir ruído ao obrigar o juiz a escolher artificialmente entre alternativas indistinguíveis. Em experimentos iterativos, a frequência de `tie` também informa se as mudanças de prompt estão realmente produzindo diferença perceptível.

## UpdatePrompt como hipótese experimental
`updatePrompt` não é apenas uma nova versão textual do prompt; ele representa uma hipótese de melhoria. Primeiro compara-se A contra B na configuração atual; depois altera-se um dos prompts e executa-se novamente o mesmo desenho experimental. Se a distribuição de vitórias mudar a favor da versão atualizada, há evidência de que a modificação deslocou a qualidade relativa da saída. Esse ciclo transforma edição de prompt em iteração controlada, e não em tentativa aleatória.

## Fluxo prático da execução
A execução segue uma ordem simples: subir o dataset, criar os prompts, rodar as duas variantes sobre as mesmas entradas e enviar as saídas ao juiz. O dataset continua sendo a base comum da comparação, como já visto anteriormente, mas agora ele alimenta duas gerações concorrentes em vez de uma comparação contra ground truth. O juiz recebe três entradas por caso: código-fonte, resposta A e resposta B. O resultado de cada item é uma decisão entre A, B ou `tie`, que depois pode ser agregada para orientar a próxima iteração de prompt.