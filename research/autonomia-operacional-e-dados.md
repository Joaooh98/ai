# Deep Research: oficina de engenharia de IA autônoma

**Objetivo:** evoluir a oficina para escolher e combinar as práticas mais eficazes de engenharia de IA — workflows, harnesses, grafos, loops, agentes, busca, dados e código determinístico — para construir soluções e atuar em sistemas existentes com poucas interações humanas.  
**Data:** 28 de agosto de 2026.

## Conclusão direta

Sua ferramenta já tem a parte mais difícil da base: estado persistido em artefatos, papéis separados, gates determinísticos, metas quantitativas e fluxo de incidente. Porém, ela deve deixar de se definir principalmente como “equipe de agentes”. O produto mais durável é uma **oficina de sistemas de IA compostos**: escolhe a arquitetura apropriada para cada problema e usa agentes somente quando a decisão dinâmica realmente agrega valor.

Para chegar a uma autonomia maior, ela precisa ganhar uma camada que hoje está implícita: um **control plane de autonomia** entre modelos, workflows, código, banco, infraestrutura e produção.

Esse control plane decide, sem depender da opinião do LLM:

1. qual identidade e capacidade a execução recebe;
2. quais ações são permitidas, bloqueadas ou exigem aprovação;
3. quanto tempo, dinheiro, dados e impacto a tarefa pode consumir;
4. como pausar, retomar, cancelar e recuperar a execução;
5. quais evidências permitem promover ou reverter uma mudança.

