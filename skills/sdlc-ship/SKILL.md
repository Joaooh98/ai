---
name: sdlc-ship
description: Onda 05 do fluxo SDLC - observabilidade antes do trafego, pipeline com rollback testado e decisao go ou no-go verificada com evidencia. Carregada pela skill sdlc.
---

# Onda 05 — Delivery

Versão alvo: informada pelo usuário. Se não houver, pergunte antes de continuar.

## Passo 1 — Observabilidade antes do tráfego

Funcionalidade nova em produção sem instrumentação é uma aposta. Delegue ao `sre-observability`:

> Defina SLIs/SLOs das jornadas afetadas, a instrumentação necessária e os alertas acionáveis com
> runbook. Isso existe **antes** do release, não depois do primeiro incidente.

## Passo 2 — Pipeline

Se o caminho de deploy não existe, está quebrado, ou a mudança exige passo novo — `devops-engineer`:

> Build reprodutível, promoção do mesmo artefato entre ambientes, segredos fora do repositório,
> rollback testado incluindo as migrações.

## Passo 3 — Decisão

`release-manager` → `docs/sdlc/05-delivery/release-<versão>.md` + `CHANGELOG.md`

> Verifique cada portão **com evidência**, não com afirmação: review sem blocker, auditoria sem
> BLOCK não remediado, rastreabilidade critério → teste, migrações reversíveis, observabilidade
> presente. Portão faltando é no-go, não observação de rodapé.

## Passo 4 — Documentação

Mudança visível ao usuário ou breaking change — `tech-writer`:

> Atualize a documentação afetada e escreva o guia de migração. **Rode cada comando documentado**
> e cole a saída real. Marque como não verificado o que não conseguiu executar.

## Portão 4

Critérios em `../sdlc-gate/gates.md`. Rode antes:

```bash
tools/artifact-lint.sh 05
```

## Registro

Reporte cada artefato ao `context-manager` — `Task(subagent_type: "context-manager")`, esse nome
exato. Você não escreve `MANIFEST.md` (regra 6 do roteador `sdlc`).

## Saída

**GO**, **NO-GO** ou **GO COM CONDIÇÕES**, com a evidência de cada portão e, se for no-go,
exatamente o que falta.

Não execute o deploy. Disparar é decisão do usuário.
