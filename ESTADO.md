# ESTADO — o que está em voo neste repositório

Índice único das frentes abertas. Existe porque o trabalho aqui acontece em várias
sessões paralelas, cada uma no seu worktree, e **nenhuma enxerga a outra**. Sem este
arquivo, a única forma de saber o que existe é `gh pr list` — que não diz o que falta
nem por que parou.

**Toda sessão lê isto ao abrir e atualiza ao sair.** É um arquivo só, versionado; o git
resolve a concorrência.

> Última atualização: 2026-08-25, depois da rodada de merges

## Como conferir o estado real

```bash
gh pr list                       # frentes com PR aberto
git worktree list                # o que está aberto agora nesta máquina
git log origin/main..main        # commit local na main ainda não empurrado
git branch -vv | grep -v origin  # branch local sem remote — trabalho em risco
```

---

## Frentes abertas

| # | Branch | Estado | Parada desde | O que é |
|---|---|---|---|---|
| [#1](https://github.com/Joaooh98/ai/pull/1) | `arch-conformance` | ⚠️ **CONFLITANTE** · rascunho | 29/07 | Rotina de conformidade arquitetural com catraca |

Só uma frente ativa. Ela precisa de **rebase sobre a `main`** antes de qualquer coisa — a
main andou 5 commits desde que ela parou. E continua marcada como rascunho: o
`gh pr merge` recusa PR em draft, então precisa de `gh pr ready 1` também.

### Fora de escopo por decisão

| # | Branch | Situação |
|---|---|---|
| [#2](https://github.com/Joaooh98/ai/pull/2) | `vault-secrets` | **Parado por decisão do operador em 25/08.** Vault local para credenciais. Não desenvolver agora — o PR fica aberto como registro, sem trabalho ativo. Já está conflitante; quando for retomado, rebase primeiro. |

---

## Concluído em 25/08

Quatro frentes entraram na `main` na mesma rodada:

| # | Branch | O que entregou |
|---|---|---|
| [#7](https://github.com/Joaooh98/ai/pull/7) | `plano-skills-comunidade` | Skills da comunidade: pesquisa, auditoria de segurança e os 4 especialistas de stack em `skills/stack/` |
| [#8](https://github.com/Joaooh98/ai/pull/8) | `guard-publish` | Hook que impede artefato de planejamento chegar ao repositório |
| [#6](https://github.com/Joaooh98/ai/pull/6) | `nightly-atividades` | Atividade executável para cada uma das 6 rotinas noturnas |
| [#5](https://github.com/Joaooh98/ai/pull/5) | `sdlc-docker-devflow` | Bootstrap do fluxo de dev e execução em Docker (onda 00) |

O [#3](https://github.com/Joaooh98/ai/pull/3) (`meta-e-mcp`) foi **fechado sem merge**.

**A equipe já está ativa com o resultado:** `./agents/install.sh --user` rodado do checkout
principal, com **27 agentes e 20 skills** linkados em `~/.claude/` (eram 16 skills).
Confirmado que os symlinks apontam para `/home/smart/Documents/person/ai/`, não para
worktree.

---

## Pendências de limpeza

**1. Trabalho que existe só nesta máquina.** A branch `worktree-workspace-skill` tem um
commit sem remote e sem PR:

```
cf5698e feat(workspace): add /workspace skill and non-TTY guard for go script
```

Se o disco falhar ou o worktree for removido, some. **Empurrar ou descartar
conscientemente** — não deixar no limbo. É a pendência mais urgente desta lista.

**2. Worktree órfão.** `.claude/worktrees/meta-e-mcp` continua em disco, mas o PR #3 foi
fechado sem merge. Remover depois de confirmar que nada se aproveita:

```bash
git worktree remove .claude/worktrees/meta-e-mcp
git branch -D worktree-meta-e-mcp
```

**3. Este repositório não usa o próprio SDLC.** `docs/sdlc/` está vazio aqui, apesar de
`skills/sdlc-status` existir justamente para responder "onde o trabalho parou, inclusive
em sessão nova". A oficina não se aplica a si mesma. Enquanto isso não muda, **este
arquivo é o substituto manual**.

---

## Regra que não pode ser esquecida

**`./agents/install.sh --user` só do checkout principal.** Ele cria symlinks de
`~/.claude/agents` e `~/.claude/skills` apontando para `$REPO_ROOT`. Rodado de dentro de
um worktree, repontaria a equipe global para lá — e quando o worktree fosse removido,
todo link ficaria quebrado, derrubando as outras sessões.

De dentro de worktree, use apenas `./agents/install.sh --check`, que valida sem escrever.

Rodar de novo o `--user` sempre que um merge tocar `agents/` ou `skills/`.
