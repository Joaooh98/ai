## Objetivo arquitetural do rate limiter
Rate limiting entra aqui como exemplo recorrente porque é um problema conhecido pelos desenvolvedores, mas nem sempre compreendido do ponto de vista de implementação e desenho arquitetural. O HLD fixa o objetivo do sistema: um SDK embutido nos microserviços, escrito em Go, capaz de limitar acesso com base em API key, IP e plano do cliente. Esse recorte já mostra o papel do documento: transformar uma necessidade operacional em responsabilidades, metas e fronteiras técnicas sem descer ao código.

## Metas não funcionais e P95 abaixo de 5 ms
Metas não funcionais moldam a arquitetura antes de qualquer detalhe de implementação. Exigir P95 inferior a 5 ms para operações com Redis significa que 95% das verificações do limitador precisam terminar abaixo desse tempo, o que restringe escolhas de topologia, armazenamento e número de hops na requisição. Essa meta existe porque o rate limiter fica no caminho crítico da chamada HTTP; se ele for lento, toda a plataforma herda essa latência.

## SDK in-process como middleware HTTP
O SDK é integrado in-process, funcionando como middleware HTTP antes da lógica de negócio do serviço hospedeiro. Essa decisão reduz acoplamento com um serviço remoto dedicado e evita uma chamada extra de rede para cada requisição, mantendo o controle de acesso no próprio processo da aplicação. O efeito prático é simples: a requisição entra, o middleware consulta identidade e política, decide permitir ou negar, injeta headers e só então a lógica de negócio continua.

## Redis como estado compartilhado
Redis aparece como backend de estado porque o limitador precisa de leitura e atualização rápidas, com possibilidade de compartilhamento entre múltiplas instâncias. O processo do microserviço permanece stateless, enquanto os contadores e janelas ficam em Redis ou, em cenários específicos, em memória local. Essa separação permite escalar horizontalmente os serviços sem perder consistência básica do controle distribuído.

## Estratégias de limitação no nível do HLD
Retomando o cenário do rate limiter, as estratégias de fixed window e token bucket aparecem no HLD não para detalhar algoritmo, mas para registrar a direção arquitetural. A primeira é útil para limites por janela temporal fixa; a segunda lida melhor com rajadas e recomposição gradual de capacidade. No documento de alto nível, o importante é explicitar que estratégias diferentes atendem perfis distintos de tráfego e influenciam modelagem de estado e chaves.

## Topologia e componentes principais
Como já visto no HLD, componentes e interfaces públicas aparecem aqui apenas no nível necessário para orientar a solução. O desenho inclui microserviço hospedeiro, SDK de rate limiting, Redis, telemetria e, em produção, eventual orquestração com Kubernetes. Dentro do SDK, o ponto central é um check síncrono que recebe identidade, rota, método e plano, resolve a política aplicável e devolve decisão com metadados como `Retry-After` e headers de limite.

## Fluxo principal da requisição
O fluxo em alto nível começa quando a requisição atinge o serviço e passa primeiro pelo middleware do SDK. Em seguida, a identidade é composta a partir de elementos como API key, tenant, IP, rota e método HTTP; a política correta é resolvida; o estado é consultado em Redis ou memória; e a decisão retorna como permissão ou bloqueio. Se o limite for excedido, o host responde com `429 Too Many Requests`; se for aceito, a requisição segue e a telemetria registra métricas, logs e tracing.

## PII na composição das chaves
A composição das chaves de rate limiting precisa considerar PII porque identificadores como IP e dados de cliente podem vazar informação sensível se forem gravados de forma ingênua. O HLD não define a implementação exata da proteção, mas registra a exigência de não expor diretamente dados identificáveis nas estruturas de estado e observabilidade. Isso importa porque a chave técnica usada para contagem também é um ponto potencial de risco regulatório e operacional.

## Hot keys em Redis
Hot keys surgem quando muitas requisições concentram leitura e escrita na mesma chave do Redis, criando contenção e degradando latência. Em um rate limiter, isso pode acontecer quando muitos clientes compartilham um mesmo escopo global ou quando a estratégia de chaveamento concentra tráfego demais em poucos identificadores. O HLD precisa registrar esse risco porque ele afeta diretamente a meta de P95 e pode exigir particionamento, granularidade melhor de chave ou revisão de política.

## Fallback open como decisão arquitetural
Fallback open significa liberar a requisição quando o mecanismo de limitação falha, por exemplo em indisponibilidade de Redis. Essa é uma decisão arquitetural, não um detalhe de código, porque troca rigor de proteção por continuidade de acesso ao sistema em situações degradadas. O documento precisa explicitar essa escolha para que todos entendam o trade-off: reduz-se o risco de indisponibilidade para usuários legítimos, mas aceita-se exposição temporária a sobrecarga.

## Observabilidade e riscos no nível certo
Segurança, observabilidade e riscos arquiteturais já fazem parte da estrutura esperada de um HLD; aqui o avanço está em como eles se concretizam no exemplo. Observabilidade inclui métricas, logs, tracing e integração com Prometheus e OpenTelemetry para acompanhar latência, falhas e decisões do limitador. Entre os riscos principais estão Redis indisponível ou particionado, configuração incorreta bloqueando tráfego legítimo, hot keys e exposição de PII.

## Limite entre arquitetura e implementação
O documento mostra interfaces como `check`, contexto, identidade, escopo, decisão, `next` e `render`, mas não detalha contratos completos, campos finais nem código. Esse é o limite correto entre arquitetura e implementação: o leitor entende como a solução se organiza, quais decisões foram tomadas e onde estão os riscos, sem confundir o HLD com um Low Level Design. Quando a equipe precisar definir estruturas exatas, contratos e regras operacionais, o próximo passo será um documento de nível mais baixo.


https://devfullcycle.notion.site/HLD-Rate-Limiter-2981423c0388803c904ac92eeb11a049