# Plano de Execução — fluxo de clone + desenvolvimento + execução inteiramente em Docker

**Escala:** INITIATIVE
**Gerado por:** tech-lead-orchestrator
**Data:** 2026-07-30
**Entrada:** `docs/sdlc/00-orchestration/stack-profile.md`

---

## Objetivo

Entregar, como ferramenta versionada **deste** repositório, um fluxo que clona um projeto alvo e
executa desenvolvimento **e** execução inteiramente dentro de Docker, sem escrever nem instalar
nada no host fora de um limite declarado, e que sobrevive à queda da conexão sem perda de trabalho.

Frase literal do usuário:

> "quero implementar um fluxo que vai fazer o git clone do projeto e fazer desenvolvimento e
> execucao tudo em docker sem tocar em nada de fora e nao posso perder nada em conexao e etc."

### Por que INITIATIVE e não FEATURE

Três razões, todas verificadas no `stack-profile.md`, não presumidas:

1. **Não existe implementação parcial para estender.** Não há `Dockerfile`, `compose.yml` nem
   `.devcontainer/` em lugar nenhum da árvore. As duas peças mais próximas puxam para o lado
   errado: `tools/preview-env.sh` só **detecta** e nunca sobe nada, e `skills/verify-live` sobe um
   ambiente **descartável e o derruba no final** — o oposto de um ciclo de desenvolvimento
   persistente.
2. **Há decisões estruturais irreversíveis a preço alto.** Onde vive o clone (volume nomeado, bind
   mount, dentro da imagem), qual é o modelo de sessão que sobrevive à desconexão, e como a
   credencial de clone entra no container. Cada uma dessas escolhas contamina todas as outras e
   nenhuma é barata de trocar depois de o usuário ter trabalho dentro do container.
3. **Há superfície de segurança nova e real.** Chave SSH ou token dentro de um container que
   executa **código clonado de terceiros**, e a possibilidade de precisar do socket do Docker
   montado — que é equivalência de root no host, e que contradiz frontalmente "sem tocar em nada de
   fora". Isso exige threat model formal antes do build, não depois.

Uma quarta razão, de convenção: o artefato precisa **nascer versionado neste repositório**
(`agents/`, `skills/`, `tools/`, `workflow/`, `workspace/`) para sobreviver a um
`agents/install.sh` — escrever direto em `.claude/` seria escrever num symlink gerado e gitignorado.

---

## Fora de escopo

Definido aqui como hipótese de trabalho; o **PRD (item D1) confirma ou corrige** — é o único
artefato com autoridade para mexer nesta lista.

- **Containerizar este repositório.** Ele é a oficina (`README.md:14`, `.claude/toolbelt.md:9-10`),
  não uma aplicação. Não há artefato executável aqui para empacotar. O que se entrega é uma
  ferramenta que **este repo distribui** para usar em projetos alvo.
- **Consertar o MCP `MCP_DOCKER`.** Está quebrado desde 27/07/2026 ("Connection closed"). O desenho
  não pode depender dele; usa-se a CLI `docker` direta, como `preview-env.sh` e `verify-live` já
  fazem.
- **Substituir `workspace/go`.** O fluxo novo convive com ele; sessão no host continua existindo.
- **Ambiente de desenvolvimento remoto / multi-máquina / cloud** (Codespaces, devpod, VPS). Só se a
  pergunta em aberto Q4 disser o contrário.
- **Pipeline de CI para o projeto alvo.** É consequência possível, não o pedido.
- **Suportar runtimes que não sejam Docker** (podman, containerd puro, Kubernetes).

---

## Ambiguidades que a discovery (Onda 1) precisa resolver

Nenhuma destas tem resposta inventada aqui. Cada uma vira linha da tabela
`## Perguntas em aberto` do PRD, com dono e prazo, e **o Gate 1 bloqueia enquanto houver pergunta
sem resposta que afete o desenho.**

