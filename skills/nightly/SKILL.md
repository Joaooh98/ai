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

---

## Catálogo

Cada rotina diz o que produz e o que fazer com o resultado. Nenhuma delas altera código sozinha —
todas terminam num relatório que você lê e decide.

### `deps` — varredura de dependências
Advisories novos, pacotes sem manutenção, lockfile divergente, versões que saíram de suporte.
→ `security-auditor`. Saída: `docs/sdlc/04-quality/deps-<data>.md`. Semanal.

### `flaky` — detecção de teste instável
Roda a suíte N vezes em ordem aleatória e compara. Teste que falha de forma intermitente é o que
mais corrói confiança, e só aparece com repetição — exatamente o que ninguém faz durante o dia.
→ `test-engineer`. Saída: lista de instáveis com taxa de falha. Diária.

### `docs-drift` — deriva de documentação
Executa cada comando documentado e confere se ainda funciona. Documentação errada é pior que
ausente, porque é confiada.
→ `tech-writer`. Saída: comandos que quebraram, com a saída real. Semanal.

### `gate-audit` — auditoria dos portões
Roda `tools/artifact-lint.sh all` e reconcilia o `MANIFEST.md` contra os arquivos que existem de
fato. Pega portão marcado como aprovado sem evidência.
→ `context-manager`. Diária.

### `incident-actions` — ações de postmortem
Varre `docs/incidents/*/` por ações sem dono, sem prazo, ou vencidas. Ação de postmortem que
ninguém cobra é o motivo de o mesmo incidente voltar.
→ `sre-observability`. Semanal.

### `perf-baseline` — linha de base de performance
Roda o benchmark contra o orçamento dos NFRs e compara com a medição anterior. Regressão gradual
não aparece em nenhum PR isolado.
→ `performance-engineer`. Semanal, se houver orçamento definido.

---

## Regras

1. **Rotina não altera código.** Ela investiga e reporta; a correção entra pelo `/sdlc` com você
   decidindo. Correção automática sem revisão é como se cria o incidente das 3h.
2. **Rotina que sempre passa deve ser desligada.** Se `deps` nunca acha nada em dois meses, ou o
   projeto é excepcional ou a checagem está quebrada — descubra qual.
3. **Todo relatório aponta ação ou diz "nada a fazer".** Relatório que ninguém lê é custo puro.
4. **Comece com uma.** Seis rotinas de uma vez viram seis relatórios ignorados. `flaky` costuma
   dar o maior retorno inicial, porque o estrago já existe e ninguém mediu.
5. **Registre o custo.** Depois da primeira semana, compare o gasto com o valor do que foi achado.
   Rotina que custa mais que o defeito que previne sai do catálogo.
