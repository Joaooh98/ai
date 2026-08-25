# Run Manifest — Docker devbox flow

## General information

| item | valor |
|------|-------|
| run name | Docker devbox flow (container development & execution) |
| plan of record | `docs/sdlc/00-orchestration/plan.md` |
| orchestrator | tech-lead-orchestrator |
| manifest owner | context-manager |
| status | wave 00 bootstrap (Gate 0 APROVADO) |
| expected directories | `docs/sdlc/{01-discovery,02-design,03-build,04-quality,05-delivery,06-docs}/` |

---

## Coverage checklist

| ID | title | owner | deliverable | status |
|----|-------|-------|-------------|--------|
| D1 | PRD do fluxo devbox | product-owner | `docs/sdlc/01-discovery/prd.md` | pendente |
| D2 | Domain rules e decision tables | business-analyst | `docs/sdlc/01-discovery/domain.md` | pendente |
| D3 | UX research: jornada do desenvolvedor | ux-researcher | `docs/sdlc/01-discovery/ux-research.md` | pendente |
| A1 | Arquitetura alvo + 3 ADRs | solution-architect | `docs/sdlc/02-design/architecture.md` + `docs/sdlc/02-design/adr/{ADR-001,ADR-002,ADR-003}.md` | pendente |
| T1 | Threat model STRIDE | threat-modeler | `docs/sdlc/02-design/threat-model.md` | pendente |
| I1 | Integrations: git, docker, registry | integration-engineer | `docs/sdlc/02-design/integrations.md` | pendente |
| C1 | CLI contract / subcommand spec | api-designer | `docs/sdlc/02-design/cli-contract.md` | pendente |
| B1 | Dockerfile.devbox + compose + entrypoint | devops-engineer | `workflow/docker/{Dockerfile.devbox,compose.devbox.yml,entrypoint.sh}` | pendente |
| B2 | CLI orchestrator `workspace/devbox` | backend-engineer | `workspace/devbox` | pendente |
| B3 | Skill `/devbox` | tech-writer | `skills/devbox/SKILL.md` | pendente |
| V1 | Test plan + smoke tests | test-engineer | `docs/sdlc/04-quality/test-plan.md` + `workflow/docker/test/devbox-smoke.sh` | pendente |
| V2 | Code review: B1/B2/B3 + risk audit | code-reviewer | `docs/sdlc/04-quality/review-devbox.md` | pendente |
| V3 | Security audit: threat model verification | security-auditor | `docs/sdlc/04-quality/security-audit.md` | pendente |
| V4 | Resilience drill: connection loss scenarios | sre-observability | `docs/sdlc/04-quality/resilience-drill.md` | pendente |
| V5 | Performance & disk budget audit | performance-engineer | `docs/sdlc/04-quality/performance.md` | pendente |
| R1 | SRE runbook: failure scenarios | sre-observability | `docs/sdlc/05-delivery/observability.md` | pendente |
| R2 | Release decision & gate verification | release-manager | `docs/sdlc/05-delivery/release-devbox.md` | pendente |
| R3 | Repository docs + skills tree | tech-writer | `docs/sdlc/06-docs/devbox-guide.md` + updates to `workspace/README.md` / `skills/README.md` | pendente |

---

## Tracked artifacts

| title | path | agent | timestamp | status |
|-------|------|-------|-----------|--------|
| Stack profile (baseline) | `docs/sdlc/00-orchestration/stack-profile.md` | project-analyst | 2026-07-30 | entregue |
| Plano de execução | `docs/sdlc/00-orchestration/plan.md` | tech-lead-orchestrator | 2026-07-30 | entregue |
| Veredito do Portão 0 | `docs/sdlc/00-orchestration/gate-00.md` | coordenador `/sdlc` | 2026-07-30 | entregue |

---

## Gate map

| gate | fase | avaliador | registro do veredito | checker de evidência | status |
|------|------|-----------|----------------------|----------------------|--------|
| 0 | Bootstrap | coordenador `/sdlc` | `docs/sdlc/00-orchestration/gate-00.md` | leitura integral de `stack-profile.md` + `plan.md`, com reexecução das afirmações sobre o ferramental | **APROVADO** |
| 1 | Discovery (D1/D2/D3) | solution-architect | `docs/sdlc/00-orchestration/gate-01.md` | `tools/artifact-lint.sh 01` exit 0 + skill gates.md checklist | não avaliado |
| 2 | Design (A1/T1/I1/C1) | code-reviewer | `docs/sdlc/00-orchestration/gate-02.md` | `tools/artifact-lint.sh 02` exit 0 + skill gates.md checklist | não avaliado |
| 3 | Build (B1/B2/B3) | context-manager | `docs/sdlc/00-orchestration/gate-03-build.md` | `./agents/install.sh --check` exit 0 + ponta-a-ponta smoke | não avaliado |
| 4 | Quality (V1/V2/V3/V4/V5) | release-manager | `docs/sdlc/00-orchestration/gate-04.md` | `tools/artifact-lint.sh 04` exit 0 + skill gates.md checklist | não avaliado |
| 5 | Release (R1/R2/R3) | release-manager + security-auditor | `docs/sdlc/00-orchestration/gate-05.md` | `tools/artifact-lint.sh all` exit 0 + skill gates.md checklist | não avaliado |

