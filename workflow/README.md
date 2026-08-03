# Workflow — Hooks

Camada de imposição do fluxo. Os **procedimentos** viraram skills (`skills/`); aqui ficam só as
regras que o sistema aplica sozinho, sem depender de o modelo obedecer.

> A pasta `workflow/commands/` não existe mais. A documentação oficial fundiu commands em skills
> e recomenda skills, porque só elas aceitam arquivos de apoio — que é onde os templates de PRD e
> ADR e os critérios dos portões passaram a morar. Ver [`skills/README.md`](../skills/README.md).

---

## Os quatro hooks

### `guard-artifacts.sh` — PreToolUse (Write, Edit, NotebookEdit)

**O problema:** o frontmatter é binário — ou o agente tem `Write`, ou não tem. E restringir via
`tools:` custa caro: allowlist remove **todas** as ferramentas MCP do subagente. Então os agentes
recebem capacidade ampla, e a fronteira precisa vir de outro lugar.

**A solução:** lê `agent_type` da entrada e nega a escrita por caminho.

| Agentes | Só podem escrever em |
|---|---|
| `context-manager` · `tech-lead-orchestrator` · `project-analyst` | `docs/sdlc/00-orchestration/` |
| `product-owner` · `business-analyst` · `ux-researcher` | `docs/sdlc/01-discovery/` |
| `solution-architect` · `api-designer` · `data-architect` · `ux-ui-designer` · `threat-modeler` | `docs/sdlc/02-design/` |
| `code-reviewer` · `security-auditor` | `docs/sdlc/04-quality/` |
| `incident-commander` | `docs/incidents/` |
| `root-cause-analyst` | `docs/incidents/` ou `docs/sdlc/04-quality/` |

As duas últimas linhas são o que impõe a separação entre comando e execução no incidente: o
comandante decide e registra a linha do tempo, mas é **bloqueado** se tentar corrigir o sistema.

`MANIFEST.md` tem **um único escritor**: o `context-manager`.

Quem não aparece na tabela não é restringido — builders, `test-engineer`, `devops-engineer`,
`sre-observability`, `performance-engineer`, `release-manager` e `tech-writer` alteram o sistema
de verdade. Para eles o limite é a seção `Boundaries` do agente.

**Toda negação é registrada** em `.claude/logs/guard.tsv` com carimbo de tempo, agente, caminho e
motivo. Fronteira que ninguém consegue medir é fronteira que alguém desliga por incomodar.

### `register-artifact.sh` — PostToolUse (Write, Edit)

Toda escrita sob `docs/sdlc/` vira linha em `docs/sdlc/00-orchestration/artifact-ledger.tsv`,
deduplicada por (agente, caminho). É a evidência bruta de quem produziu o quê; o `MANIFEST.md` é
a versão curada. Divergiram? O ledger está certo. Nunca bloqueia.

### `guard-publish.sh` — PreToolUse (Bash)

**O problema:** o repositório é para **código desenvolvido**. Plano, PRD, ADR, modelo de ameaças,
MANIFEST, ledger e registro de incidente são material de trabalho — ficam no disco, ao lado do
código, e não são publicados. Só que "não commite os artefatos" é exatamente o tipo de regra que
sobrevive à primeira sessão e morre na quinta: o agente que acabou de escrever um plano tem todo
incentivo para versioná-lo, e um `git add -A` leva o diretório inteiro junto sem ninguém decidir.

**A solução:** lê o comando do `Bash` e nega quando ele publicaria `docs/sdlc/` ou `docs/incidents/`.

| Comando | Decisão |
|---|---|
| `git add .` · `git add -A` · `git add docs` com artefato pendente | **nega** |
| `git add src/Foo.java` com artefato pendente ao lado | permite |
| `git commit` com artefato no índice | **nega** |
| `git commit -am` arrastando artefato já versionado | **nega** |
| `git commit --amend` · `git commit -m` sem artefato no índice | permite |
| `git push` com commit inédito que toca artefato | **nega** |
| `git status`, `git diff`, qualquer comando não-git | permite |

Metade da tabela é sobre o que **passa**. Guarda que dá falso positivo é guarda que alguém desliga
no primeiro dia ruim — por isso `git add` só é barrado na forma abrangente, e `--amend` não é
confundido com `-a`.

A mensagem de negação diz o que fazer: tirar do índice, pôr no `.gitignore`, desfazer o commit, ou
abrir exceção. **Exceção por projeto:** crie `<projeto>/.claude/allow-planning-in-repo`.

Teste: `bash workflow/tests/guard-publish.test.sh` — monta repositórios descartáveis e verifica cada
decisão da tabela, inclusive os casos que devem passar.

### `sdlc-context.sh` — SessionStart

