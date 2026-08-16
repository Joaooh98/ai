## Contexto técnico do FDD
O FDD desce do desenho arquitetural para comportamento verificável. Retomando o rate limiter já definido no HLD, o foco agora deixa de ser a topologia geral e passa a ser a padronização de como cada microsserviço aplica limites, expõe contratos e reage a falhas. Esse recorte técnico existe porque inconsistência entre serviços produz sobrecarga, integração confusa e implementação divergente. Um SDK embutido em cada serviço resolve isso ao centralizar a lógica in-process e delegar o estado para Redis ou memória local.

## Objetivos técnicos e escopo
Objetivos técnicos transformam intenção em requisitos de implementação: API pública estável, integração por middleware HTTP, suporte a fixed window e token bucket, telemetria nativa, baixa latência e fallback open. O escopo delimita o que a feature realmente entrega, como suporte a Redis Cluster, memória local e geração de headers, e também o que fica de fora, como autenticação, gestão de políticas e estratégias alternativas. Essa separação evita que a implementação absorva responsabilidades que pertencem a outros componentes. Em FDD, exclusão explícita é tão importante quanto funcionalidade incluída.

## API `Check`, `Middleware` e `Decision`
A API pública precisa expor contratos concretos, não apenas a ideia de “aplicar rate limiting”. `Check` representa a operação de decisão síncrona: recebe o contexto da requisição e retorna uma `Decision` com campos observáveis, como permitido ou bloqueado, quantidade restante e `retry_after`. `Middleware` encapsula esse mesmo processo no pipeline HTTP, convertendo a decisão em continuação da requisição ou resposta `429`. A `Decision` existe para separar cálculo interno de efeito externo, o que facilita teste, reuso e consistência entre integração programática e integração via HTTP.

## Semântica de headers de rate limiting
Headers como `RateLimit`, `RateLimit-Reset` e `Retry-After` precisam ter semântica explícita, porque clientes dependem deles para implementar backoff, exibir limites e reagir a bloqueios. O FDD fixa não só quais headers existem, mas o significado operacional de cada valor: quanto resta, quando a janela reinicia e quanto tempo esperar antes de tentar de novo. Essa definição reduz ambiguidade entre serviços e impede que cada implementação publique convenções incompatíveis. Em uma feature de infraestrutura, contrato de header é parte da API pública.

## Estratégias: fixed window e token bucket
Retomando as estratégias já escolhidas, o FDD não reabre a decisão arquitetural; ele especifica como elas se comportam na interface e no runtime. Em `fixed window`, a contagem é agrupada por janela discreta e o reset acompanha esse limite temporal. Em `token bucket`, há recarga contínua por `rate` até um teto de `burst`, permitindo absorver rajadas controladas sem perder enforcement. A utilidade do documento está em tornar essas diferenças implementáveis e testáveis, inclusive nos headers e nos exemplos de uso.

## Padrão `options` para configuração
O padrão `options` organiza configuração incremental sem explodir construtores com muitos parâmetros posicionais. Em vez de uma assinatura rígida e frágil, a criação do rate limiter recebe opções composáveis para storage, estratégia, credenciais, pool e comportamento operacional. Esse formato funciona como um builder idiomático: cada opção altera a configuração final de forma explícita e extensível. Para uma feature com múltiplos modos de execução, `options` melhora legibilidade, compatibilidade futura e ergonomia de uso.

## Validação no construtor
Validação no construtor impede que uma instância inválida exista em runtime. Ao criar o rate limiter, o código precisa verificar se os parâmetros da estratégia são coerentes, se combinações obrigatórias foram fornecidas e se o modo selecionado possui configuração suficiente para operar. Isso desloca erro de produção para erro de inicialização, que é mais barato de detectar e corrigir. Em um componente de infraestrutura, falhar cedo é preferível a aceitar configuração inconsistente e produzir comportamento imprevisível.

## Modos de storage: Redis e memória local
Redis e memória local não são apenas implementações intercambiáveis; cada modo define um comportamento operacional distinto. Redis atende o cenário distribuído, no qual múltiplas instâncias precisam compartilhar estado e aplicar o mesmo limite global. Memória local serve para desenvolvimento ou instâncias isoladas, com a consequência explícita de perder estado ao reiniciar pod ou container. O FDD precisa registrar essa diferença para evitar adoção incorreta de um modo local em cenários que exigem coordenação distribuída.

