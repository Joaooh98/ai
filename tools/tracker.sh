#!/usr/bin/env bash
# Descobre qual rastreador de trabalho (Jira, Linear, GitHub, GitLab) este projeto
# usa e como falar com ele. Não faz chamada de rede — só relata o que está
# disponível, para a skill sdlc-intake decidir.
#
#   tools/tracker.sh [diretorio]

set -uo pipefail
P="${1:-${CLAUDE_PROJECT_DIR:-$(pwd)}}"
cd "$P" 2>/dev/null || exit 0

has() { command -v "$1" >/dev/null 2>&1; }

echo "### Rastreador de trabalho"
echo

# ------------------------------------------- declarado pelo projeto (vence)
if [ -f .claude/toolbelt.md ] && grep -qiE 'jira|linear|tracker|board|projeto no' .claude/toolbelt.md 2>/dev/null; then
  echo "**Declarado em .claude/toolbelt.md** (tem precedência):"
  grep -iE 'jira|linear|tracker|board|projeto no' .claude/toolbelt.md | sed 's/^/  /'
  echo
fi

# ------------------------------------------------------------------- CLIs
echo "**Via CLI**"
cli=0
if has gh; then
  echo "  gh issue list --assignee @me --state open      # issues atribuídas a você"
  echo "  gh issue view <n>                              # ler uma"
  echo "  gh issue comment <n> --body '...'              # comentar"
  cli=1
fi
if has glab; then
  echo "  glab issue list --assignee=@me --hostname <host>"
  echo "  glab issue view <n> --hostname <host>"
  echo "  glab issue note <n> --hostname <host>          # comentar"
  cli=1
fi
if has jira; then
  echo "  jira issue list -a\$(jira me) -s'To Do'          # jira-cli, se configurado"
  cli=1
fi
[ "$cli" -eq 0 ] && echo "  nenhum CLI de tracker instalado"

# -------------------------------------------------------------- servidores
echo
echo "**Via MCP**"
echo "  Procure na sessão com ToolSearch: 'jira', 'atlassian', 'linear', 'issue'."
echo "  Servidor de rastreamento costuma expor: buscar por JQL/filtro, ler issue,"
echo "  comentar, transicionar status."
echo "  ATENÇÃO: servidor listado mas 'needs authentication' NÃO está utilizável —"
echo "  confirme com \`claude mcp list\` antes de contar com ele."

# ------------------------------------------------------- pistas no repo
echo
echo "**Pistas no repositório**"
pistas=0
if git rev-parse --git-dir >/dev/null 2>&1; then
  # padrão de chave de ticket nas mensagens de commit recentes
  keys="$(git log --oneline -40 2>/dev/null | grep -oE '\b[A-Z][A-Z0-9]+-[0-9]+\b' | sort | uniq -c | sort -rn | head -5)"
  if [ -n "$keys" ]; then
    echo "  chaves de ticket nos commits (prefixo = projeto no tracker):"
    printf '%s\n' "$keys" | sed 's/^/    /'
    pistas=1
  fi
  branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
  case "$branch" in
    *[A-Z][A-Z]*-[0-9]*) echo "  branch atual referencia um ticket: $branch"; pistas=1 ;;
  esac
fi
for f in .github/ISSUE_TEMPLATE .gitlab/issue_templates CONTRIBUTING.md; do
  [ -e "$f" ] && { echo "  template/processo: $f"; pistas=1; }
done
[ "$pistas" -eq 0 ] && echo "  nenhuma — pergunte ao usuário qual tracker e qual projeto"

echo
echo "NOTA: leitura é livre. Comentar, transicionar status ou fechar ticket são ações"
echo "que outras pessoas veem — exigem aprovação explícita do usuário."
exit 0