Injeta o estado do fluxo no início da sessão: artefatos por fase, se há plano, últimos registros.
Silencioso quando o projeto não tem `docs/sdlc/`.

---

## Configuração em dois níveis

| Arquivo | Escopo | Versionar |
|---|---|---|
| `.claude/settings.json` | Time — os quatro hooks acima | sim |
| `.claude/settings.local.json` | Pessoal — seus hooks e permissões | não (gitignored) |

Quem sincroniza é `workflow/hooks-sync.sh`, chamado tanto por `agents/install.sh` quanto por
`workspace/go`. Um lugar só, para as duas fiações não divergirem.

| Estado do `settings.json` do alvo | O que acontece |
|---|---|
| não existe | snippet copiado inteiro |
| `hooks` idêntico ao snippet | nada |
| sem bloco `hooks` | snippet acrescentado, resto preservado |
| `hooks` diferente, mas **todo comando aponta para `ai-toolkit/workflow/hooks/`** | substituído pelo snippet |
| `hooks` diferente com **algum comando de fora** do toolkit | **nada é tocado**, avisa e pede mesclagem manual |

A quarta linha é o que faz um hook novo chegar aos projetos já fiados. Sem ela, "diferente do
esperado" trata **desatualizado** e **customizado** como o mesmo caso — e só um dos dois é seguro
de substituir. O resultado era um toolkit que nunca conseguia entregar um hook novo a lugar
nenhum: todo projeto congelava na versão do dia em que foi fiado.

A quinta linha continua valendo: configuração alheia não é sobrescrita em silêncio.

## Como os hooks alcançam este repositório

`settings.json` aponta para `${CLAUDE_PROJECT_DIR}/.claude/ai-toolkit/workflow/hooks/…`. A âncora
`.claude/ai-toolkit` é um link para a raiz deste repositório, criado pelo `install.sh` aqui e pelo
`workspace/go` em cada projeto alvo.

Os quatro scripts são **portáveis por construção**: cada um resolve o projeto por
`${CLAUDE_PROJECT_DIR}` (ou o `cwd` da entrada) em vez do próprio caminho. Por isso um hook que
mora aqui guarda corretamente uma sessão rodando em outro repositório — o ledger e o
`guard.tsv` nascem no projeto alvo, não neste.

## Dependência: `jq`

Os quatro precisam de `jq`. Sem ele **falham em modo aberto** — não bloqueiam e não registram, mas
também não travam a sessão. `sudo apt install jq`.

## Testando

Hooks são scripts; teste sem subir sessão:

```bash
# deve NEGAR
echo '{"agent_type":"code-reviewer","tool_input":{"file_path":"/proj/src/Foo.java"}}' \
  | bash workflow/hooks/guard-artifacts.sh

# deve PERMITIR (silêncio, exit 0)
echo '{"agent_type":"code-reviewer","tool_input":{"file_path":"/proj/docs/sdlc/04-quality/r.md"}}' \
  | bash workflow/hooks/guard-artifacts.sh
```

Para conferir a portabilidade — que o hook grava no projeto alvo, e não neste — aponte
`CLAUDE_PROJECT_DIR` para outro diretório e veja onde o arquivo nasce:

```bash
export CLAUDE_PROJECT_DIR=/caminho/do/alvo
echo '{"agent_type":"product-owner","cwd":"'"$CLAUDE_PROJECT_DIR"'","tool_input":{"file_path":"'"$CLAUDE_PROJECT_DIR"'/docs/sdlc/01-discovery/prd.md"}}' \
  | bash workflow/hooks/register-artifact.sh
cat "$CLAUDE_PROJECT_DIR/docs/sdlc/00-orchestration/artifact-ledger.tsv"
```

`./agents/install.sh --check` roda `bash -n` em cada hook antes de instalar.

Referência: [Hooks](https://code.claude.com/docs/en/hooks) · [Skills](https://code.claude.com/docs/en/skills)

## Portão de coerência das skills

`./agents/install.sh --check` valida que **toda injeção `` !`comando` `` casa com algum padrão de
`allowed-tools`** da própria skill. Sem esse portão o defeito só aparece no primeiro uso real, com
a mensagem `Shell command permission check failed` — longe de quem escreveu, e no pior momento.

O caso que motivou o portão: o padrão `.../x.sh *` tem um espaço e um `*` no fim, então **exige
argumento**. Uma chamada `` !`.../sdlc-state.sh` `` sem argumento nenhum não casa, e a skill trava.

Duas formas de evitar, e o repositório usa as duas:

1. passe o diretório explicitamente — `` !`.../sdlc-state.sh "${CLAUDE_PROJECT_DIR}"` `` é mais
   correto de qualquer jeito, porque não depende do diretório corrente;
2. declare os dois formatos — `Bash(.../x.sh) Bash(.../x.sh *)`.
