# Design docs — ensaios de contexto

Texto de fundamentação, escrito no MBA. **Não é documentação do repositório** — nada aqui
descreve como a oficina funciona nem é lido por agente em runtime. É o raciocínio que está por
trás de decisões que aparecem implementadas em `skills/` e `workflow/`.

```
context/modulo-1-intro/                   por que documentar, e o que já se tentou antes
context/modulo-2-docs/                    documentação na era da IA, taxonomia e PRD
context/modulo-3-design-and-arquiteture/  design doc, high level e feature design doc
plano-skills-comunidade.md                plano de trabalho, não ensaio
```

## Módulo 1 — o problema

| Texto | Tese |
|---|---|
| `context/modulo-1-intro/intro/resum.md` | Documentação é ativo de engenharia: contexto registrado deixa de depender de pessoas específicas |
| `context/modulo-1-intro/rup/resum.md` | RUP organizou o trabalho em disciplinas com ciclos menores e pontos de revisão, sem abrir mão de controle sobre artefatos |
| `context/modulo-1-intro/agile/agile.md` | O Manifesto Ágil reagiu ao excesso de processo — a virada não foi parar de documentar, foi parar de tratar o documento como produto principal |
| `context/modulo-1-intro/known-problems/known-problems.md` | Documentação desatualizada é mais perigosa que ausente: transmite confiança falsa e vira risco operacional |

O último é o que mais aparece implementado aqui. `tools/docs-lint.sh` existe por causa dele, e a
regra "item não verificável bloqueia o portão" é a mesma tese aplicada a artefato de ciclo.

## Módulo 2 — a resposta

| Texto | Tese |
|---|---|
| `context/modulo-2-docs/documentation-in-the-age-AI/docs-in-the-age-AI.md` | Documentação passa a ser lida por modelo, o que a aproxima do papel do teste automatizado |
| `context/modulo-2-docs/type-docs/type-docs.md` | Taxonomia: produto, design/arquitetura, infraestrutura, operação, conhecimento — cada categoria responde a uma pergunta diferente |
| `context/modulo-2-docs/prd/` | Oito partes sobre PRD: seções, visão de alto nível, casos de uso e dois exemplos práticos |

A taxonomia do `type-docs` é a origem direta da árvore de `docs/sdlc/` no projeto alvo: uma pasta
por pergunta, e nenhum documento misturando objetivos incompatíveis.

## Módulo 3 — design e arquitetura

| Texto | Tese |
|---|---|
| `context/modulo-3-design-and-arquiteture/intro/doc-design-arqh.md` | Design doc transforma necessidade difusa em direção técnica compartilhada, antes que cada um assuma um entendimento diferente |
| `context/modulo-3-design-and-arquiteture/high-level/` | High Level Design é o terreno arquitetural onde as features precisam caber — sistema, não código |
| `context/modulo-3-design-and-arquiteture/feature-design-docs/` | Feature Design Doc desce do terreno para comportamento detalhado e contrato real, sem prescrever código |
| `context/modulo-3-design-and-arquiteture/commun-docs/commun-docs.md` | Documentação de comunicação entre partes |
| `context/modulo-3-design-and-arquiteture/deep-research/` | Três pesquisas de apoio |

Este módulo é o antecedente direto da onda 02 do fluxo: `architecture.md` é o high level, os ADRs
registram a decisão com alternativas, e o contrato de API é o nível de detalhe que o FDD descreve.

## O que não é ensaio

`plano-skills-comunidade.md` é **plano de trabalho**, não fundamentação. Está aqui por
proximidade de assunto, mas segue a regra de `plans/`: enquanto não estiver entregue, o que ele
descreve não existe no repositório.
