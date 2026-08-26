# Skills — Procedimentos da equipe

Se os agentes são *quem* faz o trabalho, as skills são *como* se faz. Escritas uma vez, usadas por
todos — é o que impede 27 agentes de divergirem sobre a mesma regra.

## Como foram desenhadas

Curadoria a partir da pesquisa do ecossistema:

| Fonte | O que foi incorporado |
|---|---|
| [obra/superpowers](https://github.com/obra/superpowers) | A unidade de reuso é o **procedimento**, não o papel: TDD, verificação, review viram skills próprias e compõem entre si |
| [Docs oficiais](https://code.claude.com/docs/en/skills) | SKILL.md < 500 linhas · arquivos de apoio · disclosure em 3 níveis |
| [wshobson/commands](https://github.com/wshobson/commands) | Separar **orquestração** de **utilitário** |
| [qdhenry/Claude-Command-Suite](https://github.com/qdhenry/Claude-Command-Suite) | Prefixo consistente para navegabilidade |
| [travisvn/awesome-claude-skills](https://github.com/travisvn/awesome-claude-skills) | Skill boa = procedimento reusável, com exemplos, testada |

## Estrutura

As 21 skills:

```
skills/
├── sdlc/                    /sdlc — entrada única do fluxo
├── sdlc-bootstrap/          onda 00 — estrutura, perfil, plano
├── sdlc-discovery/          onda 01  + templates/prd.md
├── sdlc-design/             onda 02  + templates/adr.md
├── sdlc-build/              onda 03
├── sdlc-quality/            onda 04
├── sdlc-ship/               onda 05
├── sdlc-gate/               /sdlc-gate + gates.md (critérios dos 4 portões)
├── sdlc-status/             /sdlc-status
├── sdlc-intake/             /sdlc-intake — puxa a tarefa do tracker e devolve status
├── incident/                /incident — modo emergência + severity.md + templates/postmortem.md
├── verify-live/             /verify-live — sobe num ambiente controlado e verifica de verdade
├── nightly/                 /nightly — trabalho recorrente + routines/ (6 rotinas executáveis)
├── setup/                   /setup — calibra a equipe para o projeto que a recebeu
├── workspace/               /workspace — listar, conferir, fiar e cadastrar projeto
│                            de dentro da sessão (o `workspace/go` segue sendo o
│                            script do operador, no terminal)
├── practices/
│   ├── engineering-discipline/   disciplina compartilhada — todos os 27 agentes
│   └── mcp-toolbelt/             ferramental detectado por projeto — 26 dos 27 agentes
│                                 (o context-manager não a carrega: não fala com sistema externo)
└── stack/
    ├── nextjs-developer/         App Router, server components, server actions
    ├── react-expert/             React 18+, hooks, Suspense, migração de classe
    ├── react-native-expert/      Expo, navegação, FlatList, código por plataforma
    └── typescript-pro/           tipos avançados, type guards, tRPC ponta a ponta
```

As quatro de `stack/` são de natureza diferente das outras dezesseis. As de fluxo (`sdlc-*`,
`incident`, `setup`) descrevem **como a equipe trabalha** e valem em qualquer projeto; as de
`stack/` carregam **conhecimento de uma tecnologia** e só são acionadas quando o projeto usa
aquela stack. Por isso ficam num grupo à parte: misturar as duas na mesma lista faria parecer
que o fluxo depende de React.

## Você só precisa lembrar de um comando

```
/sdlc "cobrança multi-tenant com pausa de assinatura"
```

Ele lê os artefatos em disco, descobre a fase, executa a próxima onda e **para no portão**.
Rodou de novo, avança mais uma. As skills de fase são carregadas por ele — existem, mas não
precisam ser decoradas.

Dois utilitários quando você quiser olhar sem avançar:

```
/sdlc-status      onde o trabalho parou, lido do disco
/sdlc-gate 2      valida um portão item a item, com evidência
```

Antes você tinha que saber a ordem das fases. Agora não: são estes **três** que sustentam o fluxo
planejado, e a ordem é do disco.

> As seis skills de fase (`sdlc-bootstrap`, `sdlc-discovery`, `sdlc-design`, `sdlc-build`,
> `sdlc-quality`, `sdlc-ship`) continuam aparecendo na lista de comandos, porque nenhuma declara
> `user-invocable: false`. Elas funcionam se você digitar — só não é assim que o fluxo foi
> desenhado, já que digitar a fase errada pula o portão. Quem escolhe a onda é o `/sdlc`, lendo os
> artefatos.

## O outro modo: `/incident`

```
/incident "checkout retornando 500 desde as 14h"
```

`/sdlc` e `/incident` são opostos por desenho. No planejado, portão protege qualidade. No
incidente, o relógio corre e portão vira obstáculo — mas velocidade sem método produz o segundo
incidente.

A regra que resolve a tensão:

> **Mitigar ≠ corrigir.** Mitigação é reversível e **não exige** causa raiz — rollback, desligar
> flag, escalar, failover. Correção exige causa raiz **sempre**.

A skill injeta na abertura o resultado de `tools/incident-evidence.sh` (algumas dezenas de ms —
25 ms medidos neste repositório, e cresce com o histórico do git): o que mudou nas últimas 24h,
quais áreas de risco foram tocadas, candidatos a bissecção. A pergunta que resolve a maioria dos
incidentes — "o que mudou?" — já vem respondida antes da primeira interação.

Base: [Google SRE — Managing Incidents](https://sre.google/sre-book/managing-incidents/) para
papéis e critérios de declaração; [obra/superpowers](https://github.com/obra/superpowers)
`systematic-debugging` para as quatro fases de causa raiz.

## Skills de prática

Pré-carregadas nos agentes pelo campo `skills:` do frontmatter — não são invocadas, elas já
estão lá quando o agente começa.

**`engineering-discipline`** (todos os 27) — evidência antes de afirmação, ler antes de escrever,
teste que falha primeiro, nunca enfraquecer o sinal, honestidade sobre limites.

Existe porque a medição mostrou o estrago de escrever a mesma regra em cada agente: "rode antes de
afirmar" aparecia em 6 deles, e "teste que falha primeiro" em 1.

**`mcp-toolbelt`** (26 — fora o `context-manager`, que só registra artefato e não fala com sistema
externo) — roda uma detecção no carregamento e injeta o ferramental real **daquele** projeto:
remotes git, CLIs, servidores MCP, manifests. Ajuste por projeto em `.claude/toolbelt.md`, que tem
precedência.

## Convenções para adicionar uma skill

1. Diretório com `SKILL.md`. O nome do diretório vira o comando e precisa ser único.
2. Frontmatter: `name`, `description` (o que faz **e quando usar**), e conforme o caso
   `argument-hint`, `allowed-tools`, `disable-model-invocation`, `user-invocable`.
3. **Máximo 500 linhas** — o instalador reprova acima disso. Referência longa vai para arquivo de
   apoio ao lado, citado no corpo.
4. `disable-model-invocation: true` para o que tem efeito colateral e você quer controlar o
   momento. `user-invocable: false` para conhecimento de fundo que ninguém digita.
5. Scripts empacotados rodam com `` !`${CLAUDE_SKILL_DIR}/script.sh` `` — a injeção acontece
   **antes** do conteúdo chegar ao agente. Mantenha rápido: isso roda a cada invocação.

Validação: `./agents/install.sh --check` confere frontmatter, nomes duplicados, limite de linhas
e sintaxe dos scripts.