---

## Operational rule — verdict recording

**Fonte:** plan.md linha 123–126; `workflow/hooks/guard-artifacts.sh` restrições.

| fase | decisor | escreve veredito? | quem registra | onde |
|------|---------|-------------------|----------------|------|
| Discovery (Gate 1) | solution-architect | não | context-manager | `gate-01.md` |
| Design (Gate 2) | code-reviewer | não | context-manager | `gate-02.md` |
| Build (Gate 3) | — | — | context-manager | `gate-03-build.md` |
| Quality (Gate 4) | release-manager | não | context-manager | `gate-04.md` |
| Release (Gate 5) | release-manager + security-auditor | não | context-manager | `gate-05.md` |

**Motivo:** `guard-artifacts.sh` restringe:
- `solution-architect` → escrita permitida apenas em `docs/sdlc/02-design/`
- `code-reviewer` → escrita permitida apenas em `docs/sdlc/04-quality/`
- `security-auditor` → escrita permitida apenas em `docs/sdlc/04-quality/`

Portanto, o avaliador não pode escrever em `00-orchestration/`. O avaliador retorna veredito por mensagem; o `context-manager` registra.

---

## Known collisions — worktrees inspection required

**Fonte:** plan.md linha 291; Risco: "Trabalho duplicado em outra worktree".

| worktree | status | dono | ação |
|----------|--------|------|------|
| `.claude/worktrees/arch-conformance` | não inspecionada | context-manager | inspecionar branch + diff antes de Gate 2 |
| `.claude/worktrees/meta-e-mcp` | não inspecionada | context-manager | inspecionar branch + diff antes de Gate 2 |
| `.claude/worktrees/vault-secrets` | não inspecionada | context-manager | inspecionar branch + diff antes de Gate 2 |

**Bloqueia Gate 2 se:** qualquer worktree tiver branch/diff sobreposto ao plano deste run (mesmo espaço de design).

---

## Workflow notes (factual only)

- Bootstrap Onda 00: `stack-profile.md` (project-analyst, feito) → `plan.md` (tech-lead-orchestrator, feito) → `gate-00.md` (coordenador `/sdlc`, feito).
- Gate 0 registro: `docs/sdlc/00-orchestration/gate-00.md`, avaliado pelo coordenador do fluxo `/sdlc` — 5 critérios verificados, todos OK.
- Onda 1 paralela: D1, D2, D3 — três donos, três arquivos, todos de entrada para Gate 1.
- Onda 2 sequencial: A1 única — todo item Onda 3 (T1, I1, C1) depende dela.
- Onda 3 paralela: T1, I1, C1 — três donos, entrada comum A1, saída para Gate 2.
- Onda 4 paralela: B1, B2, B3 — costura C1 (contrato CLI), sem dependência cruzada.
- Onda 5 paralela: V1–V5 — cinco donos, entrada comum é o código + design, saída para Gate 4.
- Onda 6 paralela: R1, R2, R3 — entrada comum todos os portões anteriores.
- Bilingual artifact requirement: Ondas 1, 2, 3, 4, 5 com títulos em inglês + português; ACs em formato `Given/Dado … When/Quando … Then/Então`. Critério: saída `OK` de `tools/artifact-lint.sh`, não impressão visual.
- MCP_DOCKER proibido (quebrado desde 27/07/2026): só CLI `docker` como `preview-env.sh` e `verify-live` usam.
- Convenção `tools/` read-only: nenhum script em `tools/` pode fazer `docker run`, `git clone`, ou alterar arquivo. Precedente correto: `workspace/go` (efeito colateral permitido). ADR-003 decide o local do artefato.
- Disco: `df -h /` registra 468G total, 411G usados, **34G disponíveis**. Folga confortável para build de imagem. Risco mitigado com precheck em B2.

---

## Ressalvas do Gate 0 — dono e prazo registrados

**Fonte:** `gate-00.md` seção "Ressalvas registradas".

| ID | Ressalva | Quando afeta | Dono | Prazo |
|----|----------|--------------|------|-------|
| R-1 | `gates.md` contém itens inaplicáveis (paginação, índices, expand/contract, estado vazio de tela). Cabeçalho diz "não verificado bloqueia igual a falha". Aplicado ao pé da letra, Gate 2 trava. | Gate 2 e Gate 4 | Avaliador Gate 2 (`code-reviewer`) | Marcar cada item inaplicável como **N/A com justificativa** em `gate-02.md` |
| R-2 | Dependência intra-onda Onda 1: D2 e D3 declaram D1 como entrada, mas onda é paralela. Mesmo em Onda 6: R3←R1. | Onda 1 e Onda 6 | Coordenador | Despachar D1 primeiro e D2/D3 com rascunho, ou passar Q1-Q8 como entrada comum. Mesmo para R1→R3. |
| R-3 | Premissa não confirmada: entregável é ferramenta que *este* repo distribui, não conteinerização do repo. Evidência sustenta (README:14, toolbelt:9-10), mas é a que mais muda o resultado. | Onda 1 (D1) | `product-owner` | Confirmar com usuário como primeira linha do PRD |
| R-4 | Worktrees irmãs não inspecionadas. Risco desenho concorrente. | Antes de Gate 2 | `context-manager` | Listar branch + diff de cada uma antes do Gate 2 |
