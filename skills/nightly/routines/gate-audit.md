# `gate-audit` — auditoria dos portões

O fluxo inteiro depende de uma coisa: portão aprovado significa evidência verificada. Quando um
portão passa sem isso — porque o artefato era o esqueleto do template, porque o MANIFEST diz
"concluído" e o arquivo não existe — todo o resto do ciclo herda uma afirmação falsa, e ninguém
descobre até a onda seguinte quebrar.

Esta é a rotina mais barata do catálogo: dois scripts determinísticos e a reconciliação.

| | |
|---|---|
| Agente | `context-manager` |
| Cadência | Diária |
| Saída | `docs/sdlc/00-orchestration/gate-audit-<AAAA-MM-DD>.md` |
| Altera código? | Não. Corrige o `MANIFEST.md` — e só ele |

`context-manager` é o **único escritor** do `MANIFEST.md` (`guard-artifacts.sh`, regra 1) e só
escreve em `docs/sdlc/00-orchestration/` (regra 2). Por isso é ele que roda esta rotina: qualquer
outro agente seria bloqueado exatamente no que ela precisa fazer.

## Pré-condição

Se `docs/sdlc/` não existe, não há ciclo iniciado. `artifact-lint.sh` já sai com código 0 dizendo
isso — repita a mensagem em uma linha e pare. Não é achado.

## Procedimento

1. **Rode os dois scripts.** Determinísticos e só leitura:

   ```bash
   ${CLAUDE_PROJECT_DIR}/.claude/ai-toolkit/tools/artifact-lint.sh all
   ${CLAUDE_PROJECT_DIR}/.claude/ai-toolkit/tools/sdlc-state.sh "${CLAUDE_PROJECT_DIR}"
   ```

   `artifact-lint.sh` sai com **código 1** quando encontra artefato ausente, incompleto ou que é
   só esqueleto de template. É esse código que separa auditoria de sugestão — registre-o.

2. **Reconcilie o MANIFEST contra o disco.** Nos dois sentidos, porque cada um esconde um erro
   diferente:

   | Direção | O que revela |
   |---|---|
   | MANIFEST → disco | Item registrado como entregue cujo arquivo não existe. **O pior caso** |
   | Disco → MANIFEST | Artefato produzido que ninguém registrou — trabalho órfão, sem dono |

3. **Confronte com o plano.** Leia `docs/sdlc/00-orchestration/plan.md`. Para cada entregável
   planejado: existe, está no MANIFEST, passou no lint? Divergência entre os três é o achado.

4. **Audite os portões um a um.** Para cada `gate-NN.md` presente:

   - Diz aprovado? Então cada critério precisa de evidência **citada** — arquivo, linha, saída de
     comando. Critério marcado com um "ok" seco é aprovação sem evidência: reporte.
   - O portão foi avaliado depois do último artefato da onda? Portão avaliado e artefato alterado
     em seguida significa que a aprovação é sobre uma versão que não existe mais. Compare com o
     `artifact-ledger.tsv`, que registra toda escrita sob `docs/sdlc/` com carimbo de tempo.
   - Onda com todos os entregáveis presentes e **sem** `gate-NN.md` não é onda aprovada — é onda
     sem portão. São coisas diferentes e o relatório precisa dizer qual.

5. **Corrija o MANIFEST, e nada além dele.** Registrar artefato órfão e desmarcar item cujo
   arquivo não existe é exatamente o trabalho do `context-manager`. **Não** produza o artefato
   faltante, não edite `gate-NN.md`, não reavalie portão — isso é `/sdlc-gate`, com você presente.

## Saída

```markdown
# Auditoria de portões — <AAAA-MM-DD>

Fase segundo o disco: <NN nome>   ·   artifact-lint: exit <0|1>

## Inconsistências

| Tipo | Item | Detalhe |
|---|---|---|
| MANIFEST sem arquivo | <entregável> | registrado em <data>, arquivo não existe |
| Órfão | docs/sdlc/02-design/adr/003.md | existe desde <data>, fora do MANIFEST |
| Esqueleto | docs/sdlc/01-discovery/prd.md | lint: só template, <n> linhas de corpo |
| Portão sem evidência | gate-02 | critérios 3 e 5 marcados ok, sem citação |
| Portão desatualizado | gate-01 | aprovado <data>, artefato alterado <data posterior> |

## Cobertura do plano

| Onda | Planejado | Presente | Portão |
|---|---|---|---|
| 01 | 3 | 3 | aprovado |
| 02 | 4 | 2 | não avaliado |

## Correções aplicadas no MANIFEST
<lista — ou "nenhuma">

## Nada a fazer
<ou: "lint exit 0, MANIFEST bate com o disco, todo portão avaliado tem evidência citada.">
```

## Nada a fazer

`artifact-lint.sh` saiu com 0, o MANIFEST bate com o disco nos dois sentidos e todo portão
aprovado cita evidência. Uma linha.

## Agendamento

```
/schedule "todo dia às 5h07, rode /nightly gate-audit no projeto <nome> e me mande o relatório"
```

Diária e cedo: o valor é você sentar sabendo que o estado registrado é o estado real, antes de
tomar a primeira decisão baseada nele.

## Quando desligar

- Não há ciclo SDLC ativo → a rotina não tem o que auditar. Ligue quando o ciclo começar.
- Um mês sem inconsistência **com ciclo ativo e ondas avançando** → o fluxo está saudável. Passe
  para semanal; volte a diário quando entrar uma fase com muitos artefatos em paralelo.
- Toda execução acha as mesmas inconsistências → ninguém está agindo. O problema não é a rotina.
