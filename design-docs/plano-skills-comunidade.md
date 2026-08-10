# Plano — Adoção de Skills da Comunidade

> **Status:** planejamento, nada instalado
> **Pesquisa e auditoria:** 2026-08-01 · **2ª rodada (graphify):** 2026-08-10
> **Escopo:** avaliar as melhores skills de desenvolvimento de software criadas pela
> comunidade, validar a segurança delas, e definir o que (e como) incorporar a este repositório.

---

## 1. Contexto e objetivo

Este repositório já tem uma equipe de agentes e um fluxo SDLC próprio (`skills/sdlc-*`,
`agents/00-07`). O objetivo desta pesquisa **não** é substituir isso — é identificar onde o
ecossistema aberto é mais forte que a nossa implementação atual e importar apenas esse delta.

Duas perguntas foram respondidas antes de qualquer decisão de adoção:

1. **Quais são as melhores skills de desenvolvimento criadas pela comunidade?** (seção 2)
2. **É seguro baixá-las?** — em dois sentidos distintos: executam código perigoso (seção 3)
   e compartilham dados com quem as criou (seção 4).

---

## 2. Pesquisa — o estado da arte

Levantamento feito via API do GitHub, ordenado por estrelas, com inspeção do conteúdo real
de cada repositório (quais skills vêm dentro, não só a descrição).

### 2.1 Metodologia completa de desenvolvimento

