# workspace — onde os projetos ficam cadastrados

Este repositório é a **oficina**: agentes, skills, hooks e tools. Nenhum trabalho
de produto acontece aqui dentro. O `workspace/` é a ponte — você cadastra os
projetos em que trabalha e abre a sessão da equipe dentro deles, sem decorar
caminho nem refazer fiação.

```bash
./workspace/go add ~/Documents/person/desenv-conjunt/crm
./workspace/go                    # o que está cadastrado e em que estado
./workspace/go crm                # fia se preciso e abre o claude LÁ
```

## Dois formatos de projeto

`go` reconhece dois, e detecta qual é sozinho — não há flag para decorar.

| Tipo | O que é | Onde os artefatos nascem |
|---|---|---|
| **repo** | um repositório git | `docs/sdlc/` na raiz dele |
| **workspace** | uma raiz **sem** git, com repositórios embaixo | `docs/sdlc/` na raiz do workspace |

O workspace existe porque alguns projetos são trabalhados como um conjunto. Cadastrar cada repo em
separado funciona, mas obriga a abrir uma sessão por repositório — e o trabalho que atravessa vários
deles fica sem lugar onde morar.

Os artefatos do ciclo ficam na **raiz** do workspace, ao lado dos repositórios que descrevem. Código
e teste continuam em cada membro, versionados no repositório dele.

O que muda na prática, com o workspace aberto:

- **o toolbelt** injeta a lista de repositórios com a stack de cada um, e reporta os remotes
  **reais** em vez de "sem remote git — trabalho é local"
- **`repo-facts.sh`** abre com o inventário: repositório, stack, atividade, remote
- **`incident-evidence.sh`** abre com *quais* repositórios mudaram na janela, e só detalha esses —
  é a pergunta que estreita o incidente de 17 candidatos para dois
- **`diff-scope.sh`** percorre os repositórios e reporta só os que têm diferença
- **`git-conventions.sh`** mostra formato de commit, prefixo de branch e branch de integração,
  e onde eles divergem entre repositórios

### Layout não é arquitetura

Nenhum desses scripts conclui desenho de sistema a partir de onde o código está guardado. Estar em
dezessete repositórios ou em um só é história e conveniência de time — não implica fronteira de
serviço, unidade de deploy nem dependência entre módulos.

Do git se tira honestamente **uma** coisa: como o time versiona. O resto — quem chama quem, por qual
contrato — se descobre lendo o código, e é trabalho do `project-analyst`. O toolbelt e o
`repo-facts.sh` dizem isso explicitamente na saída, porque um agente que lê "17 repositórios" tende
a concluir "17 serviços" sem ter aberto um arquivo.

A detecção é em runtime e a regra é uma só: **raiz que é repositório git nunca é workspace.** Todo
projeto de repo único segue exatamente pelo caminho de antes.

Um repositório dentro de outro membro não vira membro de topo — contaria a mesma mudança duas vezes.

### Raiz sem git e sem repositórios

O terceiro caso: uma pasta com módulos, mas sem git em lugar nenhum. `go` cadastra e **avisa**,
porque os artefatos não ficarão versionados e os dois scripts acima não terão o que ler. O conserto
é um `git init` na raiz.

## Por que a sessão abre no projeto, e não aqui

O primeiro mecanismo do fluxo é o **contrato de artefato**: cada agente escreve
num caminho fixo em `docs/sdlc/`, e a saída de um é a entrada do próximo. Esse
caminho é relativo ao diretório onde o `claude` foi aberto.

Abrir a sessão aqui e "apontar" para o projeto — via `--add-dir`, por exemplo —
faria o PRD, os ADRs e o ledger nascerem dentro do `ai`, longe do código que
descrevem. O git seria o errado, os hooks guardariam o repositório errado, e o
`/sdlc-status` da próxima sessão leria o disco errado.

Então `go` faz o oposto: **leva o toolkit até o projeto** e abre a sessão lá.
Aqui fica só o cadastro.

## O que `go <nome>` faz antes de abrir

Idempotente — rodar de novo não duplica nada, e a saída diz o que mudou.

| Passo | O que faz | Por que |
|---|---|---|
| **âncora** | `<projeto>/.claude/ai-toolkit` → este repo | Skills e hooks referenciam `${CLAUDE_PROJECT_DIR}/.claude/ai-toolkit/...`. Um caminho só, que resolve aqui e lá |
| **hooks** | copia ou mescla `workflow/settings.hooks.json` no `.claude/settings.json` do alvo | Sem eles as fronteiras de agente não existem no projeto |
| **equipe** | `agents/install.sh --user` se ainda não estiver | Agentes em escopo de projeto não enxergam outro projeto |
| **jq** | avisa se faltar | Sem `jq` os hooks falham em modo aberto: não bloqueiam nada |

Se o `.claude/settings.json` do alvo já define `hooks` **diferentes**, `go` não
sobrescreve — avisa e deixa a mesclagem para você. Projeto alheio não é lugar de
sobrescrita silenciosa.

## A âncora `.claude/ai-toolkit`

A alternativa óbvia seria ligar `<projeto>/tools` → `<ai>/tools`, que não exigiria
mudar skill nenhuma. Foi descartada: `tools/` é nome comum na raiz de projeto e a
colisão seria silenciosa. `.claude/` já pertence ao Claude Code — lá não há com o
que colidir.

Este repositório também tem a sua, criada pelo `install.sh`, para que o mesmo
texto de skill funcione nos dois lugares.

## Primeira vez num projeto

`go` avisa quando não existe `.claude/toolbelt.md` no alvo. É o sinal de que a
equipe ainda não foi calibrada ali:

```
/setup
```

Instalar liga os arquivos; calibrar é o que faz a equipe acertar. Sem isso os 27
agentes chegam sabendo o método e **nada** sobre aquele projeto — e método sem
contexto produz o palpite plausível: o comando de teste errado, a convenção
ignorada, o "a suíte passa" quando não existe suíte.

## Começar já num fluxo

Tudo depois do nome vai direto para o `claude`:

```bash
./workspace/go crm "/sdlc-status"
./workspace/go crm "/sdlc 'permitir pausar assinatura'"
./workspace/go crm "/incident 'checkout 500 desde as 14h'"
```

## Comandos

| Comando | Para |
|---|---|
| `./workspace/go` | Listar cadastro, fiação e estado do fluxo de cada projeto |
| `./workspace/go add <caminho> [nome]` | Cadastrar |
| `./workspace/go <nome> [args...]` | Fiar e abrir a sessão lá |
| `./workspace/go wire <nome>` | Só fiar |
| `./workspace/go check <nome>` | Diagnóstico de um projeto |
| `./workspace/go rm <nome>` | Descadastrar (não toca no projeto) |

## O cadastro não é versionado

`workspace/projects/*.md` guarda caminhos absolutos desta máquina — o mesmo
motivo pelo qual `.claude/agents/` já é ignorado. Só o `_template.md` vai para o
git.

Se você quiser o cadastro sincronizado entre máquinas, use caminhos com `~` (o
`go` expande) e tire a linha do `.gitignore`. Aí os projetos precisam viver no
mesmo lugar relativo ao `$HOME` em toda máquina.
