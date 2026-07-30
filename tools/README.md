# Tools — Scripts de apoio da equipe

Scripts determinísticos que os agentes chamam via Bash. Existem porque reconstruir a mesma
informação a cada execução do modelo é caro, lento e inconsistente — um script devolve o mesmo
resultado sempre, e o agente gasta o raciocínio no julgamento, não na coleta.

Todos são **somente leitura**. Nenhum instala, builda, acessa a rede ou altera arquivo.

## Dois formatos de projeto

Os scripts que dependem de git reconhecem **workspace**: uma raiz que não é repositório mas contém
repositórios — 11 microserviços, 3 frontends e um mobile lado a lado, por exemplo. Nesse caso eles
percorrem os membros em vez de desistir com "não é um repositório git".

A detecção é em runtime, no `_workspace.sh`, e a regra é simples: **se a raiz é um repositório git,
não é workspace** — e todo script cai no caminho de sempre. É assim que o comportamento anterior
fica intacto sem flag nenhuma.

`_workspace.sh` é helper carregado com `source`, não um tool que agente chama; por isso o prefixo
`_`. O instalador valida a sintaxe dele junto com os outros, mas não o conta como tool.

Um repositório dentro de outro membro **não** é membro de topo: contaria a mesma mudança duas vezes
e daria ao agente a impressão de dois donos para o mesmo código.

### O limite: layout não é arquitetura

Estes scripts reportam **onde o código está**, nunca **como o sistema é desenhado**. Estar separado
em dezessete repositórios ou junto em um só é história e conveniência de time — não implica
fronteira de serviço, unidade de deploy nem dependência entre módulos.

Do git se tira honestamente **uma** coisa: como o time versiona. Formato de commit, nomenclatura de
branch, branch de integração, se MR é obrigatório. É exatamente o escopo do `git-conventions.sh`, e
tanto ele quanto o `repo-facts.sh` e o toolbelt dizem isso em voz alta na saída, porque o agente que
lê "17 repositórios" tende a concluir "17 serviços com contratos entre si" sem ter aberto um arquivo.

Arquitetura se descobre lendo o código — trabalho do `project-analyst`, não de detecção.

| Script | Devolve | Usado por |
|---|---|---|
| `repo-facts.sh [dir]` | Manifests, versões declaradas, comandos de build/teste, config de qualidade, CI, migrações, estado do git. **Workspace:** abre com o mapa do sistema — membro, stack, atividade e remote | `project-analyst`, qualquer builder antes da primeira linha |
| `diff-scope.sh [base]` | Escopo do diff + áreas de risco (auth, migração, segredos, infra, dependências, entrada externa) e se há teste no diff. **Workspace:** percorre os membros e reporta só os que têm diferença, resolvendo o nome da base em cada um | `code-reviewer`, `security-auditor`, `release-manager` |
| `artifact-lint.sh [fase]` | Verifica se cada artefato do `docs/sdlc/` tem as seções obrigatórias do contrato de saída; detecta artefato que é só o esqueleto do template | `/sdlc-gate`, `/sdlc-status` |
| `sdlc-state.sh [dir]` | Fase atual lida do disco, separando artefato real de esqueleto | `/sdlc`, `/sdlc-status` |
| `incident-evidence.sh [horas]` | O que mudou na janela: commits, arquivos por frequência, áreas de risco tocadas, tags, candidatos a bissecção. **Workspace:** abre com quais membros mudaram, e só detalha esses | `/incident`, `root-cause-analyst` |
| `calibrate.sh [dir]` | Rascunho do `.claude/toolbelt.md`: o que o projeto é e o que a equipe pode fazer nele. Não executa build nem teste — relata o declarado, para `/setup` verificar | `/setup` |
| `preview-env.sh [dir]` | Como subir o projeto num ambiente controlado e o que já está de pé. Não sobe nem derruba nada | `/verify-live` |
| `tracker.sh [dir]` | Qual rastreador de trabalho (Jira, Linear, GitHub, GitLab) o projeto usa e como falar com ele. Sem chamada de rede | `/sdlc-intake` |
| `git-conventions.sh [dir] [n]` | Como o time versiona: formato de commit, prefixo de branch, branch de integração e se MR é o caminho. `--resumo` devolve 4 linhas para o toolbelt | `/setup`, `code-reviewer`, `release-manager` |

## Uso

```bash
tools/repo-facts.sh                    # repositório atual
tools/repo-facts.sh caminho/do/modulo  # subdiretório específico

tools/diff-scope.sh                    # diff contra main
tools/diff-scope.sh develop            # diff contra outra base

tools/artifact-lint.sh                 # todas as fases
tools/artifact-lint.sh 02              # só design
```

`artifact-lint.sh` sai com código 1 quando encontra artefato ausente, incompleto ou vazio — é o
que permite usá-lo como portão real em `/sdlc-gate`, e não como sugestão.

## Por que separar de MCP

MCP resolve acesso a **sistemas externos** (GitLab, Figma, VPS, documentação). Estes scripts
resolvem **fatos locais do repositório**. Um agente sem nenhum servidor MCP configurado continua
tendo os oito — é o piso de capacidade da equipe, não um extra.

## Como as skills os alcançam

Skills referenciam estes scripts por `${CLAUDE_PROJECT_DIR}/.claude/ai-toolkit/tools/…`. A âncora
`.claude/ai-toolkit` aponta para a raiz deste repositório e é criada pelo `install.sh` aqui e pelo
`workspace/go` em cada projeto alvo — um caminho só, que resolve nos dois lugares. Chamados
direto do shell, os caminhos relativos acima continuam valendo.