| id | pergunta | por que trava o desenho |
|----|----------|-------------------------|
| Q1 | O que exatamente "não posso perder nada" cobre: (a) arquivos editados e não commitados, (b) processos rodando (dev server, watcher, build), (c) a sessão do agente/Claude em si, (d) histórico de shell e scroll-back? | (a) é volume; (b) é container detached; (c) exige multiplexador **dentro da imagem** ou daemon; (d) é logging. São quatro mecanismos diferentes com custos diferentes. |
| Q2 | O projeto alvo é privado? Se sim, a credencial de clone é chave SSH, token HTTPS ou `gh auth`? | Define se existe segredo dentro do container — e portanto se o threat model tem ou não trabalho pesado. |
| Q3 | O container precisa executar Docker **de dentro** (o projeto alvo tem o próprio `compose.yml`)? | Bifurca entre: nada de Docker dentro, socket do host montado (= root no host), ou DinD rootless. É a decisão de maior impacto de segurança do projeto inteiro. |
| Q4 | O usuário reattacha sempre da mesma máquina, ou de outra (SSH, outro terminal, outro host)? | "Mesma máquina" resolve com container detached. "Outra máquina" exige processo servidor e porta exposta — outro projeto. |
| Q5 | Qual é o limite literal de "sem tocar em nada de fora"? Volume nomeado do Docker conta como "fora"? Bind mount para um diretório declarado conta? | Sem esta resposta não dá para escolher onde o clone vive, e é justamente onde mora o trabalho que não pode ser perdido. |
| Q6 | "Desenvolvimento e execução tudo em docker" inclui o **próprio Claude Code rodando dentro do container**, ou apenas o dev server e os comandos do projeto? | Muda tudo: o que entra na imagem, como a credencial da Anthropic é passada, e o que significa "reattach". |
| Q7 | Um projeto por vez, ou N projetos simultâneos? | Define nomenclatura de container/volume, alocação de portas e o comando `list`. |
| Q8 | O fluxo se integra ao registro `workspace/projects/*.md` de `workspace/go`, ou é autônomo? | Define a superfície do comando e se o clone substitui ou complementa o registro atual. |

**Regra de desempate para a Onda 1:** se uma pergunta não tiver resposta do usuário no prazo, o
`product-owner` registra a premissa explícita no PRD (seção `## Premissas`) e o `solution-architect`
projeta para a opção **mais restritiva** — a que menos toca o host — documentando o custo no ADR.

---

## Onda 1 — Discovery (paralela)

Fase: `docs/sdlc/01-discovery/`. Três donos, três arquivos disjuntos.

| id | título | dono | entradas | entregável | aceite verificável |
|----|--------|------|----------|------------|--------------------|
| D1 | PRD do fluxo devbox | `product-owner` | objetivo literal do usuário; Q1–Q8; `stack-profile.md` | `docs/sdlc/01-discovery/prd.md` | `tools/artifact-lint.sh 01` imprime `OK docs/sdlc/01-discovery/prd.md`. Toda pergunta Q1–Q8 aparece na tabela `## Perguntas em aberto` com dono e prazo preenchidos. `## Escopo` tem lista de fora-de-escopo não vazia. Toda story tem ao menos um AC de caminho negativo. |
| D2 | Regras e tabelas de decisão do ciclo de vida | `business-analyst` | D1 (rascunho ou final); `workspace/go`; `tools/preview-env.sh` | `docs/sdlc/01-discovery/domain.md` | `tools/artifact-lint.sh 01` imprime `OK` para `domain.md`. Contém tabela de decisão **completa, sem "caso contrário" implícito** para: (a) estados do devbox (inexistente / criado / rodando / parado / órfão / corrompido) e transição de cada comando; (b) o que conta como "trabalho perdido" por categoria do Q1; (c) modo de credencial por tipo de repositório (público / privado-SSH / privado-token). |
| D3 | Jornada do desenvolvedor e a jornada de falha | `ux-researcher` | D1; `workspace/README.md`; comportamento atual de `workspace/go` (`exec claude`, sem multiplexador) | `docs/sdlc/01-discovery/ux-research.md` | `tools/artifact-lint.sh 01` imprime `OK` para `ux-research.md`. Contém a jornada **"a conexão caiu"** ponto a ponto: o que o usuário vê, o que ele tenta, e onde perde trabalho hoje com `workspace/go` — cada achado com severidade atribuída. |

