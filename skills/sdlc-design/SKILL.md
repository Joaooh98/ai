---
name: sdlc-design
description: Onda 02 do fluxo SDLC - arquitetura e ADRs primeiro, depois contratos de API, modelo de dados, modelo de ameacas e especificacao de UI em paralelo, seguidos do portao de design. Carregada pela skill sdlc.
---

# Onda 02 — Design

Pré-condição: `docs/sdlc/01-discovery/prd.md` existe e passou no Portão 1.

## Passo 1 — Arquitetura, sozinha e bloqueante

Os outros dependem das fronteiras que ela define. Rode antes, não junto.

**`solution-architect`** → `docs/sdlc/02-design/architecture.md` + `adr/ADR-*.md`
> Derive os NFRs quantificados do PRD. Modele estado atual e alvo em C4. Defina fronteiras de
> componente, padrões de integração com comportamento de falha, plano de migração com rollback.
> Registre cada decisão significativa como ADR — estrutura em `templates/adr.md`, ao lado desta
> skill.

## Passo 2 — Especialistas em paralelo

**`api-designer`** → `docs/sdlc/02-design/api/`
> Contratos, catálogo de erros, paginação, idempotência, política de versionamento.

**`data-architect`** → `docs/sdlc/02-design/data-model.md`
> Padrões de acesso primeiro. Depois entidades, constraints, índices justificados, migrações
> expand/contract.

**`threat-modeler`** → `docs/sdlc/02-design/threat-model.md`
> STRIDE por fronteira de confiança, casos de abuso, requisitos de segurança testáveis com dono.

**`ux-ui-designer`** → `docs/sdlc/02-design/ux-spec.md` (pule se não houver interface)
> Telas com **todos** os estados, contratos de componente, tokens, acessibilidade.

**`integration-engineer`** → `docs/sdlc/02-design/integrations.md` (pule se nada externo é usado)
> Para cada sistema que não controlamos: escreva **a interface interna primeiro**, no vocabulário
> do nosso domínio, antes de abrir a documentação do fornecedor. Depois o comportamento de falha
> por operação, webhooks, limites, credenciais e degradação.
> Template em `templates/integration-register.md`.

A ordem importa: definir a interface interna depois de ler o SDK do fornecedor produz uma cópia
do SDK com outro nome — e trocar de fornecedor deixa de ser possível.

## Portão 2

Critérios em `../sdlc-gate/gates.md`. Rode antes:

```bash
tools/artifact-lint.sh 02
```

Atenção especial à **contradição entre artefatos**: contrato expondo campo que o modelo de dados
não tem, tela consumindo endpoint que não existe. É blocker, e volta para os dois agentes.

## Saída

Decisões estruturais · ADRs criados · veredito do portão.
