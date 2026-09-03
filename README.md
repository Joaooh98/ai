# AI — Repositório de Desenvolvimento

Uma **equipe de 28 agentes** que executa um ciclo de desenvolvimento disciplinado **dentro do seu
projeto**, uma onda por vez, parando num portão que sabe reprovar.

## O que isto resolve

Um agente de IA trabalhando sozinho **afirma**. Ele não mente por má-fé: ele conclui a partir do
que alcançou, e o que ele alcançou quase nunca é suficiente. Quatro exemplos medidos **nos seus
próprios projetos**, não hipotéticos:

| A afirmação | Por que ela sai errada aqui |
|---|---|
| *"os testes passam"* | `smaug-system` tem **82 `pom.xml` e só 16 com JaCoCo**. Em 66 módulos não existe relatório de cobertura para ler |
| *"nada mais usa isso"* | `grep -r "PanacheCompany"` devolve **1978 ocorrências em 471 arquivos**, sem tipo de relação nem direção. O grafo devolve **173 nós**, cada um com `calls`/`references` e `file:line` |
| *"essa é a API da biblioteca"* | os módulos rodam Quarkus **3.33.1 e 3.35.3**; o Context7 indexa 3.20.3, 3.30.0 e 3.31.2 — **nenhuma das duas** |
| *"o orçamento de performance foi atendido"* | o portão pedia isso *"quando existir"* — e nunca existia, porque nada declarava o número |

E no `smart`, com **17 repositórios**, nenhuma dessas perguntas atravessa a fronteira entre
`dafe-pix` e `dafe-gateway` sem um grafo que cruze repositório.

O trabalho **parece** terminado. Você descobre que não estava em produção.

**O que esta oficina faz é uma coisa só: transformar cada afirmação em consulta.**

| Em vez de | O mecanismo |
|---|---|
| o agente lembrar o que ficou combinado | **artefato em caminho fixo** — a saída de um agente *é* o arquivo que o próximo lê |
| o agente dizer que está pronto | **portão com exit code** — `artifact-lint.sh` e `meta-check.sh` saem com 1, e 1 reprova |
| pedir que o agente respeite fronteiras | **hook em runtime** — um agente de especificação é *impedido* de escrever código, e a negação vai para o log |
| supor o comando de teste do projeto | **toolbelt calibrado** — o `/setup` **executa** o comando e grava o resultado real |
| aceitar um número afirmado | **meta lida de relatório** — o número vem da rodada que rodou, e relatório velho bloqueia |

O preço é honesto: **é mais lento que pedir o código direto.** Uma invocação executa uma onda e
para. É esse o negócio — você troca velocidade por saber, a cada passo, o que foi conferido.

**Comece por aqui:** [`docs/porque.html`](docs/porque.html) mostra o mesmo pedido percorrendo os
dois caminhos, com e sem a equipe.

---

O repositório também guarda o **material do MBA** (prompt engineering, evaluation, versionamento)
em `prompts/` e `design-docs/` — frente separada, que não é usada em runtime pelos agentes.

```
agents/       28 agentes — 25 do SDLC + 2 de incidente + 1 de integração externa
skills/       os fluxos, a entrada por ticket, a disciplina da equipe e as skills de stack
workflow/     4 hooks que impõem as fronteiras e registram o que acontece
tools/        11 scripts de apoio somente-leitura chamados pelos agentes
workspace/    os projetos onde você trabalha — cadastro e abertura de sessão
mcp/          como a equipe detecta o ferramental do projeto, em vez de assumir
docs/         quatro diagramas interativos: por que existe, como se usa, a onda, e onde mora
plans/        decidido e ainda não construído — com a medição que sustenta a decisão
prompts/      material do MBA + biblioteca de prompts versionada (PT e EN)
design-docs/  ensaios de contexto do MBA: documentação como ativo, e RUP
research/     pesquisas com fontes que fundamentam decisões e melhorias do toolkit
```

Cada pasta tem README próprio com as decisões de desenho. Este arquivo é o mapa; os detalhes
ficam onde o código está.

