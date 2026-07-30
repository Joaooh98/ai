# `perf-baseline` — linha de base de performance

Ninguém aprova um PR que deixa o endpoint 4% mais lento. Vinte PRs assim, e o endpoint dobrou de
tempo — sem que nenhuma revisão tenha errado. Regressão gradual é invisível por construção: só
aparece contra uma medição anterior.

| | |
|---|---|
| Agente | `performance-engineer` |
| Cadência | Semanal |
| Saída | `docs/sdlc/04-quality/perf-baseline-<AAAA-MM-DD>.md` |
| Altera código? | Não — mede e compara |

## Pré-condição

Esta é a rotina com mais motivos legítimos para **não** rodar. Pare e diga qual, sem produzir
número:

- **Sem orçamento de NFR.** Procure em `docs/sdlc/02-design/`. Medição sem orçamento produz um
  número sem veredito — e número sem veredito ninguém lê duas vezes. O conserto é definir o
  orçamento na onda 02, não medir mesmo assim.
- **Sem comando de benchmark em `.claude/toolbelt.md`.** Não invente uma carga. Benchmark
  improvisado mede o improviso.
- **Sem volume de dados realista.** Medir contra base vazia responde uma pergunta que ninguém fez.
  Registre qual volume foi usado — sempre, inclusive quando estiver certo.

## Procedimento

1. **Fixe o ambiente e registre-o.** Máquina, CPU, memória, versão de runtime, volume de dados,
   se havia mais alguma coisa rodando. Sem isso a comparação com a semana passada não é válida.

2. **Compare só o comparável.** Medição feita em máquina diferente da anterior **não** se compara:
   reporte como nova linha de base, não como variação. Regressão de 30% que na verdade é "rodou em
   outro hardware" queima a credibilidade da rotina de uma vez.

3. **Aqueça antes de medir.** JIT, cache de conexão, cache de query. A primeira execução mede a
   inicialização; descarte-a explicitamente e diga que descartou.

4. **Repita e reporte variância.** Uma execução não é medição. Rode ao menos 5 e reporte
   **mediana e p95**, nunca a média sozinha — média esconde a cauda, que é justamente onde o
   usuário sente. Sem dispersão, não dá para distinguir regressão de ruído, e essa distinção é o
   trabalho inteiro.

5. **Compare com o `perf-baseline-*.md` anterior e com o orçamento.** Três números por métrica:
   agora, semana passada, orçamento. Ausência de qualquer um muda o que se pode concluir — diga
   qual falta.

6. **Só chame de regressão o que sai do ruído.** Variação dentro da dispersão observada é ruído,
   e nomeá-la regressão treina o time a ignorar o relatório. Uma regra utilizável: variação maior
   que a dispersão entre execuções da **mesma** medição, e sustentada em duas semanas seguidas.
   Diga qual critério você usou.

7. **Aponte o suspeito, não a causa.** Havendo regressão, liste os commits da janela — migração,
   dependência nova, mudança em query são os candidatos usuais:

   ```bash
   ${CLAUDE_PROJECT_DIR}/.claude/ai-toolkit/tools/incident-evidence.sh 168
   ```

   Isso é pista para investigação, não conclusão. Confirmar causa é bissecção com medição, e isso
   é trabalho com você presente — não de rotina noturna.

8. **Não otimize.** Rotina que "melhora" performance sozinha entrega um diff que ninguém pediu
   contra um número que ninguém validou.

## Saída

```markdown
# Linha de base de performance — <AAAA-MM-DD>

Ambiente: <máquina, CPU, RAM, runtime>   ·   Volume: <descrição>
Execuções: <n> (1 de aquecimento, descartada)   ·   Comparável com anterior: sim/não (<motivo>)

## Medições

| Métrica | Mediana | p95 | Semana anterior | Orçamento | Veredito |
|---|---|---|---|---|---|
| GET /faturas | 180ms | 340ms | 172ms | 250ms (p95) | dentro |
| POST /pagamento | 890ms | 1.4s | 610ms | 800ms (p95) | **estourou** |

## Regressão

### POST /pagamento — p95 de 1.1s → 1.4s
Dispersão entre execuções: ±60ms. Variação: +300ms. → fora do ruído.
Segunda semana consecutiva de piora.
Commits na janela: <lista curta com o que toca o caminho>
Suspeito: <um, com o porquê — ou "sem candidato óbvio">

## Sem medição
| Métrica | Motivo |
|---|---|

## Nada a fazer
<ou: "todas as métricas dentro do orçamento e dentro do ruído da semana anterior.">
```

## Nada a fazer

Toda métrica dentro do orçamento e a variação dentro da dispersão observada. Uma linha, com os
números mesmo assim — a série histórica é o produto desta rotina, e ela só existe se cada execução
deixar o registro.

## Agendamento

```
/schedule "todo sábado às 1h37, rode /nightly perf-baseline no projeto <nome> e me mande o relatório"
```

Sábado de madrugada: menor chance de disputa por recurso na máquina, o que é o principal
contaminante da medição. Mantenha **sempre o mesmo horário** — variar horário varia a carga de
fundo e polui a série.

## Quando desligar

- Sem orçamento de NFR definido → não ligue ainda. Volte depois da onda 02.
- Cada execução sai em máquina diferente → a série não é comparável e o relatório é decorativo.
  Conserte o ambiente ou desligue.
- O projeto tem benchmark no CI com limite que falha o build → o CI cobre regressão em código
  novo. Esta rotina continua cobrindo o que o CI não vê: dado que cresce, índice que degrada,
  dependência que ficou mais lenta sem o seu código mudar. Se isso não se aplica, desligue.
