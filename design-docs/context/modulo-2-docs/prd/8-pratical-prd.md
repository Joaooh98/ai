## Rate limiter centralizado como feature de produto
Retomando a lógica do PRD de feature, o rate limiter agora aparece em um cenário mais técnico: um serviço centralizado usado por todos os microserviços da plataforma. Ele existe para controlar volume de requisições por chave de API e por IP, reduzindo sobrecarga e protegendo disponibilidade. Quando essa decisão é centralizada, o comportamento de limitação deixa de ficar espalhado entre serviços e passa a ser governado de forma consistente.

## Objetivos e métricas aplicados ao exemplo
Os objetivos já conhecidos no PRD de feature ganham aqui uma forma operacional muito clara: reduzir indisponibilidade, limitar abuso e preservar desempenho. Isso se traduz em métricas como tempo de indisponibilidade abaixo de um minuto, proporção de respostas 429 e latência P95 inferior a 150 ms. A utilidade prática dessas métricas é transformar proteção de plataforma em algo verificável, e não apenas em intenção genérica de robustez.

## Escopo técnico e limites da entrega
O escopo inclui limitação por chave de API e por IP, controle de burst e uso de janela deslizante, além do retorno de bloqueio com status 429. Fora do escopo ficam capacidades adjacentes, como fila de prioridade, console em tempo real, API administrativa e operação multi-região. Essa delimitação impede que uma feature de proteção de tráfego se transforme prematuramente em plataforma completa de governança.

## Fluxo principal e legibilidade para IA
Quando o PRD explicita o fluxo principal — cliente envia requisição, o rate limiter identifica o chamador, verifica o limite e decide permitir ou bloquear — a feature deixa de ser apenas uma lista de requisitos soltos. Esse encadeamento melhora entendimento humano e também fornece contexto sequencial para IA, que passa a inferir menos e operar mais sobre comportamento declarado. Fluxos alternativos e erros previstos completam essa leitura ao mostrar o que acontece quando o limite já foi atingido.

## Headers padrão de rate limit
Headers padrão de rate limit tornam a limitação observável para os clientes que consomem a API. Em vez de receber apenas um bloqueio opaco, o consumidor passa a ter sinais explícitos sobre limite, uso e eventual tempo de espera, o que melhora adaptação do cliente e reduz comportamento agressivo por desconhecimento. Em um PRD consumido por times e agentes, registrar esses headers evita ambiguidade sobre o contrato de resposta.

## Burst e janela deslizante
Controle de burst lida com picos curtos de tráfego sem tratar todo excesso como abuso imediato. A janela deslizante distribui a contagem ao longo do tempo de forma mais precisa do que janelas fixas, reduzindo efeitos artificiais de borda e tornando a limitação mais justa. No exemplo, essa escolha mostra que o comportamento do rate limiter não é apenas “contar requisições”, mas definir uma política temporal coerente com uso real.

## Redis para contadores de janela
Redis aparece como storage principal para contadores porque oferece operações rápidas e adequadas para controle de estado efêmero em alta frequência. Em um rate limiter, a necessidade central é registrar e consultar contagens por chave e por intervalo com baixa latência, o que combina bem com esse tipo de armazenamento em memória. O risco correspondente também precisa ser documentado: se Redis ficar indisponível, a política de limitação pode falhar ou bloquear incorretamente.

## Observabilidade com Prometheus e OpenTelemetry
Prometheus e OpenTelemetry entram no exemplo para tornar o rate limiter mensurável e rastreável em produção. Prometheus ajuda a expor e coletar métricas como volume de bloqueios, latência e taxa de erro, enquanto OpenTelemetry permite instrumentar traces e sinais operacionais entre serviços. Essa combinação é importante porque uma feature de proteção só é confiável quando o time consegue observar seu efeito real no tráfego e diagnosticar desvios.

## Arquitetura e trade-offs do exemplo
A arquitetura registrada no PRD é suficiente para enquadrar a solução sem substituir o design doc: microserviço dedicado, back-end em Go, Redis, middleware e integração HTTP com consumidores. Os trade-offs explicitam escolhas estruturais, como usar Go para a implementação, Redis como armazenamento principal e REST como forma de exposição. Isso transforma preferências implícitas em decisões rastreáveis, úteis tanto para o time quanto para automações.

## PRD exportado em JSON
O mesmo PRD que existe em Markdown pode ser exportado em JSON para ganhar estrutura legível por máquina. Markdown favorece leitura humana e revisão rápida; JSON favorece processamento sistemático, validação de campos, filtragem e consumo por agentes. A representação em JSON não substitui o documento textual, mas funciona como contrato estruturado da mesma informação.

## JSON como formato para agentes de IA
Agentes de IA trabalham melhor quando o contexto está organizado em campos previsíveis, em vez de depender apenas de interpretação livre de texto corrido. Em JSON, seções como objetivos, escopo, requisitos, riscos e critérios de aceitação podem ser acessadas de forma determinística, o que reduz ambiguidade e melhora automação. Isso é especialmente útil quando o PRD precisa alimentar prompts, pipelines, validações ou geração de artefatos técnicos.

## Quando vale usar Markdown e quando vale usar JSON
Markdown continua sendo a forma mais prática para leitura, edição e discussão entre pessoas. JSON passa a valer mais quando o documento precisa ser consumido por agentes, filtrado programaticamente ou transformado em entrada padronizada para outras etapas. A escolha, portanto, não é exclusiva: manter as duas saídas preserva legibilidade para humanos e estrutura para sistemas.


https://devfullcycle.notion.site/PRD-de-Feature-2941423c03888001a8a3e4e27e9b3add