**Este repositório é a oficina.** Nenhum trabalho de produto acontece aqui dentro — os projetos
ficam cadastrados em `workspace/` e a sessão abre dentro deles.

**Ver antes de ler.** Quatro diagramas, cada um começando onde o anterior para — tema
claro/escuro e exportação em todos:

| # | Diagrama | Responde |
|---|---|---|
| 1 | [`docs/porque.html`](docs/porque.html) | **Por que existe** — o mesmo pedido com e sem a equipe, e onde a diferença aparece |
| 2 | [`docs/fluxo.html`](docs/fluxo.html) | **Como se usa** — do cadastro do projeto até produção, com o portão e o desvio de emergência |
| 3 | [`docs/sdlc.html`](docs/sdlc.html) | **Uma invocação por dentro** — ler o disco, despachar a onda, avaliar o portão, e o caminho da reprovação |
| 4 | [`docs/arquitetura.html`](docs/arquitetura.html) | **Onde as peças moram** — o que fica na oficina, o que fica no projeto alvo, e a âncora que liga os dois |

Leia nessa ordem. O primeiro responde *por quê*, o último responde *onde* — e olhar o *onde*
antes do *porquê* é exatamente o que faz o repositório parecer um monte de pasta sem propósito.

```bash
docs/gerar.sh            # gera os quatro a partir dos .json
xdg-open docs/porque.html
```

Os `.html` **não são versionados** — são saída, e cada um embute o runtime do `archify` inteiro.
Versionar os quatro colocava 2162 linhas duplicadas no repositório. A fonte é o `.json` ao lado;
`docs/gerar.sh` refaz em segundos. Detalhes em [`docs/README.md`](docs/README.md).

**Trabalhando neste repositório?** Leia [`ESTADO.md`](ESTADO.md) primeiro — é o índice das
frentes em voo. O trabalho aqui acontece em sessões paralelas que não enxergam umas às
outras; esse arquivo é o único lugar que sabe o que existe, o que falta e o que está parado.

---

## Começar

**Pré-requisitos:** `git`, o CLI `claude`, e `jq` — sem `jq` os hooks falham em modo aberto: não
bloqueiam nada e não registram nada.

```bash
sudo apt install jq
```

### 1. Instalar a oficina, uma vez

```bash
git clone <este repo> && cd ai
./agents/install.sh
```

Isso cria links simbólicos de `agents/` e `skills/` para `.claude/`, escreve os hooks e cria a
âncora `.claude/ai-toolkit`. **Reinicie o Claude Code** se `.claude/agents/` não existia antes.

### 2. Cadastrar um projeto

```bash
./workspace/go add /caminho/do/projeto
```

O nome sai do basename do caminho. `go` detecta sozinho qual dos dois formatos é:

| Tipo | O que é | Exemplo |
|---|---|---|
| **repo** | um repositório git | uma API, um app |
| **workspace** | raiz **sem** git, com repositórios embaixo | uma pasta com 11 serviços + 3 frontends que você trabalha junto |

No workspace, os artefatos do ciclo nascem na **raiz** e código e teste ficam em cada repositório.
É o formato certo quando você trabalha o conjunto — cadastrar cada repo em separado funciona, mas
obriga a uma sessão por repositório.

**Layout não é arquitetura.** Estar em dezessete repositórios ou em um só é história de time: os
scripts reportam onde o código está, nunca como o sistema é desenhado. Do git se tira uma coisa só
com honestidade — como o time versiona (`tools/git-conventions.sh`).

Se a raiz não tem git **nem** repositórios embaixo, `go` cadastra e avisa: os artefatos não ficam
versionados e `diff-scope.sh` / `incident-evidence.sh` não terão o que ler. Resolva com `git init`.

### 3. Abrir a sessão lá

```bash
./workspace/go <nome>
```

`go` fia o que faltar antes de abrir — instala a equipe em escopo de usuário, cria a âncora e
escreve os hooks no projeto alvo — e então abre o `claude` com o diretório de trabalho **no
projeto**. É idempotente: rodar de novo não duplica nada.

