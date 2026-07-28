#!/usr/bin/env bash
# Coleta de evidência para incidente. Roda em segundos e responde a pergunta que
# resolve a maioria dos incidentes: "o que mudou?"
#
# Somente leitura. Nunca toca no sistema.
#
#   tools/incident-evidence.sh [horas]      janela padrão: 24h

set -uo pipefail
HOURS="${1:-24}"
SINCE="${HOURS} hours ago"

git rev-parse --git-dir >/dev/null 2>&1 || { echo "não é um repositório git"; exit 0; }

echo "=== JANELA: últimas ${HOURS}h ==="
echo

echo "--- COMMITS ---"
n=$(git log --since="$SINCE" --oneline 2>/dev/null | wc -l | tr -d ' ')
if [ "$n" -eq 0 ]; then
  echo "  nenhum commit na janela — a causa provavelmente não é código deste repo."
  echo "  últimos 5 commits, para referência:"
  git log --oneline -5 2>/dev/null | sed 's/^/    /'
else
  git log --since="$SINCE" --pretty=format:'  %h  %ad  %an  %s' --date=format:'%d/%m %H:%M' 2>/dev/null
  echo
fi

echo
echo "--- ARQUIVOS ALTERADOS NA JANELA, POR FREQUÊNCIA ---"
git log --since="$SINCE" --name-only --pretty=format: 2>/dev/null \
  | grep -v '^$' | sort | uniq -c | sort -rn | head -15 | sed 's/^/  /'

echo
echo "--- ÁREAS DE RISCO TOCADAS ---"
files="$(git log --since="$SINCE" --name-only --pretty=format: 2>/dev/null | grep -v '^$' | sort -u)"
risk() {
  local label="$1" pattern="$2" hits
  hits="$(printf '%s\n' "$files" | grep -Ei "$pattern" || true)"
  [ -n "$hits" ] && { printf -- '  [%s]\n' "$label"; printf '%s\n' "$hits" | sed 's/^/      /'; }
}
risk "MIGRACAO"     '(^|/)(migrations?|flyway|liquibase|alembic)/|schema\.(sql|rb|prisma)$|\.sql$'
risk "CONFIG"       '\.env|config\.(ya?ml|json|toml)|settings|properties$'
risk "DEPENDENCIA"  'package(-lock)?\.json|pom\.xml|requirements\.txt|go\.(mod|sum)|Cargo\.lock|Gemfile\.lock'
risk "INFRA/DEPLOY" 'gitlab-ci|\.github/workflows|Dockerfile|compose|terraform|helm|k8s'
risk "AUTH"         'auth|login|session|token|jwt|permission|role'
[ -z "$files" ] && echo "  (nenhum arquivo alterado na janela)"

echo
echo "--- TAGS / RELEASES RECENTES ---"
git for-each-ref --sort=-creatordate --format='  %(refname:short)  %(creatordate:format:%d/%m %H:%M)' refs/tags 2>/dev/null | head -5
[ -z "$(git tag 2>/dev/null)" ] && echo "  nenhuma tag"

echo
echo "--- ESTADO ATUAL ---"
printf '  branch: %s\n' "$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
printf '  HEAD:   %s\n' "$(git log -1 --pretty=format:'%h %s' 2>/dev/null)"
dirty=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
printf '  alterações não commitadas: %s\n' "$dirty"
[ "$dirty" -gt 0 ] && echo "  ATENÇÃO: árvore suja. Confirme se o que roda em produção é o que está aqui."

echo
echo "--- CANDIDATOS A BISSEÇÃO ---"
first=$(git log --since="$SINCE" --pretty=format:'%h' 2>/dev/null | tail -1)
if [ -n "$first" ]; then
  echo "  Se o sistema funcionava antes da janela:"
  echo "    git bisect start HEAD ${first}~1"
else
  echo "  Sem commits na janela — bissecção neste repo não vai ajudar."
fi

echo
echo "--- DEPENDÊNCIAS EXTERNAS REGISTRADAS ---"
REG="${CLAUDE_PROJECT_DIR:-.}/docs/sdlc/02-design/integrations.md"
if [ -f "$REG" ]; then
  grep -E '^## |^\*\*Criticidade|status' "$REG" 2>/dev/null | head -20 | sed 's/^/  /'
  echo "  (inventário completo: docs/sdlc/02-design/integrations.md — cheque as páginas de status)"
else
  echo "  Nenhum inventário em docs/sdlc/02-design/integrations.md."
  echo "  Sem ele, descartar 'foi o fornecedor' vira adivinhação. Liste as integrações depois"
  echo "  do incidente, com o integration-engineer."
fi

echo
echo "NOTA: isto é o que mudou NO REPOSITÓRIO. Se nada mudou aqui, a causa costuma estar fora:"
echo "dependência externa fora do ar, config alterada em runtime, certificado ou credencial"
echo "expirado, recurso esgotado, ou deploy de outro serviço."
exit 0