### Restrição de formato que vale para os três (não é detalhe)

`tools/artifact-lint.sh` faz `grep -qi` por **strings literais em inglês**, e os templates em
`skills/sdlc-discovery/templates/prd.md` estão em português. As duas coisas não batem:

| lint exige | template entrega | resultado |
|---|---|---|
| `Problem` | `## Problema` | passa (substring) |
| `Success metrics` | `## Métricas de sucesso` | **falha** |
| `Out of scope` | `## Escopo` | **falha** |
| `Given` | `- **AC1** Dado ... Quando ... Então ...` | **falha** |
| `Open questions` | `## Perguntas em aberto` | **falha** |

Os artefatos da Onda 1 devem trazer o título bilíngue (`## Métricas de sucesso / Success metrics`,
`## Fora de escopo / Out of scope`, `## Perguntas em aberto / Open questions`) e os ACs no formato
`Dado/Given … Quando/When … Então/Then`. O mesmo vale para a Onda 2 (`NFR`, `Target state`,
`Integration patterns`, `Migration`, `Risks`) e para as ondas 4 e 5. O critério de aceite de todo
artefato lintado é a saída `OK` do script, não a impressão de estar completo.

## Gate 1 — Requisitos testáveis

- **Avaliador:** `solution-architect` — é quem vai construir em cima; se não der para projetar a
  partir do PRD, o PRD não está pronto.
- **Registro do veredito:** `context-manager` → `docs/sdlc/00-orchestration/gate-01.md`.
  O avaliador **não** escreve esse arquivo: `workflow/hooks/guard-artifacts.sh` restringe
  `solution-architect` a `docs/sdlc/02-design/` e negaria a escrita. O avaliador devolve o veredito
  por mensagem; o `context-manager` registra.
- **Evidência obrigatória:** saída de `tools/artifact-lint.sh 01` (exit 0) + checklist do
  `Portão 1` em `skills/sdlc-gate/gates.md`, item a item.
- **Bloqueia se:** qualquer pergunta de Q1–Q8 que afete o desenho seguir sem resposta **e** sem
  premissa registrada; ou se algum critério de aceite citar container, volume, imagem ou flag de
  `docker` (requisito não pode citar implementação).

---

## Onda 2 — Arquitetura e decisões estruturais (item único, sequencial por natureza)

Fase: `docs/sdlc/02-design/`. **Onda de um item só, deliberadamente**: tudo na Onda 3 depende
destas decisões, e dividir a arquitetura entre dois donos produziria artefatos que se contradizem —
que é blocker explícito no Portão 2.

| id | título | dono | entradas | entregável | aceite verificável |
|----|--------|------|----------|------------|--------------------|
| A1 | Arquitetura alvo + 3 ADRs | `solution-architect` | D1, D2, D3; `stack-profile.md`; `skills/sdlc-design/templates/adr.md` | `docs/sdlc/02-design/architecture.md` **+** `docs/sdlc/02-design/adr/ADR-001-topologia-e-persistencia.md` **+** `.../ADR-002-modelo-de-sessao-e-reattach.md` **+** `.../ADR-003-onde-o-artefato-vive-no-repo.md` | `tools/artifact-lint.sh 02` imprime `OK` para `architecture.md` e `INFO 3 ADR(s)`. Cada ADR lista **≥2 alternativas** e a seção `## Consequências` com "Desvantagens aceitas" preenchida. Todo NFR em `architecture.md` tem **número e unidade**. |

### O que cada ADR precisa fechar

- **ADR-001 — topologia e persistência.** Onde vive o clone e onde vive o trabalho não commitado:
  volume nomeado, bind mount declarado ou camada da imagem. Decide também se há Docker dentro do
  container (resposta de Q3): sem Docker / socket do host montado / DinD rootless. Consequência
  obrigatória a declarar: **montar `/var/run/docker.sock` entrega ao código clonado poder
  equivalente a root no host**, o que contradiz o requisito "sem tocar em nada de fora" — se for a
  opção escolhida, o custo tem que estar escrito.
