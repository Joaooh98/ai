# Plano — Adoção de Skills da Comunidade

> **Status:** planejamento, nada instalado
> **Data da pesquisa e auditoria:** 2026-08-01
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

### 2.4 Onde garimpar depois

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

### 5.1 O risco que mais importa não é de segurança

As auditorias vieram limpas. O risco real de adotar `superpowers` ou `addyosmani` é de
**governança de contexto**: são metodologias opinativas que entram direto no prompt e vão
**competir com o nosso `sdlc/` pela autoridade sobre como o agente trabalha**. Duas
metodologias ativas ao mesmo tempo produzem portões duplicados e roteamento ambíguo.
Isso não aparece em nenhum scanner de segurança — e é o que mais provavelmente vai
causar problema.

---

## 6. Plano de implementação

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

- [ ] Selecionar **apenas** as skills do stack real dos projetos em `workspace/`
      (candidatas: `java-architect`, `spring-boot-engineer`, `typescript-pro`,
      `nextjs-developer`, `react-expert`, `postgres-pro`, `sql-pro`, `kubernetes-specialist`,
      `terraform-engineer`, `playwright-expert`, `security-reviewer`) — não as 66
- [ ] Verificar conflito de nome com `agents/` existentes (ex.: já temos `api-designer`,
      `code-reviewer`, `devops-engineer`, `quarkus-senior-developer`)
- [ ] Adaptar o `sdlc-build` para rotear ao especialista de stack quando existir
- **Critério de aceite:** um item de trabalho em Quarkus é roteado para o especialista Java,
  não para o engenheiro genérico, e o roteamento aparece no artefato da onda 03.

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

- 8 repositórios clonados com `--depth 1` (~70 MB) em diretório descartável
- 10 varreduras por padrões de risco, com inspeção manual de todo hit não trivial
- Leitura direta do código de: `sdd-cache-post.sh` (addyosmani), `postinstall.js` (dev-browser),
  `blob.ts` (vercel-labs/skills), `hooks.json` (superpowers e addyosmani),
  `start-server.sh` (superpowers), `daemon.ts` (dev-browser)
- Nada foi instalado; o repositório não foi modificado durante a auditoria
