---
name: sdlc-quality
description: Onda 04 do fluxo SDLC - cobertura de testes, code review, auditoria de seguranca e performance em paralelo, seguidos do portao de merge. Carregada pela skill sdlc.
---

# Onda 04 — Quality

Colete o escopo primeiro:

```bash
tools/diff-scope.sh main
```

Sem diff, não há o que avaliar — diga isso e pare.

## Despacho (em paralelo)

**`test-engineer`** → `docs/sdlc/04-quality/test-plan.md`
> Derive os casos dos critérios de aceite e das tabelas de decisão — **antes** de ler a
> implementação. Ler o código primeiro enviesa você a testar o que ele faz, não o que deveria
> fazer. Rode a suíte mais de uma vez e em ordem aleatória. Cole a saída real.

**`code-reviewer`** → `docs/sdlc/04-quality/review-<escopo>.md`
> Revise o diff contra critérios de aceite e contrato. Todo achado precisa de cenário de falha
> concreto. Verifique as afirmações do autor rodando os testes.

**`security-auditor`** → `docs/sdlc/04-quality/security-audit.md`
> Audite o código implementado. Verifique cada requisito do threat-model com evidência
> file:line. Autorização no nível do objeto, não da rota.
> Dispare sempre que o `diff-scope` marcar auth, dados pessoais, pagamento, upload ou entrada
> externa como área de risco.

**`performance-engineer`** → `docs/sdlc/04-quality/performance-<escopo>.md`
> Só se houver orçamento nos NFRs ou suspeita de regressão. Baseline e pós-mudança com
> variância, em volume de dados realista.

## Verificação no mundo real

Antes do portão, se a mudança é visível ao usuário: **abra e use**. Teste verde prova que o código
faz o que o teste diz — não que o produto funciona.

- Interface → navegue o fluxo, confirme estado de erro e caminho por teclado. Use o MCP de
  navegador da sessão (`ToolSearch`) ou o Playwright/Cypress do projeto.
- Endpoint → chame de verdade, veja sucesso **e** erro.
- Pipeline → execute, não leia o YAML e conclua.

Sem forma de verificar de verdade, diga isso no relatório — `.claude/toolbelt.md` deve registrar
como se verifica neste projeto. Não registrado é lacuna de calibração: rode `/setup`.

## Portão 3

Critérios em `../sdlc-gate/gates.md`. Rode antes:

```bash
tools/artifact-lint.sh 04
```

## Ciclo de correção

Achado volta para **quem escreveu o código**, nunca para o revisor. Depois da correção, o mesmo
revisor confirma. Repita até o portão passar.

## Registro

Reporte cada artefato ao `context-manager` — `Task(subagent_type: "context-manager")`, esse nome
exato. Você não escreve `MANIFEST.md` (regra 6 do roteador `sdlc`).

## Saída

Tabela: achados por severidade · corrigidos · abertos · veredito do portão.