- **ADR-002 — modelo de sessão e reattach.** Como a sessão sobrevive à queda de conexão. Restrição
  dura de ambiente: **o host não tem `tmux` nem `screen`**, e instalar no host viola o requisito.
  Alternativas a comparar no mínimo: (a) container detached puro + `docker exec` a cada reattach —
  processos sobrevivem, a sessão interativa não; (b) multiplexador instalado **dentro da imagem** —
  não toca no host, satisfaz o requisito literalmente, e é a única opção que preserva sessão
  interativa; (c) processo supervisor no container com log persistido. A escolha depende
  diretamente da resposta de Q1 e Q6.
- **ADR-003 — onde o artefato vive neste repositório.** Restrição dura de convenção:
  `tools/README.md:7` declara que **todo script em `tools/` é somente leitura — nenhum instala,
  builda, acessa a rede ou altera arquivo**. Um executável que faz `git clone` e `docker run`
  **não pode** morar em `tools/`. O precedente correto é `workspace/go`, que já é um executável com
  efeito colateral (cria symlink, mescla `settings.json`, faz `exec claude`). Decidir entre:
  `workspace/devbox` (recomendado pelo precedente), uma skill que executa via `allowed-tools`
  (como `verify-live` faz hoje), ou um agente novo. Se a decisão for agente novo, o ADR deve
  registrar que ele precisa de entrada explícita no `case` de
  `workflow/hooks/guard-artifacts.sh` — o ramo default `*) exit 0` deixa agente novo **sem
  restrição nenhuma de escrita**.

> **Nota de plano:** os caminhos de entregável das Ondas 4 e 6 abaixo assumem a opção recomendada
> do ADR-003 (`workspace/devbox` + `workflow/docker/`). Se o ADR decidir diferente, o
> `tech-lead-orchestrator` atualiza este plano **no Gate 2**, antes de qualquer build. Nenhum
> builder começa com caminho divergente do ADR.

---

## Onda 3 — Aprofundamento de design (paralela)

Fase: `docs/sdlc/02-design/`. Três donos, três arquivos disjuntos, todos dependem só de A1.

| id | título | dono | entradas | entregável | aceite verificável |
|----|--------|------|----------|------------|--------------------|
| T1 | Threat model STRIDE | `threat-modeler` | A1 + ADR-001/002/003; D2 (tabela de credenciais) | `docs/sdlc/02-design/threat-model.md` | `tools/artifact-lint.sh 02` imprime `OK` para `threat-model.md` (exige `STRIDE`, `Security requirements`, `Residual risk`). Cobre **obrigatoriamente**: credencial de clone vazando em camada de imagem ou `docker history`; código clonado (não confiável) executando com a credencial montada; socket do Docker como fuga para o host; procedência da imagem base; escrita fora do limite declarado. Cada requisito de segurança é **testável e tem dono**. |
| I1 | Fronteira com sistemas não controlados | `integration-engineer` | A1 + ADRs; Q2 | `docs/sdlc/02-design/integrations.md` | `tools/artifact-lint.sh 02` imprime `OK` (exige `Interface interna`, `timeout`, `Degrada`, `Credenciais`). Trata os três externos reais: **remote git** (clone/fetch), **daemon do Docker** (build/run/exec), **registry** (pull da base). Cada um com timeout, comportamento em falha e degradação. `Credenciais` responde ao critério do Portão 2: **rotacionáveis sem rebuild da imagem**. |
| C1 | Contrato da CLI | `api-designer` | A1 + ADRs; D2 (máquina de estados) | `docs/sdlc/02-design/cli-contract.md` | Documento define, para **cada** subcomando: argumentos, flags, precondições, efeito, **código de saída** e formato de stdout/stderr. Cobre no mínimo os estados de D2. Toda transição da tabela de decisão de D2 mapeia para exatamente um subcomando. É este contrato que permite B1 e B2 serem construídos em paralelo. |

