---
name: sdlc-gate
description: Avalia um portao do fluxo SDLC item a item, com evidencia, e devolve aprovado ou bloqueado. Use quando precisar validar uma fase antes de avancar, ou auditar um portao ja dado como aprovado.
argument-hint: [1|2|3|4]
allowed-tools: Bash(${CLAUDE_PROJECT_DIR}/.claude/ai-toolkit/tools/artifact-lint.sh) Bash(${CLAUDE_PROJECT_DIR}/.claude/ai-toolkit/tools/artifact-lint.sh *) Bash(${CLAUDE_PROJECT_DIR}/.claude/ai-toolkit/tools/meta-check.sh) Bash(${CLAUDE_PROJECT_DIR}/.claude/ai-toolkit/tools/meta-check.sh *)
---

# Avaliação de portão

Portão: **$ARGUMENTS** (se vazio, avalie o da fase atual)

Um portão não é formalidade: é o que impede trabalho ruim de contaminar a fase seguinte.

## Procedimento

1. **Verificação automática primeiro** — barata, elimina o óbvio:

   ```bash
   tools/artifact-lint.sh <fase>     # o artefato está completo?
   tools/meta-check.sh               # portões 3 e 4: o projeto atende o que declarou?
   ```

   Exit 1 em qualquer uma é reprovação — não continue para o julgamento e não negocie o
   número. Meta é decisão já tomada pelo time no `/setup`; aqui ela só se confere.

2. **Abra cada arquivo-fonte do portão.** Não avalie de memória nem pergunte ao agente se fez
   direito — leia o que ele produziu.

3. **Para cada item, dê veredito com evidência**: caminho e trecho, ou a ausência dele.

4. **Onde precisar executar** (testes, lint, build), execute de verdade e cole a saída.

Os critérios de cada portão estão em `gates.md`, ao lado deste arquivo. Leia-o agora.

## Saída

```
Portão <n>: APROVADO | BLOQUEADO
| item | veredito | evidência |
Bloqueadores:
  - <o que falta exatamente> → devolver para <agente>
Não verificáveis:
  - <item> → faltou <o quê>
```

Item não verificável bloqueia o portão. Nunca aprove o que não conseguiu conferir.
