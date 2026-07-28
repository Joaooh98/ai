#!/usr/bin/env bash
# Detecta o ferramental REAL do projeto atual, para a skill mcp-toolbelt injetar
# no contexto dos agentes. Nada aqui é específico de empresa, host ou stack.
#
# Ordem de precedência:
#   1. .claude/toolbelt.md do projeto  — o que a equipe escreveu, vale acima de tudo
#   2. detecção automática             — remotes, CLIs, servidores MCP configurados
#
# Rápido de propósito: sem chamada de rede, sem health check. Os agentes carregam
# esta saída a cada invocação — segundos aqui viram minutos no fluxo inteiro.
#
#   detect-toolbelt.sh [diretorio-do-projeto]

set -uo pipefail
PROJECT="${1:-${CLAUDE_PROJECT_DIR:-$(pwd)}}"
cd "$PROJECT" 2>/dev/null || cd "$(pwd)"

# ---------------------------------------------------------- override do projeto
OVERRIDE="$PROJECT/.claude/toolbelt.md"
if [ -f "$OVERRIDE" ]; then
  echo "### Ferramental declarado por este projeto (.claude/toolbelt.md)"
  echo
  cat "$OVERRIDE"
  echo
  echo "O que está acima foi escrito pela equipe e tem precedência sobre a detecção abaixo."
  echo
fi

echo "### Detectado automaticamente"
echo

# ------------------------------------------------------------------ git hosting
echo "**Git hosting**"
remotes="$(git remote -v 2>/dev/null | awk '{print $2}' | sort -u)"
if [ -z "$remotes" ]; then
  echo "- sem remote git — trabalho é local"
else
  while IFS= read -r url; do
    [ -z "$url" ] && continue
    host="$(printf '%s' "$url" | sed -E 's#^[a-z]+://##; s#^[^@]+@##; s#[:/].*$##')"
    case "$host" in
      github.com)
        if command -v gh >/dev/null 2>&1; then
          echo "- $host → use \`gh\` (pr list, pr diff, run list, api)"
        else
          echo "- $host → \`gh\` NÃO instalado; use a API via curl ou só git local"
        fi ;;
      *gitlab*|git.*)
        if command -v glab >/dev/null 2>&1; then
          echo "- $host → use \`glab --hostname $host\` (mr list, mr diff, ci list, api)"
        else
          echo "- $host → \`glab\` NÃO instalado; use a API via curl ou só git local"
        fi ;;
      bitbucket.org)
        echo "- $host → sem CLI dedicado detectado; use a API ou git local" ;;
      *)
        echo "- $host → host não reconhecido; use git local e pergunte ao usuário" ;;
    esac
  done <<< "$remotes"
fi

# CLIs presentes e hosts que eles conhecem (leitura de config, sem rede)
for cli in gh glab; do
  command -v "$cli" >/dev/null 2>&1 || continue
  case "$cli" in
    glab)
      cfg="${XDG_CONFIG_HOME:-$HOME/.config}/glab-cli/config.yml"
      if [ -f "$cfg" ]; then
        # Os hosts ficam sob 'hosts:' com indentação arbitrária. Ancora no recuo
        # da primeira entrada e aceita só as irmãs desse nível.
        hosts="$(awk '
          /^hosts:/ { f=1; next }
          f && /^[^[:space:]]/ { f=0 }
          f && /^[[:space:]]+[A-Za-z0-9][A-Za-z0-9._-]*:[[:space:]]*$/ {
            match($0, /^[[:space:]]+/); ind = RLENGTH
            if (base == 0) base = ind
            if (ind == base) { gsub(/[[:space:]:]/, ""); print }
          }' "$cfg" | tr '\n' ' ')"
        [ -n "${hosts// /}" ] && echo "- \`glab\` tem config para: $hosts"
      fi ;;
    gh)
      cfg="${XDG_CONFIG_HOME:-$HOME/.config}/gh/hosts.yml"
      if [ -f "$cfg" ]; then
        hosts="$(awk '/^[^ ]/{gsub(":","");print $1}' "$cfg" | tr '\n' ' ')"
        [ -n "$hosts" ] && echo "- \`gh\` tem config para: $hosts"
      fi ;;
  esac
done
echo "- autenticação NÃO foi verificada aqui (evita chamada de rede). Se um comando"
echo "  falhar com 401/403, reporte em vez de insistir."
echo

# ------------------------------------------------------------------ servidores MCP
echo "**Servidores MCP configurados**"
listed=0
emit_servers() {
  local file="$1" origem="$2" filtro="$3"
  [ -f "$file" ] || return 0
  command -v jq >/dev/null 2>&1 || return 0
  local names
  names="$(jq -r "$filtro" "$file" 2>/dev/null | tr '\n' ' ')"
  if [ -n "${names// /}" ]; then
    echo "- $origem: $names"
    listed=1
  fi
}
emit_servers "$PROJECT/.mcp.json" "projeto (.mcp.json)" '(.mcpServers // {}) | keys[]'
emit_servers "$HOME/.claude.json" "usuário" '(.mcpServers // {}) | keys[]'
[ "$listed" -eq 0 ] && echo "- nenhum servidor MCP em arquivo de configuração"
echo "- conectores da conta e plugins não aparecem aqui — descubra com \`ToolSearch\`."
echo "- estar configurado ≠ estar conectado. Confirme com \`claude mcp list\` quando o"
echo "  resultado importar, e siga sem o servidor se ele falhar."
echo

# ------------------------------------------------------------------ stack local
echo "**Sinais do projeto**"
found=0
for m in package.json pom.xml build.gradle requirements.txt pyproject.toml go.mod Cargo.toml \
         composer.json Gemfile pubspec.yaml; do
  [ -f "$m" ] && { echo "- manifest: $m"; found=1; }
done
for c in .gitlab-ci.yml Jenkinsfile docker-compose.yml compose.yaml Dockerfile vercel.json; do
  [ -f "$c" ] && echo "- entrega: $c"
done
[ -d .github/workflows ] && echo "- entrega: .github/workflows/"
if [ "$found" -eq 0 ]; then
  echo "- nenhum manifest na raiz — rode \`tools/repo-facts.sh <subdir>\` se for monorepo"
fi

exit 0
