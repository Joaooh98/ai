---
name: sdlc
description: Entrada unica do fluxo de desenvolvimento em equipe. Le os artefatos existentes, descobre em que fase o trabalho esta e executa a proxima onda, parando no portao. Use para iniciar, continuar ou verificar qualquer trabalho nao trivial.
argument-hint: [objetivo, ou vazio para continuar de onde parou]
disable-model-invocation: true
allowed-tools: Bash(${CLAUDE_PROJECT_DIR}/tools/*.sh *) Bash(git *)
---

# Fluxo SDLC

Objetivo: **$ARGUMENTS**

Você é o coordenador. Não faz o trabalho — despacha os especialistas, valida o portão e para.

## Passo 1 — Onde estamos

```bash
!`${CLAUDE_PROJECT_DIR}/tools/sdlc-state.sh`
```

Leia a saída acima. Ela é a verdade sobre o estado, não a conversa.

## Passo 2 — Decidir a próxima ação

| Estado | Ação |
|---|---|
| Sem `docs/sdlc/` e **com** objetivo no argumento | Bootstrap → onda 00 |
| Sem `docs/sdlc/` e **sem** objetivo | O trabalho vem de um ticket? Carregue `sdlc-intake`. Senão, pergunte qual é o objetivo — não invente. |
| Onda anterior incompleta | Termine os entregáveis que faltam, com o mesmo dono |
| Onda completa, portão não avaliado | Avalie o portão. Nada avança antes disso. |
| Portão reprovado | Devolva ao agente responsável com o defeito específico |
| Portão aprovado | Execute a próxima onda |
| Tudo pronto até delivery | Reporte e pare |

Anuncie em uma linha o que decidiu e por quê, antes de despachar.

## Passo 3 — Executar a onda

Carregue a skill da fase pelo Skill tool e siga o que ela manda:

| Onda | Skill | Produz em |
|---|---|---|
| 00 bootstrap | `sdlc-bootstrap` | `docs/sdlc/00-orchestration/` |
| 01 discovery | `sdlc-discovery` | `docs/sdlc/01-discovery/` |
| 02 design | `sdlc-design` | `docs/sdlc/02-design/` |
| 03 build | `sdlc-build` | código + `docs/sdlc/03-build/` |
| 04 quality | `sdlc-quality` | `docs/sdlc/04-quality/` |
| 05 delivery | `sdlc-ship` | `docs/sdlc/05-delivery/` |

Cada skill traz os agentes da onda, o que pedir a cada um e o portão dela.

## Passo 4 — Portão

Depois de toda onda, rode a validação estrutural e some a ela o julgamento da skill da fase:

```bash
tools/artifact-lint.sh <fase>
```

Exit 1 significa artefato ausente, incompleto ou só esqueleto — **é reprovação**, não aviso.

## Passo 5 — Reportar e parar

Máximo 10 linhas:

```
Fase: <NN nome>          Portão: APROVADO | BLOQUEADO
Produzido: <arquivos>
Bloqueio: <o que falta exatamente> → <agente>
Próximo: rode /sdlc de novo para seguir
```

**Se o trabalho veio de um ticket** (o plano registra a origem), proponha o comentário de
report-back — formato e regras em `sdlc-intake`. Mostre o texto e espere aprovação: escrever no
tracker é visível para outras pessoas.

Pare aqui. Uma invocação, uma onda. Quem decide avançar é o usuário.

## Regras

1. **Nunca pule uma fase** porque "é simples". Se for realmente trivial, o bootstrap classifica como
   TRIVIAL e o fluxo encolhe sozinho — mas quem decide isso é a classificação, não a pressa.
2. **Nunca marque portão aprovado sem ter lido os artefatos.** Não avaliado ≠ aprovado.
3. **Nunca deixe dois agentes escrevendo o mesmo arquivo** na mesma onda.
4. **Nunca aceite "os testes passam"** sem a saída real. Se o agente não colou, rode você.
5. **Estado vem do disco.** Em sessão nova, `tools/sdlc-state.sh` é a única fonte.
