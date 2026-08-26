---
name: sdlc-bootstrap
description: Onda 00 do fluxo SDLC - cria a estrutura de artefatos, perfila a stack do repositorio e produz o plano de execucao com ondas, donos e portoes. Carregada pela skill sdlc quando nao existe ciclo iniciado.
---

# Onda 00 — Bootstrap

## Estrutura

```bash
mkdir -p docs/sdlc/{00-orchestration,01-discovery,02-design/adr,02-design/api,03-build,04-quality,05-delivery,06-docs}
```

## Perfil da stack

Delegue ao agente `project-analyst`:

> Perfile este repositório em `docs/sdlc/00-orchestration/stack-profile.md`. Cite o caminho do
> arquivo para cada afirmação. Liste explicitamente o que não conseguiu determinar.

Já existe e o repositório não mudou? Reutilize e diga isso.

## Plano de execução

Delegue ao `tech-lead-orchestrator`:

> Objetivo: <objetivo do usuário>
> Entrada: docs/sdlc/00-orchestration/stack-profile.md
> Produza docs/sdlc/00-orchestration/plan.md — classifique a escala, decomponha em itens com
> dono, entrada, caminho do entregável e critério de aceite, agrupados em ondas paralelizáveis
> com portões entre elas.

A escala define o tamanho do fluxo:

| Escala | O que roda |
|---|---|
| `TRIVIAL` | Um agente, sem artefato. O fluxo encolhe e termina aqui |
| `FEATURE` | Discovery enxuta → design → build → quality |
| `INITIATIVE` | Ciclo completo, com PRD formal, ADRs e modelo de ameaças |

## Registro

Delegue ao `context-manager` — `subagent_type` com esse nome exato, sem apelido:

> Inicialize docs/sdlc/00-orchestration/MANIFEST.md a partir do plano, com a checklist de
> cobertura derivada dos entregáveis planejados.

O arquivo é dele. Você não o abre — nem aqui, nem nas ondas seguintes (regra 6 do roteador `sdlc`).

## Portão 0

- [ ] Todo item de trabalho tem exatamente um dono
- [ ] Todo item tem caminho de entregável concreto
- [ ] Nenhuma dependência aponta para uma onda posterior
- [ ] Dois itens paralelos não escrevem o mesmo arquivo
- [ ] Critérios de aceite são verificáveis, não aspiracionais

## Saída

Escala classificada e por quê · as ondas com seus agentes · o que a onda 1 produz.
Não execute nenhuma onda: bootstrap só planeja.
