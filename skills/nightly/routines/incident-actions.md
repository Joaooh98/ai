# `incident-actions` — ações de postmortem

O postmortem termina com uma tabela de ações. Na semana seguinte, ninguém abre aquele arquivo de
novo. A ação sem dono e sem prazo não é acompanhada por ninguém — e é por isso que o mesmo
incidente volta, com a mesma causa, seis meses depois.

Esta rotina existe porque cobrar ação de postmortem não é trabalho de ninguém em específico, e o
que não é de ninguém não acontece.

| | |
|---|---|
| Agente | `sre-observability` |
| Cadência | Semanal |
| Saída | `docs/incidents/acoes-pendentes-<AAAA-MM-DD>.md` |
| Altera código? | Não. Também não preenche dono nem prazo por conta própria |

## Pré-condição

Sem `docs/incidents/`, não houve incidente registrado. Diga isso em uma linha e pare.

Atenção ao falso alívio: pasta vazia pode significar "nenhum incidente" ou "incidente que ninguém
registrou". Se houver sinal do segundo caso — postmortem em outro lugar, incidente citado em
commit ou issue —, diga; a ausência de registro é o achado.

## Procedimento

1. **Varra os postmortems.** `docs/incidents/<AAAA-MM-DD>-<slug>/`, arquivos `postmortem.md`,
   `incident.md` e `root-cause.md`. A tabela de ações do template tem esta forma:

   ```
   | # | ação | tipo | dono | prazo |
   |---|---|---|---|---|
   | 1 | | prevenir / detectar / mitigar mais rápido | | |
   ```

2. **Classifique cada ação.** A urgência não é a mesma:

   | Estado | Critério |
   |---|---|
   | **Vencida** | Prazo passou e não há evidência de conclusão |
   | **Órfã** | Sem dono, ou sem prazo, ou ambos — "intenção", pelo próprio template |
   | **Vencendo** | Prazo nos próximos 7 dias |
   | **Concluída** | Há evidência: commit, PR, alerta existindo, arquivo criado |
   | **Em aberto** | Dono e prazo definidos, prazo no futuro |

3. **Verifique conclusão com evidência, não com marcação.** Ação marcada como feita sem nada
   verificável é o mesmo defeito que a rotina persegue, um nível acima. Para "criar alerta de
   latência", procure o alerta. Para "adicionar teste de regressão", procure o teste. Se não
   achar, o estado é **não verificado** — não "concluída" nem "pendente". Diga qual você procurou
   e onde.

4. **Cheque a ação de detecção.** O template exige ao menos uma ação do tipo *detectar*: sem ela,
   o próximo incidente diferente vai demorar o mesmo tanto para ser notado. Postmortem sem nenhuma
   ação de detecção é achado por si só, independente de prazo.

5. **Procure a reincidência.** Dois postmortems com a mesma causa raiz e a ação do primeiro ainda
   aberta é o achado mais forte que esta rotina produz — e o único que costuma fazer alguém agir.
   Compare as seções de causa raiz, não os títulos.

6. **Não atribua dono nem prazo.** Rotina que preenche a coluna vazia transforma "ninguém assumiu"
   em "alguém foi voluntariado sem saber". A lacuna é a informação.

## Saída

```markdown
# Ações de postmortem — <AAAA-MM-DD>

Incidentes registrados: <n>   ·   Ações totais: <n>
Vencidas: <n>   ·   Órfãs: <n>   ·   Vencendo em 7 dias: <n>

## Vencidas

| Incidente | # | Ação | Dono | Prazo | Vencida há |
|---|---|---|---|---|---|
| 2026-05-14-checkout-500 | 2 | adicionar alerta de erro 5xx | <nome> | 2026-06-01 | 59 dias |

## Órfãs (sem dono ou sem prazo)

| Incidente | # | Ação | Falta |
|---|---|---|---|

## Não verificado
| Incidente | # | Ação | O que procurei |
|---|---|---|---|
| <...> | 3 | teste de regressão para X | `grep` em tests/ por <termo> — nada |

## Postmortems sem ação de detecção
<lista>

## Reincidência
<mesma causa raiz em mais de um incidente, com a ação do primeiro ainda aberta>

## Nada a fazer
<ou: "todas as N ações têm dono e prazo; nenhuma vencida.">
```

## Nada a fazer

Toda ação tem dono e prazo, nenhuma venceu, e cada postmortem tem ao menos uma ação de detecção.
Uma linha, com o número de ações em aberto — o zero absoluto é raro o bastante para merecer
desconfiança.

## Agendamento

```
/schedule "toda sexta às 6h17, rode /nightly incident-actions no projeto <nome> e me mande o relatório"
```

Sexta de manhã tem motivo: é quando ainda dá para puxar alguém antes da semana fechar, e não é
segunda — em que a lista compete com tudo que chegou no fim de semana.

## Quando desligar

- Sem incidente registrado há seis meses → desligue e religue no primeiro postmortem novo.
- A lista de vencidas só cresce → a rotina está funcionando e a organização não. Não é problema da
  rotina, mas continuar reportando semanalmente para ninguém agir é custo. Leve a lista para uma
  decisão: fazer, ou fechar as ações explicitamente como "não vamos fazer" — que é uma resposta
  legítima, ao contrário do silêncio.
- As ações vivem no tracker (Jira, Linear), não no postmortem → então é o tracker que deve cobrar.
  Confira com `${CLAUDE_PROJECT_DIR}/.claude/ai-toolkit/tools/tracker.sh` qual o projeto usa, e
  desligue esta rotina se a duplicidade estiver dividindo a atenção.
