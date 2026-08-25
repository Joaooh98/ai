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
| `meta-check.sh` | Confere as metas de qualidade declaradas em `.claude/meta.tsv` contra os relatórios que a rodada real produziu. Exit 1 em meta blocker fora, não verificável ou desatualizada | `/sdlc-gate` (portões 3 e 4), `/setup` |
| `sdlc-state.sh [dir]` | Fase atual lida do disco, separando artefato real de esqueleto | `/sdlc`, `/sdlc-status` |
| `incident-evidence.sh [horas]` | O que mudou na janela: commits, arquivos por frequência, áreas de risco tocadas, tags, candidatos a bissecção. **Workspace:** abre com quais membros mudaram, e só detalha esses | `/incident`, `root-cause-analyst` |
| `calibrate.sh [dir]` | Rascunho do `.claude/toolbelt.md`: o que o projeto é e o que a equipe pode fazer nele. Não executa build nem teste — relata o declarado, para `/setup` verificar | `/setup` |
| `preview-env.sh [dir]` | Como subir o projeto num ambiente controlado e o que já está de pé. Não sobe nem derruba nada | `/verify-live` |
| `tracker.sh [dir]` | Qual rastreador de trabalho (Jira, Linear, GitHub, GitLab) o projeto usa e como falar com ele. Sem chamada de rede | `/sdlc-intake` |
| `git-conventions.sh [dir] [n]` | Como o time versiona: formato de commit, prefixo de branch, branch de integração e se MR é o caminho. `--resumo` devolve 4 linhas para o toolbelt | `/setup`, `code-reviewer`, `release-manager` |
| `docs-lint.sh [raiz]` | Confere a documentação **deste** repositório contra ele mesmo: link quebrado, caminho citado que não existe, contagem declarada que não bate, pasta sem README, agente/skill/tool sem menção, arquivo órfão. Exit 1 em divergência | manutenção do próprio toolkit |

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

## Meta: o número que o portão pede e nunca tinha

Os portões 3 e 4 sempre pediram número — *"orçamentos de performance atendidos"*, *"critérios de
rollback numéricos"*. Sem nada declarado, esses itens caíam no julgamento e passavam sempre.
`.claude/meta.tsv` é onde o time declara o número, uma vez, no `/setup`; `meta-check.sh` só
confere.

```bash
tools/meta-check.sh                                    # relatório completo
tools/meta-check.sh --resumo                           # 3 linhas, para injeção em skill
tools/meta-check.sh --baseline > .claude/meta-baseline.tsv   # congela a catraca
tools/meta-check.sh --meta <arquivo>                   # outro arquivo de metas
tools/meta-check.sh --dir <raiz>                       # outra raiz de projeto
```

Três decisões de desenho sustentam isso:

**Ele lê relatório, nunca executa build ou teste.** Preserva a invariante desta pasta e, mais
importante, garante que o número veio da execução de verdade — não de um agente afirmando que
rodou. Relatório ausente, ou mais **velho** que o código, é **não verificável**, e não verificável
bloqueia igual a meta descumprida.

**Catraca para projeto que já existe.** `nao-cai` e `nao-sobe` comparam contra um baseline
congelado em vez de um alvo absoluto: não bloqueiam a dívida que já estava lá, só impedem
piorar. Mesma assimetria que permite exigir a meta à risca sem parar a entrega. Quando a métrica
melhora, o relatório avisa — apertar a catraca é decisão explícita, não efeito de uma medição
que oscilou.

**Extratores são lista fechada.** `jacoco-line`, `lcov-line`, `json:`, `regex:`, `count:`. Um
campo que aceitasse comando arbitrário faria do arquivo de metas um vetor de execução, e ele é
editável por agente. Extrator novo se adiciona ao script, com revisão.

O campo `fonte` aceita glob, porque review é um arquivo por item de trabalho. Glob que não casa
nada é **não verificável**, nunca zero: "ninguém escreveu o review" não pode passar como "review
sem blocker".

### Todo bloqueio sai com a ação que o resolve

Exit 1 tem quatro causas com donos diferentes, e a saída separa as quatro com uma linha `AÇÃO:`:

| Seção | É | Ação |
|---|---|---|
| `FORA DA META` | defeito de qualidade real | devolver ao agente dono da métrica |
| `SEM FERRAMENTA` | lacuna de calibração | instalar a ferramenta e rodar `/setup` — não mexer no código |
| `NÃO VERIFICÁVEL` | a suíte não rodou nesta onda | gerar o relatório e reavaliar |
| `DESATUALIZADA` | mediu antes da última mudança | rodar a suíte de novo |

A distinção existe porque um fluxo automatizado que recebe só "exit 1" devolve tudo ao mesmo
agente — inclusive `jq` não instalado, que nenhum agente de build conserta. Quando o bloqueio é
**só** de medição, o script afirma isso explicitamente: ninguém tem defeito para corrigir, a ação
é medir.

## Por que separar de MCP

MCP resolve acesso a **sistemas externos** (GitLab, Figma, VPS, documentação). Estes scripts
resolvem **fatos locais do repositório**. Um agente sem nenhum servidor MCP configurado continua
tendo os onze — é o piso de capacidade da equipe, não um extra.

## Como as skills os alcançam

Skills referenciam estes scripts por `${CLAUDE_PROJECT_DIR}/.claude/ai-toolkit/tools/…`. A âncora
`.claude/ai-toolkit` aponta para **`.toolkit/`** deste repositório e é criada pelo `install.sh`
aqui e pelo `workspace/go` em cada projeto alvo — um caminho só, que resolve nos dois lugares.
Chamados direto do shell, os caminhos relativos acima continuam valendo.

`.toolkit/` é uma pasta de symlinks (`tools`, `workflow`, `skills`, `mcp`) que existe por um
motivo só: a âncora **não pode** apontar para a raiz do repositório, porque a raiz contém um
`.claude/` que contém a própria âncora — e isso aninha `.claude` dentro de `.claude` sem fim.
Medido antes da correção: `find -L .claude -name SKILL.md` devolvia 85 resultados num
repositório que na época tinha 16 skills — cinco voltas do mesmo arquivo.
