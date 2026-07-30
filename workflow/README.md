# Workflow — Hooks

Camada de imposição do fluxo. Os **procedimentos** viraram skills (`skills/`); aqui ficam só as
regras que o sistema aplica sozinho, sem depender de o modelo obedecer.

> A pasta `workflow/commands/` não existe mais. A documentação oficial fundiu commands em skills
> e recomenda skills, porque só elas aceitam arquivos de apoio — que é onde os templates de PRD e
> ADR e os critérios dos portões passaram a morar. Ver [`skills/README.md`](../skills/README.md).

---

## Os três hooks

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

### `sdlc-context.sh` — SessionStart

Injeta o estado do fluxo no início da sessão: artefatos por fase, se há plano, últimos registros.
Silencioso quando o projeto não tem `docs/sdlc/`.

---

## Configuração em dois níveis

| Arquivo | Escopo | Versionar |
|---|---|---|
| `.claude/settings.json` | Time — os três hooks acima | sim |
| `.claude/settings.local.json` | Pessoal — seus hooks e permissões | não (gitignored) |

O instalador cria `settings.json` se não existir. Se existir com `hooks` **diferente** do
esperado, ele **não altera nada** e pede a mesclagem manual — configuração alheia não é
sobrescrita em silêncio. Se for idêntico, avisa que já está atualizado. O `workspace/go` aplica a
mesma regra ao fiar um projeto alvo.

## Como os hooks alcançam este repositório

`settings.json` aponta para `${CLAUDE_PROJECT_DIR}/.claude/ai-toolkit/workflow/hooks/…`. A âncora
`.claude/ai-toolkit` é um link para a raiz deste repositório, criado pelo `install.sh` aqui e pelo
`workspace/go` em cada projeto alvo.

Os três scripts são **portáveis por construção**: cada um resolve o projeto por
`${CLAUDE_PROJECT_DIR}` (ou o `cwd` da entrada) em vez do próprio caminho. Por isso um hook que
mora aqui guarda corretamente uma sessão rodando em outro repositório — o ledger e o
`guard.tsv` nascem no projeto alvo, não neste.

## Dependência: `jq`

Os três precisam de `jq`. Sem ele **falham em modo aberto** — não bloqueiam e não registram, mas
também não travam a sessão. `sudo apt install jq`.

## O limite conhecido: ferramenta MCP de escrita passa por fora

O `guard-artifacts.sh` é registrado com o matcher `Write|Edit|NotebookEdit` e lê
`.tool_input.file_path`. Um servidor MCP que ofereça edição — `replace_symbol_body`,
`insert_after_symbol`, `execute_shell_command` e afins — **não casa esse matcher**, então o hook
nem chega a rodar. E se rodasse, o esquema de entrada dessas ferramentas não tem `file_path`: o
hook cairia no `[ -z "$path" ] && exit 0` e permitiria.

Consequência concreta: com um servidor desses habilitado, o `solution-architect` e o
`security-auditor` ganham um caminho para alterar código de produção, **sem linha no
`guard.tsv`** — a fronteira continua escrita, e deixa de ser imposta.

Isso não é motivo para não usar MCP. É motivo para habilitar com cuidado:

1. **Prefira servidor somente-leitura.** Um servidor de documentação ou de busca por símbolo não
   tem essa superfície. É o caso do Context7 e de um servidor de grafo de código em modo leitura.
2. **Servidor que edita, configure em modo somente-leitura** na configuração dele próprio, e
   exclua explicitamente a ferramenta de execução de shell.
3. **Precisando mesmo da escrita**, estenda o matcher em `settings.json` para incluir o nome das
   ferramentas MCP de escrita, e ensine o `guard-artifacts.sh` a ler o campo de caminho que
   aquele servidor usa — o nome do campo varia por servidor, não existe um genérico.

O `/setup` pergunta antes de habilitar qualquer servidor, e este aviso é o que ele referencia.

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