| Repositório | ⭐ | Conteúdo |
|---|---|---|
| [obra/superpowers](https://github.com/obra/superpowers) | 263k | `brainstorming`, `writing-plans`, `executing-plans`, `subagent-driven-development`, `test-driven-development`, `systematic-debugging`, `requesting-code-review`, `receiving-code-review`, `verification-before-completion`, `using-git-worktrees`, `dispatching-parallel-agents`, `finishing-a-development-branch`, `writing-skills` |
| [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) | 81k | 24 skills, ciclo `/spec → /plan → /build → /test → /review → /ship`. Destaques: `code-review-and-quality`, `debugging-and-error-recovery`, `spec-driven-development`, `doubt-driven-development`, `context-engineering`, `observability-and-instrumentation`, `deprecation-and-migration`, `code-simplification`, `incremental-implementation`, `source-driven-development` |
| [anthropics/skills](https://github.com/anthropics/skills) | 165k | Oficial. Relevantes para dev: `skill-creator`, `webapp-testing`, `mcp-builder`, `frontend-design`, `claude-api` |

### 2.2 Coleções por stack / especialista

| Repositório | ⭐ | Conteúdo |
|---|---|---|
| [Jeffallan/claude-skills](https://github.com/Jeffallan/claude-skills) | 10.8k | 66 skills de especialista: `python-pro`, `golang-pro`, `rust-engineer`, `typescript-pro`, `java-architect`, `spring-boot-engineer`, `nextjs-developer`, `react-expert`, `postgres-pro`, `sql-pro`, `kubernetes-specialist`, `terraform-engineer`, `microservices-architect`, `legacy-modernizer`, `secure-code-guardian`, `security-reviewer`, `playwright-expert`, `test-master`, `database-optimizer`, `sre-engineer`, `graphql-architect`, `mcp-developer`, `chaos-engineer` |
| [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills) | 29.6k | Oficial Vercel: `react-best-practices`, `web-design-guidelines`, `deploy-to-vercel`, `react-native-skills`, `composition-patterns`, `vercel-optimize` |

### 2.3 Skills pontuais

| Repositório | ⭐ | Para quê |
|---|---|---|
| [SawyerHood/dev-browser](https://github.com/SawyerHood/dev-browser) | 6.5k | Browser real para o agente validar o que construiu |
| [OthmanAdi/planning-with-files](https://github.com/OthmanAdi/planning-with-files) | 25.8k | Planos em markdown que sobrevivem a `/clear` e compactação |
| [muratcankoylan/Agent-Skills-for-Context-Engineering](https://github.com/muratcankoylan/Agent-Skills-for-Context-Engineering) | 17.5k | Arquitetura multi-agente e gestão de contexto |
| [agentskills/agentskills](https://github.com/agentskills/agentskills) | 23.6k | **Especificação** do formato Agent Skills — útil para escrever as nossas de forma portável |
| [vercel-labs/skills](https://github.com/vercel-labs/skills) | 27.5k | A CLI `npx skills` — virou o padrão de instalação em 70+ agentes |
| [Graphify-Labs/graphify](https://github.com/Graphify-Labs/graphify) | 105k | Skill `/graphify`: transforma o repositório num **grafo de conhecimento consultável** (AST via tree-sitter, sem embeddings, sem vector store). Ver §2.4 |

### 2.4 Nota de método — uma lacuna na busca

A pesquisa inicial usou busca por palavra-chave em nome e descrição (`"claude skills"`,
`"agent skills"`, `"claude code skills software engineering"`), ordenada por estrelas.
Esse método **não encontra ferramenta cuja identidade primária é outra coisa**, mesmo que
ela publique uma skill.

O `Graphify-Labs/graphify` (105k ⭐, Apache-2.0, topics `claude-code` e `skills`) passou
batido exatamente por isso: apresenta-se como *knowledge graph*, não como coleção de skills.
Foi apontado depois, auditado, e está incluído aqui.

**Correção de método para a próxima rodada:** buscar também por *capacidade* — busca de
código, análise de dependência, migração, observabilidade — e por topic do GitHub
(`topic:claude-code`, `topic:skills`), não só por nome.

### 2.5 Onde garimpar depois

`VoltAgent/awesome-agent-skills` (29k, 1000+ skills) · `ComposioHQ/awesome-claude-skills` (71k) ·
`davepoon/buildwithclaude` (hub de skills + agents + hooks) ·
`majiayu000/claude-skill-registry` (registry com busca web)

---

## 3. Auditoria de segurança — execução de código

**Método:** clone raso dos 8 repositórios (~70 MB) e varredura por seis vetores:
bypass de permissão, prompt injection, pipe-to-shell, acesso a segredos, hooks
auto-executáveis e egress de rede.

### 3.1 Veredito

**Nenhum código malicioso encontrado.** Zero ocorrências de exfiltração, backdoor,
ofuscação, `curl | sh`, leitura de `~/.ssh` / `.env` / credenciais, ou instruções de
prompt injection. Todos os hits dos greps por padrões perigosos eram falsos positivos:
harness de teste, type definitions do Playwright, ou — ironicamente — **conselhos
defensivos** (o `browser-testing-with-devtools` do Addy ensina explicitamente o agente
a nunca tratar conteúdo de DOM como instrução).

| Repositório | Risco | Nota |
|---|---|---|
| anthropics/skills | 🟢 Baixo | Oficial, sem hooks, sem scripts de rede |
| vercel-labs/agent-skills | 🟢 Baixo | Só markdown + `deploy.sh` (`rm -rf` no próprio `$TEMP_DIR`) |
| Jeffallan/claude-skills | 🟢 Baixo | 100% markdown, sem hooks, sem executáveis |
| obra/superpowers | 🟡 Médio | Hook SessionStart + servidor HTTP local |
| addyosmani/agent-skills | 🟡 Médio | Hook SessionStart + cache de WebFetch em disco |
| OthmanAdi/planning-with-files | 🟡 Médio | Superfície de hooks bem ampla |
| vercel-labs/skills (CLI) | 🟡 Médio | Endpoint de terceiro no caminho de install |
| SawyerHood/dev-browser | 🟠 Atenção | Baixa binário nativo **sem verificação de integridade** |
| Graphify-Labs/graphify | 🟢 Baixo | Python, superfície maior — mas auditado limpo. Ver §3.3 |

### 3.2 Achados

**A1 — dev-browser: binário sem checksum.**
`scripts/postinstall.js` baixa binário de
`github.com/SawyerHood/dev-browser/releases/download/v<versão>/` e aplica `chmod 755`.
O slug confere com o repositório real e o download é HTTPS, mas **não há verificação de
SHA256, checksum ou assinatura** (grep por `sha256|checksum|integrity|signature` = 0).
Se a conta npm ou os assets de release fossem comprometidos, executaríamos binário
arbitrário. É o padrão da indústria para módulos nativos (esbuild, swc fazem igual), mas
é o item de maior privilégio do conjunto.

**A2 — Hooks executam sem pedir permissão.**
Superpowers e Addy registram `SessionStart`. O planning-with-files registra o conjunto
completo (`PreToolUse`, `PostToolUse`, `Stop`, `PreCompact`, `UserPromptSubmit`,
`SessionStart/End`), replicado em 8+ diretórios de IDE. Hooks rodam com o nosso shell,
sem prompt de aprovação. Não é malicioso — é a natureza do mecanismo — mas é a
superfície que muda a cada atualização do plugin.

**A3 — Cache de WebFetch grava conteúdo web no projeto.**
O `sdd-cache-post.sh` do Addy escreve o corpo de toda resposta de WebFetch em
`.claude/sdd-cache/<sha>.json`. O `curl -sI` que ele faz é apenas HEAD, para pegar
ETag/Last-Modified da **mesma URL** que o agente já buscou — nada é enviado para fora.
Mas se fizermos WebFetch de algo interno, isso encosta em disco.
→ **Ação:** `.claude/sdd-cache/` no `.gitignore`.

**A4 — `npx skills` contata domínio de terceiro.**
A CLI fala com `skills.sh`, `api.github.com`, `raw.githubusercontent.com` e
`connectors-skills.zapier.com`. O endpoint da Zapier está numa allowlist que **só dispara
para o repo `zapier/connectors`** — nunca é tocado nos demais.

**A5 — Superpowers sobe servidor HTTP local.**
A skill `brainstorming` inicia servidor Node. Higiene boa: bind em `127.0.0.1` por padrão,
porta alta aleatória, chave por sessão, timeout de idle. `0.0.0.0` só via flag explícita.

**A6 — Licenças.** MIT em 6 repositórios. `anthropics/skills` e `vercel-labs/agent-skills`
**não declaram licença** (sem arquivo LICENSE, sem SPDX na API). Relevante se formos
redistribuir ou derivar conteúdo deles aqui.

### 3.3 Auditoria específica — graphify

Avaliado separadamente por ser o único candidato com **código executável de verdade**
(Python, 21 MB) em vez de markdown, e por vir de empresa YC (S26) com plataforma
comercial paga — combinação onde o README não serve como evidência.

O `README` claima *"nothing leaves your machine"* e *"no telemetry, no usage tracking,
no analytics"*. **Ambas as afirmações se confirmaram no código:**

| Verificação | Resultado |
|---|---|
| SDK de telemetria | Nenhum. O único hit com "telemetry" é um comentário declarando a postura |
| Upload do grafo para fora | Nenhum `requests.post` / `httpx.post` / `urlopen` no pacote |
| `app.graphify.com` no código | **1 ocorrência, dentro de um `print()`** — linha de marketing impressa no terminal após o install. Zero chamada de rede |
| Log de queries | **OFF por padrão**, confirmado em `querylog.py`. Exige `GRAPHIFY_QUERY_LOG_ENABLE=1` explícito |
| `SECURITY.md` | Declara modelo de segurança real: ferramenta local, sem chamada de rede durante análise, só no `ingest` iniciado pelo usuário |

**Domínios encontrados e por quê:** `api.anthropic.com`, `api.openai.com`,
`generativelanguage.googleapis.com`, `api.deepseek.com`, `api.moonshot.ai`, Azure —
todos são o **provider LLM que você escolhe e configura com a sua chave**, usados apenas
no passo semântico opcional sobre docs/PDF/imagem. Parsing de código é 100% local via
tree-sitter, sem LLM. `unpkg.com`/`d3js.org`/`cdn.jsdelivr.net` são bibliotecas do
`graph.html` de visualização. `localhost` é Ollama.

**Comportamento a saber (não é falha):** o `graphify install` escreve em
`~/.claude/skills/graphify/` e registra uma seção no `CLAUDE.md` do projeto. O código de
remoção é cuidadoso — casa o H1 exato `# graphify` e nunca um `##`/`###` do usuário, com
referência à issue #2062 onde isso foi corrigido. Sinal de maturidade, mas fica o registro
de que **ele edita o seu CLAUDE.md**.

**Ressalvas não-técnicas:** versão 0.3.x (pré-1.0, API pode mudar) e o incentivo comercial
de funilar para a plataforma hospedada. Nenhum dos dois é problema de segurança — são
considerações de estabilidade e dependência.

**Veredito:** 🟢 risco baixo. Saiu **mais limpo que vários dos 8 originais** — tem política
de segurança declarada, log desligado por padrão e nenhuma coleta.

---

## 4. Auditoria de segurança — compartilhamento de dados

Pergunta específica: **essas skills mandam dados nossos de volta para quem as criou?**

### 4.1 Veredito

**Não. Nenhuma delas compartilha dados com o criador.**

Estruturalmente: uma skill é **markdown**. Markdown não faz requisição de rede. Ele é lido
para dentro do contexto do nosso agente e para por aí — não há runtime, callback, nem
servidor de licença. A única forma de uma skill "ligar para casa" é trazendo script, hook
ou binário que faça isso. Todos foram auditados.

### 4.2 Evidências

**B1 — Zero SDK de telemetria.** Varredura por posthog, segment, mixpanel, amplitude,
google-analytics, plausible, sentry, datadog, umami, fathom, `trackEvent`, `beacon`:
nenhuma ocorrência real. Os únicos hits com a palavra "telemetry" são a skill do Addy
**ensinando** observabilidade (inclusive com a regra "nunca logue segredos, tokens ou PII").

**B2 — Inventário completo de domínios em código executável.** Toda URL de todo `.sh`,
`.js`, `.ts`, `.py`, `.json` dos 8 repositórios:

| Domínio | O que é |
|---|---|
| playwright.dev, MDN, w3.org, react.dev, nextjs.org | Links de documentação em comentários |
| registry.npmjs.org, opencollective.com | Metadados de lockfile — não são requisições |
| github.com | Links de issue + download de release |
| localhost, 127.0.0.1 | Servidores locais |
| example.com, myproxy.com, gitlab.example.com | Fixtures de teste |
| skills.sh, vercel.com | A CLI de instalação |

**Não existe um único domínio controlado por autor de skill.** Nada de `obra.*`,
`addyosmani.com`, nem endpoint pessoal de Jeffallan, OthmanAdi ou SawyerHood.
Se houvesse coleta, apareceria aqui.

**B3 — A CLI `npx skills` não reporta instalação.** As três chamadas `fetch()` não declaram
`method:` (logo, GET) e não têm `body:`. São downloads puros:
GitHub Trees API → raw.githubusercontent → snapshot.

**B4 — Nenhuma skill manda o agente enviar dados.** Este era o vetor sutil: não precisaria
de código malicioso, bastaria uma instrução tipo "poste os resultados em tal endpoint" que
o nosso próprio agente executaria. Grep específico: nada.

**B5 — O daemon do dev-browser não contata domínio externo.** As duas ocorrências de
github.com são comentários citando issues do Playwright.

### 4.3 O que os autores realmente veem

Apenas o que o GitHub dá a qualquer dono de repositório: **contagem agregada e anônima**
de clones e visitantes. Sem identidade, sem conteúdo. Usando `npx skills`, o `skills.sh`
(infra da Vercel, não do autor da skill) vê IP e qual skill foi baixada — log de CDN padrão.
Nada disso inclui nosso código, prompts ou projeto.

### 4.4 Ressalva honesta

Foi auditado o **código-fonte**. O binário nativo que o `dev-browser` baixa no `postinstall`
é compilado e **não foi inspecionado** — não dá para verificar por leitura de fonte, e vem
sem checksum. É o único item onde não há afirmação por evidência direta. Os outros 7
repositórios são markdown e scripts em texto puro, integralmente auditáveis — e auditados.

---

## 5. Análise de sobreposição com o nosso SDLC

| Deles | Nosso equivalente | Decisão |
|---|---|---|
| superpowers (metodologia completa) | `skills/sdlc-*` + `agents/00-07` | **Não instalar.** Conflito de autoridade. Importar conceitos. |
| addyosmani (ciclo spec→ship) | `skills/sdlc-*` | **Não instalar.** Mesmo motivo. Importar conceitos. |
| Jeffallan (especialista por stack) | — (lacuna real) | **Adotar seletivamente.** `sdlc-build` hoje roteia para engenheiro genérico. |
| vercel-labs (React/Next) | — | **Adotar se houver projeto React/Next** no `workspace/`. |
| anthropics `skill-creator` | — | **Adotar.** Melhora as skills que já escrevemos. |
| dev-browser | `skills/verify-live` + claude-in-chrome | **Não adotar.** Já coberto, e evita o binário sem checksum. |
| planning-with-files | `docs/sdlc/` (artefatos em disco) | **Avaliar.** Já persistimos, mas a recuperação de sessão deles é mais dura. |
| agentskills (spec) | — | **Ler.** Referência para portabilidade das nossas skills. |
| graphify (grafo do código) | `agents/project-analyst` (hoje: grep e leitura) | **Adotar — candidato mais forte.** Ver §5.1. |

### 5.1 Por que graphify é o candidato de maior valor

É o único da lista que resolve um problema que **não temos solução nenhuma** hoje, em vez
de competir com algo que já fizemos:

- O `project-analyst` mapeia stack e convenções **grepando e lendo arquivo por arquivo**.
  Um grafo consultável troca isso por travessia dirigida.
- O `business-analyst` tem como caso de uso declarado *"reverse-engineer as regras já
  enterradas em código legado"* — que é literalmente para isso que a ferramenta existe.
- O `sdlc-discovery` em repositório desconhecido é hoje a fase mais cara em tokens.

E o custo de contexto é **zero**: diferente de superpowers e addyosmani, graphify não
injeta metodologia opinativa que disputa autoridade com o nosso SDLC (§5.2). É uma
ferramenta que o agente chama, não um fluxo que compete com o nosso.

### 5.2 O risco que mais importa não é de segurança

As auditorias vieram limpas. O risco real de adotar `superpowers` ou `addyosmani` é de
**governança de contexto**: são metodologias opinativas que entram direto no prompt e vão
**competir com o nosso `sdlc/` pela autoridade sobre como o agente trabalha**. Duas
metodologias ativas ao mesmo tempo produzem portões duplicados e roteamento ambíguo.
Isso não aparece em nenhum scanner de segurança — e é o que mais provavelmente vai
causar problema.

---

## 6. Plano de implementação

### 6.0 Princípio de instalação — a oficina absorve, o projeto não recebe nada

Este repositório é a **oficina**: ele manipula outros projetos, e nenhum trabalho de produto
acontece aqui. A fiação real, lida do `workspace/go` e do `agents/install.sh`, é:

| Onde | O quê | Como |
|---|---|---|
| `~/.claude/skills/` e `~/.claude/agents/` | A equipe inteira | `./agents/install.sh --user` cria symlinks para as fontes versionadas em `agents/` e `skills/` |
| `<projeto>/.claude/ai-toolkit` | Symlink para este repo | Criado pelo `go`, dá acesso a `workflow/hooks` e `tools/` |
| `<projeto>/.claude/settings.json` | Aponta os hooks para o toolkit | Criado pelo `go` |
| `<projeto>/.claude/toolbelt.md` | Calibração daquele projeto | Gerado pelo `/setup` na primeira sessão |

**A regra que decorre disso, e que vale para toda skill de terceiro:**

> Skill de terceiro entra **versionada na oficina** (`skills/` ou `agents/`) ou **em escopo de
> usuário** (`~/.claude/`). Nunca no repositório do projeto-alvo.

Três razões, todas concretas:

1. **O projeto-alvo é código de terceiro.** Regra já vigente: repositório só recebe código —
   análise, relatório e ferramental ficam fora. Instalar skill lá dentro é sujar repositório
   que não é nosso para sujar.
2. **Não escala.** Instalar por projeto significa repetir a instalação a cada `go add`, e
   divergir silenciosamente entre projetos.
3. **Perde o portão de validação.** O `install.sh` já valida nome duplicado de agente e skill,
   e exige que toda referência `skills:` no frontmatter resolva. Instalação ad-hoc pula isso.

**Consequência para os artefatos gerados:** qualquer saída que uma ferramenta de terceiro
produzir dentro do projeto (ex.: `graphify-out/`) precisa respeitar o contrato de `docs/sdlc/`
ou entrar no `.gitignore` do projeto. Ela não pode aparecer no diff que vai virar MR.

### Fase 0 — Guarda-corpos (antes de instalar qualquer coisa)

- [ ] Adicionar `.claude/sdd-cache/` ao `.gitignore` (achado A3)
- [ ] Definir política escrita: **instalar sem hooks primeiro**. `npx skills add <repo>` copia
      markdown; hooks só entram na instalação como plugin. Sem hooks se obtém ~90% do valor
      com quase nenhuma superfície de execução.
- [ ] Criar diretório de quarentena (`.claude/skills-quarentena/`, fora do path de carga)
      para avaliar skill nova antes de promover
- **Critério de aceite:** nenhuma skill de terceiro é carregada automaticamente sem passar
  pela quarentena.

### Fase 1 — Especialistas por stack (maior valor, menor risco)

Alvo: `Jeffallan/claude-skills` — 100% markdown, sem hooks, sem executáveis (risco 🟢).
Preenche lacuna real: hoje o `sdlc-build` roteia para engenheiro genérico.

Modo de adoção, conforme §6.0: **absorver na oficina**, não instalar ad-hoc. As skills
escolhidas viram arquivos versionados em `agents/` ou `skills/` deste repo, com a origem
citada no frontmatter, e são distribuídas pelo `install.sh --user` como todo o resto.

- [ ] Selecionar **apenas** as skills do stack real dos projetos em `workspace/`
      (candidatas: `java-architect`, `spring-boot-engineer`, `typescript-pro`,
      `nextjs-developer`, `react-expert`, `postgres-pro`, `sql-pro`, `kubernetes-specialist`,
      `terraform-engineer`, `playwright-expert`) — não as 66
- [ ] **Resolver colisão de nomes antes de copiar qualquer arquivo.** O `install.sh` falha
      com nome duplicado, e há colisão direta: o Jeffallan tem `api-designer`,
      `code-reviewer` e `devops-engineer` — os três já existem em `agents/`. O
      `security-reviewer` dele colide em papel com o nosso `security-auditor`. Decidir caso
      a caso: **fundir** o conteúdo no nosso agente existente, ou **renomear** com sufixo de
      stack (`java-architect` não colide; `api-designer` teria de virar outra coisa ou ser
      absorvido). Copiar sem resolver quebra a instalação da equipe inteira.
- [ ] Rodar `./agents/install.sh --check` após cada absorção — ele valida duplicidade e
      referências `skills:` do frontmatter
- [ ] Adaptar o `sdlc-build` para rotear ao especialista de stack quando existir
- **Critério de aceite:** `install.sh --check` passa, e um item de trabalho em Quarkus é
  roteado para o especialista Java — não para o engenheiro genérico — com o roteamento
  visível no artefato da onda 03.

### Fase 1B — Piloto do graphify (maior valor esperado)

Auditado 🟢 (§3.3). Roda em paralelo à Fase 1 — não há dependência entre elas.

**Correção sobre a versão anterior deste plano:** a primeira redação mandava usar
`graphify install --project` "para conter o blast radius". Está errado para esta arquitetura.
O `--project` escreve no `.claude/` e no `CLAUDE.md` do **projeto-alvo** — exatamente o que
§6.0 proíbe: sujar repositório de terceiro, não escalar, e exigir reinstalação a cada
`go add`. O certo é o **escopo de usuário**, o mesmo lugar onde o `install.sh --user` já
coloca a equipe.

- [ ] `uv tool install graphifyy` e `graphify install` em **escopo de usuário**
      (`~/.claude/skills/graphify/`) — sem `--project`, o repositório do projeto não recebe nada
- [ ] Confirmar que nenhum `CLAUDE.md` de projeto foi tocado após o install (§3.3 mostra que
      ele mexe nesse arquivo no modo `--project`)
- [ ] Garantir que `graphify-out/` **não entre no diff** do projeto-alvo: `.gitignore` local
      ou saída redirecionada para fora da árvore
- [ ] Definir `GRAPHIFY_QUERY_LOG_DISABLE=1` no ambiente — o log já é off por padrão,
      mas explícito é melhor que implícito
- [ ] Rodar `/graphify .` numa sessão aberta pelo `go` sobre um projeto real e comparar o
      custo em tokens de uma pergunta de arquitetura **com** o grafo versus o
      `project-analyst` grepando hoje
- [ ] Se aprovado: ligar ao `agents/project-analyst` e ao `sdlc-discovery`, e registrar a
      dependência no `mcp/README.md` — a equipe precisa saber que a ferramenta existe
- **Critério de aceite:** medida real de tokens/tempo nas duas abordagens sobre o mesmo
  repositório e a mesma pergunta, **e** `git status` limpo no projeto-alvo depois do uso.
  Adotar só se o ganho for demonstrável — sem número, não passa.

### Fase 2 — Importar conceitos (não código) de superpowers e addyosmani

Não instalar — canibalizar. Onde eles são mais fortes que o nosso fluxo hoje:

- [ ] `verification-before-completion` (superpowers) → comparar com `skills/sdlc-gate`
      e `skills/verify-live`; incorporar o delta
- [ ] `receiving-code-review` (superpowers) → hoje temos o lado de *fazer* review
      (`agents/04-quality`), não o de *receber* e agir sobre ele
- [ ] `doubt-driven-development` (addyosmani) → disciplina de duvidar do próprio resultado;
      comparar com `skills/practices`
- [ ] `context-engineering` (addyosmani) → gestão de contexto em tarefa longa
- [ ] `code-simplification` (addyosmani) → compara com a skill `simplify` nativa
- **Critério de aceite:** cada conceito importado vira um diff explícito numa skill nossa,
  com o repositório de origem citado no arquivo.

### Fase 3 — Ferramentas oficiais

- [ ] `anthropics/skills` → `skill-creator` (melhora as skills que escrevemos),
      `mcp-builder` (se formos construir MCP próprio), `webapp-testing`
- [ ] `vercel-labs/agent-skills` → só se houver projeto React/Next ativo no `workspace/`
- [ ] Registrar que ambos **não declaram licença** (achado A6) — não redistribuir conteúdo
      derivado sem verificar
- **Critério de aceite:** `skill-creator` usado para revisar pelo menos uma skill existente.

### Fase 4 — Portabilidade

- [ ] Ler a spec em `agentskills/agentskills` e avaliar aderência das nossas 16 skills
- [ ] Decidir se vale publicar parte do nosso SDLC no formato aberto
- **Critério de aceite:** relatório de aderência com lista de desvios.

### Fase 5 — Governança contínua

O commit auditado hoje está limpo. O risco é o commit de amanhã, em repositório com
263k estrelas e atualização automática.

- [ ] Pinar versão/SHA de tudo que for adotado — nunca `latest` com auto-update
- [ ] Transformar a auditoria da seção 3–4 em **checklist reutilizável** (anexo A) e rodá-la
      a cada atualização de skill de terceiro
- [ ] Revisar o diff antes de aceitar qualquer atualização
- **Critério de aceite:** checklist versionado no repo e executado ao menos uma vez sobre
  uma atualização real.

### Não fazer

- ❌ Instalar `superpowers` ou `addyosmani` como plugin por cima do nosso SDLC
      (conflito de autoridade — seção 5.1)
- ❌ Instalar `dev-browser` (`verify-live` + claude-in-chrome já cobrem, e evita o
      binário sem checksum — achado A1)
- ❌ Instalar as 66 skills do Jeffallan de uma vez (poluição de contexto)
- ❌ **Instalar qualquer skill de terceiro dentro do repositório do projeto-alvo** (§6.0).
      A oficina distribui via `~/.claude/`; o projeto recebe só o symlink `ai-toolkit` que
      o `go` já cria.
- ❌ Copiar skill de terceiro para `agents/`/`skills/` sem rodar `install.sh --check` —
      nome duplicado quebra a instalação da equipe inteira

---

## 7. Decisões pendentes

1. **Fase 1 depende do stack real** — precisa da lista de projetos ativos em `workspace/`
   para escolher os especialistas certos.
2. **`planning-with-files`** — vale a superfície de hooks dele, dado que `docs/sdlc/` já
   persiste artefatos? Decisão adiada até a Fase 2 mostrar se há lacuna de recuperação
   de sessão.
3. **Publicar nosso SDLC no formato aberto** (Fase 4) — decisão de produto, não técnica.

---

## Anexo A — Checklist de auditoria reutilizável

Rodar sobre qualquer skill de terceiro, antes de adotar e a cada atualização.

```bash
# Clonar raso em diretório descartável (nunca no repo)
git clone --depth 1 https://github.com/<owner>/<repo>.git /tmp/audit/<repo>
cd /tmp/audit/<repo>

# 1. Bypass de permissão / sandbox
grep -rniE -- "dangerously-skip-permissions|bypassPermissions|dangerouslyDisableSandbox|autoApprove" .

# 2. Prompt injection / ocultar do usuário
grep -rniE "ignore (all )?(previous|prior) instructions|do not (tell|inform) the user|without (telling|asking) the user|secretly" --include="*.md" .

# 3. Pipe-to-shell / exec dinâmico
grep -rniE "curl[^|]*\|[[:space:]]*(ba)?sh|wget[^|]*\|[[:space:]]*(ba)?sh|\beval[[:space:]]*\(|base64[[:space:]]+-d" .

# 4. Acesso a segredos
grep -rniE "\.ssh/|id_rsa|\.aws/credentials|\.env\b|API_KEY|GITHUB_TOKEN|netrc" --include="*.sh" --include="*.js" --include="*.py" .

# 5. Hooks (executam sem aprovação)
find . -name "hooks.json" -o -name "settings.json" -o -name "plugin.json" | grep -v node_modules

# 6. SDK de telemetria
grep -rniE "posthog|segment\.(io|com)|mixpanel|amplitude|google-analytics|plausible|@sentry|datadog|trackEvent|beacon" .

# 7. Inventário COMPLETO de domínios de saída — o teste decisivo de privacidade
grep -rhoE "https?://[a-zA-Z0-9.-]+" --include="*.sh" --include="*.js" --include="*.ts" --include="*.py" --include="*.json" . \
  | grep -v node_modules | sed -E 's|https?://||' | sort | uniq -c | sort -rn

# 8. Instruções para o AGENTE enviar dados (vetor indireto)
grep -rniE "(post|send|upload|submit)[[:space:]]+.*(code|data|result|output|findings)[[:space:]]+(to|via)[[:space:]]+(http|api|our|server)" --include="*.md" .

# 9. Lifecycle npm (executa no install)
grep -rl '"postinstall"\|"preinstall"\|"prepare"' --include="package.json" . | grep -v node_modules

# 10. Licença
ls LICENSE* 2>/dev/null; gh api repos/<owner>/<repo> --jq '.license.spdx_id'
```

**Critério de reprovação:** qualquer domínio no passo 7 que pertença ao autor da skill e não
seja documentação, npm registry, GitHub ou localhost. Qualquer hit real nos passos 1, 2, 4 ou 8.

---

## Anexo B — Como esta auditoria foi feita

**1ª rodada — 8 repositórios (2026-08-01)**

- Clone `--depth 1` (~70 MB) em diretório descartável
- 10 varreduras por padrões de risco, com inspeção manual de todo hit não trivial
- Leitura direta do código de: `sdd-cache-post.sh` (addyosmani), `postinstall.js` (dev-browser),
  `blob.ts` (vercel-labs/skills), `hooks.json` (superpowers e addyosmani),
  `start-server.sh` (superpowers), `daemon.ts` (dev-browser)

**2ª rodada — graphify (2026-08-10)**

- Mesmo checklist do Anexo A, aplicado ao ser apontado que faltava na 1ª rodada
- Leitura direta de: `querylog.py` (default do log), `install.py` (o que escreve e onde,
  incluindo a manipulação do `CLAUDE.md`), `SECURITY.md`, e o contexto exato da única
  ocorrência de `app.graphify.com`
- Serviu também como validação do checklist: ele pegou um repositório que a busca por
  palavra-chave tinha deixado passar (§2.4)

Nada foi instalado em nenhuma das rodadas; o repositório não foi modificado durante as auditorias.