> `ux-ui-designer` **não** é acionado: não há superfície gráfica. O `ux-spec.md` fica ausente de
> propósito — `artifact-lint.sh` só o verifica se o arquivo existir, então a ausência não quebra o
> portão. A ergonomia da linha de comando é coberta por C1 (contrato) e D3 (jornada).

## Gate 2 — Design implementável

- **Avaliador:** `code-reviewer` — não escreveu nenhum artefato de design, e o Portão 2 é sobretudo
  uma verificação de contradição entre artefatos.
- **Registro do veredito:** `context-manager` → `docs/sdlc/00-orchestration/gate-02.md`
  (`guard-artifacts.sh` restringe `code-reviewer` a `docs/sdlc/04-quality/`).
- **Evidência obrigatória:** `tools/artifact-lint.sh 02` com exit 0, incluindo `INFO 3 ADR(s)`, mais
  o checklist do `Portão 2` de `skills/sdlc-gate/gates.md`.
- **Bloqueia se:** `architecture.md` × `threat-model.md` × `integrations.md` × `cli-contract.md` se
  contradisserem em qualquer ponto (blocker declarado, volta para os dois agentes envolvidos); se
  algum NFR estiver sem número e unidade; se alguma credencial não for rotacionável sem deploy.
- **Ação obrigatória do `tech-lead-orchestrator` neste portão:** reconciliar os caminhos das Ondas 4
  e 6 com a decisão do ADR-003 e atualizar este arquivo.

---

## Onda 4 — Build (paralela)

Fase: `docs/sdlc/03-build/` (registro) + código no repositório. Três donos, três caminhos
disjuntos, todos com C1 (contrato da CLI) como interface compartilhada.

| id | título | dono | entradas | entregável | aceite verificável |
|----|--------|------|----------|------------|--------------------|
| B1 | Imagem e runtime do devbox | `devops-engineer` | A1, ADR-001, ADR-002, T1 (requisitos de segurança), C1 | `workflow/docker/Dockerfile.devbox`, `workflow/docker/compose.devbox.yml`, `workflow/docker/entrypoint.sh` | `docker build -f workflow/docker/Dockerfile.devbox` conclui com exit 0. `docker history` da imagem **não contém segredo em nenhuma camada**. Container roda com usuário **não-root** (`docker run --rm <img> id -u` ≠ 0). `bash -n workflow/docker/entrypoint.sh` limpo. Tamanho da imagem dentro do orçamento definido em A1. |
| B2 | CLI orquestradora | `backend-engineer` | C1 (contrato — fonte da verdade), D2 (máquina de estados), ADR-003, `workspace/go` como precedente de estilo | `workspace/devbox` | `bash -n workspace/devbox` limpo. `workspace/devbox --help` sai 0 e lista **exatamente** os subcomandos de C1. Cada subcomando devolve o código de saída especificado em C1 para o caminho feliz **e** para a precondição violada. Segue o estilo do repo: `set -uo pipefail`, `SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"`, comentários em português explicando o *porquê*. |
| B3 | Skill de entrada `/devbox` | `tech-writer` | C1; D3 (jornada); `skills/README.md:41-49` (convenções de skill) | `skills/devbox/SKILL.md` | `./agents/install.sh --check` sai 0 (valida frontmatter, teto de 500 linhas e coerência de `allowed-tools` com toda injeção `` !`cmd` ``). Frontmatter tem `name`, `description` dizendo **quando usar**, e `disable-model-invocation: true` — a skill tem efeito colateral (sobe container), e a convenção do repo exige. |

> Um detalhe que separa B1 de B2 e é o motivo de serem donos diferentes: B1 responde "o que existe
> dentro do container", B2 responde "qual é o ciclo de vida visto de fora". O contrato C1 é a
> costura. Se durante o build o contrato se mostrar errado, a correção é em C1 primeiro — não uma
> divergência silenciosa entre os dois.

