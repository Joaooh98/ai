---
name: workspace
description: Gerencia os projetos cadastrados no workspace de dentro do Claude - listar, diagnosticar, fiar, cadastrar e descadastrar. Use quando o usuario invocar /workspace, perguntar o estado dos projetos cadastrados ou quiser preparar um projeto para receber a equipe. Abrir a sessao em outro projeto continua sendo no terminal.
allowed-tools: Bash(${CLAUDE_PROJECT_DIR}/.claude/ai-toolkit/workspace/go) Bash(${CLAUDE_PROJECT_DIR}/.claude/ai-toolkit/workspace/go *)
---

# Workspace

!`${CLAUDE_PROJECT_DIR}/.claude/ai-toolkit/workspace/go list`

## Roteamento

A listagem acima é o estado atual do cadastro. Interprete o argumento e roteie para o script —
sempre pelo caminho `${CLAUDE_PROJECT_DIR}/.claude/ai-toolkit/workspace/go`, nunca relativo:

| Invocação | O que rodar |
|---|---|
| `/workspace` | nada — apresente a listagem acima |
| `/workspace check <nome>` | `go check <nome>` |
| `/workspace wire <nome>` | `go wire <nome>` |
| `/workspace add <caminho> [nome]` | `go add <caminho> [nome]` |
| `/workspace rm <nome>` | `go rm <nome>` |
| `/workspace <nome>` | `go wire <nome>` e em seguida `go check <nome>` |

## Regras

- **Nunca** rode `go <nome>` sem subcomando: essa rota abre uma sessão interativa (`exec claude`)
  e não funciona dentro de uma sessão já aberta. Aqui dentro, "ir para o projeto" é `wire` +
  `check`.
- Depois de `/workspace <nome>`, feche com o comando pronto para o operador colar no terminal:
  `./workspace/go <nome>` (a partir do repo ai).
- `rm` só descadastra, não toca no projeto — mesmo assim, se o pedido for ambíguo, confirme
  antes.
- Se a injeção acima falhou por caminho inexistente, este projeto não tem a âncora
  `.claude/ai-toolkit` — a fiação se faz a partir do repo ai: `./workspace/go wire <nome>`.

## Saída

Apresente a listagem como o script imprime, sem reescrever em prosa. Em `check`, destaque o que
está AUSENTE e o próximo passo concreto.
