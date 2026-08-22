# Design docs — ensaios de contexto

Texto de fundamentação, escrito no MBA. **Não é documentação do repositório** — nada aqui
descreve como a oficina funciona nem é lido por agente em runtime. É o raciocínio que está por
trás de decisões que aparecem implementadas em `skills/` e `workflow/`.

```
context/modulo-1/   por que documentar, e o que já se tentou antes
context/modulo-2/   documentação na era da IA, taxonomia e PRD
```

## Módulo 1 — o problema

| Texto | Tese |
|---|---|
| `context/modulo-1/intro/resum.md` | Documentação é ativo de engenharia: contexto registrado deixa de depender de pessoas específicas |
| `context/modulo-1/rup/resum.md` | RUP organizou o trabalho em disciplinas com ciclos menores e pontos de revisão, sem abrir mão de controle sobre artefatos |
| `context/modulo-1/agile/agile.md` | O Manifesto Ágil reagiu ao excesso de processo — a virada não foi parar de documentar, foi parar de tratar o documento como produto principal |
| `context/modulo-1/known-problems/known-problems.md` | Documentação desatualizada é mais perigosa que ausente: transmite confiança falsa e vira risco operacional |

O último é o que mais aparece implementado aqui. `tools/docs-lint.sh` existe por causa dele, e a
regra "item não verificável bloqueia o portão" é a mesma tese aplicada a artefato de ciclo.

## Módulo 2 — a resposta

| Texto | Tese |
|---|---|
| `context/modulo-2/documentation-in-the-age-AI/docs-in-the-age-AI.md` | Documentação passa a ser lida por modelo, o que a aproxima do papel do teste automatizado |
| `context/modulo-2/type-docs/type-docs.md` | Taxonomia: produto, design/arquitetura, infraestrutura, operação, conhecimento — cada categoria responde a uma pergunta diferente |
| `context/modulo-2/prd/` | Oito partes sobre PRD: seções, visão de alto nível, casos de uso e dois exemplos práticos |

A taxonomia do `type-docs` é a origem direta da árvore de `docs/sdlc/` no projeto alvo: uma pasta
por pergunta, e nenhum documento misturando objetivos incompatíveis.

## Estado

As **17 imagens** em `context/modulo-*/*/img/` não estão referenciadas por nenhum dos textos.
Ou entram no corpo do ensaio, ou saem do repositório — arquivo que ninguém alcança é peso morto
que ninguém percebe estar desatualizado.