## Gate 3 — Build integrado (portão leve, antes da qualidade)

- **Avaliador:** `context-manager`.
- **Registro:** `docs/sdlc/00-orchestration/gate-03-build.md` + `artifact-ledger.tsv`.
- **Evidência:** os três entregáveis existem; `./agents/install.sh --check` sai 0; um ciclo mínimo
  ponta a ponta (`clone → up → exec → down`) roda contra um repositório público de teste e é
  registrado com a saída real do terminal.
- **Bloqueia se:** `workspace/devbox --help` divergir de `cli-contract.md`.

---

## Onda 5 — Qualidade (paralela)

Fase: `docs/sdlc/04-quality/`. Cinco donos, cinco arquivos disjuntos.

| id | título | dono | entradas | entregável | aceite verificável |
|----|--------|------|----------|------------|--------------------|
| V1 | Plano de teste + testes | `test-engineer` | ACs do PRD (D1); tabelas de decisão (D2); C1 | `docs/sdlc/04-quality/test-plan.md` + `workflow/docker/test/devbox-smoke.sh` | `tools/artifact-lint.sh 04` imprime `OK` para `test-plan.md` (exige `Traceability`, `Results`). Todo AC do PRD mapeia para um teste **nomeado que existe e passa**; a seção `Results` traz a saída real da execução, não a intenção. `devbox-smoke.sh` roda duas vezes seguidas com o mesmo resultado (idempotência). |
| V2 | Code review | `code-reviewer` | diff completo das Ondas 4/5; A1; C1 | `docs/sdlc/04-quality/review-devbox.md` | `tools/artifact-lint.sh 04` imprime `OK` (exige `Verdict`, `Failure scenario`, `Test assessment`). Cada achado descreve um **cenário de falha concreto**, não preferência de estilo. Verifica explicitamente que nada em `tools/` passou a ter efeito colateral. |
| V3 | Auditoria de segurança | `security-auditor` | `threat-model.md` (T1); diff; imagem construída | `docs/sdlc/04-quality/security-audit.md` | `tools/artifact-lint.sh 04` imprime `OK` (exige `Verdict`, `Attack path`, `requirement verification`). **Cada** requisito de segurança de T1 marcado como verificado-no-código ou não-implementado, com caminho de arquivo. Verificações mínimas com comando: `docker history` sem segredo; usuário não-root; nenhuma credencial em `docker inspect` do container; egress de rede conforme o desenho. |
| V4 | Drill de resiliência | `sre-observability` | ADR-002; resposta da pergunta Q1 (categorias de perda) | `docs/sdlc/04-quality/resilience-drill.md` | Executa e registra a saída real de: (a) matar o cliente/terminal com trabalho não commitado dentro do devbox → container segue `Up` em `docker ps` e o arquivo modificado continua íntegro; (b) reattach → processo de longa duração ainda vivo; (c) `docker restart` do devbox → o trabalho não commitado sobrevive. **Cada categoria que a pergunta Q1 marcou como não-perdível tem um drill correspondente.** Este é o teste de aceite do requisito central do usuário. |
| V5 | Orçamentos de performance e disco | `performance-engineer` | A1 (NFRs numéricos); B1 | `docs/sdlc/04-quality/performance.md` | Mede e reporta com número: tamanho final da imagem; tempo de `clone + build` a frio; **delta de `df -h /` antes e depois** de um ciclo completo, incluindo `docker system df`. Mede I/O de bind mount **versus** volume nomeado neste host (backend Docker Desktop, VM), e o resultado confirma ou refuta a escolha do ADR-001. Cada medição comparada ao orçamento de A1: dentro ou fora, com o número. |

> **Convenção de identificadores:** `Q1`–`Q8` são sempre as **perguntas em aberto** da discovery.
> Os itens de qualidade são `V1`–`V5`. Nunca use `Q` para se referir a um item de trabalho.

## Gate 4 — Pronto para merge