Pouca interação humana é viável quando o trabalho é **isolado, decomposto, verificável e reversível**. A evidência atual não sustenta um agente com credenciais amplas fazendo SQL ou deploy livre em produção. Pesquisas de horizonte de tarefas mostram que a confiabilidade cai à medida que a tarefa se alonga; benchmarks reais também dependem fortemente da qualidade do ambiente, das ferramentas e dos verificadores ([METR](https://arxiv.org/abs/2503.14499), [SWE-bench Verified](https://openai.com/index/introducing-swe-bench-verified/)).

## A unidade central não é o agente: é o sistema de IA composto

Um sistema composto combina modelos com retrievers, ferramentas, regras, grafos, memória, simuladores, avaliadores e orquestradores. Essa taxonomia é mais apropriada para a oficina do que “multiagente”, porque permite resolver uma tarefa sem agente algum quando uma pipeline determinística é superior ([survey de Compound AI Systems](https://arxiv.org/abs/2506.04565)).

A oficina deve aplicar uma escada de seleção:

| Ordem | Mecanismo | Use quando |
|---|---|---|
| 1 | código/regra determinística | entrada, saída e regra são conhecidas |
| 2 | retrieval, SQL ou grafo de conhecimento | a lacuna é encontrar fatos e relações |
| 3 | workflow/graph explícito | caminhos, estados e checkpoints são previsíveis |
| 4 | loop com evaluator | existe critério objetivo e a saída pode ser refinada |
| 5 | agente com ferramentas | os passos não podem ser enumerados antecipadamente |
| 6 | múltiplos agentes | há subtarefas realmente independentes ou perspectivas adversariais |

Subir nessa escada aumenta flexibilidade, mas também custo, variância e superfície de falha. A decisão deve ser registrada no plano: “por que este problema precisa de um agente ou grafo, em vez de código ou workflow?”.

## As disciplinas que a oficina precisa incorporar

### Harness engineering

É a engenharia do substrato que envolve o modelo: como ele observa o projeto, recebe contexto, chama ferramentas, executa, recebe feedback, verifica conclusão, persiste estado e respeita permissões. A formulação acadêmica recente descreve a capacidade como resultado de **modelo + harness + ambiente**, não apenas do modelo ([AI Harness Engineering](https://arxiv.org/abs/2605.13357)). Relatos de engenharia de 2026 também enfatizam sensores e feedback do ambiente ([Thoughtworks](https://www.thoughtworks.com/insights/blog/generative-ai/harness-engineering-agent-feedback-exploring-ai-coding-sensors)).

A oficina já possui partes do harness — skills, hooks, toolbelt, gates e artefatos — mas falta tratá-las como um produto mensurável. Cada harness deveria declarar:

- tarefa e ambiente alvo;
- ferramentas e sensores disponíveis;
- política de contexto e compactação;
- estado persistente e recuperação;
- verificadores de conclusão;
- limites de tempo, tokens, custo e efeitos;
- conjunto de evals que prova sua utilidade.

### Graph engineering

Aqui “grafo” tem três significados que não devem ser misturados:

1. **grafo de execução:** nós executam código/modelo/ferramenta; arestas controlam transição e estado;
2. **grafo de conhecimento:** representa entidades e relações do domínio;
3. **grafo de software:** símbolos, chamadas, dependências, APIs, filas, tabelas e ownership.

Graph engineering, no sentido emergente de 2026, é desenhar workflows stateful como grafos, combinando caminhos determinísticos e passos de decisão. LangGraph define explicitamente `State`, `Nodes` e `Edges`, além de checkpoints e breakpoints ([Graph API](https://langchain-ai.github.io/langgraph/how-tos/state-reducers/)). A própria LangChain ressalta que grafos servem bem quando existe estrutura previsível, enquanto pesquisa aberta pode funcionar melhor com um harness mais livre ([Graph Engineering](https://www.langchain.com/blog/3-years-of-graph-engineering-with-langgraph)).

Para a oficina, o grafo de execução deveria substituir a sequência implícita em Markdown quando houver branching, retry, pausa, compensação ou retomada. O Markdown continua como contrato humano; a máquina de estados passa a ser executável.

### Loop engineering

Loop engineering é ainda mais recente. O problema real por trás do termo é projetar ciclos sustentados que não virem repetição infinita ou desperdício:

```text
observar -> escolher ação -> executar -> medir -> avaliar
         -> corrigir / escalar / concluir / abortar
```

O loop precisa ter:

- invariante e objetivo mensurável;
- condição de progresso;
- orçamento por iteração e global;
- detecção de repetição e estagnação;
- diversidade controlada de estratégia após falha;
- evaluator independente do executor;
- critério explícito de conclusão, pausa e aborto;
- checkpoint e resumo entre janelas de contexto.

O termo ganhou pesquisas e benchmarks próprios em 2026, mas ainda é emergente; deve ser tratado como uma disciplina útil, não como padrão universal ([LoopsBench](https://arxiv.org/abs/2608.00267)).

### Evaluation engineering

Evals não são apenas um portão final. Eles orientam a escolha de modelo, prompt, ferramenta, graph e harness. A unidade avaliada deve ser o sistema completo e a trajetória, com múltiplas tentativas e validação do estado final. Anthropic define o evaluation harness como a infraestrutura que executa evals ponta a ponta ([Anthropic](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents)).

Cada capacidade da oficina deveria ter:

- dataset de tarefas reais e falhas históricas;
- graders determinísticos quando possível;
- teste de outcome, trajetória, custo e segurança;
- baseline contra workflow simples e contra humano;
- execução repetida para medir variância;
- promoção somente quando a melhoria atravessar um limiar declarado.

### Context, retrieval e memory engineering

Contexto é uma janela de trabalho, retrieval seleciona evidência e memória preserva estado útil entre execuções. Não devem ser um único arquivo crescente. A oficina precisa medir precisão de recuperação, freshness, contaminação, custo e impacto da compactação.

### Tool e environment engineering

Ferramentas pequenas, tipadas e verificáveis são parte da inteligência do sistema. O ambiente deve fornecer sensores rápidos: testes focados, compilador, linter, traces, banco governado, navegador, feature flags e simuladores. O agente não deve reconstruir via raciocínio o que o ambiente pode medir diretamente.

### Policy e safety engineering

Permissão não é instrução em prompt. Identidade, autorização, orçamento, escopo de dados e efeitos externos devem ser aplicados pelo runtime. Essa disciplina une o control plane, OPA, credenciais efêmeras, sandbox, auditoria e kill switch.

## Arquitetura recomendada

```text
Objetivo / ticket / alerta
        |
        v
Autonomy Controller
  - classifica risco e ambiente
  - cria execução durável e orçamento
  - emite identidade temporária
  - consulta políticas externas ao LLM
        |
        +--> Workspace efêmero --> build / testes / PR
        |
        +--> MCP Data Gateway --> catálogo / métricas / réplica read-only
        |
        +--> Observability Gateway --> logs / traces / métricas / incidentes
        |
        +--> Deployment Gateway --> dry-run / canary / promover / rollback
        |
        v
Gates determinísticos + Policy Engine
        |
        +--> permitido automaticamente
        +--> pausa para aprovação
        +--> bloqueado com explicação e audit_id
```

O agente propõe e executa dentro das capacidades recebidas. O policy engine decide se a ação pode ocorrer. O gate verifica o resultado. Essa separação é coerente com OPA como Policy Decision Point e com decision logs auditáveis ([OPA](https://www.openpolicyagent.org/docs/deploy), [decision logs](https://www.openpolicyagent.org/docs/management-decision-logs)).

## 1. Autonomia graduada por risco

Adote níveis explícitos em vez de “manual” versus “autônomo”:

| Nível | Capacidade | Exemplos | Interação humana |
|---|---|---|---|
| A0 — observar | Consultar código, docs, métricas e réplica de dados | diagnóstico, mapa de dependências | nenhuma |
| A1 — preparar | Alterar worktree efêmero e produzir evidência | teste, patch, documentação, PR draft | nenhuma |
| A2 — integrar | Abrir PR e fazer merge se todos os gates passarem | correção pequena e reversível | só em exceção |
| A3 — entregar | Deploy canário e promoção por SLO | serviço stateless com rollback testado | aprovação inicial por classe de mudança |
| A4 — operar | Mitigações tipadas e reversíveis | rollback, feature flag, scale-out | automático dentro de política |
| A5 — mutar estado crítico | Dados, schema, IAM, secrets, exclusão | migração, update em massa | aprovação obrigatória ou proibido |

OpenAI e Anthropic convergem no uso de workflows verificáveis e intervenção em ações de alto risco ([OpenAI](https://openai.com/business/guides-and-resources/a-practical-guide-to-building-ai-agents/), [Anthropic](https://www.anthropic.com/engineering/building-effective-agents)). OWASP classifica permissões e autonomia excessivas como risco direto ([OWASP LLM06](https://genai.owasp.org/llmrisk/llm062025-excessive-agency/)).

### Artefato novo

Adicionar `.claude/autonomy.yaml` por projeto:

```yaml
default_level: A1
environments:
  development: { max_level: A3 }
  staging:     { max_level: A3 }
  production:  { max_level: A2 }
policies:
  - action: data.query
    allow: [development, staging, production]
    constraints: { readonly: true, max_rows: 1000, timeout_ms: 5000 }
  - action: deploy.canary
    allow: [staging]
  - action: production.rollback
    allow: [production]
    when: incident_declared && rollback_target_verified
  - action: data.write
    require_approval: true
  - action: schema.drop
    deny: true
```

O arquivo deve ser interpretado por código determinístico ou OPA, nunca pelo modelo.

## 2. MCP Data Gateway: conhecimento de dados sem entregar o banco ao agente

O melhor desenho não é registrar uma connection string num MCP genérico. O repositório oficial de servidores MCP alerta que exemplos de referência não são automaticamente adequados para produção; o antigo servidor PostgreSQL read-only está arquivado ([MCP servers](https://github.com/modelcontextprotocol/servers), [PostgreSQL arquivado](https://github.com/modelcontextprotocol/servers-archived/tree/main/src/postgres)).

Crie um gateway mantido pela própria oficina, com ferramentas pequenas:

- `data.catalog.search(term)`
- `data.dataset.describe(dataset)`
- `data.lineage.get(dataset)`
- `data.metric.run(metric, dimensions, filters, time_range)`
- `data.rows.sample(dataset, columns, filters, limit)`
- `data.query.explain(query_id, parameters)`
- `data.health.replica()`

Evite `execute_sql(sql)` no primeiro estágio. Em workloads empresariais, text-to-SQL sofre com schemas extensos, metadata e múltiplos dialetos; a interface tipada restringe o espaço de erro e permite política por ferramenta. RAG deve responder significado — documentação, glossário, contratos e runbooks — enquanto SQL ou uma camada semântica responde fatos atuais e agregações.

### Defesa em profundidade

O gateway deve aplicar simultaneamente:

- conta sem `SUPERUSER`, ownership, DDL ou `BYPASSRLS`;
- acesso somente a schemas, views e colunas aprovados;
- réplica de leitura ou warehouse como destino padrão;
- transação `READ ONLY` e `default_transaction_read_only`;
- RLS/ABAC, preferencialmente default-deny;
- `statement_timeout`, `lock_timeout` e timeout de sessão;
- limite de linhas, bytes, custo, concorrência e tamanho da resposta;
- `EXPLAIN`/estimativa antes de consultas caras;
- mascaramento e tokenização de PII antes de chegar ao modelo;
- resposta com proveniência e frescor.

PostgreSQL documenta RLS default-deny, transações read-only, timeouts e hot standbys que aceitam consultas de leitura ([RLS](https://www.postgresql.org/docs/18/ddl-rowsecurity.html), [configuração](https://www.postgresql.org/docs/18/runtime-config-client.html), [replicação](https://www.postgresql.org/docs/18/high-availability.html)). Uma réplica pode estar atrasada; toda resposta precisa declarar esse limite.

### Contrato da resposta

```json
{
  "data": [],
  "source": "orders_analytics.order_summary",
  "as_of": "2026-08-28T14:32:00Z",
  "replica_lag_ms": 420,
  "row_count": 217,
  "truncated": false,
  "policy_decision": "allow",
  "audit_id": "aud_01J...",
  "sensitivity": ["internal"],
  "cost": {"estimated_units": 3}
}
```

Dados retornados devem ser tratados como conteúdo não confiável. AgentDojo demonstra prompt injection indireta por dados vindos de ferramentas ([paper](https://arxiv.org/abs/2406.13352)). Portanto, strings do banco nunca se tornam instruções, memória ou política sem validação.

## 3. Identidade temporária e revogável

Cada execução deve receber uma identidade própria, vinculada a projeto, tarefa, ambiente e conjunto de capacidades. Não reutilize token humano nem armazene senha de banco em `.mcp.json`.

Para MCP remoto, use OAuth 2.1 com audience/resource binding. A especificação proíbe token passthrough e recomenda tokens curtos para reduzir impacto de vazamento ([MCP Authorization](https://modelcontextprotocol.io/specification/2025-06-18/basic/authorization)). Para banco, use identidade IAM ou credencial dinâmica com TTL. Vault gera usuários únicos, leases e revogação, o que melhora atribuição e resposta a incidentes ([Vault Database Secrets](https://developer.hashicorp.com/vault/docs/secrets/databases)).

Implemente:

- `execution_id` como identidade de auditoria;
- token de 5–15 minutos, renovável somente enquanto a execução estiver saudável;
- escopos como `data:catalog`, `data:read:orders`, `deploy:canary`;
- kill switch que cancela workflows e revoga todos os leases da execução;
- proibição de segredo em prompt, trace, artefato ou configuração versionada.

## 4. Execução durável

Hoje a oficina persiste estado em arquivos, o que é bom para retomada humana. Autonomia de horas ou dias precisa também de uma máquina de execução durável:

- checkpoints após cada efeito externo;
- retries limitados e classificados por erro;
- timeout e deadline global;
- cancelamento cooperativo;
- idempotency key em toda ação mutável;
- compensação quando rollback transacional não alcança o efeito externo;
- fila de aprovação que pode pausar e retomar sem perder estado.

Temporal descreve workflows que sobrevivem a falhas e podem executar por segundos ou anos ([Temporal](https://github.com/temporalio/documentation/blob/main/docs/encyclopedia/workflow/workflow-execution/workflow-execution.mdx)). Não é obrigatório adotar Temporal imediatamente; o requisito arquitetural é o journal durável. Um MVP pode usar SQLite/PostgreSQL e uma state machine explícita.

Estados mínimos:

```text
QUEUED -> DISCOVERING -> PLANNED -> EXECUTING -> VERIFYING
       -> WAITING_APPROVAL -> DEPLOYING -> OBSERVING -> SUCCEEDED
       -> COMPENSATING -> FAILED | CANCELLED
```

## 5. Observabilidade do agente e do resultado

Adicione um trace por execução, com spans filhos para:

- geração/modelo;
- chamada de ferramenta;
- consulta de política;
- query de banco;
- build/teste;
- criação de PR;
- deploy, canário, promoção e rollback;
- espera por aprovação.

OpenTelemetry já define atributos para operações GenAI e ferramentas, inclusive datastore, mas alerta que argumentos e resultados podem conter informações sensíveis ([OpenTelemetry](https://opentelemetry.io/docs/specs/semconv/registry/attributes/gen-ai/)). Registre hashes, IDs, contagens e classificações; conteúdo integral deve ser opt-in e sanitizado.

Métricas recomendadas:

- taxa de conclusão sem interação;
- interações humanas por tarefa;
- taxa de rollback e escape para produção;
- tempo até primeira evidência e tempo total;
- retries, loops e custo por resultado aceito;
- violações de política e tentativas bloqueadas;
- consultas por dataset, custo, linhas e timeouts;
- precisão das decisões de promoção/rollback.

## 6. Construção e entrega autônomas

Transforme o fluxo atual numa esteira fechada:

```text
reproduzir -> teste falhando -> patch -> testes -> análise estática
-> review independente -> PR -> merge protegido
-> canário -> observar SLO + métrica de negócio -> promover ou rollback
```

Gates externos continuam obrigatórios. Branch protection e ambientes protegidos podem exigir status checks e controlar secrets de deploy. Para Kubernetes, Argo Rollouts oferece canary/blue-green, análise de KPIs e promoção/rollback automáticos ([Argo Rcrie uma agente nesse repositorio que vai ficar responsavel somente por configurar os projetos que tenho cadastrado nessa ferramentaollouts](https://argoproj.github.io/rollouts/), [Analysis](https://argoproj.github.io/argo-rollouts/features/analysis/)).

Não automatize inicialmente:

- migração destrutiva;
- alteração de IAM, segredos ou rede;
- mudança sem teste ou sem rollback conhecido;
- deploy sem SLO e métricas de negócio;
- correção de produção sem causa confirmada, salvo mitigação reversível previamente tipada.

## 7. Memória operacional confiável

O histórico de chat não deve ser a memória principal. Continue usando arquivos, mas separe:

- **fatos observados:** schema, versão, SLO, owners, comandos verificados;
- **decisões:** ADRs, políticas e aprovações;
- **estado efêmero:** tarefa, hipótese atual, retries e leases;
- **lições candidatas:** padrões inferidos ainda não validados;
- **lições promovidas:** aprendizado confirmado por evidência ou revisão.

Toda memória precisa de `source`, `observed_at`, `valid_until`, `scope`, `sensitivity` e `confidence`. Memória expirada deve provocar nova coleta. Conteúdo vindo de ticket, banco, log ou página externa nunca deve ser promovido automaticamente, pois memória persistente é alvo de poisoning ([OWASP Agent Security](https://cheatsheetseries.owasp.org/cheatsheets/AI_Agent_Security_Cheat_Sheet.html)).

## 8. Alterações concretas no repositório

### Novos componentes

```text
autonomy/
  controller/           state machine e orçamento
  policy/               políticas OPA/Rego ou engine equivalente
  risk/                 classificação determinística
  audit/                eventos append-only

mcp/data-gateway/
  tools/                catálogo, métricas, sample e explain
  adapters/             postgres, warehouse, catálogo
  policy/               schemas, colunas, RLS e limites
  tests/                permissões negativas e exfiltração

tools/
  autonomy-check.sh     decide nível máximo e aprova/bloqueia ação
  data-access-check.sh  valida gateway, réplica, role, RLS e timeouts
  run-state.sh          consulta execução durável
  kill-switch.sh        cancela execução e revoga credenciais

skills/
  operate/              objetivo operacional de baixo risco
  autonomous-fix/       issue/alerta -> PR -> canário
  data-investigate/     investigação usando ferramentas tipadas
  approve-action/       explica e retoma checkpoint
```

### Evoluções em componentes existentes

- `/setup`: descobrir fontes de dados, classificação, owners, SLOs, réplica e operações permitidas.
- `.claude/toolbelt.md`: registrar apenas capacidades verificadas; nunca credenciais.
- `mcp/catalog.tsv`: adicionar campos `trust`, `write_capable`, `auth`, `data_classes`, `last_security_review` e `sandbox`.
- hooks: cobrir ferramentas MCP e ações externas, não apenas `Write|Edit|Bash`.
- gates 3/4: consultar policy decision, trace completo, rollback testado e janela de observação.
- `/nightly`: permitir abrir PR automaticamente para correções A1/A2, mantendo deploy separado.
- `/incident`: automatizar apenas mitigações tipadas e reversíveis autorizadas por política.
- `.claude/meta.tsv`: incluir limites de autonomia, custo, query, rollout e interação humana.

## Roadmap recomendado

### Fase 1 — autonomia de leitura e diagnóstico

1. Criar `.claude/autonomy.yaml` e taxonomia A0–A5.
2. Criar audit log único com `execution_id` e `decision_id`.
3. Instrumentar tools e agentes com OpenTelemetry, sem conteúdo sensível.
4. Implementar MCP Data Gateway read-only para uma réplica de homologação.
5. Adicionar catálogo/glossário e conjunto dourado de 30–50 perguntas reais.

**Gate:** nenhuma query alcança o primário; testes negativos provam que DDL/DML, PII e datasets não autorizados são bloqueados.

### Fase 2 — correção autônoma até PR

1. Criar worktree/container efêmero por tarefa.
2. Implementar journal/checkpoints, timeout, retries e cancelamento.
3. Issue ou rotina nightly pode produzir PR com testes e evidências.
4. Merge automático apenas para classes A1/A2 com branch protection.
5. Criar kill switch e revogação de credenciais.

**Gate:** 20 tarefas históricas executadas múltiplas vezes; nenhuma alteração fora do escopo; outcome verificado pelo estado final, não pela mensagem do agente.

### Fase 3 — deploy autônomo controlado

1. Definir SLO e métrica de negócio por serviço.
2. Introduzir canary/blue-green e rollback automático.
3. Liberar A3 somente para serviços com rollback provado.
4. Observar após deploy antes de promover.
5. Suspender autonomia automaticamente quando error budget ou confiança cair.

**Gate:** game days demonstram promoção, abort e rollback; schema/data migrations ficam fora.

### Fase 4 — escritas de negócio tipadas

1. Criar ferramentas como `cancel_order` ou `reprocess_payment`, nunca SQL genérico.
2. Exigir dry-run, precondições, limite de linhas e idempotency key.
3. Usar credencial efêmera separada da leitura.
4. Começar em staging e shadow mode.
5. Autoaprovar somente operações repetidas, reversíveis e com histórico de evals.

**Gate:** testes de concorrência, replay, duplicação, timeout, compensação e prompt injection passam.

## KPIs para saber se a autonomia melhorou

Não use “quantidade de agentes” como métrica. Meça:

- `% de tarefas concluídas sem interação` por nível de risco;
- `interações humanas / tarefa aceita`;
- `% de decisões automáticas posteriormente revertidas`;
- `change failure rate` e `escaped defects` comparados ao baseline humano;
- tempo de diagnóstico, PR, deploy e recuperação;
- custo total por tarefa aceita, incluindo revisão e rollback;
- precisão do gateway de dados no conjunto dourado;
- número de violações de política prevenidas;
- consultas canceladas por custo/timeout e impacto evitado;
- freshness e cobertura dos dados disponíveis ao agente.

## Decisão recomendada

O primeiro incremento deve ser **A0/A1 + MCP Data Gateway read-only + audit trail**. Ele entrega conhecimento real do sistema e dos dados, reduz suas interações durante diagnóstico e construção, e cria a base de identidade/política necessária para qualquer autonomia de escrita futura.

Depois, avance até PR automático. Deploy autônomo só deve entrar quando a mesma ferramenta já consegue provar, em tarefas históricas e game days, que sabe pausar, retomar, limitar impacto e reverter sozinha.
