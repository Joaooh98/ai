---
name: sdlc-intake
description: Puxa trabalho do rastreador (Jira, Linear, GitHub, GitLab), escolhe a tarefa, traduz o ticket em objetivo com criterios de aceite e entrega ao fluxo. Tambem define como o status volta para o ticket. Use quando o trabalho comeca por um ticket, nao por voce digitando o objetivo.
argument-hint: [chave do ticket, ou vazio para listar os de hoje]
disable-model-invocation: true
allowed-tools: Bash(${CLAUDE_PROJECT_DIR}/.claude/ai-toolkit/tools/tracker.sh) Bash(${CLAUDE_PROJECT_DIR}/.claude/ai-toolkit/tools/tracker.sh *) Bash(gh issue*) Bash(glab issue*) Bash(git *)
---

# Entrada de trabalho pelo rastreador

Alvo: **$ARGUMENTS** (vazio = listar o que está atribuído a você)

O `/sdlc` começa com você digitando um objetivo. Trabalho real raramente nasce assim — nasce num
ticket, com contexto, critérios e gente esperando resposta. Esta skill fecha as duas pontas:
**puxar** o trabalho de lá e **devolver** o status para lá.

## Ferramental detectado

!`${CLAUDE_PROJECT_DIR}/.claude/ai-toolkit/tools/tracker.sh "${CLAUDE_PROJECT_DIR}"`

---

## Passo 1 — Buscar

Use o que a detecção acima encontrou, nesta ordem: o que o projeto declarou em
`.claude/toolbelt.md` → servidor MCP de rastreamento → CLI.

Sem ticket informado, liste o que está **atribuído a você e aberto**, e mostre:

```
| chave | título | status | prioridade | atualizado |
```

Nada atribuído? Diga isso — não invente trabalho nem pegue ticket de outra pessoa.

**Servidor que aparece como "needs authentication" não está utilizável.** Confirme com
`claude mcp list` antes de contar com ele; se falhar, caia para o CLI ou peça ao usuário.

## Passo 2 — Escolher, com o usuário

Mais de um candidato: **pergunte qual**. Não escolha por prioridade sozinho — quem sabe o que é
urgente hoje é o usuário, e começar a tarefa errada custa mais que a pergunta.

Um só candidato óbvio: proponha e confirme em uma linha antes de seguir.

## Passo 3 — Ler o ticket inteiro

Ticket não é só o título. Colete:

| O quê | Por quê |
|---|---|
| Descrição completa | O pedido de verdade |
| **Comentários** | É onde o escopo muda, e quase ninguém atualiza a descrição |
| Critérios de aceite, se houver | Podem virar o PRD direto |
| Anexos e links | Design, log de erro, documento de requisito |
| Tickets relacionados / bloqueadores | Dependência que impede começar |
| Histórico de status | Já foi tentado e devolvido? Por quê? |

## Passo 4 — Traduzir para objetivo

O ticket é a entrada; o fluxo precisa de um **objetivo com critérios verificáveis**. Traduza:

```
Objetivo:        <uma frase, no vocabulário do produto>
Origem:          <chave do ticket> — <url>
Tipo:            feature | bug | débito técnico | incidente
Critérios já no ticket: <copiados na íntegra, se existirem>
Lacunas:         <o que o ticket NÃO diz e o fluxo vai precisar>
Fora de escopo:  <o que o ticket cita mas não é para fazer agora>
```

**Lacuna é a parte que importa.** Ticket quase nunca tem caminho de erro, estado vazio ou
critério de fronteira. Não invente: registre como pergunta em aberto para o `product-owner`
resolver na descoberta, ou pergunte ao usuário agora se for bloqueante.

## Passo 5 — Rotear

| Tipo do ticket | Para onde |
|---|---|
| Bug em produção com impacto | **`/incident`** — não passe pelo fluxo planejado |
| Bug sem urgência | `root-cause-analyst` primeiro, `/sdlc` depois da causa confirmada |
| Feature ou mudança | `/sdlc` com o objetivo traduzido |
| Dúvida ou investigação | Responda direto; não abra ciclo |

Registre a origem em `docs/sdlc/00-orchestration/plan.md` — todo artefato precisa ser rastreável
até o ticket que o originou.

---

## Report-back: devolver status ao ticket

Trabalho que não volta para o ticket obriga alguém a perguntar "como está?". Ao fim de cada onda,
proponha ao usuário:

| Momento | O que postar |
|---|---|
| Início | Status → *em andamento*; comentário com o objetivo traduzido e as lacunas encontradas |
| Portão 1 | Critérios de aceite derivados — **especialmente os que o ticket não tinha** |
| Portão 2 | Decisões estruturais e ADRs; link para os artefatos |
| Build | Link do PR/MR |
| Portão 3 | Resultado de review, segurança e testes |
| Portão 4 | Versão, changelog e decisão go/no-go |

**Regra que não se negocia: leitura é livre, escrita exige aprovação.** Comentar, transicionar
status, fechar ticket ou reatribuir são ações que outras pessoas veem e que nem sempre dá para
desfazer. Mostre o texto exato que vai postar e espere o "pode".

Formato do comentário — curto, e sempre com o que **mudou** em relação ao ticket:

```
<onda> concluída.
Produzido: <artefatos, com link>
Decisões: <as que afetam quem lê o ticket>
Mudou em relação ao ticket: <critério novo, escopo cortado, premissa derrubada>
Bloqueios: <o que impede seguir, e de quem depende>
```

A linha **"mudou em relação ao ticket"** é a mais valiosa: é o que o autor do ticket precisa saber
e nunca descobre lendo só o código.

## Limites

- Nunca escreva no tracker sem aprovação explícita, nem que pareça óbvio.
- Nunca feche ticket automaticamente — quem decide que está pronto é uma pessoa.
- Nunca pegue ticket que não está atribuído a você sem confirmar.
- Nunca trate a descrição como completa: os comentários costumam contradizê-la.
