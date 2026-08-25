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

| # | Branch | Merge | Tamanho | Parada desde | O que é |
|---|---|---|---|---|---|
| [#7](https://github.com/Joaooh98/ai/pull/7) | `plano-skills-comunidade` | ✅ CLEAN | +8369/−2 | — | Skills da comunidade: pesquisa, auditoria de segurança e absorção dos especialistas de stack |
| [#8](https://github.com/Joaooh98/ai/pull/8) | `guard-publish` | ✅ CLEAN | +465/−43 | 03/08 | Hook que impede artefato de planejamento chegar ao repositório |
| [#6](https://github.com/Joaooh98/ai/pull/6) | `nightly-atividades` | ✅ CLEAN | +755/−33 | 30/07 | Atividade executável para cada uma das 6 rotinas noturnas |
| [#5](https://github.com/Joaooh98/ai/pull/5) | `sdlc-docker-devflow` | ✅ CLEAN | +804/−0 | 30/07 | Bootstrap do fluxo de dev e execução em Docker (onda 00) |
| [#1](https://github.com/Joaooh98/ai/pull/1) | `arch-conformance` | ⚠️ **CONFLITANTE** | +703/−7 | 29/07 | Rotina de conformidade arquitetural com catraca |

### Fora de escopo por decisão

| # | Branch | Situação |
|---|---|---|
| [#2](https://github.com/Joaooh98/ai/pull/2) | `vault-secrets` | **Parado por decisão do operador em 25/08.** Vault local para credenciais. Não desenvolver agora — o PR fica aberto como registro, sem trabalho ativo. |

### Encerradas

| # | Branch | Situação |
|---|---|---|
| [#3](https://github.com/Joaooh98/ai/pull/3) | `meta-e-mcp` | **Fechado sem merge** em 25/08. O worktree `.claude/worktrees/meta-e-mcp` continua em disco — remover quando confirmar que nada se aproveita. |

---

## Riscos abertos

**1. Trabalho que existe só nesta máquina.** A branch `worktree-workspace-skill` tem um
commit sem remote e sem PR:

```
cf5698e feat(workspace): add /workspace skill and non-TTY guard for go script
```

Se o disco falhar ou o worktree for removido, some. **Empurrar ou descartar
conscientemente** — não deixar no limbo.

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
