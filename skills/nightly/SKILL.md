---
name: nightly
description: Catalogo de trabalho recorrente que roda fora do horario de trabalho - varredura de dependencias, deteccao de teste instavel, deriva de documentacao, auditoria de portoes - e como agendar cada um de forma duravel.
argument-hint: [nome da rotina, ou vazio para listar]
disable-model-invocation: true
---

# Trabalho recorrente

Rotina: **$ARGUMENTS** (vazio = listar o catálogo)

Trabalho que não precisa de você olhando: varreduras longas, verificações repetitivas, coisas que
competiriam com a sua sessão durante o dia.

## Como esta skill se comporta

| `$ARGUMENTS` | O que fazer |
|---|---|
| vazio | Mostre o catálogo abaixo e pare. **Não execute nada** |
| nome de rotina | Leia `routines/<nome>.md` **inteiro** e execute o procedimento dele |
| nome desconhecido | Diga que não existe, liste os nomes válidos e pare |

O procedimento de cada rotina mora no arquivo dela, não aqui. O catálogo diz o que cada uma
persegue e quando vale a pena; o arquivo diz **como** fazer, com qual comando, o que conta como
evidência e o que fazer com o resultado.

## Primeiro, a correção sobre custo

> **Não existe preço menor por horário do dia.** As tarifas da API são fixas por modelo, 24h por
> dia. Rodar de madrugada não sai mais barato.

O desconto real vem de outro lugar:

| Mecanismo | Desconto | Custo |
|---|---|---|
| **Batch API** | **50%** em todos os tokens | Assíncrono — maioria em 1h, teto de 24h |
| **Prompt caching** | ~90% na parte cacheada | Nenhum — exige prefixo estável |

O que rodar fora do horário **de fato** entrega: não disputa atenção nem rate limit com o seu
trabalho, o resultado está pronto quando você senta, e varredura longa não te deixa esperando.

## Mecanismo de agendamento — escolha com cuidado

| Mecanismo | Persiste? | Use para |
|---|---|---|
| `/schedule` (cloud agent) | **Sim** | Rotina noturna de verdade — roda sem sessão aberta |
| `CronCreate` | **Não** — só na sessão, expira em 7 dias | Repetição dentro de uma sessão que você deixa aberta |
| Cron do SO / CI agendado | Sim | Quando o trabalho é script, não julgamento |

**`CronCreate` não serve para tarefa noturna.** Vive em memória, morre quando o Claude fecha.
Verificado no próprio contrato da ferramenta. Para rotina durável, use `/schedule`.

Projeto **sem remote** não roda em cloud agent — não há de onde clonar. Aí o mecanismo é cron do
SO chamando `workspace/go <projeto> "/nightly <rotina>"`. Projeto marcado `type: sem-git` no
cadastro não roda nem isso até existir um `git init`.

### Minuto quebrado, de propósito

Todo mundo que pede "3h da manhã" agenda `0 3`. Prefira minuto que não seja `:00` nem `:30` —
`7 3 * * 2` em vez de `0 3 * * 2`. Você não nota a diferença; a fila da API nota.

## Catálogo

| Rotina | Persegue | Agente | Cadência | Procedimento |
|---|---|---|---|---|
| `flaky` | Teste que falha de forma intermitente | `test-engineer` | Diária | [routines/flaky.md](routines/flaky.md) |
| `deps` | Advisory novo, pacote abandonado, lockfile divergente | `security-auditor` | Semanal | [routines/deps.md](routines/deps.md) |
| `docs-drift` | Comando documentado que não funciona mais | `tech-writer` | Semanal | [routines/docs-drift.md](routines/docs-drift.md) |
| `gate-audit` | Portão aprovado sem evidência, MANIFEST divergente | `context-manager` | Diária | [routines/gate-audit.md](routines/gate-audit.md) |
| `incident-actions` | Ação de postmortem sem dono, sem prazo ou vencida | `sre-observability` | Semanal | [routines/incident-actions.md](routines/incident-actions.md) |
| `perf-baseline` | Regressão gradual que nenhum PR isolado mostra | `performance-engineer` | Semanal | [routines/perf-baseline.md](routines/perf-baseline.md) |

Cada rotina termina num relatório que você lê e decide. **Nenhuma altera código.**

O caminho de saída de cada uma não é escolha estética: `guard-artifacts.sh` restringe onde alguns
agentes podem escrever. `security-auditor` só escreve em `docs/sdlc/04-quality/`, `context-manager`
só em `docs/sdlc/00-orchestration/`. Mudar o caminho da rotina sem olhar o guard faz a rotina
falhar às 3h, quando ninguém está vendo.

## Regras

1. **Rotina não altera código.** Ela investiga e reporta; a correção entra pelo `/sdlc` com você
   decidindo. Correção automática sem revisão é como se cria o incidente das 3h.
2. **Rotina que sempre passa deve ser desligada.** Se `deps` nunca acha nada em dois meses, ou o
   projeto é excepcional ou a checagem está quebrada — descubra qual. Cada rotina traz o próprio
   critério na seção *Quando desligar*.
3. **Todo relatório aponta ação ou diz "nada a fazer".** Relatório que ninguém lê é custo puro.
4. **Comece com uma.** Seis rotinas de uma vez viram seis relatórios ignorados. `flaky` costuma
   dar o maior retorno inicial, porque o estrago já existe e ninguém mediu.
5. **Registre o custo.** Depois da primeira semana, compare o gasto com o valor do que foi achado.
   Rotina que custa mais que o defeito que previne sai do catálogo.
6. **Rotina não inventa ambiente.** Comando de teste, benchmark e orçamento de NFR saem do
   `.claude/toolbelt.md`. Se não estiverem lá, a rotina para e diz que falta calibração — não
   adivinha o comando. O conserto é `/setup`, uma vez, e vale para todas.
