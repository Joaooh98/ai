## Posição do FDD na hierarquia
Feature Design Doc é o documento que desce do desenho arquitetural para a especificação operacional da feature. O HLD já definiu o terreno da solução; o FDD transforma esse contexto em comportamento detalhado, contratos reais e condições de implementação. Ele não chega ao nível de prescrever código linha por linha, mas também não fica apenas na organização macro do sistema. Seu papel é reduzir a ambiguidade entre arquitetura e execução.

## Quando usar um FDD
O FDD se justifica quando a feature expõe API, altera contratos, adiciona configuração ou produz efeitos relevantes em segurança, performance e compatibilidade. Nesses casos, a implementação depende de definições que não cabem mais no nível arquitetural, mas ainda precisam ser compartilhadas antes do código. Se a mudança afeta integração entre partes do sistema, comportamento em runtime ou expectativas externas, o documento deixa de ser opcional e passa a ser instrumento de alinhamento técnico.

## Perguntas que o documento responde
Um FDD responde como a feature se comporta em tempo de execução, quais interfaces expõe, como é configurada, de quais dependências precisa e como lida com erros, exceções e concorrência. Ele também define como validar que a implementação está correta, o que desloca a discussão de intenção para verificabilidade. Isso torna o documento útil não só para construir, mas para revisar, testar e aceitar a feature com critérios objetivos.

## FDD como ponte entre arquitetura e código
A fronteira do FDD é deliberada: ele detalha o suficiente para orientar implementação sem virar prescrição de padrão de codificação ou detalhe interno de classe. Essa posição intermediária importa porque muitos erros surgem justamente no espaço entre “a arquitetura permite” e “o código realmente faz”. O FDD fecha esse espaço ao explicitar contratos públicos, fluxos, erros e regras operacionais que o HLD apenas sinaliza em alto nível.

## Contratos públicos e comportamento detalhado
Contratos públicos são a parte do documento que define o que outras partes do sistema ou consumidores externos podem esperar da feature. Aqui entram assinaturas, endpoints, headers, exemplos de uso e semântica de resposta, porque integração depende de precisão, não de intenção genérica. Retomando o rate limiter já conhecido, o foco agora deixa de ser a topologia com Redis e middleware e passa a ser o comportamento exato da feature: quais headers ela retorna, em que condição responde `429` e qual contrato expõe para quem integra.

## Erros, exceções e fallbacks
Erros e exceções precisam aparecer como comportamento especificado, não como detalhe deixado para o implementador decidir no meio do desenvolvimento. Fallbacks entram nessa mesma camada porque representam a resposta esperada quando dependências falham ou quando a feature não consegue operar no modo principal. No rate limiter, a decisão arquitetural de fallback open já existe; no FDD, ela precisa virar regra operacional clara, com condições de acionamento e efeito observável no comportamento da feature.

## Configuração, dependências e compatibilidade
Configuração aparece no FDD no nível em que afeta uso real da feature: quais opções existem, como são fornecidas via código e quais combinações são válidas ou inválidas. Dependências também deixam de ser apenas componentes do desenho e passam a ser requisitos concretos para a feature funcionar, inclusive com impacto em integração e rollout. Compatibilidade precisa ser tratada explicitamente quando a mudança altera contratos, comportamento esperado ou forma de adoção por consumidores já existentes.

## Critérios de aceite como núcleo da especificação
Critérios de aceite técnicos são centrais porque transformam o documento em referência verificável, não apenas descritiva. Eles definem as condições sob as quais a feature pode ser considerada correta, cobrindo comportamento, contratos, erros e restrições técnicas relevantes. Sem essa seção, o time até implementa algo plausível; com ela, o time implementa algo testável contra uma definição compartilhada.

## Estrutura típica do documento
Um FDD costuma reunir contexto e motivação técnica, objetivos, escopo e exclusões, fluxos detalhados, diagramas quando necessários, contratos públicos, erros, fallbacks, dependências, compatibilidade, critérios de aceite, riscos e mitigação. Essa composição mostra que o documento não serve apenas para descrever a feature, mas para cercar os pontos que mais geram divergência durante implementação. Observabilidade e riscos podem ser apenas referenciados a partir do que já foi estabelecido antes, desde que o documento deixe claro como essas preocupações afetam a operação específica da feature.

## Implicações para implementação com IA
Um FDD bem escrito melhora a implementação assistida por IA porque fornece contexto operacional reutilizável em vez de depender de prompts vagos. Como o documento já explicita contratos, erros, configuração e critérios de aceite, a IA passa a gerar código e testes com menos espaço para interpretação arbitrária. O ganho principal não é “automatizar a feature”, mas reduzir a distância entre o que foi decidido e o que será implementado.