### 4. Calibrar, na primeira sessão de cada projeto

```
/setup
```

**Este é o passo que faz a equipe acertar, e o mais fácil de pular.** Instalar cria links: a
equipe chega sabendo o método e **nada** sobre o seu projeto. Calibrar detecta a stack, **executa**
o comando de teste e o de build para confirmar que funcionam de verdade, pergunta o que nenhuma
detecção alcança (VPN, o que não pode ser mexido, como se verifica uma mudança aqui) e grava tudo
em `.claude/toolbelt.md` — carregado por todo agente, em toda invocação.

O `/setup` também **pergunta antes de habilitar**, em vez de assumir. Duas decisões que são suas:

- **Quais servidores MCP este projeto ganha.** A pergunta não chega vazia: `mcp/catalog.tsv`
  guarda o que a equipe já avaliou, e a detecção cruza com os manifests daqui para trazer o
  comando exato **e a ressalva** de cada um. Instala com `--scope project`, que escreve
  `.mcp.json`; como conector de conta o servidor fica invisível para os 28 agentes, e eles
  seguem adivinhando.
- **Qual é a meta de qualidade daqui** — cobertura, latência, o que nunca vai para produção.
  Gravada em `.claude/meta.tsv`, é o que os portões 3 e 4 conferem. Em projeto que já existe,
  use catraca: não bloqueia a dívida que estava lá, só impede piorar.

Sem calibrar, o primeiro "os testes passam" pode ser falso porque nem existe suíte — e sem meta,
os itens numéricos do portão passam sempre, porque não há número contra o que conferir.

Rode `/setup` de novo quando a stack mudar — ou quando um agente errar por falta de contexto, que
é o sintoma de calibração velha.

### 5. Trabalhar

```
/sdlc "permitir que o cliente pause a assinatura"
```

Executa a próxima onda e **para no portão**. Rode de novo para avançar mais uma.

---

## Referência — `workspace/go`

Roda no shell, a partir da raiz deste repositório.

| Comando | Para |
|---|---|
| `./workspace/go` | Listar cadastro, tipo, estado da fiação e do fluxo de cada projeto |
| `./workspace/go add <caminho> [nome]` | Cadastrar. Aceita `~`. Nome padrão = basename, precisa ser kebab-case |
| `./workspace/go <nome> [args...]` | Fiar o que faltar e **abrir a sessão** no projeto |
| `./workspace/go wire <nome>` | Só fiar, sem abrir |
| `./workspace/go check <nome>` | Diagnóstico: tipo, fiação, âncora, hooks, calibração, fluxo, repositórios |
| `./workspace/go rm <nome>` | Descadastrar. Não toca no projeto |

De dentro do Claude, use a skill `/workspace` — mesmos subcomandos, sem abrir sessão:
`/workspace <nome>` fia e devolve o comando de terminal pronto para colar.

Tudo que vem depois do nome vai direto para o `claude`, então dá para entrar já num fluxo:

```bash
./workspace/go smaug-system "/sdlc-status"
./workspace/go smaug-system "/sdlc 'permitir pausar assinatura'"
./workspace/go smaug-system "/incident 'checkout 500 desde as 14h'"
```

O cadastro fica em `workspace/projects/<nome>.md` — frontmatter para a máquina, corpo livre para
suas anotações. Não é versionado: guarda caminhos absolutos desta máquina.

Detalhes e as decisões de desenho: [`workspace/README.md`](workspace/README.md).

## Referência — comandos dentro da sessão

**Os três que sustentam o trabalho planejado:**

| Comando | Argumento | Para |
|---|---|---|
| `/sdlc` | `[objetivo]`, ou vazio para continuar | Executa a próxima onda e para no portão |
| `/sdlc-status` | — | Onde o trabalho parou, lido do disco |
| `/sdlc-gate` | `[1\|2\|3\|4]` | Valida um portão item a item, com evidência |

**Apoio:**

