# Portão 0 — Bootstrap

**Veredito:** APROVADO
**Avaliador:** coordenador `/sdlc`
**Data:** 2026-07-30
**Artefatos avaliados:** `stack-profile.md` (294 linhas), `plan.md` (307 linhas)

Ambos foram lidos integralmente antes deste veredito. Nenhum item abaixo foi marcado sem
verificação — onde houve afirmação sobre o ferramental do repo, ela foi reexecutada.

---

## Checklist

| # | Critério | Veredito | Evidência |
|---|---|---|---|
| 1 | Todo item de trabalho tem exatamente um dono | OK | 18 itens (D1-D3, A1, T1/I1/C1, B1-B3, V1-V5, R1-R3). Cada linha das tabelas tem uma única célula `dono`. Nenhum dono repetido dentro da mesma onda exceto `tech-writer` (B3 na onda 4, R3 na onda 6) e `sre-observability` (V4 na onda 5, R1 na onda 6) — ondas diferentes, sem concorrência. |
| 2 | Todo item tem caminho de entregável concreto | OK | Todos os 18 nomeiam arquivo, não intenção. Ex.: B1 → `workflow/docker/Dockerfile.devbox` + `compose.devbox.yml` + `entrypoint.sh`; B2 → `workspace/devbox`; V4 → `docs/sdlc/04-quality/resilience-drill.md`. |
| 3 | Nenhuma dependência aponta para onda posterior | OK | Verificado item a item. A dependência mais tardia é V1←C1 (onda 5 ← onda 3) e R1←V4 (onda 6 ← onda 5). Nenhuma inversão. |
| 4 | Dois itens paralelos não escrevem o mesmo arquivo | OK | Onda 1: `prd.md` / `domain.md` / `ux-research.md`. Onda 3: `threat-model.md` / `integrations.md` / `cli-contract.md`. Onda 4: `workflow/docker/*` / `workspace/devbox` / `skills/devbox/SKILL.md`. Onda 5: cinco arquivos distintos em `04-quality/`. Onda 6: `observability.md` / `release-devbox.md` / `devbox-guide.md`+READMEs. Disjunto em todas. |
| 5 | Critérios de aceite verificáveis, não aspiracionais | OK | Predominam comando e saída: `docker build` exit 0, `docker run --rm <img> id -u` ≠ 0, `bash -n`, `./agents/install.sh --check` exit 0, `tools/artifact-lint.sh <fase>` imprimindo `OK`, delta de `df -h /`. Nenhum "funciona bem". |

**Todos os cinco critérios passam. Portão 0 aprovado.**

---

## Verificações que reexecutei (não aceitas por afirmação)

| Afirmação do artefato | Resultado |
|---|---|
| "disco `/` a 93% — risco para build de imagem" | **Superdimensionado.** `df -h /` → 468G total, 411G usados, **34G disponíveis**. A percentagem assusta; 34G é folga confortável para imagem de devbox. Segue como risco a monitorar (a mitigação de precheck em B2 é boa), não como ameaça ao cronograma. Corrigido aqui porque o `stack-profile.md` o classificou como "real constraint". |
| "host não tem `tmux` nem `screen`" | **Confirmado, e pior que o relatado.** `tmux`, `screen`, `dtach` e `abduco` — todos ausentes. Nenhum multiplexador no host. Isso valida o ADR-002 como decisão obrigatória. |
| "`artifact-lint.sh` procura strings em inglês que o template em português não entrega" | **Confirmado por execução.** Testado o mesmo `grep -qi` do lint contra `skills/sdlc-discovery/templates/prd.md`: `Problem` encontra; `Success metrics`, `Out of scope`, `Given` e `Open questions` **não encontram**. 4 de 5. Quem seguisse o template do próprio repo reprovaria no Portão 1 sem entender a causa. A mitigação de títulos bilíngues no plano é obrigatória, não estilística. |
| "docker disponível" | Confirmado. Client 29.6.2, **Server 24.0.6**, backend Docker Desktop, driver `overlay2`, compose v2.22.0. A divergência client/server e o backend em VM são fatos de desenho — sustentam o risco de I/O de bind mount que o plano levanta. |
| "`guard-artifacts.sh` restringe escrita por `agent_type`" | Confirmado. `case "$agent"` na linha 72; `tech-lead-orchestrator` autorizado na linha 73; ramo default `*) exit 0` deixa agente novo sem restrição — como o plano registra. |
| Mapeamento dos portões do plano para `skills/sdlc-gate/gates.md` | Confirmado. `gates.md` define Portões 1-4. O plano mapeia Gate 1→Portão 1, Gate 2→Portão 2, Gate 4→**Portão 3**, Gate 5→**Portão 4**, e define o Gate 3 (build) com critérios próprios. O deslocamento é deliberado e correto. |