## Atomicidade em Redis com scripts Lua
Concorrência é um problema central em rate limiting porque múltiplas requisições podem disputar o mesmo contador ao mesmo tempo. Scripts Lua em Redis resolvem isso ao executar leitura, cálculo e atualização como uma operação atômica no servidor, evitando condições de corrida entre clientes concorrentes. Essa escolha protege a correção do limite sem exigir múltiplos round-trips frágeis. Além de consistência, ela ajuda a preservar latência em um caminho síncrono e sensível a desempenho.

## Concorrência em memória com mutex por chave
No modo em memória, atomicidade depende de sincronização local dentro do processo. Um mutex por chave evita que requisições concorrentes atualizem o mesmo identificador de limite simultaneamente, sem serializar desnecessariamente chaves independentes. Isso reduz contenção em comparação com um lock global e preserva paralelismo onde ele é seguro. O FDD precisa explicitar essa decisão porque concorrência correta não é detalhe opcional em um limitador.

## Compatibilidade e dependências
Compatibilidade com Go 1.22 e Redis 6.2 delimita o piso técnico da implementação e evita dependência acidental de recursos mais novos. Dependências como Prometheus, OpenTelemetry, Collector, Linux e arquitetura AMD64 ou ARM deixam de ser contexto implícito e viram requisitos verificáveis de build, execução e observação. Esse nível de detalhe importa porque uma feature pode estar correta em código e ainda falhar por incompatibilidade de ambiente. Em FDD, dependência é condição operacional, não nota de rodapé.

## Segurança e proteção de dados
Proteção de dados aparece aqui de forma concreta: logs, métricas, tracing e chaves não podem vazar identificadores sensíveis como IP em texto cru. O documento precisa indicar uso de TLS entre aplicação e Redis quando disponível, tratamento seguro de credenciais e cuidado com atributos e spans exportados. Segurança, nesse nível, não é um princípio abstrato; é uma restrição sobre o que pode circular em observabilidade e infraestrutura. Isso evita que um componente de controle operacional introduza exposição indevida de dados.

## Fallback open e comportamento em falha
O fallback open já foi decidido antes; o avanço agora é especificar quando ele dispara e qual efeito observável produz. Se houver falha no backend de limitação e o modo permissivo estiver ativo, a requisição segue, mas o sistema precisa registrar logs, métricas e transições de conectividade para que a operação saiba que o enforcement foi relaxado. Sem essa definição, a feature até continua disponível, mas o comportamento fica opaco e difícil de auditar. Fallback útil é fallback explicitamente operacionalizado.

## Observabilidade aplicada ao componente
Observabilidade aqui deixa de ser preocupação arquitetural genérica e vira contrato operacional do componente. Métricas precisam cobrir decisões, erros, fallback e desempenho; logs estruturados precisam registrar eventos relevantes sem expor dados sensíveis; tracing precisa definir atributos e spans que permitam localizar gargalos e falhas. Esse detalhamento é o que torna o comportamento depurável em produção. Um FDD bom não apenas diz que haverá telemetria, ele define o que será observável.

## Critérios de aceite e prontidão para código
Critérios de aceite convertem o documento em checklist verificável para implementação. Contratos funcionando, testes passando, desempenho sob carga validado e resiliência confirmada são sinais objetivos de que a feature está pronta para uso. Isso reduz discussão subjetiva sobre “estar pronto” e alinha desenvolvimento, teste e revisão técnica na mesma referência. Quando o FDD chega a esse nível, ele já serve como ponte direta para tarefas de código.

## Pesquisa técnica como insumo para IA
IA acelera a escrita do documento, mas não inventa requisitos corretos que não foram fornecidos ou compreendidos. Se o autor não souber que scripts Lua, mutex por chave, semântica de headers ou modos de fallback são relevantes, o rascunho tende a omitir exatamente os pontos que mais afetam a implementação. Pesquisa técnica profunda amplia o repertório de decisões que podem ser pedidas e revisadas. O valor da IA cresce quando ela recebe contexto técnico real, não quando substitui entendimento do problema.