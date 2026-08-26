# ESTADO — o que está em voo neste repositório

Índice único das frentes abertas. Existe porque o trabalho aqui acontece em várias
sessões paralelas, cada uma no seu worktree, e **nenhuma enxerga a outra**. Sem este
arquivo, a única forma de saber o que existe é `gh pr list` — que não diz o que falta
nem por que parou.

**Toda sessão lê isto ao abrir e atualiza ao sair.** É um arquivo só, versionado; o git
resolve a concorrência.

> Última atualização: 2026-08-25

## Como conferir o estado real

```bash
gh pr list                       # frentes com PR aberto
git worktree list                # o que está aberto agora nesta máquina
git log origin/main..main        # commit local na main ainda não empurrado
git branch -vv | grep -v origin  # branch local sem remote — trabalho em risco
```

---

## Frentes abertas

| # | Branch | Estado | O que é |
|---|---|---|---|
| — | `worktree-meta-e-mcp` | **16 commits, fast-forward da main** | Metas de qualidade, catálogo de MCP, docs-lint, 4 diagramas, correção do `.claude` aninhado, graphify medido. **Não tem PR — neste repositório não abrimos PR.** Merge direto quando você quiser |
| [#1](https://github.com/Joaooh98/ai/pull/1) | `arch-conformance` | ⚠️ **CONFLITANTE** e em rascunho | Rotina de conformidade arquitetural com catraca. Precisa de rebase sobre a main **e** `gh pr ready 1` |
| — | `integra-workspace-skill` | **4 commits, pronto para merge** | Resgata o `cf5698e` (skill `/workspace` + guard não-TTY, agora no remote), tira o ledger do versionamento e corrige o `guard-publish`, que barrava a própria remediação que recomenda |

### Fora de escopo por decisão

| # | Branch | Situação |
|---|---|---|
| [#2](https://github.com/Joaooh98/ai/pull/2) | `vault-secrets` | **Parado por decisão do operador.** Vault local para credenciais. O PR fica aberto como registro, sem trabalho ativo. |

### Encerradas

| # | Branch | Situação |
|---|---|---|
| [#5](https://github.com/Joaooh98/ai/pull/5) | `sdlc-docker-devflow` | **Mergeado.** Bootstrap do fluxo em Docker (onda 00) |
| [#6](https://github.com/Joaooh98/ai/pull/6) | `nightly-atividades` | **Mergeado.** Atividade executável para as 6 rotinas noturnas |
| [#7](https://github.com/Joaooh98/ai/pull/7) | `plano-skills-comunidade` | **Mergeado.** Trouxe as quatro de stack, levando o total de 16 para 20 skills na época (hoje 21) e o plano do graphify |
| [#8](https://github.com/Joaooh98/ai/pull/8) | `guard-publish` | **Mergeado.** 4º hook — impede artefato de planejamento no repositório |
| [#3](https://github.com/Joaooh98/ai/pull/3) | `meta-e-mcp` | **PR fechado por escolha de processo, NÃO por descarte.** O branch está vivo e é a frente principal acima. ⚠️ Não rode `git branch -D worktree-meta-e-mcp` — apagaria 16 commits validados que ainda não estão na main |

---

## Estado das ferramentas nos projetos

Medido em 22/08. Só o que falta:

| | smaug-system | smart |
|---|---|---|
| hooks · calibração · grafo graphify | ok | ok |
| `.claude/meta.tsv` | rascunho gravado, tudo `aviso` | rascunho gravado, tudo `aviso` |
| `.mcp.json` (graphify) | registrado, **aguarda aprovação** | registrado, **aguarda aprovação** |
| âncora `.claude/ai-toolkit` | **forma antiga** — migra no `wire` pós-merge | **forma antiga** |

**Achado do grafo no `smart`, que precisa de decisão sua:** 30 cópias de `Utils.java`, os clones
`dafe-pix-wt-estorno` e `solve-card-api-fix-debit-installment` ao lado dos originais, dois
repositórios aninhados em `dafe-payment/` e uma worktree em `micro-services/.wt-onboarding-track/`.
Enquanto isso existir, número medido sobre o workspace conta a mesma coisa duas vezes.

---|---|---|
| [#3](https://github.com/Joaooh98/ai/pull/3) | `meta-e-mcp` | **Fechado sem merge** em 25/08. O worktree `.claude/worktrees/meta-e-mcp` continua em disco — remover quando confirmar que nada se aproveita. |

---

## Riscos abertos

**1. ~~Trabalho só nesta máquina~~ — RESOLVIDO em 22/08.** O commit `cf5698e` foi
empurrado para `origin/worktree-workspace-skill` e integrado em
`integra-workspace-skill`. Não há mais trabalho em um lugar só.

**2. O #1 conflita com a `main`.** Parado desde 29/07, e a main andou. Precisa de rebase
antes de qualquer coisa. Quanto mais tempo parado, pior fica.

**3. Este repositório não usa o próprio SDLC.** `docs/sdlc/` está vazio aqui, apesar de
`skills/sdlc-status` existir justamente para responder "onde o trabalho parou, inclusive
em sessão nova". A oficina não se aplica a si mesma. Enquanto isso não muda, **este
arquivo é o substituto manual**.

---

## Ordem sugerida de merge

As quatro frentes limpas não se sobrepõem em arquivo, então a ordem entre elas é livre.
Verificado: o #8 toca `agents/install.sh` e `skills/sdlc/SKILL.md`; o #7 toca
`agents/03-build/`, `skills/stack/` e `.gitignore`. Sem interseção.

```bash
gh pr merge 7 --squash --delete-branch    # skills de stack
gh pr merge 8 --squash --delete-branch    # guard-publish
gh pr merge 6 --squash --delete-branch    # nightly
gh pr merge 5 --squash --delete-branch    # docker devflow
```

Depois de cada merge que toque `agents/` ou `skills/`, reativar a equipe a partir do
**checkout principal** (nunca de um worktree — ver abaixo):

```bash
cd /home/smart/Documents/person/ai && git pull && ./agents/install.sh --user
./agents/install.sh --check     # confere a contagem
```

O #1 fica por último, depois de resolver o conflito.

---

## Regra que não pode ser esquecida

**`./agents/install.sh --user` só do checkout principal.** Ele cria symlinks de
`~/.claude/agents` e `~/.claude/skills` apontando para `$REPO_ROOT`. Rodado de dentro de
um worktree, repontaria a equipe global para lá — e quando o worktree fosse removido,
todo link ficaria quebrado, derrubando as outras sessões.

De dentro de worktree, use apenas `./agents/install.sh --check`, que valida sem escrever.
