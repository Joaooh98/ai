# Grafo de código para os agentes

**Status:** proposto

---

## Problema

Três afirmações que os agentes fazem em toda onda, hoje por **inferência**:

1. *"nada mais usa isso"* — base de toda decisão de mudança segura
2. *"onde eu mexo"* — o agente grepa e lê arquivo inteiro, gastando turnos
3. *"mudar este contrato quebra quem?"* — entre repositórios, ninguém responde

As três são perguntas de **alcançabilidade** — "existe caminho de A até B?". Nenhuma estrutura de
texto responde isso: grep responde "onde aparece este literal", embedding responde "o que é
parecido". Alcançabilidade transitiva exige grafo, e é justamente a classe de pergunta que o
modelo erra em silêncio, com prosa confiante.

## Evidência

Caso real em `crm-api` (510 arquivos Java, 52 com `@Inject`, 26 interfaces).

Pergunta: *"posso mudar `IMessagingProvider.sendMessage`? o que quebra?"*

`grep -rn "sendMessage(" src/main` devolve **10 acertos**, dos quais **5 são símbolos diferentes
que apenas compartilham o nome**: `metaRepository.sendMessage` (×2), `TicketController.sendMessage`
(endpoint HTTP), `TicketMessageService.sendMessage(String, DTO)` (outra assinatura, outra camada).

Pior: o grep **omite** `RecordingMessagingProvider` em `TicketMessageServiceTest:506`, que
implementa a interface e **quebra a compilação** — ficou de fora por estar em `src/test`.

E a aresta que decide a resposta não está no texto em lugar nenhum:

```
TicketMessageService:484  resolveMessagingProvider(...).sendMessage(...)
        └─> MessagingProviderRegistry.require(EnumProvider)
                └─> @Inject Instance<IMessagingProvider>
                        └─> resolvido em RUNTIME pelo enum provider()
                                └─> Meta | Evolution | Zpro
```

A ligação entre a linha 484 e `ZproMessagingProvider.sendMessage` existe apenas no container CDI,
em tempo de execução. Nenhum grep, regex ou embedding a produz.

**Escala do problema:** `crm` = 510 Java + 166 TS. `smart` = 17 repositórios (11 Java/Maven,
6 node/ts) — onde nenhum grep atravessa `dafe-pix` → `dafe-gateway`.

## Proposta

Dois níveis, porque nenhuma ferramenta cobre os dois.

**Nível 1 — MCP pronto, grafo do compilador.** Um servidor MCP baseado em LSP (ex.: Serena) sobe
o mesmo language server do go-to-definition e expõe `find_symbol`, `find_referencing_symbols`,
`find_implementations`. Java e TypeScript são first-class, o que cobre 100% do workspace.

Por que LSP e não índice AST próprio: o grafo do LSP tem resolução de tipo. Um call graph por
tree-sitter, em Quarkus, resolve `svc.doThing()` para o método da **interface** e para ali — erra
exatamente onde o blast radius importa.

**Obrigatório:** modo somente-leitura. Ver Risco.

**Nível 2 — tool nossa, para a fronteira que LSP não cruza.** Nenhum language server atravessa
repositório. Para o `smart`, o grafo tem que ser construído sobre o que de fato cruza: rota HTTP
declarada, nome de evento/fila, tabela. Uma tool no padrão das outras — somente leitura, sem rede
— que responda "este diff toca um nó com dependente fora do repo?" e saia **1** quando não houver
teste de contrato cobrindo.

**Onde o ganho vira portão:** o valor não é o agente navegar melhor, é o portão poder reprovar com
evidência de grafo. "Nenhum símbolo público mudou sem que o dependente fosse revisado" é consulta
com exit code, no mesmo mecanismo que já sustenta `artifact-lint.sh` e `meta-check.sh`.

## Custo

- Nível 1: dependência externa (`uv` não está instalado nesta máquina) + language server baixado
  por linguagem no primeiro uso. Nada de código nosso.
- Nível 2: tool nova, com a manutenção que toda heurística de fronteira exige.

## Risco

**O que precisa ser resolvido antes de instalar:** `guard-artifacts.sh` é `PreToolUse` com matcher
`Write|Edit|NotebookEdit` e lê `.tool_input.file_path`. Uma ferramenta MCP de edição não casa o
matcher — o hook **não roda**; e se rodasse, o esquema dela não tem `file_path` e a chamada seria
permitida. Habilitar um servidor de grafo com edição ligada dá ao `solution-architect` e ao
`security-auditor` caminho para editar código de produção **sem linha no `guard.tsv`**.

Correção: modo somente-leitura na configuração do servidor, excluir a ferramenta de shell, e
estender o matcher do hook. Documentado em `workflow/README.md`.

## Descartado, com motivo

- **Neo4j / CodeGraph / code-graph-mcp** — infra a operar e índice que envelhece, e o call graph
  por AST erra no CDI, que é o padrão de todos os serviços Java daqui.
- **RAG vetorial sobre o código** — devolve trecho parecido. Assertividade exige aresta exata,
  não similaridade.
- **GraphRAG sobre os artefatos** — GraphRAG serve para *inferir* estrutura de prosa. Aqui já
  existe estrutura exata (grafo de símbolos, IDs de artefato); extrair com LLM rebaixaria a
  precisão e ainda custaria.
- **Reescrever `/sdlc` como motor de DAG** — as ondas já dão o paralelismo grosso, e o estado em
  disco é o que torna o fluxo retomável em sessão nova. Trocar o motor custa muito e ganha pouco.