| Comando | Argumento | Para |
|---|---|---|
| `/setup` | — | Calibrar a equipe para este projeto |
| `/sdlc-intake` | `[chave do ticket]` | Puxar do Jira/Linear/GitHub/GitLab e devolver status para lá |
| `/verify-live` | `[o que verificar]` | Subir num ambiente controlado e verificar de verdade, no navegador |
| `/nightly` | `[rotina]`, ou vazio para listar | Trabalho recorrente fora do horário |
| `/incident` | `[sintoma observado]` | Modo emergência |

**Também aparecem na lista, mas não é assim que o fluxo foi desenhado:** `/sdlc-bootstrap`,
`/sdlc-discovery`, `/sdlc-design`, `/sdlc-build`, `/sdlc-quality` e `/sdlc-ship`. São as skills de
fase, carregadas pelo `/sdlc`. Digitar a fase direto pula o portão — quem escolhe a onda é o
`/sdlc`, lendo os artefatos.

Você também pode acionar um especialista direto, sem fluxo:

```
Use o security-auditor para auditar o fluxo de upload
Use o tech-lead-orchestrator para planejar <objetivo>
```

## Um dia de trabalho

```bash
./workspace/go                       # onde eu parei em cada projeto?
./workspace/go smaug-system "/sdlc-status"    # e neste, especificamente?
./workspace/go smaug-system                   # abre a sessão
```

Dentro da sessão:

```
/sdlc-intake PROJ-482       # puxa o ticket e traduz em objetivo
/sdlc "<o objetivo>"        # onda 00: perfil da stack + plano
/sdlc                       # onda 01: PRD, regras de domínio, UX
/sdlc-gate 1                # o portão passou mesmo? confira sem avançar
/sdlc                       # onda 02: arquitetura, contratos, ameaças
/sdlc                       # onda 03: código, com teste que falha primeiro
/verify-live "o fluxo de pausa"   # sobe e verifica no navegador
/sdlc                       # onda 04: testes, review, segurança, performance
/sdlc                       # onda 05: observabilidade, pipeline, go/no-go
```

Você não decora a ordem: `/sdlc` sem argumento continua de onde parou, porque **quem sabe onde
parou é o disco**, não a memória da conversa.

---

## A equipe

28 agentes genéricos — nenhum preso a linguagem ou framework. Cada um lê o perfil da stack do
repositório e segue as convenções que já existem lá.

| Fase | Agentes |
|---|---|
| **00 Orquestração** | tech-lead-orchestrator · project-analyst · project-configurator · context-manager |
| **01 Discovery** | product-owner · business-analyst · ux-researcher |
| **02 Design** | solution-architect · api-designer · data-architect · ux-ui-designer · threat-modeler |
| **03 Build** | backend · frontend · mobile · data · ai-engineer · integration-engineer |
| **04 Quality** | test-engineer · code-reviewer · security-auditor · performance-engineer |
| **05 Delivery** | devops-engineer · sre-observability · release-manager |
| **06 Docs** | tech-writer |
| **07 Incidente** | incident-commander · root-cause-analyst |

O `integration-engineer` atua em duas ondas: desenha a interface interna na 02, implementa o
adapter do fornecedor na 03. Os dois de incidente não são uma fase — entram por `/incident`.

Detalhes, curadoria e roster completo: [`agents/README.md`](agents/README.md).

## O ciclo

