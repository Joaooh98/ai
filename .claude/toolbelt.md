# Ferramental deste projeto

Fatos que a detecção automática não alcança. Injetado no contexto dos agentes com precedência
sobre o que é detectado. Mantenha curto e factual — cada linha aqui é carregada em toda invocação
de agente.

- Este repositório **é** a biblioteca de agentes. Trabalhar aqui significa editar `agents/`,
  `skills/`, `workflow/` e `tools/`. Depois de qualquer alteração, rode `./agents/install.sh --check`.
- Remote é GitHub (`Joaooh98/ai`) — use `gh`, não `glab`.
- O material do MBA em `prompts/` usa **um venv e um `requirements.txt` por capítulo**. Nunca
  instale dependência na raiz nem assuma um ambiente compartilhado. Detalhes em
  `prompts/mba-ia-prompt-engineering/AGENTS.md`.
- Servidores MCP `MCP_DOCKER` e `hostinger-*` estão cadastrados mas **não conectam**
  (verificado em 27/07/2026, `Connection closed`). Não conte com eles; não tente reconfigurá-los
  sem o usuário pedir.
- Não existe suíte de testes na raiz. `pytest` só funciona dentro dos capítulos que o declaram.
