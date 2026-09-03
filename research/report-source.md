# Fonte canônica — oficina de engenharia de IA autônoma

**Audiência:** mantenedor da oficina de agentes  
**Data:** 2026-08-28  
**Escopo:** práticas 2024–2026 para sistemas de IA compostos construírem e operarem sistemas existentes com poucas interações humanas, incluindo harness engineering, graph engineering, loop engineering, evals e acesso seguro a bancos.

## Resposta executiva

A oficina já possui uma boa base de autonomia verificável: artefatos persistentes, gates com exit code, especialistas, metas quantitativas e separação de responsabilidades. Ela deve se posicionar como oficina de sistemas de IA compostos, não como biblioteca de agentes: código determinístico, retrieval, grafos, loops, modelos, ferramentas e humanos são mecanismos intercambiáveis. A evolução recomendada não é conceder acesso irrestrito, mas criar um plano de controle independente do modelo. Esse plano deve classificar risco, emitir credenciais efêmeras, aplicar políticas por ação, executar trabalhos de forma durável, observar cada ferramenta e promover mudanças progressivamente com rollback automático.

Para dados, o modelo não deve receber credencial de produção nem SQL de escrita arbitrário. A interface recomendada é um MCP Data Gateway com ferramentas de domínio, conectado inicialmente a uma réplica de leitura ou warehouse. Read-only, RLS, limites de custo/tempo/linhas, mascaramento e auditoria devem ser impostos fora do prompt. Escritas entram depois, por comandos tipados, com dry-run, precondições, idempotência, limite de impacto e política de aprovação.

## Evidência reconciliada

- Autonomia útil hoje concentra-se em tarefas decompostas, verificáveis, reversíveis e isoladas. Pesquisas sobre horizonte de tarefas e benchmarks empresariais ainda não sustentam autonomia irrestrita em produção.
- Execuções longas precisam de estado persistente, retomada após falha, retries limitados e efeitos idempotentes.
- Políticas e gates precisam ser externos ao modelo, pois dados e ferramentas podem carregar prompt injection e induzir uso indevido.
- Credenciais curtas e vinculadas à audiência reduzem exposição; token passthrough é proibido pela especificação MCP.
- SQL livre tem baixa confiabilidade em schemas empresariais e amplia o impacto de prompt injection. Catálogo, camada semântica e ferramentas tipadas reduzem ambiguidade.
- Read replica, transação read-only, RLS e timeouts são controles complementares, não alternativas.
- Tracing deve cobrir a execução completa, mas prompts, argumentos e resultados podem conter segredos ou PII e precisam de sanitização.
- Canary/blue-green com métricas permite promoção ou rollback automáticos e reduz blast radius.

## Limitações

- Não foi escolhido um provedor de nuvem ou banco único; os controles foram descritos de modo portável, usando PostgreSQL como implementação de referência.
- Métricas e limiares exatos dependem dos SLOs, volume, regulação e tolerância a atraso de cada projeto.
- Benchmarks de agentes envelhecem rapidamente e simplificam sistemas privados; por isso as recomendações enfatizam evals internos e controle de risco.
- Nenhuma defesa geral contra prompt injection em agentes com ferramentas está estabelecida. O desenho usa defesa em profundidade e redução de capacidade.

## Ledger de fontes principais

| Alegação | Fonte | Publicador/autor | Data | URL |
|---|---|---|---|---|
| Autonomia deve ser graduada e interrompida em ações de alto risco | A practical guide to building agents | OpenAI | 2025 | https://openai.com/business/guides-and-resources/a-practical-guide-to-building-ai-agents/ |
| Execuções com aprovação podem ser pausadas e retomadas | Human-in-the-loop | OpenAI Agents SDK | atual | https://openai.github.io/openai-agents-python/human_in_the_loop/ |
| Workflows simples e verificáveis são preferíveis quando os passos são previsíveis | Building Effective AI Agents | Anthropic | 2024-12-19 | https://www.anthropic.com/engineering/building-effective-agents |
| Agentes precisam de sandbox e rede limitada | Claude Code sandboxing | Anthropic | 2025 | https://www.anthropic.com/engineering/claude-code-sandboxing |
| Excessive agency exige reduzir ferramentas, permissões e autonomia | LLM06:2025 Excessive Agency | OWASP | 2025 | https://genai.owasp.org/llmrisk/llm062025-excessive-agency/ |
| Dados de ferramentas podem sequestrar agentes | AgentDojo | Debenedetti et al., NeurIPS | 2024 | https://arxiv.org/abs/2406.13352 |
| Execução durável retoma workflows após falhas | Workflow Execution | Temporal | atual | https://github.com/temporalio/documentation/blob/main/docs/encyclopedia/workflow/workflow-execution/workflow-execution.mdx |
| MCP exige audience binding e proíbe token passthrough | MCP Authorization | Model Context Protocol | 2025-06-18 | https://modelcontextprotocol.io/specification/2025-06-18/basic/authorization |
| MCP recomenda validação, autorização e consentimento | MCP Specification | Model Context Protocol | 2025-03-26 | https://modelcontextprotocol.io/specification/2025-03-26/index |
| RLS pode operar em default-deny | PostgreSQL Row Security | PostgreSQL Global Development Group | 2026 | https://www.postgresql.org/docs/18/ddl-rowsecurity.html |
| PostgreSQL oferece read-only e timeouts de sessão | Client Connection Defaults | PostgreSQL Global Development Group | 2026 | https://www.postgresql.org/docs/18/runtime-config-client.html |
| Hot standby atende consultas read-only | High Availability | PostgreSQL Global Development Group | 2026 | https://www.postgresql.org/docs/18/high-availability.html |
| Credenciais dinâmicas têm leases e revogação | Database secrets engine | HashiCorp | atual | https://developer.hashicorp.com/vault/docs/secrets/databases |
| OPA separa decisão de política da aplicação e registra decisões | OPA Deployment / Decision Logs | Open Policy Agent | atual | https://www.openpolicyagent.org/docs/deploy |
| Convenções GenAI incluem chamadas e resultados de ferramentas, com alerta de sensibilidade | Gen AI semantic attributes | OpenTelemetry | atual | https://opentelemetry.io/docs/specs/semconv/registry/attributes/gen-ai/ |
| Rollouts podem promover ou abortar por métricas | Argo Rollouts | Argo Project | atual | https://argoproj.github.io/rollouts/ |
| Benchmarks precisam de tarefas verificáveis e ambientes reproduzíveis | SWE-bench Verified | OpenAI | 2024 | https://openai.com/index/introducing-swe-bench-verified/ |
| Capacidade autônoma cai com o comprimento da tarefa | Measuring AI Ability to Complete Long Tasks | METR et al. | 2025 | https://arxiv.org/abs/2503.14499 |
| Capacidade emerge do conjunto modelo, harness e ambiente | AI Harness Engineering | Schmid et al. | 2026 | https://arxiv.org/abs/2605.13357 |
| Grafos representam estado, nós e transições executáveis | Graph API overview | LangChain | atual | https://langchain-ai.github.io/langgraph/how-tos/state-reducers/ |
| Graph engineering é útil quando há estrutura previsível | 3 Years of Graph Engineering with LangGraph | LangChain | 2026-07-22 | https://www.langchain.com/blog/3-years-of-graph-engineering-with-langgraph |
| Loops longos exigem avaliação própria | LoopsBench | autores do paper | 2026 | https://arxiv.org/abs/2608.00267 |
| Sistemas compostos combinam LLM, retrieval, ferramentas e orquestração | Survey of Compound AI Systems | autores do survey | 2025 | https://arxiv.org/abs/2506.04565 |