---

## Ressalvas registradas — não bloqueiam o Portão 0, mas têm dono

| # | Ressalva | Quando morde | Dono |
|---|---|---|---|
| R-1 | **`gates.md` contém itens inaplicáveis a este projeto.** O Portão 2 exige "todo endpoint de lista pagina", "todo índice aponta para padrão de acesso", "migrações expand/contract", "toda tela documenta estado vazio". Não há API HTTP, banco nem tela aqui. E o cabeçalho do `gates.md` diz: *"item que você não conseguiu verificar não é aprovado... bloqueia igual a uma falha"*. Aplicado ao pé da letra, o Gate 2 trava por itens que nunca poderiam existir. O mesmo vale para os itens de webhook e terceiro no Portão 3. | Gate 2 e Gate 4 | Avaliador do Gate 2 (`code-reviewer`) deve marcar cada item inaplicável como **N/A com justificativa escrita** — "não aplicável" é diferente de "não verificado". Registrar no `gate-02.md`. |
| R-2 | **Dependência intra-onda na Onda 1.** D2 e D3 declaram D1 como entrada, mas a onda é anunciada como paralela. O plano hedge com "rascunho ou final". Não viola o critério 3 (não aponta para onda *posterior*), mas se os três subirem simultaneamente, D2 e D3 começam sem PRD. | Onda 1 | Coordenador: despachar D1 primeiro e D2/D3 assim que o rascunho do PRD existir, ou passar o objetivo literal + Q1-Q8 como entrada comum aos três. Mesma situação em R3←R1 na Onda 6. |
| R-3 | **Premissa de escopo ainda não confirmada pelo usuário.** O plano assume que o entregável é uma ferramenta que *este* repo distribui para projetos-alvo, não a conteinerização deste repo. A evidência sustenta (`README.md:14` e `.claude/toolbelt.md:9-10` declaram que aqui não há trabalho de produto), mas é a premissa que mais muda o resultado se estiver errada. | Onda 1 (D1) | `product-owner` confirma com o usuário como primeira linha do PRD. |
| R-4 | **Worktrees irmãs não inspecionadas.** `arch-conformance`, `meta-e-mcp` e `vault-secrets` existem em `.claude/worktrees/` e ninguém leu o conteúdo. Risco de desenho concorrente. | Antes do Gate 2 | `context-manager`, como o plano já determina. |

---

## Escala

**INITIATIVE.** Aceito a classificação. A justificativa do plano se sustenta nos três pontos:
não há implementação parcial para estender (nenhum `Dockerfile`/`compose`/`.devcontainer` na árvore);
há decisões estruturais caras de reverter depois que houver trabalho do usuário dentro do container
(onde vive o clone, modelo de sessão, entrada da credencial); e há superfície de segurança nova e
real — credencial de terceiro num container que executa **código clonado que não escrevemos**, com
a possibilidade de socket do Docker montado, que é equivalência de root no host e contradiz
frontalmente o requisito "sem tocar em nada de fora".

Esse último ponto é o que descarta FEATURE: a tensão entre "tudo em Docker" e "sem tocar em nada de
fora" não é detalhe de implementação, é uma contradição em potencial no próprio enunciado, e precisa
de ADR e threat model antes de qualquer linha de código.

---

## Próxima onda

**Onda 1 — Discovery.** Três itens, três donos, três arquivos disjuntos:

- D1 `product-owner` → `docs/sdlc/01-discovery/prd.md`
- D2 `business-analyst` → `docs/sdlc/01-discovery/domain.md`
- D3 `ux-researcher` → `docs/sdlc/01-discovery/ux-research.md`

Entrada crítica para os três: as perguntas Q1-Q8 do plano. Elas não têm resposta inventada, e
Q1 ("o que exatamente 'não perder nada' cobre"), Q3 (Docker por dentro do container) e Q5 (o limite
literal de "sem tocar em nada de fora") são as que mais mudam o desenho.

Portão 1 é avaliado por `solution-architect`, registrado por `context-manager` em `gate-01.md`.
