## Composição explícita dos insumos
Um draft útil de FDD surge quando o prompt combina três artefatos com papéis diferentes: o HLD fixa as decisões arquiteturais já tomadas, o PDF de Deep Research amplia o repertório técnico com alternativas e referências, e o esqueleto do FDD define a estrutura mínima de saída. Essa composição evita pedir “um documento do zero”, porque a IA passa a preencher uma moldura com contexto real. Retomando o rate limiter, a geração deixa de depender só de entrevista e passa a reutilizar tudo o que já foi produzido no fluxo.

## Montagem prática do prompt
O prompt pode ser simples e ainda funcionar bem se o contexto estiver forte. A instrução central é pedir um Feature Design Doc para a feature alvo, informar que o HLD será fornecido, anexar a pesquisa técnica e exigir que a saída siga o esqueleto do FDD. Também vale orientar o nível de detalhe: não descer para implementação linha por linha, mas explicitar contratos, comportamento e decisões suficientes para orientar a execução.

## HLD como insumo operacional
O HLD não entra no prompt como referência decorativa; ele serve para ancorar o draft nas decisões já estabilizadas. Isso faz a IA herdar elementos como arquitetura escolhida, componentes, responsabilidades e trade-offs, em vez de reinventar a solução. No exemplo do rate limiter, é esse insumo que ajuda a saída a manter coerência com middleware, estratégias, storage e limites arquiteturais já definidos.

## Deep Research como insumo de densidade técnica
A pesquisa estruturada complementa o HLD porque traz detalhes que normalmente não cabem no documento arquitetural, como comparações, estratégias, referências externas e implicações operacionais. Quando esse PDF entra no mesmo prompt, a IA ganha base para enriquecer seções do FDD com maior precisão técnica. O efeito prático é um rascunho menos genérico e mais próximo de uma especificação utilizável.

## Template como contrato de saída
O esqueleto do FDD continua sendo o mecanismo que força cobertura mínima das seções relevantes. Em vez de confiar que a IA lembrará espontaneamente de contexto, escopo, exclusões, erros, observabilidade, compatibilidade e critérios de aceite, o template transforma isso em obrigação estrutural. O resultado tende a ser mais revisável, porque a equipe consegue inspecionar lacunas por seção, não apenas pela impressão geral do texto.

## Prompt imperfeito com contexto forte
Um prompt “mal feito” ainda pode produzir um draft valioso quando os insumos são bons. Isso acontece porque a qualidade da saída não depende só da redação do comando, mas da densidade e da complementaridade do contexto fornecido. A lição prática não é abandonar bons prompts, e sim entender que contexto forte reduz fragilidade e acelera a primeira versão.

## Grounding e rastreabilidade da saída
Grounding é a indicação explícita de onde a IA tirou determinada informação, como trechos ou referências do PDF anexado. Isso pode poluir a leitura quando o objetivo é obter um documento mais limpo, mas é útil para auditoria, validação e revisão crítica do draft. Em fluxos de design, grounding funciona como mecanismo de rastreabilidade: ele mostra se a saída está realmente apoiada nos insumos ou se começou a improvisar.

## Leitura crítica do draft gerado
Um draft bom não é aquele que sai perfeito, e sim aquele que evita a página em branco e já organiza o trabalho de refinamento. A revisão deve verificar aderência ao HLD, cobertura das seções do template, presença de detalhes úteis e possíveis distorções de foco, como ênfase excessiva em multi-tenant quando isso não era central. No rate limiter, a utilidade do resultado aparece quando ele já traz contratos, headers, erros, fallback, observabilidade, dependências, compatibilidade e critérios de aceite em formato editável.

## Iterações manuais como parte do processo
A geração assistida não elimina edição humana; ela desloca o esforço de escrever tudo para revisar, corrigir, compor e ajustar. Esse ponto é essencial porque nem todas as informações virão corretas, completas ou no nível certo de detalhe. O fluxo robusto assume várias iterações curtas sobre um rascunho inicial, em vez de esperar uma geração automática definitiva.

## Documentação como ativo de engenharia
Documentação dá trabalho, mas se torna um ativo quando passa a ser lida por pessoas e por IA ao longo do ciclo de vida do software. Um FDD inicial bem gerado acelera implementação, revisão técnica, testes, manutenção e futuras automações baseadas em contexto. Em engenharia de software, isso importa porque o desenvolvimento não termina no código: decisões, contratos e restrições precisam continuar acessíveis, atualizáveis e reutilizáveis.