```mermaid
flowchart LR
    SETUP(["/setup — uma vez: calibra a stack,<br/>habilita MCP, fixa a meta de qualidade"]) -.-> A

    subgraph PLAN["1 · TRABALHO PLANEJADO — o portão protege a qualidade"]
        direction TB
        T["/sdlc-intake<br/>puxa a tarefa do tracker<br/>e traduz em objetivo"] --> A["/sdlc 'objetivo'"]
        A --> B{"em que fase<br/>os artefatos estão?"}
        B --> C["executa UMA onda<br/>agentes em paralelo"]
        C --> V["/verify-live<br/>sobe e verifica no navegador<br/>(onda de qualidade)"]
        V --> D{"portão<br/>artefato + meta"}
        D -->|bloqueado| F["devolve ao agente dono<br/>com o defeito específico"]
        D -->|aprovado| E["para e reporta<br/>+ report-back ao ticket"]
        F -. "corrigido, rode de novo" .-> A
        E -. "rode de novo<br/>para avançar" .-> A
    end

    E ==> P(["produção"])
    P == "quebrou" ==> G

    subgraph EMERG["2 · EMERGÊNCIA — o relógio corre, o portão atrapalha"]
        direction TB
        G["/incident 'sintoma'"] --> H["o que mudou em 24h<br/>já vem coletado na abertura"]
        H --> I["fatos em 5 min<br/>+ severidade SEV1-4"]
        I --> J{"existe mitigação<br/>REVERSÍVEL?"}
        J -->|sim| K["mitiga e restaura<br/>SEM exigir causa raiz"]
        J -->|não| L["segue com<br/>o relógio à vista"]
        K --> M["causa raiz<br/>4 fases, 1 hipótese por vez"]
        L --> M
        M --> N["corrige<br/>teste de regressão primeiro"]
        N --> O["postmortem<br/>ações viram trabalho planejado,<br/>de volta ao /sdlc"]
    end

    NIGHT(["/nightly — fora do horário<br/>flaky · deps · docs-drift · gates"]) -. "achado vira trabalho" .-> T
```

As ondas dentro de `/sdlc`:

| Onda | Produz | Portão |
|---|---|---|
| 00 bootstrap | perfil da stack · plano com ondas, donos e portões | plano executável |
| 01 discovery | PRD testável · regras de domínio · pesquisa UX | requisitos testáveis |
| 02 design | arquitetura + ADRs · contratos · modelo de dados · ameaças | design implementável |
| 03 build | código, com teste que falha primeiro | — |
| 04 quality | testes · review · segurança · performance | sem blockers |
| 05 delivery | observabilidade · pipeline · changelog | go / no-go com evidência |

## O modo emergência

```
/incident "checkout retornando 500 desde as 14h"
```

Quando algo quebra em produção, o fluxo planejado atrapalha. `/incident` inverte as prioridades:

```
   ↓  fatos em 5 min      sintoma observável · impacto · desde quando · o que já mexeram
   ↓  severidade          SEV1–4 decide quanto processo roda
   ↓  MITIGAR             reversível, sem exigir causa raiz — rollback, flag, escalar, failover
   ↓  diagnosticar        4 fases, uma hipótese por vez, hipótese refutada fica registrada
   ↓  corrigir            só com causa confirmada, teste de regressão primeiro
   ↓  postmortem          por que não detectamos antes · por que passou no review
```

A regra que faz isso ser rápido **e** assertivo: **mitigar não é corrigir**. Mitigação é
reversível e dispensa causa raiz; correção exige causa raiz sempre. Confundir os dois é o que
produz o segundo incidente.

A evidência de "o que mudou nas últimas 24h" já vem coletada na abertura, em algumas dezenas de
milissegundos.

Detalhes: [`skills/README.md`](skills/README.md) · [`workflow/README.md`](workflow/README.md).

## Onde as coisas ficam

No **projeto alvo**, não aqui:

```
docs/sdlc/
├── 00-orchestration/  plan.md · stack-profile.md · MANIFEST.md · artifact-ledger.tsv
├── 01-discovery/      prd.md · domain.md · ux-research.md
├── 02-design/         architecture.md · adr/ADR-NNN-*.md · api/ · data-model.md
│                      ux-spec.md · threat-model.md
├── 03-build/          implementation-log.md · data-pipelines/ · ai/
├── 04-quality/        test-plan.md · review-*.md · security-audit.md · performance-*.md
├── 05-delivery/       pipeline.md · observability.md · release-*.md
└── 06-docs/           doc-status.md

docs/incidents/<data>-<slug>/    incident.md · root-cause.md   (fora do sdlc: não é uma fase)

.claude/toolbelt.md      a calibração do /setup — versione, é contexto de time
.claude/meta.tsv         as metas de qualidade do projeto — o número que os portões 3 e 4 conferem
.claude/meta-baseline.tsv  o ponto de partida das metas de catraca, congelado por decisão
.mcp.json                servidores MCP com escopo de projeto — é este arquivo que a detecção lê
.claude/settings.json    os hooks apontando para a âncora
.claude/ai-toolkit       link para esta oficina
.claude/logs/guard.tsv   toda negação de fronteira, com carimbo de tempo
```