- **Avaliador:** `release-manager` — lê os vereditos de V2/V3, o `Results` de V1 e o drill de V4.
- **Registro:** `context-manager` → `docs/sdlc/00-orchestration/gate-04.md`.
- **Evidência:** `tools/artifact-lint.sh 04` exit 0 + checklist do `Portão 3` de `gates.md`.
- **Bloqueia se:** `code-reviewer` com blocker aberto; `security-auditor` com achado BLOCK não
  remediado; qualquer AC sem teste nomeado que passe; **ou qualquer drill de V4 que não preserve
  uma categoria de trabalho que o PRD declarou como não-perdível.**

---

## Onda 6 — Entrega e documentação (paralela)

Fases `docs/sdlc/05-delivery/` e `docs/sdlc/06-docs/`. Três donos, três conjuntos disjuntos.

| id | título | dono | entradas | entregável | aceite verificável |
|----|--------|------|----------|------------|--------------------|
| R1 | Observabilidade e runbook | `sre-observability` | V4; A1; D3 | `docs/sdlc/05-delivery/observability.md` | `tools/artifact-lint.sh 05` imprime `OK` (exige `SLO`, `Alerts`, `runbook`). O runbook cobre com comando exato: "a conexão caiu, e agora"; "o container sumiu"; "o disco encheu no meio do build"; "quero recuperar trabalho de um devbox órfão". |
| R2 | Decisão de release | `release-manager` | todos os portões anteriores | `docs/sdlc/05-delivery/release-devbox.md` | `tools/artifact-lint.sh 05` imprime `OK` (exige `Decision`, `Gate verification`, `Rollback criteria`). `Gate verification` cita **caminho de arquivo** como evidência de cada portão, não afirmação. `Rollback criteria` numérico e com dono. |
| R3 | Documentação do repositório | `tech-writer` | B1, B2, B3; R1 | `docs/sdlc/06-docs/devbox-guide.md` + atualização de `workspace/README.md` e da árvore de skills em `skills/README.md` | Todo comando do guia foi **executado** e a saída confere. A contagem e a árvore de `skills/README.md` refletem a skill nova (hoje o arquivo declara 16 skills). `./agents/install.sh --check` continua saindo 0 após as mudanças. |

## Gate 5 — Release

- **Avaliador:** `release-manager`, com verificação independente de `security-auditor` sobre o diff
  final (há credencial envolvida — mudança tardia na superfície de segredo não pode passar).
- **Registro:** `context-manager` → `docs/sdlc/00-orchestration/gate-05.md`.
- **Evidência:** `tools/artifact-lint.sh all` exit 0 + checklist do `Portão 4` de `gates.md`.

---

## Riscos

