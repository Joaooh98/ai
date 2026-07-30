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

# Resolver o próprio caminho ANTES de trocar de diretório: ${BASH_SOURCE[0]} pode
# ser relativo ao cwd de quem chamou, e o `cd` abaixo invalidaria o relativo.
# `pwd -P` resolve o symlink que o instalador cria em ~/.claude/skills, chegando
# ao caminho real dentro do repositório da oficina.
_SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

PROJECT="${1:-${CLAUDE_PROJECT_DIR:-$(pwd)}}"
cd "$PROJECT" 2>/dev/null || cd "$(pwd)"

# Ausente o helper, seguimos sem ele: um toolbelt incompleto atrapalha menos que
# um toolbelt que não carrega.
WS_MEMBERS=""
if [ -r "$_SELF/../../../tools/_workspace.sh" ]; then
  # shellcheck source=/dev/null
  . "$_SELF/../../../tools/_workspace.sh"
  WS_MEMBERS="$(ws_members "$PROJECT")"
fi
WS_COUNT=0
[ -n "$WS_MEMBERS" ] && WS_COUNT="$(printf '%s\n' "$WS_MEMBERS" | wc -l | tr -d ' ')"

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
if [ "$WS_COUNT" -gt 0 ]; then
  # Workspace: a raiz não é repositório, mas os membros são. Dizer "sem remote"
  # aqui seria falso — e essa frase entra no contexto de todo agente.
  echo "- este projeto é um **workspace**: $WS_COUNT repositórios, a raiz NÃO é repo git"
  echo "- todo comando git precisa de \`-C <membro>\`: \`git -C micro-services/x log\`"
  remotes="$(while IFS= read -r m; do
               git -C "$PROJECT/$m" remote get-url origin 2>/dev/null
             done <<< "$WS_MEMBERS" | sort -u)"
  [ -z "$remotes" ] && echo "- nenhum membro tem remote — trabalho é local"
else
  remotes="$(git remote -v 2>/dev/null | awk '{print $2}' | sort -u)"
fi
if [ -z "$remotes" ]; then
  [ "$WS_COUNT" -eq 0 ] && echo "- sem remote git — trabalho é local"
else
  # Deduplica por HOST, não por URL: 17 membros no mesmo GitLab devem render uma
  # linha de conselho, não dezessete.
  hosts="$(printf '%s\n' "$remotes" \
           | sed -E 's#^[a-z]+://##; s#^[^@]+@##; s#[:/].*$##' | sort -u)"
  while IFS= read -r host; do
    [ -z "$host" ] && continue
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
  done <<< "$hosts"
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

# Os membros são o mapa do sistema: sem eles o agente vê pastas soltas em vez de
# um projeto. É a informação mais cara de redescobrir a cada sessão.
if [ "$WS_COUNT" -gt 0 ]; then
  echo "**Membros do workspace** ($WS_COUNT)"
  i=0
  while IFS= read -r m; do
    i=$((i + 1))
    if [ "$i" -gt 30 ]; then
      echo "- … e mais $((WS_COUNT - 30)). Lista completa: \`tools/repo-facts.sh\` na raiz"
      break
    fi
    printf -- '- `%s` — %s\n' "$m" "$(ws_stack "$PROJECT/$m")"
  done <<< "$WS_MEMBERS"
  echo "- **isto é layout de repositório, não arquitetura.** Não conclua daqui fronteira"
  echo "  de serviço, unidade de deploy nem dependência entre módulos: um repositório ou"
  echo "  dezessete é história de time. A arquitetura se lê no código."
  echo "- convenção de commit, branch e MR: \`tools/git-conventions.sh\`"
  echo
fi

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
  if [ "$WS_COUNT" -gt 0 ]; then
    echo "- sem manifest na raiz, e é esperado: cada membro tem o seu."
    echo "  Rode \`tools/repo-facts.sh <membro>\` antes de tocar em qualquer um."
  else
    echo "- nenhum manifest na raiz — rode \`tools/repo-facts.sh <subdir>\` se for monorepo"
  fi
fi

exit 0
