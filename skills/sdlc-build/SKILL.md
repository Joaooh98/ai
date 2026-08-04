---
name: sdlc-build
description: Onda 03 do fluxo SDLC - roteia cada item de trabalho para o engenheiro certo com contrato e requisitos de seguranca como entrada, e verifica a entrega com saida real de teste. Carregada pela skill sdlc.
---

# Onda 03 — Build

Pré-condição: Portão 2 aprovado. Sem contrato, não se implementa — é o motivo de o fluxo existir.

## Roteamento

Um item, um dono:

| Natureza | Agente |
|---|---|
| Servidor, endpoints, persistência, lógica de domínio | `backend-engineer` |
| **Sistema externo que não controlamos** — API de terceiro, gateway, ERP, webhook | `integration-engineer` |
| Interface web, componentes, estado, consumo de API | `frontend-engineer` |
| iOS, Android, React Native, Flutter | `mobile-engineer` |
| Pipeline de dados, ETL/ELT, modelo analítico | `data-engineer` |
| Prompt, RAG, agente, saída estruturada de LLM | `ai-engineer` |
| Pipeline, IaC, containerização, ambiente | `devops-engineer` |

Item que cruza camadas: **divida em itens separados**. Nunca dois agentes no mesmo arquivo na
mesma onda.

## Despacho

Dê ao agente, explicitamente:

> Item: <id e título>
> Critérios de aceite: <copiados do PRD na íntegra>
> Contrato: <caminho>
> Requisitos de segurança atribuídos a você: <ids do threat-model>
> Convenções: docs/sdlc/00-orchestration/stack-profile.md
>
> Escreva o teste que falha antes da implementação. Rode a suíte de verdade e cole a saída real,
> incluindo falhas. Registre em docs/sdlc/03-build/implementation-log.md.

## Verificação imediata

- [ ] Os testes foram **executados** — peça a saída, não a afirmação
- [ ] Todo critério de aceite tem teste nomeado, inclusive os de erro
- [ ] Lint e formatador passam
- [ ] O contrato não foi alterado unilateralmente
- [ ] Nenhum teste foi desabilitado ou enfraquecido para a suíte ficar verde

Agente disse "os testes passam" sem colar saída? **Rode você.** Essa é a falha mais comum e a
mais cara: ela contamina o portão 3 inteiro.

## Registro

Reporte cada artefato ao `context-manager` — `Task(subagent_type: "context-manager")`, esse nome
exato. Você não escreve `MANIFEST.md` (regra 6 do roteador `sdlc`).

## Saída

Arquivos alterados · critérios cobertos · resultado real dos testes · desvios do design ·
pendências.
