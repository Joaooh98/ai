# Design docs — ensaios de contexto

Texto de fundamentação, escrito no MBA. **Não é documentação do repositório** — nada aqui
descreve como a oficina funciona nem é lido por agente em runtime. É o raciocínio que está por
trás de decisões que aparecem implementadas em `skills/` e `workflow/`.

```
context/intro/resum.md   documentação como ativo de engenharia
context/rup/resum.md     Rational Unified Process — disciplinas e iterações
```

## `context/intro` — documentação como ativo

Por que documentação burocrática fracassa, e o que muda quando o consumidor do documento passa a
ser também um modelo. A tese central: documento existe para servir ao fluxo de trabalho, não para
cumprir formalidade — e contexto registrado cedo vira insumo reutilizável durante todo o ciclo.

É a origem direta do contrato de artefatos do fluxo SDLC: cada agente escreve num caminho fixo, e
a saída de um é a entrada do próximo.

## `context/rup` — RUP

Como o RUP organizou o desenvolvimento em disciplinas com ciclos menores e pontos de revisão, sem
abrir mão de controle sobre artefatos. É o antecedente das ondas e dos portões em `skills/sdlc/`.

## Estado

As imagens em `context/*/img/` **não estão referenciadas** por nenhum dos dois textos. Ou entram
no corpo do ensaio, ou saem do repositório — arquivo que ninguém alcança é peso morto que ninguém
percebe estar desatualizado.
