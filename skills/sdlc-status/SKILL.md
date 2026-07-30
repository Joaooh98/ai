---
name: sdlc-status
description: Mostra o estado real do ciclo SDLC lido do disco - cobertura do plano, portoes pendentes, inconsistencias e proximo passo. Use para saber onde o trabalho parou, inclusive em sessao nova.
allowed-tools: Bash(${CLAUDE_PROJECT_DIR}/.claude/ai-toolkit/tools/sdlc-state.sh) Bash(${CLAUDE_PROJECT_DIR}/.claude/ai-toolkit/tools/sdlc-state.sh *) Bash(${CLAUDE_PROJECT_DIR}/.claude/ai-toolkit/tools/artifact-lint.sh) Bash(${CLAUDE_PROJECT_DIR}/.claude/ai-toolkit/tools/artifact-lint.sh *) Bash(git status*) Bash(git log*)
---

# Status do ciclo

!`${CLAUDE_PROJECT_DIR}/.claude/ai-toolkit/tools/sdlc-state.sh "${CLAUDE_PROJECT_DIR}"`

## Análise

1. Leia `docs/sdlc/00-orchestration/plan.md` e `MANIFEST.md`.
2. Para cada entregável planejado, confirme que o arquivo **existe de fato**. Item marcado como
   concluído no MANIFEST sem arquivo correspondente é inconsistência — reporte explicitamente.
3. Rode `tools/artifact-lint.sh` para separar artefato pronto de esqueleto de template.
4. Identifique a fase atual: a última onda com todos os entregáveis presentes **e** com portão
   avaliado. Portão não avaliado ≠ portão aprovado.

## Saída

```
Ciclo: <objetivo>          Fase: <NN nome>
Onda 1  ████████  3/3  · portão aprovado
Onda 2  ████░░░░  2/4  · portão pendente
  falta: docs/sdlc/02-design/data-model.md (data-architect)
Inconsistências: <nenhuma | lista>
Próximo passo: <comando concreto>
```

Não invente progresso. Artefato que existe mas está claramente incompleto conta como pendente,
e você diz por quê.
