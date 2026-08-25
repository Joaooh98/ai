# `flaky` — detecção de teste instável

Teste que passa em uma execução e falha na seguinte, sem nada ter mudado. É o defeito que mais
corrói confiança na suíte, porque o time aprende a reagir a vermelho com "roda de novo" — e no dia
em que o vermelho é real, a reação é a mesma.

Só aparece com repetição. Ninguém roda a suíte dez vezes durante o dia; é exatamente por isso que
esta é a rotina que costuma pagar primeiro.

| | |
|---|---|
| Agente | `test-engineer` |
| Cadência | Diária |
| Saída | `docs/sdlc/04-quality/flaky-<AAAA-MM-DD>.md` |
| Altera código? | Não |

## Pré-condição

Pare e diga o motivo, sem produzir relatório, se:

- **Não há comando de teste em `.claude/toolbelt.md`.** Não adivinhe `npm test` nem `mvn test`.
  Falta calibração — o conserto é `/setup`.
- **A suíte já está vermelha de forma determinística.** Instabilidade se mede contra verde. Com
  falha fixa, reporte *isso* — em uma linha, não num relatório de flaky — e pare.

## Procedimento

1. **Estabeleça o verde.** Rode a suíte uma vez, em ordem padrão. Guarde a saída.
   Se falhar igual em duas execuções seguidas, é quebra determinística: veja a pré-condição.

2. **Repita N vezes em ordem aleatória.** `N = 10` é o padrão. Ordem aleatória é o que separa
   "teste instável" de "teste que depende do vizinho" — e a segunda categoria é mais comum.

   | Runner | Ordem aleatória |
   |---|---|
   | Go | `go test -shuffle=on ./...` — nativo |
   | Jest | `jest --randomize` |
   | Vitest | `vitest --sequence.shuffle` |
   | Maven Surefire | `-Dsurefire.runOrder=random` |
   | pytest | exige o plugin `pytest-randomly` |

   **Confirme a flag no runner do projeto antes de confiar nela** — versão antiga a ignora em
   silêncio, e você conclui "sem instabilidade" tendo rodado dez vezes na mesma ordem. Um `--help`
   resolve. Se a flag não existir e o plugin não estiver instalado, rode em ordem padrão e
   **diga no relatório que a ordem não variou** — a rotina fica mais fraca, não inválida.
   A rotina não instala plugin.

3. **Compare execução a execução.** Para cada teste, conte falhas em N. O que interessa é a taxa,
   não a existência: 1/10 e 7/10 são problemas de urgência diferente.

4. **Classifique cada instável.** Sem isso o relatório é uma lista que ninguém sabe atacar:

   | Classe | Sinal |
   |---|---|
   | Ordem | Falha só depois de um teste específico; passa isolado |
   | Tempo | `sleep`, timeout, comparação com relógio, timezone |
   | Concorrência | Falha varia com paralelismo; some com `-p 1` / `--runInBand` |
   | Estado compartilhado | Banco, arquivo, singleton, variável de módulo não resetada |
   | Rede | Chamada externa real dentro do teste |

   Para classificar, rode o suspeito **isolado** e depois **em série** (sem paralelismo). Duas
   execuções extras, e a classe sai quase sempre.

5. **Não conserte.** Nem quarentene, nem marque `@Disabled`, nem toque no teste. Teste desligado
   por rotina noturna é cobertura que some sem ninguém decidir.

## Evidência obrigatória

Cole a **saída real** da falha — mensagem, asserção, stack. "Falhou 3 de 10" sem a saída obriga
quem for consertar a reproduzir do zero, e é o que faz o relatório ser ignorado.

## Saída

```markdown
# Instabilidade — <AAAA-MM-DD>

Suíte: <comando>   ·   Execuções: <N>   ·   Ordem aleatória: sim/não (<motivo se não>)
Duração média: <t>   ·   Ambiente: <local | CI | cloud agent>

## Instáveis

| Teste | Falhas/N | Classe | Primeira vez visto |
|---|---|---|---|
| <caminho::nome> | 3/10 | ordem | <data ou "hoje"> |

### <caminho::nome>
Saída real da falha:
```
<colada, não parafraseada>
```
Isolado: passou 5/5. Em série: passou 5/5. → depende de ordem.

## Nada a fazer
<ou: "N execuções, mesmo resultado em todas. Nenhuma instabilidade detectada.">
```

## Nada a fazer

As N execuções deram o mesmo resultado. Diga isso em uma linha e encerre — sem relatório longo
para dizer que está tudo bem.

## Agendamento

```
/schedule "todo dia às 3h07, rode /nightly flaky no projeto <nome> e me mande o relatório"
```

Diária tem motivo: instabilidade nova aparece com a mudança que a introduziu, e a janela em que
dá para ligar uma à outra é curta.

## Quando desligar

- Duas semanas sem nenhum instável → o valor virou custo. Reduza para semanal antes de desligar.
- A suíte roda em menos de 30s → N execuções cabem no CI de todo PR. Aí o lugar disso é o
  pipeline, não uma rotina noturna.
- A suíte demora mais que a janela noturna → reduza N ou rode só o módulo com histórico de
  instabilidade. Rotina que não termina não é rotina.