Num **workspace**, essa árvore fica na raiz e descreve o sistema. Código, teste e o histórico de
cada serviço ficam no repositório do membro:

```
smart/                        ← a sessão abre aqui
├── docs/sdlc/                ← PRD, arquitetura, ADRs, contratos ENTRE membros
├── .claude/                  ← toolbelt, hooks, âncora
├── micro-services/dafe-pix/  ← repo próprio: código, teste, git, deploy
├── micro-services/dafe-gateway/
└── front-end/solve-report/
```

## Quando algo falha

| Sintoma | Comando |
|---|---|
| "Será que este projeto está fiado?" | `./workspace/go check <nome>` |
| Mexi em `agents/`, `skills/` ou `workflow/` | `./agents/install.sh --check` |
| Um agente afirma coisa errada sobre o projeto | `/setup` — calibração velha |
| Não sei em que fase o trabalho está | `/sdlc-status` |
| "O portão passou mesmo?" | `/sdlc-gate <n>` |
| Servidor MCP não responde | `claude mcp list` — configurado ≠ conectado |
| Hooks não bloqueiam nada | `command -v jq` — sem `jq` eles falham em modo aberto |

Os 11 scripts de `tools/` também rodam direto no shell, sem sessão — todos somente leitura:

```bash
tools/repo-facts.sh              # manifests, versões, comandos declarados, estado do git
tools/diff-scope.sh [base]       # escopo do diff e áreas de risco
tools/sdlc-state.sh              # fase atual lida do disco
tools/artifact-lint.sh [fase]    # sai com código 1 quando o artefato está incompleto
tools/meta-check.sh              # sai com código 1 quando o projeto está fora da meta que declarou
tools/incident-evidence.sh 24    # o que mudou nas últimas 24h
tools/git-conventions.sh         # formato de commit, branch e MR do time
```

Referência completa: [`tools/README.md`](tools/README.md).

Para amarrar um servidor MCP a um projeto em vez de globalmente:

```bash
claude mcp add --scope project <nome> <comando-ou-url>
claude mcp list    # confirme que conecta antes de contar com ele
```

Outras opções do instalador:

```bash
./agents/install.sh            # projeto: .claude/{agents,skills,settings.json} + âncora
./agents/install.sh --user     # global: ~/.claude/{agents,skills}
./agents/install.sh --check    # só valida, não instala
./agents/install.sh --no-hooks # agentes e skills, sem tocar em settings.json
```

## O que faz esse fluxo funcionar

Seis mecanismos, e nenhum deles é "o prompt é bom":

1. **Contrato de artefato** — cada agente escreve num caminho fixo em `docs/sdlc/`, então a saída
   de um é literalmente a entrada do próximo. Sem passagem de contexto manual.
2. **Gates com evidência** — nenhuma onda avança sem que os artefatos da anterior existam e passem
   nos critérios. `tools/artifact-lint.sh` sai com código 1 quando um artefato está incompleto,
   o que torna o portão real e não uma sugestão. E `tools/meta-check.sh` faz o mesmo com o
   **número**: a meta que o projeto declarou no `/setup` é conferida contra o relatório que a
   rodada real produziu, não contra a afirmação de um agente. Relatório ausente ou mais velho que
   o código é não verificável — e não verificável bloqueia, igual a meta descumprida. É o que
   tira "orçamento de performance atendido, quando existir" do julgamento e põe num exit code.
3. **Fronteiras em runtime** — um hook nega, por caminho, que agentes de especificação escrevam
   código ou artefatos de outras fases. O que o frontmatter não consegue expressar, o hook impõe.
