#!/usr/bin/env bash
# Coleta de evidência para incidente. Roda em segundos e responde a pergunta que
# resolve a maioria dos incidentes: "o que mudou?"
#
# Num workspace (raiz sem git, com repositórios embaixo) varre todos os membros e
# ordena por recência — num sistema distribuído, saber QUAL serviço mudou na
# janela é metade do diagnóstico. Num repositório comum, comportamento de sempre.
#
# Somente leitura. Nunca toca no sistema.
#
#   tools/incident-evidence.sh [horas]      janela padrão: 24h

set -uo pipefail
HOURS="${1:-24}"
SINCE="${HOURS} hours ago"

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=/dev/null
[ -r "$SELF_DIR/_workspace.sh" ] && . "$SELF_DIR/_workspace.sh"

ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"

risk_scan() {  # risk_scan <arquivos>
  local files="$1"
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
}

# evidence_one <dir> — o relatório de um repositório.
evidence_one() {
  local d="$1" n files first dirty

  echo "--- COMMITS ---"
  n=$(git -C "$d" log --since="$SINCE" --oneline 2>/dev/null | wc -l | tr -d ' ')
  if [ "$n" -eq 0 ]; then
    echo "  nenhum commit na janela — a causa provavelmente não é código deste repo."
    echo "  últimos 5 commits, para referência:"
    git -C "$d" log --oneline -5 2>/dev/null | sed 's/^/    /'
  else
    git -C "$d" log --since="$SINCE" --pretty=format:'  %h  %ad  %an  %s' --date=format:'%d/%m %H:%M' 2>/dev/null
    echo
  fi

  echo
  echo "--- ARQUIVOS ALTERADOS NA JANELA, POR FREQUÊNCIA ---"
  git -C "$d" log --since="$SINCE" --name-only --pretty=format: 2>/dev/null \
    | grep -v '^$' | sort | uniq -c | sort -rn | head -15 | sed 's/^/  /'

  echo
  echo "--- ÁREAS DE RISCO TOCADAS ---"
  files="$(git -C "$d" log --since="$SINCE" --name-only --pretty=format: 2>/dev/null | grep -v '^$' | sort -u)"
  risk_scan "$files"

  echo
  echo "--- TAGS / RELEASES RECENTES ---"
  git -C "$d" for-each-ref --sort=-creatordate --format='  %(refname:short)  %(creatordate:format:%d/%m %H:%M)' refs/tags 2>/dev/null | head -5
  [ -z "$(git -C "$d" tag 2>/dev/null)" ] && echo "  nenhuma tag"

  echo
  echo "--- ESTADO ATUAL ---"
  printf '  branch: %s\n' "$(git -C "$d" rev-parse --abbrev-ref HEAD 2>/dev/null)"
  printf '  HEAD:   %s\n' "$(git -C "$d" log -1 --pretty=format:'%h %s' 2>/dev/null)"
  dirty=$(git -C "$d" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  printf '  alterações não commitadas: %s\n' "$dirty"
  [ "$dirty" -gt 0 ] && echo "  ATENÇÃO: árvore suja. Confirme se o que roda em produção é o que está aqui."

  echo
  echo "--- CANDIDATOS A BISSEÇÃO ---"
  first=$(git -C "$d" log --since="$SINCE" --pretty=format:'%h' 2>/dev/null | tail -1)
  if [ -n "$first" ]; then
    echo "  Se o sistema funcionava antes da janela:"
    echo "    git bisect start HEAD ${first}~1"
  else
    echo "  Sem commits na janela — bissecção neste repo não vai ajudar."
  fi
}

integrations_note() {
  echo
  echo "--- DEPENDÊNCIAS EXTERNAS REGISTRADAS ---"
  local reg="$ROOT/docs/sdlc/02-design/integrations.md"
  if [ -f "$reg" ]; then
    grep -E '^## |^\*\*Criticidade|status' "$reg" 2>/dev/null | head -20 | sed 's/^/  /'
    echo "  (inventário completo: docs/sdlc/02-design/integrations.md — cheque as páginas de status)"
  else
    echo "  Nenhum inventário em docs/sdlc/02-design/integrations.md."
    echo "  Sem ele, descartar 'foi o fornecedor' vira adivinhação. Liste as integrações depois"
    echo "  do incidente, com o integration-engineer."
  fi
}

# ------------------------------------------------------------------- workspace
MEMBERS=""
declare -F ws_members >/dev/null && MEMBERS="$(ws_members "$ROOT")"

if [ -n "$MEMBERS" ]; then
  total="$(printf '%s\n' "$MEMBERS" | wc -l | tr -d ' ')"
  echo "=== JANELA: últimas ${HOURS}h · WORKSPACE com $total membros ==="
  echo

  # Primeiro o mapa: qual serviço mexeu. Num sistema distribuído essa é a pergunta
  # que estreita o incidente de 17 candidatos para dois ou três.
  echo "--- QUAIS MEMBROS MUDARAM NA JANELA ---"
  hot=""
  while IFS= read -r m; do
    c=$(git -C "$ROOT/$m" log --since="$SINCE" --oneline 2>/dev/null | wc -l | tr -d ' ')
    last=$(git -C "$ROOT/$m" log -1 --format='%cr' 2>/dev/null || echo '-')
    if [ "$c" -gt 0 ]; then
      printf '  * %-38s %s commit(s) · último %s\n' "$m" "$c" "$last"
      hot="$hot$m"$'\n'
    else
      printf '    %-38s —          · último %s\n' "$m" "$last"
    fi
  done <<< "$MEMBERS"

  if [ -z "$hot" ]; then
    echo
    echo "NENHUM membro mudou na janela. A causa não está em código deste sistema:"
    echo "procure em dependência externa, config alterada em runtime, certificado ou"
    echo "credencial expirado, recurso esgotado, ou deploy de um sistema vizinho."
    integrations_note
    exit 0
  fi

  # Risco agregado antes do detalhe: dá a forma do incidente numa olhada.
  echo
  echo "--- ÁREAS DE RISCO TOCADAS (TODOS OS MEMBROS) ---"
  all=""
  while IFS= read -r m; do
    [ -z "$m" ] && continue
    all="$all$(git -C "$ROOT/$m" log --since="$SINCE" --name-only --pretty=format: 2>/dev/null \
               | grep -v '^$' | sed "s|^|$m/|")"$'\n'
  done <<< "$hot"
  risk_scan "$(printf '%s' "$all" | sort -u)"

  while IFS= read -r m; do
    [ -z "$m" ] && continue
    echo
    printf -- '========== %s ==========\n' "$m"
    evidence_one "$ROOT/$m"
  done <<< "$hot"

  integrations_note
  echo
  echo "NOTA: isto é o que mudou NOS REPOSITÓRIOS deste workspace. Membro que não"
  echo "aparece acima não mudou na janela — o que não o inocenta: ele pode estar"
  echo "quebrando por causa da mudança de um vizinho."
  exit 0
fi

# ------------------------------------------------------- repositório único
git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1 || { echo "não é um repositório git"; exit 0; }

echo "=== JANELA: últimas ${HOURS}h ==="
echo
evidence_one "$ROOT"
integrations_note

echo
echo "NOTA: isto é o que mudou NO REPOSITÓRIO. Se nada mudou aqui, a causa costuma estar fora:"
echo "dependência externa fora do ar, config alterada em runtime, certificado ou credencial"
echo "expirado, recurso esgotado, ou deploy de outro serviço."
exit 0
