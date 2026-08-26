---
name: sdlc-discovery
description: Onda 01 do fluxo SDLC - PRD com criterios testaveis, regras de dominio e pesquisa de UX, em paralelo, seguidos do portao de requisitos. Carregada pela skill sdlc.
---

# Onda 01 — Discovery

Pré-condição: `docs/sdlc/00-orchestration/plan.md` existe. Se não, rode o bootstrap antes.

## Despacho (numa única mensagem, para rodarem em paralelo)

**`product-owner`** → `docs/sdlc/01-discovery/prd.md`
> Escreva o PRD para <escopo>. Critérios de aceite em Given/When/Then cobrindo caminho feliz,
> ao menos dois caminhos de erro e as fronteiras. Nenhum detalhe de implementação.
> Estrutura em `templates/prd.md`, ao lado desta skill.

**`business-analyst`** → `docs/sdlc/01-discovery/domain.md`
> Formalize linguagem ubíqua, catálogo de regras e tabelas de decisão. Faça engenharia reversa
> das regras já existentes no código, citando o caminho.

**`ux-researcher`** → `docs/sdlc/01-discovery/ux-research.md`
> Personas, jobs-to-be-done, jornada atual, auditoria heurística e de acessibilidade. Marque cada
> persona como evidence-based ou provisional.

Pule `business-analyst` se o domínio for trivial, e `ux-researcher` se não houver interface —
mas **diga que pulou e por quê**. Omissão silenciosa é o que faz o fluxo apodrecer.

## Portão 1

Critérios em `../sdlc-gate/gates.md`. Rode antes:

```bash
tools/artifact-lint.sh 01
```

Item reprovado volta ao agente que o produziu, com o defeito específico. **Não avance com portão
falhando** — diga ao usuário o que está bloqueando.

## Registro

Reporte cada artefato ao `context-manager` — `Task(subagent_type: "context-manager")`, esse nome
exato. Você não escreve `MANIFEST.md` (regra 6 do roteador `sdlc`).

## Saída

Até 10 linhas: o que foi decidido, quantos critérios de aceite existem, o que ficou em aberto,
veredito do portão.
