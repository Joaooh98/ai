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
sobrescrita em silêncio. Se for idêntico, avisa que já está atualizado.

## Dependência: `jq`

Os três precisam de `jq`. Sem ele **falham em modo aberto** — não bloqueiam e não registram, mas
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

`./agents/install.sh --check` roda `bash -n` em cada hook antes de instalar.

Referência: [Hooks](https://code.claude.com/docs/en/hooks) · [Skills](https://code.claude.com/docs/en/skills)