4. **Ferramental detectado, não assumido** — nenhum agente declara `tools:`, então todos herdam as
   ferramentas MCP da sessão. A skill `mcp-toolbelt` roda uma detecção no carregamento e injeta o
   ferramental **daquele** projeto: remotes git, CLIs, servidores MCP, manifests. Ajuste por
   projeto em `.claude/toolbelt.md`, que tem precedência sobre a detecção.
5. **Um formato de projeto detectado, não declarado** — repo único e workspace multi-repo são
   reconhecidos em runtime pela mesma regra: raiz que é repositório git nunca é workspace. Os
   scripts que dependem de git percorrem os repositórios em vez de desistir, e o toolbelt reporta
   os remotes reais — dizer "sem remote git" com 17 repositórios seria uma afirmação falsa injetada
   em toda invocação de agente. O que esses scripts **não** fazem é inferir arquitetura do layout:
   dizem onde o código está, e avisam na própria saída que isso não descreve o desenho.
6. **Um caminho só para o toolkit** — skills e hooks alcançam `tools/` e `workflow/hooks/` por
   `${CLAUDE_PROJECT_DIR}/.claude/ai-toolkit/…`, uma âncora criada aqui pelo `install.sh` e em cada
   projeto pelo `workspace/go`. É o que permite o mesmo texto de skill funcionar nos dois lugares —
   e os hooks, que resolvem o projeto por variável de ambiente e não pelo próprio caminho, gravam
   o ledger no projeto alvo.

   A âncora aponta para **`.toolkit/`**, não para a raiz desta oficina. A raiz tem um `.claude/`
   dentro, e esse `.claude/` tem a própria âncora: apontar para a raiz encadearia
   `.claude/ai-toolkit/.claude/ai-toolkit/…` sem fim. Não era teoria — com a âncora na raiz,
   `find -L .claude -name SKILL.md` devolvia **85** resultados num repositório com **16** skills.
   `.toolkit/` expõe só `tools/`, `workflow/`, `skills/` e `mcp/`, e não contém `.claude/`.

   **O `.claude/` do seu projeto e o desta oficina coexistem, e nenhum enxerga o outro.** A
   instalação nunca substitui o que já existe: reaproveita o `.claude/` do projeto, mescla os
   hooks no `settings.json` (e recusa, avisando, se já houver um bloco `hooks` diferente), e
   instala os 28 agentes em **escopo de usuário** (`~/.claude`) — então `.claude/agents/` e
   `.claude/skills/` do seu projeto ficam intactos.

---

## O que está decidido e ainda não existe

`plans/` guarda **só** trabalho já analisado a ponto de ser executável, e ainda não construído.
Nada listado lá está no ar.

A pasta existe porque análise sem registro apodrece: a decisão tomada numa conversa — junto com a
medição que a sustenta — se perde, e a próxima sessão refaz o mesmo estudo para chegar à mesma
conclusão. Por isso um plano só entra com **evidência medida**: número, saída de comando ou
caminho de arquivo. Sem isso é vontade, não plano.

| Plano | Sobre |
|---|---|
| [`plans/grafo-de-codigo.md`](plans/grafo-de-codigo.md) | Grafo de símbolos para os agentes responderem "quem chama isto" por consulta, e não por grep |

Plano **descartado fica no repositório, com o motivo** — é o registro mais barato contra refazer a
mesma análise para chegar à mesma recusa. Entregue, o conteúdo migra para o README da pasta que
passa a descrevê-lo e o arquivo de plano é apagado.

Detalhes e o formato obrigatório: [`plans/README.md`](plans/README.md).

## Material do MBA

`prompts/mba-ia-prompt-engineering/` — capítulos práticos: tipos de prompt, workflows de agentes,
versionamento com LangSmith, prompts enriquecidos (ITER-RETGEN) e evaluation.

`prompts/prompt-library/` e `prompts/prompt-library-en/` — biblioteca de prompts de produção
versionada, com datasets, avaliadores e schema de validação.

Cada capítulo tem **um venv e um `requirements.txt` próprios** — nunca instale dependência na raiz.
Setup por capítulo: [`prompts/mba-ia-prompt-engineering/AGENTS.md`](prompts/mba-ia-prompt-engineering/AGENTS.md).
