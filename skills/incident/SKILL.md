---
name: incident
description: Resposta rapida a incidente ou problema em producao - classifica severidade, mitiga antes de diagnosticar, investiga a causa raiz sem chutar e fecha com postmortem. Use quando algo esta quebrado, degradado, ou um usuario reporta impacto.
argument-hint: [sintoma observado]
disable-model-invocation: true
allowed-tools: Bash(${CLAUDE_PROJECT_DIR}/tools/incident-evidence.sh *) Bash(git *)
---

# Resposta a incidente

Sintoma relatado: **$ARGUMENTS**

Este fluxo é o oposto do `/sdlc`. Lá, portões protegem a qualidade. Aqui, o relógio está correndo
e portão é obstáculo. Mas velocidade sem método vira o segundo incidente — então a ordem importa
mais do que nunca.

## A distinção que define tudo

> **Mitigar ≠ corrigir.**
> Mitigação é reversível e **não exige causa raiz**: rollback, desligar flag, escalar, failover.
> Correção exige causa raiz **sempre**.
>
> Aplicar "correção" sem causa raiz identificada não é conserto — é chute com deploy. É a fonte
> número um de incidentes que voltam.

---

## O que mudou (coletado agora)

!`${CLAUDE_PROJECT_DIR}/tools/incident-evidence.sh 24`

---

## Passo 1 — Fatos, em 5 minutos

Não peça diagnóstico ainda. Estabeleça, com o usuário:

| Pergunta | Por que importa |
|---|---|
| Sintoma **observável**? | "Está lento" não serve. "p95 saiu de 300ms para 9s" serve |
| Quem é afetado, e quanto? | Define severidade |
| Desde quando, exatamente? | Cruza com a janela de mudanças acima |
| Piorando, estável ou melhorando? | Define urgência da mitigação |
| **Alguém já mexeu em algo?** | Mudança não registrada é a causa raiz falsa mais comum |
| **Alguma dependência externa caiu?** | Se nada mudou aqui, esta é a primeira suspeita |

Nenhum commit na janela é um **sinal forte**, não um beco sem saída: a causa provavelmente está
fora do seu código. Verifique, nesta ordem — dependência externa (a saída acima lista as
registradas, com página de status), config alterada em runtime, credencial ou certificado
expirado, recurso esgotado, deploy de outro serviço.

Faltando resposta crítica, pergunte. Chutar aqui contamina tudo que vem depois.

## Passo 2 — Severidade

Escala em `severity.md`, ao lado desta skill. Leia agora. Ela decide **quanto processo roda** —
é dosagem, não burocracia.

Declare incidente assim que qualquer um for verdade: cliente percebe · um segundo time precisa
entrar · uma hora de análise focada sem solução · perda ou corrupção de dados · suspeita de
comprometimento.

Declarar cedo e cancelar é barato. Declarar tarde é o que vira desastre.

## Passo 3 — Mitigar, se houver mitigação reversível

Delegue ao `incident-commander`:

> Sintoma: <observável>. Impacto: <quem, quanto>. Início: <quando>.
> Evidência de mudanças: a saída acima.
> Classifique a severidade, decida a mitigação reversível e mantenha a linha do tempo em
> `docs/incidents/<data>-<slug>/incident.md`. Você comanda e não altera o sistema.

Quem executa a mitigação é **um** agente — `devops-engineer` ou `sre-observability`. Nunca dois
mexendo ao mesmo tempo.

**Uma mitigação por vez, com verificação entre elas.** Duas juntas e você não sabe qual funcionou
— e vai carregar essa dúvida para o postmortem.

Sem mitigação reversível disponível? Diga isso explicitamente e vá ao passo 4 com o relógio à
vista.

## Passo 4 — Diagnosticar

Serviço restaurado (ou sem mitigação possível), delegue ao `root-cause-analyst`:

> Investigue a causa raiz. Reproduza antes de teorizar. Uma hipótese por vez, testada
> minimamente. Registre as hipóteses refutadas. Não proponha correção sem causa confirmada.
> Saída em `docs/incidents/<data>-<slug>/root-cause.md`.

Ele não altera nada. Investiga e propõe.

## Passo 5 — Corrigir

Só com causa raiz confirmada. Delegue ao builder da área, com:

> Causa raiz: <do relatório>. Correção proposta: <do relatório>.
> Escreva primeiro o teste de regressão que falha. Aplique só a correção da causa — nada de
> melhorias no caminho. Cole a saída real do teste.

## Passo 6 — Verificar de verdade

- [ ] O teste de regressão falhava antes e passa agora
- [ ] O sintoma sumiu **medido**, não por impressão
- [ ] As mitigações temporárias foram revertidas, ou viraram item de acompanhamento explícito
- [ ] Nenhum estado degradado ficou implícito

## Passo 7 — Postmortem

Obrigatório em SEV1 e SEV2. Delegue ao `sre-observability`, com o template em
`templates/postmortem.md`.

Duas perguntas valem mais que o resto: **por que não foi detectado antes** e **por que passou
pelos testes e pelo review**. É o que vira melhoria de verdade; a correção em si só apaga um
incêndio.

## Regras

1. **Mitigação não exige causa raiz. Correção exige.** Sempre.
2. **Uma mudança por vez**, verificada. Sob pressão essa é a primeira regra a ser quebrada, e a
   que mais custa.
3. **Registre tentativa que falhou.** Na terceira hora, é o que impede repetir o já tentado.
4. **Sistemático é mais rápido que chutar.** Pressa é o motivo de usar o método, não de largá-lo.
5. **"Reiniciar resolveu" não é causa raiz** — é evidência de estado acumulado, vazamento ou
   corrida. O incidente vai voltar.
6. **Nada de freelancing.** Só o papel de operação altera o sistema.