| risco | impacto | mitigação | dono |
|-------|---------|-----------|------|
| **Disco `/` a 93% (34G livres de 468G).** Build de imagem e clone consomem o mesmo filesystem; um build que falha no meio deixa camadas dangling e piora a situação. | Build falha, ou pior, enche o disco do usuário — exatamente o "tocar em coisa de fora" que o requisito proíbe. | Orçamento de tamanho de imagem numérico em A1, verificado em V5. A CLI (B2) faz precheck de espaço livre e **recusa** o build abaixo do limite, com mensagem acionável. `docker system df` no runbook (R1). | `devops-engineer` (build) / `performance-engineer` (medição) |
| **Host sem `tmux` e sem `screen`.** Hoje `workspace/go` faz `exec claude` puro: se o terminal cai, o processo morre junto. É literalmente a falha que o usuário quer eliminar. | Sem decisão explícita, o fluxo novo herda o mesmo ponto único de falha. | ADR-002 decide entre container detached + `docker exec`, ou multiplexador **dentro da imagem** — instalar no container não toca no host e satisfaz o requisito. V4 prova com drill real. | `solution-architect` |
| **Credencial de clone dentro do container.** Chave SSH ou token acessível ao código clonado, ou gravada em camada da imagem / visível em `docker history`. | Vazamento de credencial do usuário para código de terceiros. | T1 (STRIDE) define o requisito; V3 verifica com `docker history` e `docker inspect`; I1 garante rotação sem rebuild. | `threat-modeler` → `security-auditor` |
| **Socket do Docker montado.** Se a pergunta Q3 confirmar que o projeto alvo precisa de Docker por dentro, `/var/run/docker.sock` dá ao código clonado poder equivalente a root no host. | Contradiz frontalmente "sem tocar em nada de fora" e é a fuga de container mais direta que existe. | ADR-001 escolhe explicitamente entre sem-Docker / socket / DinD rootless e **escreve o custo aceito**. Se for socket, T1 trata como fronteira de confiança rompida e V3 audita. | `threat-modeler` |
| **Código clonado é entrada não confiável que a gente executa.** O fluxo inteiro existe para rodar código que não escrevemos. | Execução arbitrária com as credenciais que estiverem montadas. | Limites em T1: usuário não-root, sem privilégios extras, política de egress explícita, montagens mínimas. Verificado em V3 com comando. | `threat-modeler` |
| **Quebrar a convenção somente-leitura de `tools/`.** Um script que faz `docker run` e `git clone` não pode morar lá (`tools/README.md:7`). | Corrompe uma invariante que agentes e skills assumem em todo o repo. | ADR-003 decide o lugar; `workspace/devbox` é o precedente correto (`workspace/go` já tem efeito colateral). V2 verifica no review que nada em `tools/` mudou de natureza. | `solution-architect` → `code-reviewer` |
| **Bind mount lento no backend do Docker Desktop (VM).** `docker info` reporta "Docker Desktop", não dockerd nativo. | Ciclo de desenvolvimento inutilizável mesmo estando correto. | V5 mede bind mount versus volume nomeado **neste host** antes de fixar a escolha; se refutar o ADR-001, volta para o `solution-architect`. | `performance-engineer` |
| **"Nada no host" versus "não perder nada" podem se contradizer.** Se o clone só existe dentro do container, remover o container remove o trabalho. | Requisito impossível de satisfazer como enunciado. | Pergunta em aberto Q5 resolvida no PRD com o usuário; a pergunta Q1 e o item D2 categorizam o que precisa sobreviver a quê. | `product-owner` |
| **`MCP_DOCKER` quebrado** ("Connection closed", verificado em 27/07/2026). | Desenho que dependesse dele nasceria morto. | Proibição explícita no plano: só CLI `docker`, como `preview-env.sh` e `verify-live` já fazem. V2 verifica no review. | `devops-engineer` |
| **Agente novo sem restrição de escrita.** Se o ADR-003 optar por criar um agente, o `case` de `guard-artifacts.sh` cai no default `*) exit 0` — sem restrição nenhuma. | Agente novo pode escrever em qualquer lugar do repositório. | Se o ADR-003 escolher agente novo, entra item de build para adicionar a entrada explícita no `case`; V2 verifica. | `solution-architect` → `code-reviewer` |
| **Trabalho duplicado em outra worktree.** `.claude/worktrees/` tem worktrees irmãs (`arch-conformance`, `meta-e-mcp`, `vault-secrets`) não inspecionadas. | Dois desenhos concorrentes para o mesmo problema. | `context-manager` lista o branch e o diff de cada worktree **antes do Gate 2** e reporta colisão. | `context-manager` |

---

## Contabilidade do plano

- **6 ondas, 5 portões, 18 itens de trabalho** (3 + 1 + 3 + 3 + 5 + 3).
- Todo item tem exatamente um dono.
- Nenhum arquivo é escrito por dois itens da mesma onda.
- Nenhuma dependência aponta para onda posterior.
- Vereditos de portão são sempre gravados pelo `context-manager` em
  `docs/sdlc/00-orchestration/`, porque `workflow/hooks/guard-artifacts.sh` restringe
  `solution-architect` a `02-design/` e `code-reviewer`/`security-auditor` a `04-quality/` — o
  avaliador julga, o `context-manager` registra.
- Todo artefato verificado por `tools/artifact-lint.sh` tem como critério de aceite a saída `OK` do
  próprio script, e precisa carregar os títulos literais em inglês descritos na Onda 1.
